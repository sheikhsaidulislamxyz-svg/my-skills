# my-skills installer (Windows PowerShell).
# Copies skills/ and agents/ into your user-level Claude config, merges the
# Flutter/Firebase rules into your CLAUDE.md (without overwriting), installs the
# MCP servers from mcp/servers.json with --scope user, then runs `claude mcp list`.
#
# Safety:
#   * Anything already present with the same name is moved to
#     "$env:CLAUDE_HOME\backups\my-skills-<timestamp>\" before being replaced.
#   * CLAUDE.md is MERGED: a clearly-marked block is inserted/updated, the rest of
#     your file is preserved byte-for-byte.
#   * If any step fails, the script stops immediately and prints the error.
#   * $env:MY_SKILLS_TEST = "1" (or -SkipRemote) skips all network/npx/claude steps
#     so the script can be tested hermetically.
#
# Params:  -SkipRemote   skip remote (npx/claude) steps
#          -ClaudeHome   user-level Claude config dir (default: $env:USERPROFILE\.claude)
[CmdletBinding()]
param(
  [switch]$SkipRemote,
  [string]$ClaudeHome = $(if ($env:CLAUDE_HOME) { $env:CLAUDE_HOME } else { Join-Path $env:USERPROFILE '.claude' })
)
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$TestMode = ($env:MY_SKILLS_TEST -eq '1')
if ($TestMode) { $SkipRemote = $true }
$Stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$BackupDir = Join-Path $ClaudeHome "backups\my-skills-$Stamp"

function Note($m) { Write-Host "==> $m" -ForegroundColor Cyan }
function Ok($m)   { Write-Host " ok $m" -ForegroundColor Green }
function Warn($m) { Write-Host "warn $m" -ForegroundColor Yellow }
function Die($m)  { Write-Host "ERROR: $m" -ForegroundColor Red; exit 1 }

function Backup-Path($Path) {
  New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null
  $dest = Join-Path $BackupDir (Split-Path -Leaf $Path)
  $i = 1
  while (Test-Path -LiteralPath $dest) { $dest = Join-Path $BackupDir ((Split-Path -Leaf $Path) + ".$i"); $i++ }
  Move-Item -LiteralPath $Path -Destination $dest
  Ok "backed up $(Split-Path -Leaf $Path) -> $dest"
}

function Copy-Tree($SourceDir, $TargetDir, $Label) {
  New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null
  $count = 0
  foreach ($item in Get-ChildItem -LiteralPath $SourceDir -Force) {
    $target = Join-Path $TargetDir $item.Name
    if (Test-Path -LiteralPath $target) { Backup-Path $target }
    Copy-Item -LiteralPath $item.FullName -Destination $target -Recurse -Force
    Ok "$Label/$($item.Name)"
    $count++
  }
  return $count
}

Note "my-skills installer"
Write-Host "repo:         $RepoRoot"
Write-Host "claude home:  $ClaudeHome"
Write-Host "test mode:    $TestMode"

# --- 1. skills ----------------------------------------------------------------
Note "skills -> $ClaudeHome\skills\"
$SkillsCount = Copy-Tree (Join-Path $RepoRoot 'skills') (Join-Path $ClaudeHome 'skills') 'skill'

# --- 2. agents ----------------------------------------------------------------
Note "agents -> $ClaudeHome\agents\"
$AgentsCount = Copy-Tree (Join-Path $RepoRoot 'agents') (Join-Path $ClaudeHome 'agents') 'agent'

# --- 3. merge CLAUDE.md --------------------------------------------------------
Note "merging Flutter/Firebase rules into $ClaudeHome\CLAUDE.md"
$BeginMark = '<!-- >>> my-skills managed block (Flutter/Firebase) >>> -->'
$EndMark   = '<!-- <<< my-skills managed block <<< -->'
$TargetClaude = Join-Path $ClaudeHome 'CLAUDE.md'
$template = Get-Content -LiteralPath (Join-Path $RepoRoot 'templates\CLAUDE.md') -Raw -Encoding UTF8
$block = "$BeginMark`n$template`n$EndMark`n"

if (Test-Path -LiteralPath $TargetClaude) {
  Copy-Item -LiteralPath $TargetClaude -Destination (Join-Path (New-Item -ItemType Directory -Force -Path $BackupDir) 'CLAUDE.md') -Force
  Ok "backed up CLAUDE.md -> $BackupDir\CLAUDE.md"
  $rest = Get-Content -LiteralPath $TargetClaude -Raw -Encoding UTF8
  # Drop any previous my-skills block (markers are single dedicated lines)
  $lines = $rest -split "`r?`n"
  $kept = New-Object System.Collections.Generic.List[string]
  $skip = $false
  foreach ($line in $lines) {
    if ($line -eq $BeginMark) { $skip = $true; continue }
    if ($line -eq $EndMark)   { $skip = $false; continue }
    if (-not $skip) { $kept.Add($line) }
  }
  $merged = ($kept -join "`n").TrimEnd() + "`n`n" + $block
  [System.IO.File]::WriteAllText($TargetClaude, $merged, (New-Object System.Text.UTF8Encoding($false)))
  Ok "merged (existing rules preserved; old file in backup)"
} else {
  [System.IO.File]::WriteAllText($TargetClaude, $block, (New-Object System.Text.UTF8Encoding($false)))
  Ok "created $TargetClaude"
}

# --- 4. remote skills via npx (license unclear upstream — not copied) ----------
Note "remote skills (npx skills add)"
$RemoteSkills = @('anthropics/skills', 'vercel-labs/agent-skills')
if ($SkipRemote) {
  Warn "skipped remote installs. Would run:"
  foreach ($pkg in $RemoteSkills) { Write-Host "      npx --yes skills add $pkg -g -a claude -s '*' -y" }
} else {
  if (-not (Get-Command npx -ErrorAction SilentlyContinue)) { Die "npx not found on PATH. Install Node.js 18+ and re-run, or use -SkipRemote." }
  foreach ($pkg in $RemoteSkills) {
    Write-Host "      npx --yes skills add $pkg -g -a claude -s '*' -y"
    & npx --yes skills add $pkg -g -a claude -s '*' -y
    if ($LASTEXITCODE -ne 0) { Die "remote install failed for $pkg. Re-run with -SkipRemote to install only local skills." }
    Ok "installed remote skills from $pkg"
  }
}

# --- 5. MCP servers -------------------------------------------------------------
Note "MCP servers (claude mcp add --scope user)"
$servers = (Get-Content -LiteralPath (Join-Path $RepoRoot 'mcp\servers.json') -Raw -Encoding UTF8 | ConvertFrom-Json).servers

$dartOk = $true
$dart = Get-Command dart -ErrorAction SilentlyContinue
if ($dart) {
  $verLine = (& dart --version 2>&1) | Out-String
  $m = [regex]::Match($verLine, '(\d+)\.(\d+)\.(\d+)')
  if ($m.Success) {
    $maj = [int]$m.Groups[1].Value; $min = [int]$m.Groups[2].Value
    if ($maj -lt 3 -or ($maj -eq 3 -and $min -lt 9)) {
      $dartOk = $false
      Warn "Dart $($m.Value) found - dart MCP requires >= 3.9. Skipping dart MCP (everything else unaffected)."
    } else { Ok "Dart $($m.Value) (>= 3.9) - dart MCP will be installed" }
  } else {
    $dartOk = $false
    Warn "could not parse 'dart --version' output ('$verLine') - skipping dart MCP."
  }
} else {
  $dartOk = $false
  Warn "dart not found on PATH - skipping dart MCP. Install Dart >= 3.9 and re-run to add it."
}

if ($TestMode) {
  Warn "test mode: not calling 'claude mcp add'. Would run:"
  foreach ($s in $servers) {
    if ($s.name -eq 'dart' -and -not $dartOk) { continue }
    $scope = if ($s.scope) { $s.scope } else { 'user' }
    Write-Host ("      claude mcp add --scope {0} {1} {2} -- {3}" -f $scope, $s.name, $s.command, ($s.args -join ' '))
  }
} else {
  $claude = Get-Command claude -ErrorAction SilentlyContinue
  if (-not $claude) {
    Warn "'claude' CLI not found on PATH. Skipping automatic MCP setup."
    Write-Host "      Run these manually on the machine where Claude Code is installed:"
    foreach ($s in $servers) {
      if ($s.name -eq 'dart' -and -not $dartOk) { continue }
      $scope = if ($s.scope) { $s.scope } else { 'user' }
      Write-Host ("      claude mcp add --scope {0} {1} {2} -- {3}" -f $scope, $s.name, $s.command, ($s.args -join ' '))
    }
  } else {
    foreach ($s in $servers) {
      if ($s.name -eq 'dart' -and -not $dartOk) { Write-Host "      (dart MCP skipped - see warning above)"; continue }
      $scope = if ($s.scope) { $s.scope } else { 'user' }
      Write-Host ("      claude mcp add --scope {0} {1} {2} -- {3}" -f $scope, $s.name, $s.command, ($s.args -join ' '))
      & claude mcp add --scope $scope $s.name $s.command -- @($s.args)
      if ($LASTEXITCODE -ne 0) { Die "failed to add MCP server '$($s.name)'. Fix the error above and re-run - replaced files were backed up in $BackupDir" }
      Ok "MCP server '$($s.name)' added (scope: $scope)"
    }
  }
}

# --- 6. verify -------------------------------------------------------------------
if (-not $TestMode -and (Get-Command claude -ErrorAction SilentlyContinue)) {
  Note "claude mcp list"
  & claude mcp list
  if ($LASTEXITCODE -ne 0) { Die "'claude mcp list' failed - run it manually to inspect server state." }
} else {
  Note "claude mcp list (skipped: test mode or claude CLI not on PATH)"
}

# --- summary ----------------------------------------------------------------------
Note "summary"
Write-Host "  skills copied      : $SkillsCount  -> $ClaudeHome\skills\"
Write-Host "  agents copied      : $AgentsCount  -> $ClaudeHome\agents\"
Write-Host "  CLAUDE.md          : merged block inserted (full file: $TargetClaude)"
if (Test-Path -LiteralPath $BackupDir) { Write-Host "  backups            : $BackupDir" }
Write-Host ""
Write-Host "Plugin installs are manual (the installer never runs /plugin):"
Write-Host "  Superpowers:  /plugin marketplace add obra/superpowers-marketplace"
Write-Host "                /plugin install superpowers@superpowers-marketplace"
Write-Host "  Flutter/Dart: /plugin marketplace add flutter/agent-plugins"
Write-Host "                /plugin install dart-flutter@dart-flutter"
if ($TestMode) { Write-Host "TEST MODE: no network calls were made and nothing outside $ClaudeHome was written." }
Ok "done"
