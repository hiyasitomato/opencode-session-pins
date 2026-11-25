param(
  [Parameter(Mandatory = $true)]
  [string]$RepoPath
)

$ErrorActionPreference = "Stop"

$patch = Join-Path $PSScriptRoot "..\patches\opencode-v2.4.1-home-session-pins.patch"
$patch = (Resolve-Path $patch).Path
$target = (Resolve-Path $RepoPath).Path

Write-Host "Checking patch against $target ..."
git -C $target apply --check $patch
if ($LASTEXITCODE -ne 0) {
  throw "Patch check failed. Make sure the target repository is checked out at OpenCode v2.4.1 with a clean working tree."
}

Write-Host "Applying patch..."
git -C $target apply $patch
if ($LASTEXITCODE -ne 0) {
  throw "Failed to apply patch."
}

Write-Host ""
Write-Host "Patch applied cleanly."
Write-Host "Next steps:"
Write-Host "  cd `"$target`""
Write-Host "  bun install"
Write-Host "  `$env:OPENCODE_CHANNEL = `"latest`""
Write-Host "  `$env:OPENCODE_VERSION = `"2.4.1-pins.1`""
Write-Host "  bun run --cwd packages/cli build --single --baseline"
Write-Host "  bun run --cwd packages/desktop build"
