#!/usr/bin/env bash
# Installs antigen (zsh plugin manager) to ~/antigen.zsh on first apply.
# ~/.zshrc sources this file. Run once; future updates handled by `antigen update`.

set -euo pipefail

if [ -f "$HOME/antigen.zsh" ]; then
  echo "==> antigen already present at ~/antigen.zsh; skipping."
  exit 0
fi

echo "==> Installing antigen..."
curl -fsSL https://git.io/antigen -o "$HOME/antigen.zsh"
echo "==> antigen installed to ~/antigen.zsh"
