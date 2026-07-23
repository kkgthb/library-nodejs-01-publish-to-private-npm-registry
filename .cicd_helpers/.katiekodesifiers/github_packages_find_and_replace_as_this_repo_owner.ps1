# If (-not ([System.Environment]::GetEnvironmentVariable('GITHUB_ACTIONS') -eq 'true')) {
#     Throw "You are not running within a GitHub Actions CI/CD pipeline.  You should not be running this script."
# }

$repo_root_folder_path = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, '..', '..'))
$shadow_copy_folder_path = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($repo_root_folder_path, '.ignoreme', 'repo_shadow_copy'))

$old_example_namespace = '@insertyourcompanynamespacehere'

$new_namespace_matching_this_repo_owner = "@$([System.Environment]::GetEnvironmentVariable('GITHUB_REPOSITORY_OWNER'))"
If (-not ([System.Environment]::GetEnvironmentVariable('GITHUB_REPOSITORY_OWNER'))) {
    Throw "There is no GITHUB_REPOSITORY_OWNER environment variable set."
}

If (Test-Path -Path $shadow_copy_folder_path -PathType 'Container') {
    [System.IO.Directory]::Delete($shadow_copy_folder_path, $true) | Out-Null # Remove any existing shadow-copy directory from old runs
}
[System.IO.Directory]::CreateDirectory($shadow_copy_folder_path) | Out-Null # Create the shadow-copy directory afresh

# Copy every file from repo root into the shadow copy, skipping .git and .ignoreme
$folders_to_exclude = @('.git', '.ignoreme')
Get-ChildItem -Path $repo_root_folder_path -Recurse -File -Force | Where-Object {
    $relative = $_.FullName.Substring($repo_root_folder_path.Length).TrimStart('\', '/')
    $top_level_folder = ($relative -split '[/\\]')[0]
    $folders_to_exclude -notcontains $top_level_folder
} | ForEach-Object {
    $source_file_path = $_.FullName
    $relative_path = $source_file_path.Substring($repo_root_folder_path.Length).TrimStart('\', '/')
    $dest_file_path = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($shadow_copy_folder_path, $relative_path))
    $dest_dir_path = Split-Path $dest_file_path
    If (-not (Test-Path -Path $dest_dir_path -PathType 'Container')) {
        [System.IO.Directory]::CreateDirectory($dest_dir_path) | Out-Null
    }
    # Replace @insertyourcompanynamespacehere with current repo owner in file contents
    $original_contents = [System.IO.File]::ReadAllText($source_file_path)
    $replaced_contents = $original_contents.Replace($old_example_namespace, $new_namespace_matching_this_repo_owner)
    [System.IO.File]::WriteAllText($dest_file_path, $replaced_contents)
}

Write-Host "Shadow copy with '$new_namespace_matching_this_repo_owner' substitution written successfully to:" -ForegroundColor 'Green'
Write-Host $shadow_copy_folder_path -ForegroundColor 'Green'
