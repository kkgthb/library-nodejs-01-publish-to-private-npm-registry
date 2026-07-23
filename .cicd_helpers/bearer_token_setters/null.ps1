Function Set-BearerTokenToNull {
    [System.Environment]::SetEnvironmentVariable('TARGET_NPM_REGISTRY_BEARER_TOKEN', $null, 'Process')
    If (-not [string]::IsNullOrWhiteSpace([System.Environment]::GetEnvironmentVariable('TARGET_NPM_REGISTRY_BEARER_TOKEN'))) {
        Throw "We did not actually clear the token"
    }
}

Set-BearerTokenToNull