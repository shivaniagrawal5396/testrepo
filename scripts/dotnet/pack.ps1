<#
Purpose:
Creates a NuGet package for .NET library projects.
#>

param(
    [string]$ProjectPath,
    [string]$Version
)

# Convert to full path
$ProjectPath = Resolve-Path $ProjectPath | Select-Object -ExpandProperty Path

Write-Host "ℹ️ Packing NuGet library version $Version"
Write-Host "ℹ️ Project path: $ProjectPath"

# Find the .csproj file
$projectFile = Get-ChildItem -Path $ProjectPath -Filter *.csproj | Select-Object -First 1
if (-not $projectFile) {
    throw "❌ No .csproj file found in $ProjectPath"
}

# NuGet output folder
$packageOutput = Join-Path $ProjectPath "nupkg"
if (-not (Test-Path $packageOutput)) {
    New-Item -ItemType Directory -Force -Path $packageOutput | Out-Null
}
Write-Host "ℹ️ NuGet output directory: $packageOutput"

# Run dotnet pack
dotnet pack $projectFile.FullName `
    --configuration Release `
    --output "$packageOutput" `
    /p:PackageVersion=$Version

# Validate .nupkg exists
$pkgFiles = Get-ChildItem -Path $packageOutput -Filter "*.nupkg"
if (-not $pkgFiles) {
    throw "❌ Pack succeeded but no .nupkg was produced!"
}

Write-Host "✅ NuGet package successfully created:"
$pkgFiles | ForEach-Object { Write-Host "   $_" }
