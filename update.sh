#!/usr/bin/env bash
set -euo pipefail

# Réinstalle les fichiers depuis le repo local et recharge les services.
# À utiliser après un `git pull` ou après avoir édité les scripts.

mkdir -p "$HOME/.local/bin" "$HOME/.config/systemd/user"

# Binaries
install -m 0755 bin/aw-deckd         "$HOME/.local/bin/aw-deckd"
install -m 0755 bin/aw-deckctl       "$HOME/.local/bin/aw-deckctl"
install -m 0755 bin/aw-deck-sync     "$HOME/.local/bin/aw-deck-sync"
install -m 0755 bin/deck-bootstrap   "$HOME/.local/bin/deck-bootstrap"
install -m 0755 bin/aw-deck-timer    "$HOME/.local/bin/aw-deck-timer"

# User services
install -m 0644 systemd-user/aw-deckd.service          "$HOME/.config/systemd/user/aw-deckd.service"
install -m 0644 systemd-user/aw-deck-sync.service      "$HOME/.config/systemd/user/aw-deck-sync.service"
install -m 0644 systemd-user/deck-bootstrap.service    "$HOME/.config/systemd/user/deck-bootstrap.service"
install -m 0644 systemd-user/streamdeck-ui.service     "$HOME/.config/systemd/user/streamdeck-ui.service"
install -m 0644 systemd-user/deck-before-sleep.service "$HOME/.config/systemd/user/deck-before-sleep.service"
install -m 0644 systemd-user/aw-deck-timer.service     "$HOME/.config/systemd/user/aw-deck-timer.service"

systemctl --user daemon-reload

# D'abord: streamdeck-ui (dépendance de deck-bootstrap et aw-deck-sync)
if systemctl --user is-enabled streamdeck-ui.service >/dev/null 2>&1; then
  systemctl --user restart streamdeck-ui.service
else
  systemctl --user enable --now streamdeck-ui.service 2>/dev/null || true
fi

# (Re)lancer/activer les services principaux (aw-deck*)
for svc in aw-deckd.service aw-deck-sync.service aw-deck-timer.service; do
  if systemctl --user is-enabled "$svc" >/dev/null 2>&1; then
    systemctl --user restart "$svc"
  else
    systemctl --user enable --now "$svc"
  fi
done

# deck-bootstrap (oneshot) : activer au login et exécuter maintenant une fois
if ! systemctl --user is-enabled deck-bootstrap.service >/dev/null 2>&1; then
  systemctl --user enable deck-bootstrap.service
fi
systemctl --user start deck-bootstrap.service || true
systemctl --user enable deck-before-sleep.service || true

echo "OK. Status :"
systemctl --user --no-pager status streamdeck-ui.service aw-deckd.service aw-deck-sync.service
