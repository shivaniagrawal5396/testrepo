param(
    # Default for local / push builds
    [string]$BaseRef = "origin/main"
)

Write-Info "Detecting changed solutions..."

# -----------------------------
# Determine correct base branch
# -----------------------------
if ($env:GITHUB_BASE_REF) {
    # Pull Request build
    $BaseRef = "origin/$($env:GITHUB_BASE_REF)"
    Write-Info "PR detected. BaseRef: $BaseRef"
}

# Ensure base branch exists (CI safety)
git fetch origin | Out-Null

# -----------------------------
# Get changed files
# -----------------------------
$changedFiles = git diff --name-only $BaseRef HEAD

if (-not $changedFiles -or $changedFiles.Count -eq 0) {
    Write-Info "No changes detected"
    return @()
}

$solutions = @()

foreach ($file in $changedFiles) {

    # Ignore non-code / infra-only changes
    if ($file -match '\.(md|txt|png|jpg|jpeg|gif|yml|yaml)$') {
        continue
    }

    $dir = Split-Path $file -Parent

    while ($dir -and $dir -ne ".") {

        $sln = Get-ChildItem `
            -Path $dir `
            -Filter *.sln `
            -ErrorAction SilentlyContinue

        if ($sln) {
            $solutions += $sln.FullName
            break
        }

        $dir = Split-Path $dir -Parent
    }
}

$uniqueSolutions = $solutions | Sort-Object -Unique

if ($uniqueSolutions.Count -eq 0) {
    Write-Info "No solutions affected by the changes"
}

return $uniqueSolutions
