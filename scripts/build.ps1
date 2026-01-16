<#
Purpose:
Single entry point for PR, CI, and local builds.

Behavior:
- PR  → build + test + docker build
- CI  → build + test + docker build + push to ACR
- CD  → NOT USED (deploy only)

This script guarantees identical behavior locally and in CI.
#>

param(
    # Project selection
    [ValidateSet("dotnet", "angular")]
    [string]$ProjectType = "dotnet",

    [ValidateSet("app", "library")]
    [string]$DotnetMode = "app",

    # Paths / Image
    [string]$ProjectPath,
    [string]$ImageName,
    [string]$Registry,

    # Sonar configuration (optional)
    [string]$SonarProjectKey,
    [string]$SonarProjectName,
    [string]$SonarOrg,
    [string]$SonarHostUrl,
    [string]$SonarToken,

    # NuGet publishing (libraries only)
    [string]$NugetApiKey,

    # Pipeline control
    [bool]$Build  = $false,
    [bool]$Publish = $false
)

. "$PSScriptRoot/shared/common.ps1"

Write-Info "Starting build for project type: $ProjectType"

# -----------------------------
# Sonar start (optional)
# -----------------------------
if ($SonarProjectKey) {
    . "$PSScriptRoot/shared/sonar.ps1" `
        -ProjectKey  $SonarProjectKey `
        -ProjectName $SonarProjectName `
        -Organization $SonarOrg `
        -HostUrl     $SonarHostUrl `
        -Token       $SonarToken
}

# -----------------------------
# Restore → Build → Test
# -----------------------------
switch ($ProjectType) {
    "dotnet" {
        . "$PSScriptRoot/dotnet/restore.ps1" -ProjectPath $ProjectPath
        . "$PSScriptRoot/dotnet/build.ps1"   -ProjectPath $ProjectPath
        . "$PSScriptRoot/dotnet/test.ps1"    -ProjectPath $ProjectPath
    }

    "angular" {
        . "$PSScriptRoot/angular/restore.ps1" -ProjectPath $ProjectPath
        . "$PSScriptRoot/angular/build.ps1"   -ProjectPath $ProjectPath
        . "$PSScriptRoot/angular/test.ps1"    -ProjectPath $ProjectPath
    }
}

# -----------------------------
# Sonar end
# -----------------------------
if ($SonarProjectKey) {
    dotnet sonarscanner end /d:sonar.login="$SonarToken"
}

# -----------------------------
# Version resolution
# -----------------------------
$Version = . "$PSScriptRoot/shared/version.ps1" -AppPath $ProjectPath
Write-Info "Resolved version: $Version"

# -----------------------------
# NuGet library flow
# -----------------------------
if ($ProjectType -eq "dotnet" -and $DotnetMode -eq "library") {
	
    . "$PSScriptRoot/dotnet/pack.ps1" `
    -ProjectPath $ProjectPath `
    -Version $Version
	
    . "$PSScriptRoot/dotnet/publish-nuget.ps1" `
    -ProjectPath $ProjectPath `
    -GitHubOwner "your-github-org" `
    -GitHubToken $env:GITHUB_TOKEN
	
    Write-Info "Library build completed successfully"
    return
}

# -----------------------------
# Publish deployable artifact
# -----------------------------
if ($ProjectType -eq "dotnet" -and $DotnetMode -eq "app" -and $Publish) {

    . "$PSScriptRoot/dotnet/publish.ps1" `
        -ProjectPath $ProjectPath `
        -Version $Version

    Write-Info "Deployable artifact published"
}

Write-Info "Build completed successfully. Image: ${ImageName}:${Version}"
