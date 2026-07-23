Function Set-NpmUserConfigOverrideForNpmjsDotOrg {
    Process {
        $repo_root_folder_path = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, '..', '..'))
        $npmrc_override_file_path = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($repo_root_folder_path, '.ignoreme', 'npmrc_override', 'npmrc_override.ini'))
        $npm_userconfig_override_contents = @'
@insertyourcompanynamespacehere:registry=https://registry.npmjs.org/
//registry.npmjs.org/:always-auth=true
//registry.npmjs.org/:_authToken=${TARGET_NPM_REGISTRY_BEARER_TOKEN}
'@
        New-Item -ItemType Directory -Path (Split-Path $npmrc_override_file_path) -Force | Out-Null
        $npm_userconfig_override_contents | Out-File -FilePath $npmrc_override_file_path
        [System.Environment]::SetEnvironmentVariable('NPM_CONFIG_USERCONFIG', $npmrc_override_file_path, 'Process')
    }
}

Set-NpmUserConfigOverrideForNpmjsDotOrg
