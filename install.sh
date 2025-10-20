#!/usr/bin/env bash
set -euo pipefail
mkdir -p "$HOME/.local/bin" "$HOME/.config/systemd/user"

# Binaries
install -m 0755 bin/aw-deckd           "$HOME/.local/bin/aw-deckd"
install -m 0755 bin/aw-deckctl         "$HOME/.local/bin/aw-deckctl"
install -m 0755 bin/aw-deck-sync       "$HOME/.local/bin/aw-deck-sync"
install -m 0755 bin/deck-bootstrap     "$HOME/.local/bin/deck-bootstrap"
install -m 0755 bin/aw-deck-timer      "$HOME/.local/bin/aw-deck-timer"
install -m 0755 bin/deck-sleep-watcher "$HOME/.local/bin/deck-sleep-watcher"

# User services
install -m 0644 systemd-user/aw-deckd.service        "$HOME/.config/systemd/user/aw-deckd.service"
install -m 0644 systemd-user/aw-deck-sync.service    "$HOME/.config/systemd/user/aw-deck-sync.service"
install -m 0644 systemd-user/deck-bootstrap.service  "$HOME/.config/systemd/user/deck-bootstrap.service"
install -m 0644 systemd-user/streamdeck-ui.service   "$HOME/.config/systemd/user/streamdeck-ui.service"
install -m 0644 systemd-user/aw-deck-timer.service   "$HOME/.config/systemd/user/aw-deck-timer.service"

# (Optionnel) service "avant veille" si présent dans le repo
if [ -f systemd-user/deck-before-sleep.service ]; then
  install -m 0644 systemd-user/deck-before-sleep.service "$HOME/.config/systemd/user/deck-before-sleep.service"
fi

systemctl --user daemon-reload

# Démarrer d'abord streamdeck-ui (UI nécessaire aux autres)
systemctl --user enable --now streamdeck-ui.service || true

systemctl --user enable --now aw-deckd.service
systemctl --user enable --now aw-deck-sync.service
systemctl --user enable --now aw-deck-timer.service
systemctl --user enable deck-bootstrap.service
systemctl --user start deck-bootstrap.service || true
systemctl --user enable --now deck-before-sleep.service || true

echo "OK. Status :"
systemctl --user --no-pager status streamdeck-ui.service aw-deckd.service aw-deck-sync.service
