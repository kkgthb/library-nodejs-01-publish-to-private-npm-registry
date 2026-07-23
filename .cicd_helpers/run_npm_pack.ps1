Param (
    [Parameter(Mandatory = $true)]
    [ValidateSet('HelloWorld')] # Make sure these match the `WhichPkg` enum & the `$pkg_folder_paths_by_pkg_enum` keys
    [string]
    $WhichPackage
)

enum WhichPkg {
    HelloWorld
}

Function New-NpmTarballFile {
    Param (
        [Parameter(Mandatory = $true)]
        [WhichPkg]
        $which_package
    )
    Begin {
        $repo_root_folder_path = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, '..'))
        $dist_folder_path = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($repo_root_folder_path, '.ignoreme', 'dist'))
    }
    Process {
        $pkg_folder_paths_by_pkg_enum = @{
            [WhichPkg]::HelloWorld = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($repo_root_folder_path, 'src', 'hello_world'))
        }
        $selected_pkg_folder_path = $pkg_folder_paths_by_pkg_enum.$([WhichPkg]$which_package)
        If (-Not (Test-Path -Path $selected_pkg_folder_path -PathType 'Container')) {
            Throw "Source code folder not found: $selected_pkg_folder_path"
        }
        $selected_pkg_json_file_path = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($selected_pkg_folder_path, 'package.json'))
        If (-Not (Test-Path -Path $selected_pkg_json_file_path -PathType 'Leaf')) {
            Throw "Package.json file not found: $selected_pkg_json_file_path"
        }
        $selected_pkg_dist_folder_path = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($dist_folder_path, $which_package.ToString()))
        [System.IO.Directory]::Delete($selected_pkg_dist_folder_path, $true) | Out-Null # Remove any existing dist-pkg-specific directory from old runs
        [System.IO.Directory]::CreateDirectory($selected_pkg_dist_folder_path) | Out-Null # Create the dist-pkg-specific directory afresh

        # Do the NPM Pack dry-run
        Try {
            $old_error_action_preference = $ErrorActionPreference
            $ErrorActionPreference = 'Stop'
            # Do a dry-run of "npm pack" NPM CLI command, 
            # which does the same sysout as non-dryrun but doesn't write to the filesystem.
            $tarball_dry_run_name = ( `
                    npm pack $selected_pkg_folder_path `
                    --pack-destination $selected_pkg_dist_folder_path `
                    --dry-run
            ) `
            | Select-Object -Last 1
            If ($LASTEXITCODE -ne 0) {
                Write-Error "'npm pack --dry-run' failed with exit code: $LASTEXITCODE"
            }
            Write-Host "'npm pack --dry-run' executed successfully!  Would have made file: $tarball_dry_run_name"
        }
        Catch {
            Write-Error "An exception occurred during 'npm pack --dry-run': $_"
        }
        Finally {
            $ErrorActionPreference = $old_error_action_preference
        }

        # Do the NPM Pack real Tarball creation dry-run
        Try {
            $old_error_action_preference = $ErrorActionPreference
            $ErrorActionPreference = 'Stop'
            # Do the real "npm pack" NPM CLI command:
            #   Create a `.tgz` file in the dist, 
            #   with a `package` folder in its root that contains what 
            #   the source folder contained, 
            #   minus certain always-ignored filenames such as `package-lock.json` and `.npmrc`.
            $tarball_name = (npm pack $selected_pkg_folder_path --pack-destination $selected_pkg_dist_folder_path) | Select-Object -Last 1
            If ($LASTEXITCODE -ne 0) {
                Write-Error "'npm pack' failed with exit code: $LASTEXITCODE"
            }
            Write-Host "'npm pack' executed successfully!  Wrote Tarball to filepath:" -ForegroundColor 'Green'
            $tarball_file_path = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($selected_pkg_dist_folder_path, $tarball_name))
            Write-Host $tarball_file_path -ForegroundColor 'Green'

            # If currently running in a CI/CD pipeline, upload the Tarball into an appropriate job artifact
            # - For Azure DevOps (ADO)'s Azure Pipelines:
            If ([System.Environment]::GetEnvironmentVariable('TF_BUILD') -eq 'True') {
                Write-Host "##vso[artifact.upload containerfolder=dist;artifactname=dist]$dist_folder_path"
            }
            # - GitHub Actions does not seem to have an in-PowerShell command. 
            #   You'll have to do a separate 'actions/upload-artifact' YAML step 
            #   after this PowerShell function's execution finishes.
            If ([System.Environment]::GetEnvironmentVariable('GITHUB_ACTIONS') -eq 'true') {
                Write-Warning "There is no PowerShell-native GitHub Actions artifact upload command.  Please call a 'actions/upload-artifact' step, next, in the YAML that invoked this PowerShell function, against this directory:  $dist_folder_path"
            }
            # - GitLab CI does not seem to have an in-PowerShell command. 
            #   You'll have to do a separate 'actions/upload-artifact' YAML step 
            #   after this PowerShell function's execution finishes.
            If ([System.Environment]::GetEnvironmentVariable('GITLAB_CI') -eq 'true') {
                Write-Warning "There is no PowerShell-native GitLab CI artifact upload command.  Please call a 'artifacts' step, next, in the YAML that invoked this PowerShell function, against this directory:  $dist_folder_path"
            }
        }
        Catch {
            Write-Error "An exception occurred during 'npm pack': $_"
        }
        Finally {
            $ErrorActionPreference = $old_error_action_preference
        }

    }
}

New-NpmTarballFile -which_package ([WhichPkg]$WhichPackage)