param(
    [switch]$OverwriteConfig
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$codexHome = Join-Path $HOME ".codex"
$claudeHome = Join-Path $HOME ".claude"

New-Item -ItemType Directory -Force -Path $codexHome, $claudeHome | Out-Null

Copy-Item -LiteralPath (Join-Path $repoRoot ".codex\AGENTS.md") -Destination (Join-Path $codexHome "AGENTS.md") -Force
Copy-Item -LiteralPath (Join-Path $repoRoot ".codex\rules") -Destination $codexHome -Recurse -Force
Copy-Item -LiteralPath (Join-Path $repoRoot ".codex\skills") -Destination $codexHome -Recurse -Force

$targetConfig = Join-Path $codexHome "config.toml"
if ($OverwriteConfig -or -not (Test-Path -LiteralPath $targetConfig)) {
    Copy-Item -LiteralPath (Join-Path $repoRoot ".codex\config.example.toml") -Destination $targetConfig -Force
    Write-Host "已写入 Codex config.toml，请补充本机 token 和 runtime 路径。"
} else {
    Write-Host "已跳过现有 Codex config.toml。需要覆盖时添加 -OverwriteConfig。"
}

Copy-Item -LiteralPath (Join-Path $repoRoot ".claude\CLAUDE.md") -Destination (Join-Path $claudeHome "CLAUDE.md") -Force
Copy-Item -LiteralPath (Join-Path $repoRoot ".claude\rules") -Destination $claudeHome -Recurse -Force
if (Test-Path -LiteralPath (Join-Path $repoRoot ".claude\skills")) {
    Copy-Item -LiteralPath (Join-Path $repoRoot ".claude\skills") -Destination $claudeHome -Recurse -Force
}

Write-Host "配置恢复完成。"
