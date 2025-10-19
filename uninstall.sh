#!/usr/bin/env bash
set -euo pipefail
systemctl --user disable --now aw-deckd.service || true
rm -f "$HOME/.config/systemd/user/aw-deckd.service"
rm -f "$HOME/.local/bin/aw-deckd" "$HOME/.local/bin/aw-deckctl"
systemctl --user daemon-reload
echo "Désinstallé."
