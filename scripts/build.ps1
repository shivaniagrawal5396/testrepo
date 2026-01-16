<#
Purpose:
Single entry point for PR, CI, and local builds.

Behavior:
- PR → build + test
- Merge to main → build + test + publish deployable ZIP artifacts
- Mono-repo friendly (auto-detects changed solutions)

This script guarantees identical behavior locally and in CI.
#>

param(
    # Project selection
    [ValidateSet("dotnet", "angular")]
    [string]$ProjectType = "dotnet",

    [ValidateSet("app", "library")]
    [string]$DotnetMode = "app",

    # Sonar configuration (optional)
    [string]$SonarProjectKey,
    [string]$SonarProjectName,
    [string]$SonarOrg,
    [string]$SonarHostUrl,
    [string]$SonarToken,

    # NuGet publishing (libraries only)
    [string]$NugetApiKey,

    # Pipeline control
    [bool]$Build   = $false,
    [bool]$Publish = $false
)

. "$PSScriptRoot/shared/common.ps1"

Write-Info "Starting build"
Write-Info "ProjectType=$ProjectType | DotnetMode=$DotnetMode | Publish=$Publish"

# -----------------------------
# Detect changed solutions
# -----------------------------
$Projects = . "$PSScriptRoot/shared/changed-solutions.ps1"

if (-not $Projects -or $Projects.Count -eq 0) {
    Write-Info "No affected solutions detected. Skipping build."
    return
}

Write-Info "Affected solutions:"
$Projects | ForEach-Object { Write-Info " - $_" }

# -----------------------------
# Sonar start (optional)
# -----------------------------
if ($SonarProjectKey) {
    . "$PSScriptRoot/shared/sonar.ps1" `
        -ProjectKey   $SonarProjectKey `
        -ProjectName  $SonarProjectName `
        -Organization $SonarOrg `
        -HostUrl      $SonarHostUrl `
        -Token        $SonarToken
}

# -----------------------------
# Process each solution
# -----------------------------
foreach ($ProjectPath in $Projects) {

    Write-Info "Processing solution: $ProjectPath"

    switch ($ProjectType) {

        "dotnet" {

            # Restore → Build → Test
            . "$PSScriptRoot/dotnet/restore.ps1" -ProjectPath $ProjectPath
            . "$PSScriptRoot/dotnet/build.ps1"   -ProjectPath $ProjectPath
            . "$PSScriptRoot/dotnet/test.ps1"    -ProjectPath $ProjectPath

            # Version resolution
            $Version = . "$PSScriptRoot/shared/version.ps1" -AppPath $ProjectPath
            Write-Info "Resolved version: $Version"

            # -----------------------------
            # Library flow (NuGet)
            # -----------------------------
            if ($DotnetMode -eq "library") {

                . "$PSScriptRoot/dotnet/pack.ps1" `
                    -ProjectPath $ProjectPath `
                    -Version     $Version

                if ($Publish) {
                    . "$PSScriptRoot/dotnet/publish-nuget.ps1" `
                        -ProjectPath $ProjectPath `
                        -GitHubOwner "your-github-org" `
                        -GitHubToken $env:GITHUB_TOKEN
                }

                continue
            }

            # -----------------------------
            # App flow (ZIP artifact)
            # -----------------------------
            if ($DotnetMode -eq "app" -and $Publish) {

                . "$PSScriptRoot/dotnet/publish.ps1" `
                    -ProjectPath $ProjectPath `
                    -Version     $Version
            }
        }

        "angular" {

            . "$PSScriptRoot/angular/restore.ps1" -ProjectPath $ProjectPath
            . "$PSScriptRoot/angular/build.ps1"   -ProjectPath $ProjectPath
            . "$PSScriptRoot/angular/test.ps1"    -ProjectPath $ProjectPath
        }
    }
}

# -----------------------------
# Sonar end
# -----------------------------
if ($SonarProjectKey) {
    dotnet sonarscanner end /d:sonar.login="$SonarToken"
}

Write-Info "Build completed successfully"
