# aw-deck — Pont ActivityWatch ⇄ Stream Deck

Suivi d’activité (client/projet/tâche) depuis ton Stream Deck, envoyé vers ActivityWatch via des services **systemd (user)**.

## 🧱 Vue d’ensemble

* **Daemon** : `aw-deckd` lit `~/.local/state/aw-deck/state.json` toutes les `INTERVAL` secondes et envoie un **heartbeat** vers le bucket `aw-deck_<hostname>`.
* **CLI** : `aw-deckctl` met à jour `state.json` (ex. `start ACME -p SiteWeb -t "Fix header"` / `stop`).
* **Sync UI** : `aw-deck-sync` (service user) écoute les changements de `state.json` et met à jour l’UI du deck :
  - **Page 1** : colonne du **client actif** en **état 2** (ou 1 si pas d’état 2),
  - **Bouton Stop (9)** : **état 2** quand actif,
  - **Page client** (2..5) : bouton **projet actif** en **état 1**.
* **Bootstrap** : `deck-bootstrap` (service oneshot) met **page 0** au login puis **page 1** quand prêt.

**Testé avec** : StreamController (via venv) et `streamdeckc`.

---

## ✅ Prérequis

```bash
sudo apt install -y curl jq inotify-tools
systemctl --user enable --now aw-server.service   # ActivityWatch
```

---

## 🚀 Installation

```bash
./install.sh
```

Active `aw-deckd`, `aw-deck-sync`, et exécute `deck-bootstrap` (oneshot).

Vérifier :

```bash
systemctl --user status aw-deckd.service
systemctl --user status aw-deck-sync.service
journalctl --user -u aw-deck-sync.service -f
```

> Le daemon crée le bucket si nécessaire et réessaie calmement si `aw-server` n’est pas encore prêt.

---

## 🕹️ Utilisation (CLI)

```bash
aw-deckctl start <client> [-p <projet>] [-t <tache>]
aw-deckctl switch <client> [-p <projet>] [-t <tache>]   # alias de start
aw-deckctl stop
aw-deckctl status
```

Exemples :

```bash
aw-deckctl start ACME -p SiteWeb -t "Fix header"
aw-deckctl switch ACME -p AppMobile
aw-deckctl stop
aw-deckctl status
```

Le fichier d’état est toujours ici :

```bash
~/.local/state/aw-deck/state.json
```

Il est auto-créé si absent et ignoré s’il est invalide (pas de crash).

---

## ⚙️ Paramètres (daemon)

Dans `~/.config/systemd/user/aw-deckd.service` :

```ini
[Service]
Environment=INTERVAL=10    # heartbeat toutes les 10 s
Environment=PULSETIME=30   # fusion de pulses ≤ 30 s côté AW
```

Appliquer une modification :

```bash
systemctl --user daemon-reload
systemctl --user restart aw-deckd.service
```

---

## 🔍 Vérifications & Debug

* Voir les buckets :

  * UI Web : [http://localhost:5600/#/buckets](http://localhost:5600/#/buckets)
  * API : `curl -s http://localhost:5600/api/0/buckets/ | jq`

* Suivre en direct :

  ```bash
  journalctl --user -u aw-deckd.service -f
  ```

* Forcer un test :

  ```bash
  aw-deckctl start TEST -p Demo
  sleep 12
  aw-deckctl stop
  ```

---

## 🔄 Mise à jour

Après un `git pull` (ou si tu as modifié `bin/` ou `systemd-user/`), applique :

```bash
git pull
./update.sh
```

Cela recopie les fichiers vers `~/.local/bin/` et `~/.config/systemd/user/`, fait un `daemon-reload` et **redémarre** le service (ou l’active s’il ne l’était pas).

---

## 🗑️ Désinstallation

```bash
./uninstall.sh
```

Cela désactive/arrête le service, supprime les fichiers installés et recharge systemd user.

---

## 📝 Notes plateformes

* **StreamController en Flatpak** : l’accès USB/DBus peut être restreint (sandbox). Des overrides existent (`--device=all`, `--filesystem=home`, permissions DBus), mais la voie **venv** est en général plus simple/fiable.
* **Libadwaita/GTK** : si tu vois des erreurs du type `Adw.ToggleGroup` introuvable, c’est lié à la version de libadwaita de ta distro (mets à jour ou utilise une révision SC compatible).
* **Veille/Réveil** : le service user `systemd` gère bien la reprise ; `aw-deckd` réémet au cycle suivant.

---

## 💡 Idées d’amélioration

* Bouton “⏱ Pause 15 min” : script qui bascule `active:false` puis remet l’état précédent.
* Ajout d’un champ “tag” / “note” temporaire via un bouton dédié (`aw-deckctl switch ACME -p SiteWeb -t "Debug SSL"`).
* Exploiter l’UI/queries d’ActivityWatch pour des exports (CSV/rapports).

---

## Licence

Fais-en ce que tu veux.
