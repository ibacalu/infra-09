#!/bin/bash

LOGFILE="/tmp/${ARGOCD_APP_NAME}.qts.render.log"
ENVIRONMENT=${ARGOCD_ENV_ENVIRONMENT:-development}
HELM_CONFIG=".helm"
HELM_VALUES=""

truncate -s 0 "$LOGFILE"
# Log some information
{ date; pwd; ls -lah; echo "Plugin: qts"; echo "Revision: $ARGOCD_APP_REVISION"; } >> "$LOGFILE"

info() {
  echo -e "$(date +%Y-%m-%d\ %H:%M:%S) - [INFO]\t $1" >> "$LOGFILE"
}

debug() {
  if [ "$ARGOCD_ENV_DEBUG" == "true" ]; then
    echo -e "$(date +%Y-%m-%d\ %H:%M:%S) - [DEBUG]\t $1" >> "$LOGFILE"
  fi
}

warn() {
  echo -e "$(date +%Y-%m-%d\ %H:%M:%S) - [WARN]\t \033[33m$1\033[0m" >> "$LOGFILE"
}

error() {
  echo -e "$(date +%Y-%m-%d\ %H:%M:%S) - [ERROR]\t \033[31m$1\033[0m" >> "$LOGFILE"
}

login() {
  local usage="Usage: $FUNCNAME <helm-config-path>"
  local config=${1:?$usage}
  local repo=$(yq eval '.config.repository' "$config")

  if yq '.config.login // null' "$config" > /dev/null; then
    info "Logging in to $repo..."
    local user pass
    user=$(yq '.config.login.user' "$config") || error "User not found in $config"
    pass=$(yq '.config.login.pass' "$config") || error "Password not found in $config"

    info "Logging into $repo"
    echo "$pass" | helm registry login "$repo" --username "$user" --password-stdin
  fi
}

load_values() {
  local usage="Usage: $FUNCNAME <helm-config-path>"
  local config=${1:?$usage}
  local error=false

  info "--- Loading App Config..."
  local name=$(yq '.metadata.name' $config)

  while IFS= read -r file; do
    local file_path="$(realpath $file)"
    info "file_path: $file_path"
    if [ -f "$file_path" ]; then
      info "  - loading values $file_path"
      process_values "$file_path"
      HELM_VALUES="$HELM_VALUES -f $file_path"
    elif [ -d "$file_path" ]; then
      info "file_path $file_path is a dir"
      local counter=0
      while IFS= read -r item; do
        ((counter+=1))
        info "  - loading values $item"
        process_values "$item"
        HELM_VALUES="$HELM_VALUES -f $item"
      done < <(find $file_path -type f -name "*.y*ml")
      if [ $counter -eq 0 ]; then
        error "'$file' path contains no '*.y*ml' files."
        error=true
        break
      else
        info "Loaded $counter values from '$file'"
      fi
    else
      error "Error: Path '$file' does not exist."
      # TODO: Add support for URLs
      error=true
      break
    fi
  done < <(yq ".config.values[]" "$config")

  if $error; then
    error "Critical error encountered. Rendering aborted..."
    exit 1
  fi
}

getArgs() {
  local string=${1}
  RESOURCE_PATH=$(echo "$string" | cut -d'#' -f1)
  RESOURCE_NAMESPACE=$(echo "$RESOURCE_PATH" | grep -Po '^.*(?=\/)')
  RESOURCE_NAME=$(echo "$RESOURCE_PATH" | grep -Po '(?<=\/).*$')
  RESOURCE_KEY=$(echo "$string" | cut -d'#' -f2 | cut -d'|' -f1)
  RESOURCE_VERSION=$(echo "$string" | cut -d'#' -f3 | cut -d'|' -f1)
  RESOURCE_OPTIONS=$(echo "$string" | grep '|' | cut -d'|' -f2)
  SAFESTRING=$(echo "$string" | sed -r 's/([\$\(\)\|])/\\\0/g')
}

handle_yaml_replacement() {
  local filepath=$1
  local type=$2
  local string=$3
  local content=$4
  local safe_string=$(echo "$string" | sed -r 's/([\$\(\)\|])/\\\0/g')
  
  # Log for debugging
  info "Replacing placeholder '$string' with YAML content for $type"
  debug "Content to insert:\n---\n$content\n---"
  
  # Get the line with the placeholder
  local line_with_placeholder=$(grep -F "$string" "$filepath")
  if [ -z "$line_with_placeholder" ]; then
    error "Placeholder '$string' not found in $filepath"
    return 1
  fi
  
  # Find the indentation level of the placeholder
  local indent_spaces=$(echo "$line_with_placeholder" | sed -E 's/^( *).*/\1/' | tr -d '\n' | wc -c | tr -d ' ')
  
  debug "Line with placeholder: \n---\n$line_with_placeholder\n---"
  debug "Base indent level: '$indent_spaces' spaces"
  
  # Determine if placeholder is alone on a line or part of a key-value pair
  local placeholder_is_value=false
  local left_side=$(echo "$line_with_placeholder" | tr -d ' ')
  local right_side="\$($type:$string)"
  debug "Left side: '$left_side'"
  debug "Right side: '$right_side'"
  if [ "$left_side" = "$right_side" ]; then
    # Placeholder is alone on a line - use the same indentation
    debug "Placeholder is alone on a line - keeping base indent level: '$indent_spaces' spaces"
  else
    # Placeholder is the value of a key - increment indent for YAML content
    indent_spaces=$((indent_spaces + 2))
    placeholder_is_value=true
    debug "Placeholder is a value - adding 2 spaces to indent level, new indent: '$indent_spaces' spaces"
  fi
  
  # Create temporary files
  local temp_file="/tmp/${ARGOCD_APP_NAME}-temp-${RANDOM}.yaml"
  local temp_content_file="/tmp/${ARGOCD_APP_NAME}-content-${RANDOM}.yaml"
  
  # Add the content with proper indentation
  debug "Adding content with proper indentation"
  echo "$content" | while IFS= read -r line; do
    echo "$(printf "%${indent_spaces}s%s" "" "$line")" >> "$temp_content_file"
  done
  
  # Get line number where placeholder is found
  local placeholder_line=$(grep -n -F "$string" "$filepath" | cut -d':' -f1)
  debug "Placeholder line: '$placeholder_line'"
  
  # Create the new file by:
  # 1. Copy all lines before the placeholder
  debug "Copying all lines before the placeholder"
  
  if [ "$placeholder_is_value" = true ]; then
    # If placeholder is part of a key-value pair, keep the line with the key
    # and replace only the value part in the next step
    head -n $((placeholder_line)) "$filepath" > "$temp_file"
    
    # Get the key part and append it to the temp file
    local key_part=$(echo "$line_with_placeholder" | sed -E 's/^([^:]+:).*/\1/')
    debug "Key part: '$key_part'"
    
    # Remove the last line (the one with the placeholder)
    sed -i '$d' "$temp_file"
    
    # Add the key line back to the file
    echo "$key_part" >> "$temp_file"
  else
    # If placeholder is on its own line, just exclude that line
    head -n $((placeholder_line - 1)) "$filepath" > "$temp_file"
  fi
  
  # 2. Add the content with proper indentation from the temp content file
  cat "$temp_content_file" >> "$temp_file"
  
  # 3. Add all lines after the placeholder
  debug "Adding all lines after the placeholder"
  tail -n +$((placeholder_line + 1)) "$filepath" >> "$temp_file"
  
  # Check if the operation was successful
  if [ $? -eq 0 ] && [ -s "$temp_file" ]; then
    # Validate the YAML structure (optional)
    if command -v yq &>/dev/null; then
      if yq eval '.' "$temp_file" &>/dev/null; then
        mv "$temp_file" "$filepath"
        info "YAML content for $type has been processed successfully"
      else
        error "Resulting YAML is not valid"
        debug "\n---\n$(cat "$temp_file")\n---"
        rm -f "$temp_file" "$temp_content_file"
        restore "$filepath"
        return 1
      fi
    else
      # If yq is not available, just use the file
      mv "$temp_file" "$filepath"
      info "YAML content for $type has been processed successfully"
    fi
  else
    error "Failed to process YAML content for $type"
    rm -f "$temp_file" "$temp_content_file"
    restore "$filepath"
    return 1
  fi
  
  # Clean up
  rm -f "$temp_content_file" 2>/dev/null
  return 0
}

vault_get_value() {
  VAULT_ADDR=${VAULT_ADDR:?VAULT_ADDR must be set}
  VAULT_AUTH_BACKEND=${VAULT_AUTH_BACKEND:?VAULT_AUTH_BACKEND must be set}
  VAULT_SECRET_BACKEND=${VAULT_SECRET_BACKEND:?VAULT_SECRET_BACKEND must be set}
  VAULT_SA_TOKEN="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
  
  retry=0
  while [ $retry -le 5 ]; do
    warn "Auth to Vault [$retry]"
    VAULT_TOKEN_REQUEST=$(curl -k --request POST --data "{\"jwt\": \"$VAULT_SA_TOKEN\", \"role\": \"argo\"}" "${VAULT_ADDR}/v1/auth/${VAULT_AUTH_BACKEND}/login")
    VAULT_TOKEN=$(echo "$VAULT_TOKEN_REQUEST" | yq -r '.auth.client_token')
    if [ "$VAULT_TOKEN" == "null" ]; then
      warn "VAULT_TOKEN is null"
      warn "VAULT_TOKEN_REQUEST: ${VAULT_TOKEN_REQUEST}"
    else
      break
    fi
    if [ $retry -le 5 ]; then
      retry=$(( retry + 1 ))
    else
      error "VAULT_TOKEN is null. Sent logs to ${LOGFILE}"
      exit 1
    fi
  done

  if [ -z "$RESOURCE_VERSION" ]; then
    RESOURCE_URL="${VAULT_ADDR}/v1/${VAULT_SECRET_BACKEND}/data/service/${RESOURCE_PATH}"
  else
    RESOURCE_URL="${VAULT_ADDR}/v1/${VAULT_SECRET_BACKEND}/data/service/${RESOURCE_PATH}?version=${RESOURCE_VERSION}"
  fi

  retry=0
  while [ $retry -le 5 ]; do
    info "Retrieving secret from Vault [$retry]"
    curl -k -sSk -H "Authorization: Bearer $VAULT_TOKEN" --request GET "${RESOURCE_URL}" -o response.json
    VALUE=$(yq ".data.data.\"${RESOURCE_KEY}\"" response.json)
    if [ "$VALUE" == "null" ] || [ -z "$VALUE" ]; then
      warn "VALUE '${string}' is null"
      cat response.json >> "$LOGFILE"
    else
      debug "${RESOURCE_KEY}: \n---\n${VALUE}\n---"
      break
    fi
    if [ $retry -le 5 ]; then
      retry=$(( retry + 1 ))
    else
      error "VALUE '${string}' is null. Sent logs to ${LOGFILE}"
      exit 1
    fi
  done
}

k8s_get_value() {
  RESOURCE_TYPE=${1:-configmaps}
  SA_TOKEN="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
  RESOURCE_URL="https://kubernetes.default:443/api/v1/namespaces/${RESOURCE_NAMESPACE}/${RESOURCE_TYPE}/${RESOURCE_NAME}"

  retry=0
  while [ $retry -le 5 ]; do
    info "Retrieving ${RESOURCE_TYPE} from Kubernetes [$retry]"
    curl -k -sSk -H "Authorization: Bearer $SA_TOKEN" --request GET "${RESOURCE_URL}" -o response.json
    VALUE=$(yq ".data.\"${RESOURCE_KEY}\"" response.json)
    if [ "$VALUE" == "null" ] || [ -z "$VALUE" ]; then
      warn "VALUE '${string}' is null"
      cat response.json >> "$LOGFILE"
    else
      # Automatically decode base64 if resource type is secrets
      if [ "$RESOURCE_TYPE" == "secrets" ]; then
        VALUE=$(echo -n "$VALUE" | base64 -d)
        info "Automatically decoded secret value for ${RESOURCE_KEY}"
      fi
      debug "${RESOURCE_KEY}: \n---\n${VALUE}\n---"
      break
    fi
    if [ $retry -le 5 ]; then
      retry=$(( retry + 1 ))
    else
      error "VALUE '${string}' is null. Sent logs to ${LOGFILE}"
      exit 1
    fi
  done
}

options() {
  RESOURCE_OPTIONS=$(echo "$string" | grep '|' | cut -d'|' -f2)

  if [ -z "$RESOURCE_OPTIONS" ]; then
    info "No options detected"
  else
    info "Options detected: ${RESOURCE_OPTIONS}"
    case "$RESOURCE_OPTIONS" in
      b64enc)
        VALUE=$(echo -n "$VALUE" | base64 -w 0)
        ;;
      b64dec)
        VALUE=$(echo -n "$VALUE" | base64 -d)
        ;;
      str)
        VALUE="\"$VALUE\""
        ;;
      yaml)
        # For YAML option, we don't need to do anything to the value
        # as it will be inserted as YAML in the process_secrets function
        info "Using yaml option for value"
        ;;
      trunc*)
        LENGTH=${RESOURCE_OPTIONS#trunc }
        if [[ $LENGTH =~ ^-?[0-9]+$ ]]; then
          if [ $LENGTH -ge 0 ]; then
            VALUE=${VALUE:0:$LENGTH}
          else
            VALUE=${VALUE:$LENGTH}
          fi
        else
          error "Invalid length for trunc option"
        fi
        ;;
    esac
  fi
}

backup() {
  local usage="Usage: $FUNCNAME <file-path>"
  local filepath=${1:?$usage}
  local filename=$(basename "$filepath")
  info "Backing $filepath"
  cp -f $filepath /tmp/$ARGOCD_APP_NAME-$ARGOCD_APP_REVISION-$filename
}

restore() {
  local usage="Usage: $FUNCNAME <file-path>"
  local filepath=${1:?$usage}
  local filename=$(basename "$filepath")
  warn "Restoring $filepath"
  cp -f /tmp/$ARGOCD_APP_NAME-$ARGOCD_APP_REVISION-$filename $filepath
}

process_vault() {
  local usage="Usage: $FUNCNAME <file-path>"
  local filepath=${1:?$usage}
  if [ -z "$VAULT_ADDR" ]; then
    warn "Vault is not enabled. Skipping '${filepath}'"
    return
  fi
  #? Get values for Vault Secrets
  while IFS= read -r string; do
    info "[Vault]: Replacing '${string}'"
    backup "$filepath"
    getArgs "$string"
    vault_get_value
    options

    if [ "$(echo "$VALUE" | wc -l)" -gt 1 ]; then
      warn "${string} is multiline"
      
      # Check if yaml option is specified
      if [[ "$RESOURCE_OPTIONS" == "yaml" ]]; then
        info "Processing as YAML structure"
        handle_yaml_replacement "$filepath" "vault" "$string" "$VALUE"
      else
        # Regular multiline string replacement
        string=$string safestring=$SAFESTRING val=$VALUE yq -i '(.. | select(. == "*$(vault:"+ env(string) +")*")) |= sub("\$\(vault:"+ env(safestring) +"\)", strenv(val))' $filepath || restore "$filepath"
      fi
    else
      sed -i -e "s|\$(vault:${SAFESTRING})|${VALUE}|g" $filepath || restore "$filepath"
    fi
    backup "$filepath"
  done < <(grep -Po '(?<=\$\(vault:).+#.+(?=\))' $filepath | sort --unique | grep -v '\$')
}

process_secrets() {
  local usage="Usage: $FUNCNAME <file-path>"
  local filepath=${1:?$usage}

  #? Get values for Secrets

  while IFS= read -r string; do
    info "[Secret]: Replacing '${string}'"
    backup "$filepath"
    getArgs "$string"
    k8s_get_value secrets
    options

    if [ "$(echo "$VALUE" | wc -l)" -gt 1 ]; then
      warn "${string} is multiline"
      
      # Check if yaml option is specified
      if [[ "$RESOURCE_OPTIONS" == "yaml" ]]; then
        info "Processing as YAML structure"
        handle_yaml_replacement "$filepath" "secret" "$string" "$VALUE"
      else
        # Regular multiline string replacement
        string=$string safestring=$SAFESTRING val=$VALUE yq -i '(.. | select(. == "*$(secret:"+ env(string) +")*")) |= sub("\$\(secret:"+ env(safestring) +"\)", strenv(val))' $filepath || restore "$filepath"
      fi
    else
      # If it's not a multiline value, use the original sed replacement
      sed -i -e "s|\$(secret:${SAFESTRING})|${VALUE}|g" $filepath || restore "$filepath"
    fi
    backup "$filepath"
  done < <(grep -Po '(?<=\$\(secret:).+#.+(?=\))' $filepath | sort --unique | grep -v '\$')
}

process_configmaps() {
  local usage="Usage: $FUNCNAME <file-path>"
  local filepath=${1:?$usage}

  #? Get values for ConfigMaps
  while IFS= read -r string; do
    info "[ConfigMap]: Replacing '${string}'"
    backup "$filepath"
    getArgs "$string"
    k8s_get_value configmaps
    options

    if [ "$(echo "$VALUE" | wc -l)" -gt 1 ]; then
      warn "${string} is multiline"
      
      # Check if yaml option is specified
      if [ "$RESOURCE_OPTIONS" = "yaml" ]; then
        info "Processing as YAML structure"
        handle_yaml_replacement "$filepath" "configmap" "$string" "$VALUE"
      else
        # Regular multiline string replacement
        string=$string safestring=$SAFESTRING val=$VALUE yq -i '(.. | select(. == "*$(configmap:"+ env(string) +")*")) |= sub("\$\(configmap:"+ env(safestring) +"\)", strenv(val))' $filepath || restore "$filepath"
      fi
    else
      sed -i -e "s|\$(configmap:${SAFESTRING})|${VALUE}|g" $filepath || restore "$filepath"
    fi
    backup "$filepath"
  done < <(grep -Po '(?<=\$\(configmap:).+#.+(?=\))' $filepath | sort --unique | grep -v '\$')
}

process_envvar() {
  local usage="Usage: $FUNCNAME <file-path>"
  local filepath=${1:?$usage}

  #? Get values for ENV variables
  while IFS= read -r string; do
    info "[ENV]: Replacing '${string}'"
    backup "$filepath"
    SAFESTRING=$(echo "$string" | sed -r 's/([\$\(\)\|])/\\\0/g')
    VAR_NAME=$(echo "$string" | cut -d'|' -f1)
    if [[ $VAR_NAME == ARGOCD_APP_* ]]; then
      S_STRING="$VAR_NAME"
    else
      S_STRING="ARGOCD_ENV_${VAR_NAME}"
    fi
    VALUE="${!S_STRING:-$string is not defined}"
    options
    sed -i -e "s|\$(env:${SAFESTRING})|${VALUE}|g" $filepath || restore "$filepath"
    backup "$filepath"
  done < <(grep -Po '(?<=\$\(env:).+(?=\))' $filepath | sort --unique | grep -v '\$')
}

process_values() {
  local usage="Usage: $FUNCNAME <file-path>"
  local filepath=${1:?$usage}
  process_vault "$filepath"
  process_secrets "$filepath"
  process_configmaps "$filepath"
  process_envvar "$filepath"
}

helm_template() {
  local usage="Usage: $FUNCNAME <config-path>"
  local config=${1:?$usage}

  local repo chart version namespace output
  repo=$(yq -e '.config.repository' "$config")
  chart=$(yq -e '.config.chart' "$config")
  version=$(yq -e '.config.version' "$config")
  namespace=$(yq -e '.metadata.namespace // env(ARGOCD_APP_NAMESPACE)' "$config")
  output=$(yq -e '.config.output' "$config")

  local chart_ref

  if [[ "$repo" == oci://* ]]; then
    info "OCI Repository detected"
    chart_ref="${repo}/${chart}"
  else
    local repo_name
    repo_name=$(basename "$repo")
    info "Adding helm repo: '$repo'"
    helm repo add "$repo_name" "$repo" >/dev/null 2>&1 || true
    helm repo update "$repo_name" >/dev/null 2>&1 || true
    chart_ref="${repo_name}/${chart}"
  fi

  info "Running helm template for chart: $chart_ref"
  info "Chart Version: $version"
  info "App Namespace: $namespace"
  if helm template "$chart_ref" \
    --name-template $ARGOCD_APP_NAME \
    --version "$version" \
    $HELM_VALUES \
    --namespace "$namespace" \
    --include-crds 2> >(tee "/tmp/${ARGOCD_APP_NAME}-helm.error.log" >&2) \
    | yq . > "$output"; then
    info "Helm template rendered successfully: $output"
  else
    error "Helm template failed"
    cat "/tmp/${ARGOCD_APP_NAME}-helm.error.log" | while read -r line; do error "[ERROR] $line"; done
    return 1
  fi
}

kustomization() {
  local usage="Usage: $FUNCNAME <output-path>"
  local output=${1:?$usage}
  local error=false

  touch kustomization.yaml
  
  if [ "$output" != "none" ]; then
    info "Preparing kustomization for output: $output"

    if ! kustomize edit add resource "$output" 2> >(tee "/tmp/${ARGOCD_APP_NAME}-kustomize.error.log" >&2); then
      error "Failed to add resource to kustomization.yaml"
      cat "/tmp/${ARGOCD_APP_NAME}-kustomize.error.log" | while read -r line; do error "[ERROR] $line"; done
      error=true
    fi
  else
    info "No output specified. Skipping kustomization."
  fi

  if kustomize build > render.yaml 2> >(tee "/tmp/${ARGOCD_APP_NAME}-kustomize.error.log" >&2); then
    info "Kustomize build completed successfully: render.yaml"
  else
    error "Kustomize build failed"
    cat "/tmp/${ARGOCD_APP_NAME}-kustomize.error.log" | while read -r line; do error "[ERROR] $line"; done
    error=true
  fi

  if [ "$ARGOCD_ENV_DEBUG" == "true" ]; then
    warn "DEBUG is enabled. Saving logs."
    mkdir -p "/tmp/${ARGOCD_APP_NAME}"
    cp kustomization.yaml "/tmp/${ARGOCD_APP_NAME}/"
    cp render.yaml "/tmp/${ARGOCD_APP_NAME}/"
  fi

  if $error; then
    error "Critical errors encountered. Rendering aborted..."
    exit 1
  fi

  info "Processing final manifests..."
  process_values "render.yaml"
}

if [ -f ".helm" ]; then
  info "Helm package configuration"
  load_values $HELM_CONFIG
  login $HELM_CONFIG
  helm_template $HELM_CONFIG

  output="$(yq '.config.output // "manifest.yaml"' "$HELM_CONFIG")"
  kustomization "$output"
else
  info "Kustomize package configuration"
  kustomization "none"
fi
