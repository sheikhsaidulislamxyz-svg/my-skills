# my-skills hook: run `dart format` on any .dart file written/edited by the agent (Windows).
# Wire it into settings.json as a PostToolUse hook (see hooks/README.md).
# Exit 0 = nothing to do / formatted ok. Exit 1 = formatting failed (agent sees the error).
param([string]$File = "")

if ([string]::IsNullOrWhiteSpace($File)) {
  $inputJson = [Console]::In.ReadToEnd()
  try {
    $j = $inputJson | ConvertFrom-Json
    $File = $j.tool_input.file_path
  } catch {
    $m = [regex]::Match($inputJson, '"file_path"\s*:\s*"([^"]+)"')
    if ($m.Success) { $File = $m.Groups[1].Value }
  }
}

if ($File -notlike '*.dart') { exit 0 }
if (-not (Test-Path -LiteralPath $File -PathType Leaf)) { exit 0 }

$dart = Get-Command dart -ErrorAction SilentlyContinue
if (-not $dart) {
  [Console]::Error.WriteLine("my-skills/dart-format: 'dart' not found on PATH - skipping format for $File")
  exit 0
}

& dart format $File | Out-Null
if ($LASTEXITCODE -eq 0) {
  Write-Host "my-skills/dart-format: formatted $File"
  exit 0
} else {
  [Console]::Error.WriteLine("my-skills/dart-format: FAILED to format $File")
  & dart format $File
  exit 1
}
