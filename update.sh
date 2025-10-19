#!/usr/bin/env bash
set -euo pipefail

# Réinstalle les fichiers depuis le repo local et recharge le service.
# À utiliser après un `git pull` ou après avoir édité les scripts.

mkdir -p "$HOME/.local/bin" "$HOME/.config/systemd/user"

install -m 0755 bin/aw-deckd    "$HOME/.local/bin/aw-deckd"
install -m 0755 bin/aw-deckctl  "$HOME/.local/bin/aw-deckctl"
install -m 0644 systemd-user/aw-deckd.service "$HOME/.config/systemd/user/aw-deckd.service"

systemctl --user daemon-reload

# Si le service n’était pas encore activé, on l’active ; sinon on redémarre.
if systemctl --user is-enabled aw-deckd.service >/dev/null 2>&1; then
  systemctl --user restart aw-deckd.service
else
  systemctl --user enable --now aw-deckd.service
fi

echo "OK. Status :"
systemctl --user --no-pager status aw-deckd.service
