<#
Purpose:
Builds the .NET project in Release mode.
Assumes restore has already been completed.
#>

param(
    [Parameter(Mandatory)]
    [string]$ProjectPath
)

. "$PSScriptRoot/../shared/common.ps1"

Write-Info "Building .NET project in $ProjectPath"
Push-Location $ProjectPath

dotnet build --configuration Release --no-restore
if ($LASTEXITCODE -ne 0) {
    Pop-Location
    Write-ErrorAndExit "Build failed"
}

Pop-Location
