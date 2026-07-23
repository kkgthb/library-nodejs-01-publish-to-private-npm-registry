Function Set-NpmUserConfigFilePathOverrideToNull {
    [System.Environment]::SetEnvironmentVariable('NPM_CONFIG_USERCONFIG', $null, 'Process')
    If (-not [string]::IsNullOrWhiteSpace([System.Environment]::GetEnvironmentVariable('NPM_CONFIG_USERCONFIG'))) {
        Throw "We did not actually clear the NPM userconfig overrride"
    }
    # Also clear out $npmrc_override_file_path = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($repo_root_folder_path, '.ignoreme', 'npmrc_override', 'npmrc_override.ini')) ?
}

Set-NpmUserConfigFilePathOverrideToNull