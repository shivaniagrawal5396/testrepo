<#
Purpose:
Executes automated unit tests for .NET projects.
Fails the pipeline if tests fail.
#>

param(
    [Parameter(Mandatory)]
    [string]$ProjectPath
)

. "$PSScriptRoot/../shared/common.ps1"

Write-Info "Running .NET tests in $ProjectPath"
Push-Location $ProjectPath

dotnet test --configuration Release --no-build
if ($LASTEXITCODE -ne 0) {
    Pop-Location
    Write-ErrorAndExit "Tests failed"
}

Pop-Location
