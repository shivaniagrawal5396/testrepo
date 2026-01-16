<#
Purpose:
Restores NuGet dependencies for .NET projects.
#>

param(
    [Parameter(Mandatory)]
    [string]$ProjectPath
)

. "$PSScriptRoot/../shared/common.ps1"

Write-Info "Restoring .NET dependencies in $ProjectPath"
Push-Location $ProjectPath

dotnet restore
if ($LASTEXITCODE -ne 0) {
    Pop-Location
    Write-ErrorAndExit "Restore failed"
}

Pop-Location
