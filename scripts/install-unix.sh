#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
codex_home="${HOME}/.codex"

mkdir -p "${codex_home}"

cp -f "${repo_root}/.codex/AGENTS.md" "${codex_home}/AGENTS.md"
cp -R "${repo_root}/.codex/rules" "${codex_home}/"
cp -R "${repo_root}/.codex/skills" "${codex_home}/"

if [[ ! -f "${codex_home}/config.toml" ]]; then
  cp "${repo_root}/.codex/config.example.toml" "${codex_home}/config.toml"
  echo "已写入 Codex config.toml，请补充本机 token 和 runtime 路径。"
else
  echo "已跳过现有 Codex config.toml。需要覆盖时手动复制 .codex/config.example.toml。"
fi

echo "配置恢复完成。"
