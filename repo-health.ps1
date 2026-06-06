param(
    [string]$Path = ".",
    [int]$LargeFileMb = 10,
    [switch]$Markdown
)

$ErrorActionPreference = "Stop"

function Write-Result {
    param(
        [string]$Status,
        [string]$Check,
        [string]$Details = ""
    )

    if ($Markdown) {
        "| $Status | $Check | $Details |"
    }
    else {
        "{0,-8} {1,-30} {2}" -f $Status, $Check, $Details
    }
}

function Test-Command {
    param([string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

$root = Resolve-Path -LiteralPath $Path
$scriptPath = if ($PSCommandPath) { (Resolve-Path -LiteralPath $PSCommandPath).Path } else { $null }
Set-Location -LiteralPath $root

if ($Markdown) {
    "# Repository Health Report"
    ""
    "Path: ``$root``"
    ""
    "| Status | Check | Details |"
    "| --- | --- | --- |"
}
else {
    "Repository Health Report"
    "Path: $root"
    ""
}

$requiredFiles = @(
    "README.md",
    ".gitignore",
    "CONTRIBUTING.md",
    "LICENSE"
)

foreach ($file in $requiredFiles) {
    if (Test-Path -LiteralPath $file) {
        Write-Result "OK" $file "Found"
    }
    else {
        Write-Result "WARN" $file "Missing"
    }
}

$issueTemplatePaths = @(
    ".github/ISSUE_TEMPLATE",
    "ISSUE_TEMPLATE_bug_report.md",
    "ISSUE_TEMPLATE_feature_request.md"
)

if ($issueTemplatePaths | Where-Object { Test-Path -LiteralPath $_ }) {
    Write-Result "OK" "Issue templates" "Found"
}
else {
    Write-Result "WARN" "Issue templates" "Missing"
}

if ((Test-Path -LiteralPath ".github/PULL_REQUEST_TEMPLATE.md") -or (Test-Path -LiteralPath "PULL_REQUEST_TEMPLATE.md")) {
    Write-Result "OK" "PR template" "Found"
}
else {
    Write-Result "WARN" "PR template" "Missing"
}

$testPaths = @("test", "tests", "__tests__", "spec")
if ($testPaths | Where-Object { Test-Path -LiteralPath $_ }) {
    Write-Result "OK" "Tests" "Test directory found"
}
else {
    Write-Result "INFO" "Tests" "No common test directory found"
}

$largeFiles = Get-ChildItem -File -Recurse -Force |
    Where-Object {
        $_.FullName -notmatch "\\.git\\" -and
        $_.Length -gt ($LargeFileMb * 1MB)
    } |
    Sort-Object Length -Descending |
    Select-Object -First 10

if ($largeFiles) {
    $names = ($largeFiles | ForEach-Object {
        "{0} ({1:N1} MB)" -f $_.FullName.Substring($root.Path.Length + 1), ($_.Length / 1MB)
    }) -join "; "
    Write-Result "WARN" "Large files" $names
}
else {
    Write-Result "OK" "Large files" "None over $LargeFileMb MB"
}

$secretPattern = '(api[_-]?key|secret|token|password|private[_-]?key)\s*[:=]\s*[''"]?[^''">\s]{8,}'
$secretHits = Get-ChildItem -File -Recurse -Force |
    Where-Object {
        $_.FullName -notmatch "\\.git\\" -and
        $_.Length -lt 1MB -and
        $_.Extension -notin @(".png", ".jpg", ".jpeg", ".gif", ".webp", ".pdf", ".zip", ".exe")
    } |
    Select-String -Pattern $secretPattern -AllMatches -ErrorAction SilentlyContinue |
    Select-Object -First 10

if ($secretHits) {
    $locations = ($secretHits | ForEach-Object {
        "{0}:{1}" -f $_.Path.Substring($root.Path.Length + 1), $_.LineNumber
    }) -join "; "
    Write-Result "WARN" "Possible secrets" $locations
}
else {
    Write-Result "OK" "Possible secrets" "No obvious matches"
}

$todoHits = Get-ChildItem -File -Recurse -Force |
    Where-Object {
        $_.FullName -notmatch "\\.git\\" -and
        $_.FullName -ne $scriptPath -and
        $_.Length -lt 1MB
    } |
    Select-String -Pattern "\b(TODO|FIXME|HACK)\b" -ErrorAction SilentlyContinue |
    Select-Object -First 10

if ($todoHits) {
    $locations = ($todoHits | ForEach-Object {
        "{0}:{1}" -f $_.Path.Substring($root.Path.Length + 1), $_.LineNumber
    }) -join "; "
    Write-Result "INFO" "TODO/FIXME/HACK" $locations
}
else {
    Write-Result "OK" "TODO/FIXME/HACK" "None found"
}

if (Test-Command "git") {
    $insideGitRepo = $false
    try {
        $insideGitRepo = (git rev-parse --is-inside-work-tree 2>$null) -eq "true"
    }
    catch {
        $insideGitRepo = $false
    }

    if ($insideGitRepo) {
        $status = git status --short
        if ($status) {
            Write-Result "INFO" "Git status" (($status | Select-Object -First 10) -join "; ")
        }
        else {
            Write-Result "OK" "Git status" "Working tree clean"
        }
    }
    else {
        Write-Result "INFO" "Git repository" "Current path is not inside a git repository"
    }
}
else {
    Write-Result "INFO" "Git" "git command not available"
}

if (-not $Markdown) {
    ""
    "Tip: run with -Markdown to create a report that can be pasted into a GitHub issue or PR."
}
