param(
    # Base branch to compare against
    [string]$BaseBranch = "origin/main",

    # Folder(s) containing projects
    [string[]]$SourceRoots = @("src")
)

Write-Host "🔍 Detecting changed .NET projects"
Write-Host "Base branch: $BaseBranch"

# Ensure refs exist
git fetch origin main | Out-Null

# Get changed files
$changedFiles = git diff --name-only "$BaseBranch...HEAD"

if (-not $changedFiles) {
    Write-Host "✅ No files changed"
    "matrix=" | Out-File -FilePath $env:GITHUB_OUTPUT -Append
    exit 0
}

Write-Host "Changed files:"
$changedFiles | ForEach-Object { Write-Host " - $_" }

$changedProjects = New-Object System.Collections.Generic.HashSet[string]
$fullRebuild = $false

foreach ($file in $changedFiles) {

    # Ignore docs and non-code changes
    if ($file -match "^docs/|\.md$") {
        continue
    }

    # Shared/common code → rebuild everything
    if ($file -match "^src/Common/") {
        Write-Host "⚠ Shared code changed, triggering full rebuild"
        $fullRebuild = $true
        break
    }

    # If a csproj itself changed
    if ($file -like "*.csproj") {
        $projectPath = Split-Path $file -Parent
        $changedProjects.Add($projectPath) | Out-Null
        continue
    }

    # Otherwise walk up directory tree to find csproj
    $dir = Split-Path $file -Parent
    while ($dir) {
        $csproj = Get-ChildItem $dir -Filter *.csproj -ErrorAction SilentlyContinue
        if ($csproj) {
            $changedProjects.Add($dir) | Out-Null
            break
        }
        $parent = Split-Path $dir -Parent
        if ($parent -eq $dir) { break }
        $dir = $parent
    }
}

# Full rebuild → include all projects
if ($fullRebuild) {
    Write-Host "🔄 Including all projects"
    foreach ($root in $SourceRoots) {
        Get-ChildItem $root -Recurse -Filter *.csproj |
            ForEach-Object {
                $changedProjects.Add($_.DirectoryName) | Out-Null
            }
    }
}

if ($changedProjects.Count -eq 0) {
    Write-Host "✅ No .NET project changes detected"
    "matrix=" | Out-File -FilePath $env:GITHUB_OUTPUT -Append
    exit 0
}

# Build matrix
$matrix = @{
    include = @(
        $changedProjects | ForEach-Object {
            @{ project = $_ }
        }
    )
}

$json = $matrix | ConvertTo-Json -Compress

Write-Host "📦 Build matrix:"
Write-Host $json

"matrix=$json" | Out-File -FilePath $env:GITHUB_OUTPUT -Append
