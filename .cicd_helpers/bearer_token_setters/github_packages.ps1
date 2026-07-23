Function Set-BearerTokenAgainstGithubPackages {
    If ([string]::IsNullOrWhiteSpace([System.Environment]::GetEnvironmentVariable('GITHUB_TOKEN'))) {
        Throw "No GitHub token provided.  Set the GITHUB_TOKEN environment variable before running this script."
    }
    [System.Environment]::SetEnvironmentVariable('TARGET_NPM_REGISTRY_BEARER_TOKEN', [System.Environment]::GetEnvironmentVariable('GITHUB_TOKEN'), 'Process')
    If ([string]::IsNullOrWhiteSpace([System.Environment]::GetEnvironmentVariable('TARGET_NPM_REGISTRY_BEARER_TOKEN'))) {
        Throw "We did not actually get a token"
    }
}

Set-BearerTokenAgainstGithubPackages
