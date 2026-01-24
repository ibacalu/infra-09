# Changelog

All notable changes to this project will be documented in this file.

## [1.2.2](https://github.com/ibacalu/infra-09/compare/v1.2.1...v1.2.2) (2026-01-24)


### Bug Fixes

* **dagster:** use instance.get_run_stats() for run duration ([3194234](https://github.com/ibacalu/infra-09/commit/3194234287e4ef37d707240b18a2d7ecf4b80939))

## [1.2.1](https://github.com/ibacalu/infra-09/compare/v1.2.0...v1.2.1) (2026-01-24)


### Bug Fixes

* **dagster:** enable prometheus sensors by default ([c3c5c23](https://github.com/ibacalu/infra-09/commit/c3c5c23df3669c2210c7a3eca1fdf353505a9171))

# [1.2.0](https://github.com/ibacalu/infra-09/compare/v1.1.0...v1.2.0) (2026-01-24)


### Bug Fixes

* **argocd:** add missing ref keys ([4d908e8](https://github.com/ibacalu/infra-09/commit/4d908e80b39897f4bb4aa1de1350fa4e456ff809))
* **argocd:** ignore diff ([da6be2b](https://github.com/ibacalu/infra-09/commit/da6be2b87ccdfdd93c363c758920e1f42fdc9aa7))
* cleanup ns from prometheus stack ([2a350a6](https://github.com/ibacalu/infra-09/commit/2a350a6872a64597d13a241756480b6de97af3cc))
* **grafana:** enable unified alerting ([a472d64](https://github.com/ibacalu/infra-09/commit/a472d643edf425c32bc6a824fec256f1d684e792))
* **kube-prometheus-stack:** avoid render issue ([094cc09](https://github.com/ibacalu/infra-09/commit/094cc0926b5886ce2d129bbfdc770916fcff9595))


### Features

* **dagster:** add custom prometheus metrics for job monitoring ([fdcac9d](https://github.com/ibacalu/infra-09/commit/fdcac9d157adbe0359850b7dd92184ab5bab1a15))

# [1.1.0](https://github.com/ibacalu/infra-09/compare/v1.0.1...v1.1.0) (2026-01-24)


### Bug Fixes

* **grafana:** define storage class ([f6a3781](https://github.com/ibacalu/infra-09/commit/f6a3781677267d971c89b368ac4753db08d0203a))
* **irsa:** move ebs-csi to pod identity ([d7dffca](https://github.com/ibacalu/infra-09/commit/d7dffca6174792d38d226424834ac3fc6f3d8268))
* **karpenter:** add spot service-linked role ([3fc73b1](https://github.com/ibacalu/infra-09/commit/3fc73b149c639cf7b392502f29fc12a2f9df29dd))


### Features

* **observability:** enable kube-prometheus-stack ([99b6a69](https://github.com/ibacalu/infra-09/commit/99b6a6957c26028e5e0ce5cebb1ed95845d52398))
* prepare for monitoring and alerting ([38411d0](https://github.com/ibacalu/infra-09/commit/38411d096c49dd49e485f55e683baa2fa2caf802))

## [1.0.1](https://github.com/ibacalu/infra-09/compare/v1.0.0...v1.0.1) (2026-01-23)


### Bug Fixes

* **karpenter:** overprovision ([29846cf](https://github.com/ibacalu/infra-09/commit/29846cfdbfb81618d2bae6738bc712b2c2284bd2))
* **keydb:** select amd nodes ([1c8b253](https://github.com/ibacalu/infra-09/commit/1c8b2538caad6571742c392396d12434831124c5))
* **pipelines:** add node_selector ([1b0dd57](https://github.com/ibacalu/infra-09/commit/1b0dd579b0d75bb05b1cf7c48061eba161318d3c))
* resolve certificate issues ([5e5dcc8](https://github.com/ibacalu/infra-09/commit/5e5dcc8c472242e49364c2ca81e65e4978910dce))

# 1.0.0 (2026-01-23)


### Bug Fixes

* **argocd:** update dex secret ([96bb862](https://github.com/ibacalu/infra-09/commit/96bb862a38a4bc2d95cfa2b4af40c3d4fc55d31d))
* **argocd:** update dex-sso secret ([f0b3c95](https://github.com/ibacalu/infra-09/commit/f0b3c95521d328fd17f8f0b74e206297c0427158))
* **cert-manager:** update issuers ([18492cc](https://github.com/ibacalu/infra-09/commit/18492cce3a5a92f4d0a2d708dd39be77e7d9e86c))
* **cert-manager:** update secret ([95c59bb](https://github.com/ibacalu/infra-09/commit/95c59bbf6032baefd3cd97c532aba777ce6fd792))
* **cert-manager:** use route53 ([e871de0](https://github.com/ibacalu/infra-09/commit/e871de0342f90bd0d1fdb5c10e1711f5df6f0364))
* **ci:** typo path ([187b062](https://github.com/ibacalu/infra-09/commit/187b0627b4ed62913557aa5cbcd3b5392819c5bd))
* **ci:** update dockerfile path ([efb2920](https://github.com/ibacalu/infra-09/commit/efb2920fb4d4c6b43b0dfbf95eadb2939a1704a0))
* **cloudnative-pg:** update storage class ([43a915f](https://github.com/ibacalu/infra-09/commit/43a915f56e7d286118879b13108fff94199b517e))
* **dagster:** add default storage class ([bfba647](https://github.com/ibacalu/infra-09/commit/bfba647bc332f2ef33b62a822520e91ee345d8fc))
* **dagster:** define redis storage class ([18fa527](https://github.com/ibacalu/infra-09/commit/18fa5272e636942ff281628c5e63e3e6609a7ca0))
* **dagster:** do not generate secret ([114aa95](https://github.com/ibacalu/infra-09/commit/114aa95fb1af44e02850cb36106ddac9bcf9511a))
* **dagster:** rename overlays ([5aeca32](https://github.com/ibacalu/infra-09/commit/5aeca324f8b37c41058c012fc04e818c0dac1acc))
* **dagster:** update db config ([09c6e12](https://github.com/ibacalu/infra-09/commit/09c6e122b010fc20893c1b9d9e17b7cb20199696))
* **dagster:** update db SA name ([d936bf3](https://github.com/ibacalu/infra-09/commit/d936bf35f1ed1f98a66206344ef48408636eece6))
* **dagster:** update ingress api version ([30a80fb](https://github.com/ibacalu/infra-09/commit/30a80fb9eb87477b8329ec4b517a02f15da49ae0))
* **dagster:** use correct secret ([ec4c9ca](https://github.com/ibacalu/infra-09/commit/ec4c9cacd590470a1317c4e2bd5f8b59201460cc))
* **dagster:** workaround templating failure ([3e65f94](https://github.com/ibacalu/infra-09/commit/3e65f94118bf7f3f85e762be063331aeb687c86f))
* **eso:** update config ([bac919c](https://github.com/ibacalu/infra-09/commit/bac919c5bd93284b77d649711906db1b8177a223))
* **eso:** update kustomize configuration ([70515a6](https://github.com/ibacalu/infra-09/commit/70515a6c1eb5da43f4f30d51a8dc148e893f99c2))
* **external-dns:** remove duplicate ([6e84f29](https://github.com/ibacalu/infra-09/commit/6e84f29ede36e36a9f8550b18c8538dd9f4b9485))
* **external-dns:** update secret ([3b2caac](https://github.com/ibacalu/infra-09/commit/3b2caaccb4d8f9e3bc33d88adfc777d92ed1257b))
* **external-dns:** use route53 ([09071e8](https://github.com/ibacalu/infra-09/commit/09071e88ee0bf812c0088c595e7eb5b9989ad4b8))
* **gitops:** cleanup override ([f0c013b](https://github.com/ibacalu/infra-09/commit/f0c013bf10b20fb776c391bf88606c4217942a25))
* **gitops:** update components ([85ea713](https://github.com/ibacalu/infra-09/commit/85ea713195a34167189563616324d65a8f8b0422))
* **gitops:** update org paths ([abf3444](https://github.com/ibacalu/infra-09/commit/abf344470e467e506294662dca8458c48e833b4d))
* **karpenter:** add amiselectorTerms ([b866871](https://github.com/ibacalu/infra-09/commit/b8668717f550a6f004bbc2278a769d3f0be20171))
* **karpenter:** add back consolidateAfter ([a090395](https://github.com/ibacalu/infra-09/commit/a090395424e5cff95c2d1dd18e62ac8d21599f21))
* **karpenter:** add missing permissions ([3526df9](https://github.com/ibacalu/infra-09/commit/3526df9bd919b791e4fb5d0d64bcfe1dac6205da))
* **karpenter:** add nodes ([5e747d2](https://github.com/ibacalu/infra-09/commit/5e747d20c3cee71e7a3c2c5003dff058b8da8c53))
* **karpenter:** allow arm nodes ([c8fd980](https://github.com/ibacalu/infra-09/commit/c8fd980222f37e3e19eb2ecef6af126cd91ad233))
* **karpenter:** attempting to fix karpenter permission issues ([e0ebc51](https://github.com/ibacalu/infra-09/commit/e0ebc51effcca06198a09decaea9e38327343042))
* **karpenter:** bump version ([2ab073c](https://github.com/ibacalu/infra-09/commit/2ab073cd5c04d0a9e2dbbccc55910e48df541219))
* **karpenter:** update config ([2d591dc](https://github.com/ibacalu/infra-09/commit/2d591dc791f3f2070446cd83646bb00125d4a5db))
* **karpenter:** update replicas and requests ([a2ca2b8](https://github.com/ibacalu/infra-09/commit/a2ca2b8bdc63d63740eabc4ee91740e1bf92e67b))
* **karpenter:** update resources ([371ef3b](https://github.com/ibacalu/infra-09/commit/371ef3bd9ad173d65f9614e826db7b3ad22149dc))
* **karpenter:** use kustomize ([835aef7](https://github.com/ibacalu/infra-09/commit/835aef7b30d12887caa71d0bc06b310583be82cf))
* **keydb:** set storageClass ([ef342f4](https://github.com/ibacalu/infra-09/commit/ef342f44539d86370007117dbc368e5b132a3c17))
* **keydb:** update environments ([c9c4956](https://github.com/ibacalu/infra-09/commit/c9c49568751eea58682f70ca67ac9ebb8515d30a))
* **management:** update baseline configuration ([6cb5eec](https://github.com/ibacalu/infra-09/commit/6cb5eecd86e8239c2420aa249dde6d574b30d25a))
* **pipeline:** update versions ([f8df64e](https://github.com/ibacalu/infra-09/commit/f8df64e306b1accc075ce762378315d3835cbb34))
* **prod:** add missing zone ([06a13e0](https://github.com/ibacalu/infra-09/commit/06a13e083811190245e14b10fe0abbdb8aee5b2b))
* remove traefik ([a97fc98](https://github.com/ibacalu/infra-09/commit/a97fc98917ca2496831a49305479c80450b7bf47))
* **secrets:** bootstrap eso ([f59fd07](https://github.com/ibacalu/infra-09/commit/f59fd074d4ba18edb82970c6bb1948b1bc5a0954))


### Features

* **aws:** add karpenter ([e5317cd](https://github.com/ibacalu/infra-09/commit/e5317cd407d5b47fe8331b11d88f341df824af33))
* **dagster:** add AMD64 node selectors and configure CeleryK8sRunLauncher ([e539f67](https://github.com/ibacalu/infra-09/commit/e539f679ef7de17ef9d49702a1c64f37ed68ccf1))
* **dagster:** enable initial configuration ([99bd3c0](https://github.com/ibacalu/infra-09/commit/99bd3c08344a6abd5a45cca31b046f1011b079c4))
* **dagster:** prepare initial deploy ([54fb206](https://github.com/ibacalu/infra-09/commit/54fb206f5b8a3f40c74a6be522823050a24f011a))
* **dagster:** use external KeyDB instead of built-in Redis ([2151dba](https://github.com/ibacalu/infra-09/commit/2151dbadc3b0c002dbb308d6ad1a1560dd9ee3a8))
* deploy prod environment ([a9faaa8](https://github.com/ibacalu/infra-09/commit/a9faaa881898039761ddf40a48aa418b00947c61))
* **gitops:** add initial scaffolding ([9fd647a](https://github.com/ibacalu/infra-09/commit/9fd647a204ed08ed3d0f3607b7f57536c26b1aef))
* **infra:** prepare management and modules ([ecde962](https://github.com/ibacalu/infra-09/commit/ecde9623061060e6071ab0d56181ada4fae4a520))
* prepare an image ([046db67](https://github.com/ibacalu/infra-09/commit/046db67edea05ef0f2fd94408dc7a91f3393e2ef))
* **redis:** deploy keydb ([4c8e6d5](https://github.com/ibacalu/infra-09/commit/4c8e6d5fc6e2de40d7538240487d61b6a7d00531))
* **secrets:** add ESO ([ffdba9a](https://github.com/ibacalu/infra-09/commit/ffdba9adaf187a6ff94514770e4ed0e7142c67c8))
