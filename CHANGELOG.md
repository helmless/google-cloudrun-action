# Changelog

## [0.2.0](https://github.com/helmless/google-cloudrun-deploy-action/compare/v0.1.0...v0.2.0) (2025-03-10)


### Features

* combine template and deploy in single action ([#3](https://github.com/helmless/google-cloudrun-deploy-action/issues/3)) ([ad3b925](https://github.com/helmless/google-cloudrun-deploy-action/commit/ad3b9253a572be7dfb3fcf150379de2b0ccd43f9))

## 0.1.0 (2024-12-01)


### ⚠ BREAKING CHANGES

* it is now required to do authenticationin the own pipeline, e.g. using `google-github-actions/auth`

### Features

* move and split up action into separate parts ([b95e469](https://github.com/helmless/google-cloudrun-deploy-action/commit/b95e46965172b9cba54b5ac5d41ae5ae2ae9f8f2))


### Bug Fixes

* remove access_token request ([b95b8b8](https://github.com/helmless/google-cloudrun-deploy-action/commit/b95b8b862925a605d0fece61421d53be65fef356))
* remove auth from action ([991607b](https://github.com/helmless/google-cloudrun-deploy-action/commit/991607b8e579603ff220a63ff49a1421d493b263))
* update release-please and readmep ([ce222df](https://github.com/helmless/google-cloudrun-deploy-action/commit/ce222dffcdb84b57adb383edb647cc82a8246893))
* update secret refs in action input ([84a8313](https://github.com/helmless/google-cloudrun-deploy-action/commit/84a831353ca031423c8be47e488732ee64ce17c3))
* use location label to extract region ([09f7682](https://github.com/helmless/google-cloudrun-deploy-action/commit/09f76822d63ec812a1833f7537c39cff20755a82))
