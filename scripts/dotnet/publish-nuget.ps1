<#
Purpose:
Publishes NuGet packages:
- Local machine  → Local folder feed
- CI (GitHub)    → GitHub Packages
#>

param(
    [string]$ProjectPath,
    [string]$GitHubOwner,
    [string]$GitHubToken,
    [string]$LocalFeedPath = "C:\LocalNuGet"
)

# Full path to nupkg folder
$packagePath = Join-Path $ProjectPath "nupkg"
if (-not (Test-Path $packagePath)) {
    throw "❌ NuGet package folder not found: $packagePath"
}

# Get actual .nupkg files
$pkgFiles = Get-ChildItem -Path $packagePath -Filter "*.nupkg" -File
if (-not $pkgFiles) {
    throw "❌ No .nupkg files found in $packagePath"
}

# Publish each file
foreach ($pkg in $pkgFiles) {
    if ($GitHubToken) {
        Write-Host "ℹ️ Publishing $($pkg.Name) to GitHub Packages"
        $source = "https://nuget.pkg.github.com/$GitHubOwner/index.json"
        dotnet nuget push $pkg.FullName `
            --api-key $GitHubToken `
            --source $source `
            --skip-duplicate
    }
    else {
        Write-Host "ℹ️ Publishing $($pkg.Name) to LOCAL NuGet feed"
        if (-not (Test-Path $LocalFeedPath)) {
            New-Item -ItemType Directory -Force -Path $LocalFeedPath | Out-Null
        }
        dotnet nuget push $pkg.FullName `
            --source $LocalFeedPath `
            --skip-duplicate
    }
}
