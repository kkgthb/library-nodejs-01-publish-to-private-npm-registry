Param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $OrgName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $ProjectName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $FeedName
)
Function Set-NpmUserConfigOverrideForAzureArtifacts {
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $org_name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $project_name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $feed_name
    )
    Process {
        $repo_root_folder_path = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, '..', '..'))
        $npmrc_override_file_path = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($repo_root_folder_path, '.ignoreme', 'npmrc_override', 'npmrc_override.ini'))

        $npm_userconfig_override_contents = @"
@insertyourcompanynamespacehere:registry=https://pkgs.dev.azure.com/$org_name/$project_name/_packaging/$feed_name/npm/registry/
//pkgs.dev.azure.com/$org_name/$project_name/_packaging/$feed_name/npm/registry/:always-auth=true
//pkgs.dev.azure.com/$org_name/$project_name/_packaging/$feed_name/npm/registry/:_authToken=`${TARGET_NPM_REGISTRY_BEARER_TOKEN}
//pkgs.dev.azure.com/$org_name/$project_name/_packaging/$feed_name/npm/:always-auth=true
//pkgs.dev.azure.com/$org_name/$project_name/_packaging/$feed_name/npm/:_authToken=`${TARGET_NPM_REGISTRY_BEARER_TOKEN}
"@
        New-Item -ItemType Directory -Path (Split-Path $npmrc_override_file_path) -Force | Out-Null
        $npm_userconfig_override_contents | Out-File -FilePath $npmrc_override_file_path
        [System.Environment]::SetEnvironmentVariable('NPM_CONFIG_USERCONFIG', $npmrc_override_file_path, 'Process')
    }
}

Set-NpmUserConfigOverrideForAzureArtifacts `
    -org_name $OrgName `
    -project_name $ProjectName `
    -feed_name $FeedName
