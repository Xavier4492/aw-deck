#!/usr/bin/env bash
set -euo pipefail

for svc in deck-before-sleep.service deck-bootstrap.service aw-deck-sync.service aw-deckd.service aw-deck-timer.service streamdeck-ui.service; do
  systemctl --user disable --now "$svc" || true
done

rm -f "$HOME/.config/systemd/user/deck-before-sleep.service" \
      "$HOME/.config/systemd/user/deck-bootstrap.service" \
      "$HOME/.config/systemd/user/aw-deck-sync.service" \
      "$HOME/.config/systemd/user/aw-deckd.service" \
      "$HOME/.config/systemd/user/aw-deck-timer.service" \
      "$HOME/.config/systemd/user/streamdeck-ui.service"

rm -f "$HOME/.local/bin/deck-bootstrap" \
      "$HOME/.local/bin/aw-deck-sync" \
      "$HOME/.local/bin/aw-deckd" \
      "$HOME/.local/bin/aw-deckctl" \
      "$HOME/.local/bin/aw-deck-timer"

systemctl --user daemon-reload
echo "Désinstallé."
