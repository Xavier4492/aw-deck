# aw-deck — Pont ActivityWatch ⇄ Stream Deck

Suivi d’activité (client/projet/tâche) depuis ton Stream Deck, envoyé vers ActivityWatch via un petit démon user `systemd`.

## 🧱 Vue d’ensemble

* **Daemon** : `aw-deckd` lit `~/.local/state/aw-deck/state.json` toutes les `INTERVAL` secondes et envoie un **heartbeat** vers le bucket `aw-deck_<hostname>`.
* **CLI** : `aw-deckctl` met à jour `state.json` (ex. `start ACME -p SiteWeb -t "Fix header"` / `stop`).
* **Service** : `~/.config/systemd/user/aw-deckd.service` lance le daemon au login.

**Testé avec :**

* **StreamController** (via environnement Python **venv** — recommandé pour éviter les limitations Flatpak et disposer d’actions/scripts flexibles).

---

## ✅ Prérequis

* **ActivityWatch** (serveur) en user service :

  ```bash
  systemctl --user enable --now aw-server.service
  ```

  Par défaut accessible sur `http://localhost:5600`.

* **Outils** : `bash`, `curl`, `jq`.

  ```bash
  sudo apt install -y curl jq
  ```

---

## 🚀 Installation

### Installation (première fois)

Depuis la racine du repo :

```bash
./install.sh
```

Cela installe `aw-deckd`, `aw-deckctl`, la unit `aw-deckd.service`, recharge systemd user et **active** le service.

### Vérifier

```bash
systemctl --user status aw-deckd.service
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

```
~/.local/state/aw-deck/state.json
```

Il est auto-créé si absent et ignoré s’il est invalide (pas de crash).

---

## 🎛️ Intégration côté StreamController (recommandé)

1. **Installation de StreamController (méthode conseillée)**
   Utilise un **venv Python** dans le dossier du projet (fiable, pas de sandbox Flatpak) et installe les dépendances GNOME/GTK si besoin.
   Sur Ubuntu 24.04, paquets utiles :

   ```bash
   sudo apt install -y libadwaita-1-0 gir1.2-adw-1 \
       libgtk-4-1 gir1.2-gtk-4.0 adwaita-icon-theme
   ```

   > Remarque : certaines révisions récentes de StreamController utilisent des widgets Adwaita récents. Si ta distro n’exporte pas encore ces API, reste sur une révision compatible **ou** mets à jour libadwaita/ton OS.

2. **Mapper un bouton pour appeler le CLI**
   Dans l’éditeur de pages de StreamController :

   * Ajoute une action qui **exécute une commande shell** (via le plugin **OS** → *Run command*, ou l’action équivalente suivant ta build).
   * Exemples de commandes :

     * Démarrer une session :
       `~/.local/bin/aw-deckctl start ACME -p SiteWeb`
     * Changer de contexte (alias) :
       `~/.local/bin/aw-deckctl switch ACME -p AppMobile -t "Bug #123"`
     * Stop :
       `~/.local/bin/aw-deckctl stop`

3. **Bonnes pratiques**

   * Un bouton par **client/projet** récurrent.
   * Un bouton “Stop/Pause” global (`aw-deckctl stop`).
   * Les **états de boutons** dans StreamController ne sont **pas** scellés à une page : si tu veux un état visuel différent par page, **duplique** le bouton sur chaque page concernée.

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
