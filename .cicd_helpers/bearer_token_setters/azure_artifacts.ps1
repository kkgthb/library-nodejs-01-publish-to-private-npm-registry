Function Set-BearerTokenAgainstAzureArtifacts {
    $azure_devops_cloud_well_known_resource_guid = '499b84ac-1321-427f-aa17-267ca6975798'
    $azure_artifacts_bearer_token = az account get-access-token `
        --resource $azure_devops_cloud_well_known_resource_guid `
        --query 'accessToken' `
        --output 'tsv'
    [System.Environment]::SetEnvironmentVariable('TARGET_NPM_REGISTRY_BEARER_TOKEN', $azure_artifacts_bearer_token, 'Process')
    $azure_artifacts_bearer_token = $null
    If ([string]::IsNullOrWhiteSpace([System.Environment]::GetEnvironmentVariable('TARGET_NPM_REGISTRY_BEARER_TOKEN'))) {
        Throw "We did not actually get a token"
    }
}

Set-BearerTokenAgainstAzureArtifacts