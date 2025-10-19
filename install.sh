#!/usr/bin/env bash
set -euo pipefail
mkdir -p "$HOME/.local/bin" "$HOME/.config/systemd/user"

install -m 0755 bin/aw-deckd    "$HOME/.local/bin/aw-deckd"
install -m 0755 bin/aw-deckctl  "$HOME/.local/bin/aw-deckctl"
install -m 0644 systemd-user/aw-deckd.service "$HOME/.config/systemd/user/aw-deckd.service"

systemctl --user daemon-reload
systemctl --user enable --now aw-deckd.service

echo "OK. Status :"; systemctl --user --no-pager status aw-deckd.service
