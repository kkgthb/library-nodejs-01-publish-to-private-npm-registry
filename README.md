# Maintaining and publishing packages within this repository

1. Make sure to find-and-replace `@insertyourcompanynamespacehere` everywhere in this codebase with your own company's NPM package namespace.
1. Make sure to increment to a new appropriately-meaningful "semver"-style version number, in the body of a given `package.json` file, if you've made changes to the behavior of the package.
1. Have your CI/CD pipeline's **build** stage run `./.cicd_helpers/run_npm_pack.ps1`, passing in a `-WhichPackage` parameter value that indicates which package source code you'd like to transform into an appropriate Tarball _(`.tgz`)_ file.
    * _(Right now, `HelloWorld` / `[WhichPkg]::HelloWorld` is the only option.)_
1. Log your CI/CD pipeline's **publish** stage into an appropriate identity provider, fetch whatever `Bearer` token your it will need for authenticating into your chosen target NPM registry, and store it as an operating system environment variable named `TARGET_NPM_REGISTRY_BEARER_TOKEN`.
    * _(See the `./.cicd_helpers/bearer_token_generators` folder for examples for some major target NPM registries.)_
1. Have your CI/CD pipeline's **publish stage**, run `./cicd_helpers/run_npm_publish.ps1`, passing in a `-DistPath` parameter value that points to the **folder** that contains the previous step's `.tgz` file.
1. Manually validate that your targeted NPM registry now actually contains your new version of the package you published.
