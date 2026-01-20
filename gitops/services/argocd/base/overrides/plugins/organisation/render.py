#!/usr/bin/env python

import os
import sys
import yaml
from functools import reduce
import operator
import logging

LOGFILE=f'/tmp/{os.environ.get("ARGOCD_APP_NAME")}.org.render.log'
logging.basicConfig(filename=LOGFILE, level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')

# Find default value
def find(element, dict, default):
    try:
        value = reduce(operator.getitem, element.split('.'), dict)
    except:
        value = reduce(operator.getitem, element.split('.'), default)
    return value

# Load .organisation
logging.debug("Loading .organisation")
with open('.organisation', 'r') as file:
    defaults = yaml.safe_load(file)

# Current cluster name and environment from environment variables
cluster_name = os.getenv('CLUSTER_NAME')
environment = os.getenv('ARGOCD_ENV_ENVIRONMENT')

logging.debug(f"ClusterName: '{cluster_name}'")
logging.debug(f"Environment: '{environment}'")

# Load environment configuration
with open(f'environments/{environment}.yaml', 'r') as file:
    environment_data = yaml.safe_load(file)

# Filter clusters by name
clusters = [c for c in environment_data['spec']['clusters'] if c['name'] == cluster_name]

# If no matching clusters found, exit
if not clusters:
    logging.error(f"No matching clusters found for '{cluster_name}'")
    exit()

# Applications for the matching cluster
cluster_apps = {app['name']: app for app in clusters[0]['applications']}

projects = []
applications = []

# Process all projects
for project_file in os.listdir('projects'):
    with open(f'projects/{project_file}', 'r') as file:
        project_data = yaml.safe_load(file)

    logging.debug(f"Project: '{project_data['metadata']['name']}'")

    # Filter project applications by those present in the cluster
    project_apps = [app for app in project_data['spec']['applications'] if app['name'] in cluster_apps]

    # If no matching applications found, continue to next project
    if not project_apps:
        logging.debug(f"No matching applications found for project '{project_data['metadata']['name']}'")
        continue

    # Get project annotations (from defaults and project data)
    project_annotations = defaults.get('annotations', {}).copy()
    project_annotations.update(project_data.get('metadata', {}).get('annotations', {}) or {})
    
    # Always ensure the sync-wave is set to at least -10 (projects must be created before apps)
    project_annotations['argocd.argoproj.io/sync-wave'] = project_annotations.get('argocd.argoproj.io/sync-wave', "-10")

    # Create AppProject
    app_project = {
        'apiVersion': 'argoproj.io/v1alpha1',
        'kind': 'AppProject',
        'metadata': {
            'name': project_data['metadata']['name'],
            'namespace': 'argocd',
            'annotations': project_annotations
        },
        'spec': project_data['spec']['appProject']
    }

    projects.append(app_project)

    # Create Application for each matching application in the project
    for app in project_apps:
        logging.debug(f"Application: '{app['name']}'")

        cluster_app = cluster_apps[app['name']]
        logging.debug(f"Cluster Application: '{cluster_app['name']}'")
        # Get Application ENV VARS (defaults and defined in environment.yaml)
        app_env_vars = defaults.get('environment', {}).copy()
        app_env_vars.update(cluster_app.get('environment', {}) or {})
        
        # Get Application Overrides (defaults and defined in environment.yaml)
        app_overrides = defaults.get('overrides', {}).copy()
        app_overrides.update(cluster_app.get('overrides', {}) or {})
        
        # Set values
        app_overlay_dir = app_overrides.get('overlay_dir', environment)
        app_overlay_path = app_overrides.get('overlays_path', find('overlays_path', app, defaults))
        app_overlay_path = f"{app_overlay_path}/{app_overlay_dir}"

        # Get application annotations (from defaults, app definition, and cluster_app)
        app_annotations = defaults.get('annotations', {}).copy()
        app_annotations.update(app.get('annotations', {}) or {})
        app_annotations.update(cluster_app.get('annotations', {}) or {})

        application = {
            'apiVersion': 'argoproj.io/v1alpha1',
            'kind': 'Application',
            'metadata': {
                'name': app.get('name'),
                'annotations': app_annotations,
                'finalizers': ['resources-finalizer.argocd.argoproj.io']
            },
            'spec': {
                'project': project_data['metadata']['name'],
                'source': {
                    'repoURL': app.get('repoURL'),
                    'path': app_overlay_path,
                    'targetRevision': app.get('targetRevision'),
                },
                'destination': {
                    'server': 'https://kubernetes.default.svc',
                    'namespace': app.get('namespace', str(app.get('name'))),
                },
                "syncPolicy": {
                    "syncOptions": find("syncPolicy.syncOptions", app, defaults)
                },
            }
        }

        # Add plugin section only if env variables exist
        if app_env_vars:
            application['spec']['source']['plugin'] = {
                'env': [{'name': str(key), 'value': str(value)} for key, value in app_env_vars.items()]
            }

        # Add ignoreDifferences support:
        ignore_differences = cluster_app.get('ignoreDifferences')
        if ignore_differences is None:
            ignore_differences = app.get('ignoreDifferences')
        if ignore_differences is None:
            ignore_differences = defaults.get('ignoreDifferences')
        if ignore_differences:
            application['spec']['ignoreDifferences'] = ignore_differences

        # Add automated sync policy only if selfHeal or prune are not false
        self_heal = find("syncPolicy.automated.selfHeal", app, defaults)
        prune = find("syncPolicy.automated.prune", app, defaults)
        
        if self_heal is not False or prune is not False:
            application['spec']['syncPolicy']['automated'] = {}
            if self_heal is not False:
                application['spec']['syncPolicy']['automated']['selfHeal'] = self_heal
            if prune is not False:
                application['spec']['syncPolicy']['automated']['prune'] = prune

        applications.append(application)

for project in projects:
    print("---")
    yaml.dump(project, sys.stdout)
for app in applications:
    print("---")
    yaml.dump(app, sys.stdout)
