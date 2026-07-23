
Param (
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -Path $_ -PathType 'Container' })]
    [System.IO.DirectoryInfo]
    $TarballParentFolder
)

Function Publish-NpmTarballFileToTargetRegistry {
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path -Path $_ -PathType 'Container' })]
        [System.IO.DirectoryInfo]
        $tarball_parent_folder
    )
    Process {
        $all_child_tarball_file_paths = @(Get-ChildItem -Path $tarball_parent_folder -Filter '*.tgz' -File)
        $tarball_count = $all_child_tarball_file_paths.Count
        If ($tarball_count -ne 1) {
            Throw "Validation failed: Found $tarball_count .tgz files. Expected exactly 1."
        }
        $tarball_file_path = $all_child_tarball_file_paths[0].FullName
        $package_json_contents = tar -xf $tarball_file_path --to-stdout 'package/package.json' | ConvertFrom-Json
        Try {
            $old_error_action_preference = $ErrorActionPreference
            $ErrorActionPreference = 'Stop'
            $pkg_name_and_version = "$($package_json_contents.name)@$($package_json_contents.version)"
            $already_published_version_number = ""

            # First-time publish returns 404 from npm view; treat that as not-yet-published.
            $npm_view_output_lines = @(& npm view $pkg_name_and_version version 2>&1)
            $npm_view_exit_code = $LASTEXITCODE
            If ($npm_view_exit_code -eq 0) {
                $already_published_version_number = ($npm_view_output_lines | Select-Object -Last 1).ToString().Trim("'", '"', ' ')
            }
            ElseIf (($npm_view_output_lines -join "`n") -match 'E404|404 Not Found|not found') {
                Write-Host "Package version not found yet in target registry: $pkg_name_and_version"
            }
            Else {
                Throw "'npm view' failed for $pkg_name_and_version with exit code $npm_view_exit_code`n$($npm_view_output_lines -join "`n")"
            }

            If ($already_published_version_number -eq $package_json_contents.version) {
                Write-Host "No need to publish package $($package_json_contents.name) -- $($package_json_contents.version) already published." -ForegroundColor 'Green'
            }
            Else {
                # Publish to NPM CLI's currently-configured target NPM registry
                npm publish $tarball_file_path
                If ($LASTEXITCODE -ne 0) {
                    Write-Error "'npm publish' failed with exit code: $LASTEXITCODE"
                }
                Write-Host "'npm publish' executed successfully!"
            }
        }
        Catch {
            Write-Error "An exception occurred during 'npm publish': $_"
        }
        Finally {
            $ErrorActionPreference = $old_error_action_preference
        }
    }
}

Publish-NpmTarballFileToTargetRegistry -tarball_parent_folder $TarballParentFolder