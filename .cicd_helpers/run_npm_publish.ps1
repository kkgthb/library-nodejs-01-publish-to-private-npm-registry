
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
            $already_published_version_number = (npm view "$($package_json_contents.name)@$($package_json_contents.version)" version)
            If ($LASTEXITCODE -ne 0) {
                Write-Error "'npm view' failed with exit code: $LASTEXITCODE"
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