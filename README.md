# aw-deck — Pont ActivityWatch ⇄ Stream Deck (Ubuntu 24.04 LTS)

Automatise l’allumage du Stream Deck, l’affichage des pages et l’envoi de “heartbeats” ActivityWatch selon le **client/projet/tâche** sélectionné via des boutons.
Le tout tourne avec des **services systemd (user)**, démarre automatiquement à la session, repasse en **page 0** avant la veille, et synchronise l’UI du Deck dès qu’un client/projet change.

Testé sur **Ubuntu 24.04.3 LTS**.

---

## 🧩 Ce que fait exactement ce repo

* **`aw-deckctl` (CLI)** : écrit l’état courant dans `~/.local/state/aw-deck/state.json`
  (`start <client> [-p <projet>] [-t <tache>]`, `stop`, `status`).
* **`aw-deckd` (daemon)** : lit ce JSON toutes les `INTERVAL` secondes et envoie un heartbeat à **ActivityWatch** (bucket `aw-deck_<hostname>`).
* **`aw-deck-sync` (daemon)** : écoute les changements du JSON et **met à jour l’UI** du Stream Deck via `streamdeckc` :

  * **Page 1** (clients) : la *colonne* du client actif passe en **état 1**.
  * **Bouton Stop (index 9)** sur la page 1 : passe en **état 1** quand une activité est active.
  * **Page client** (pages 2 à 5) : le **bouton du projet actif** passe en **état 1**.
* **`deck-bootstrap` (oneshot au login)** : met **page 0** immédiatement, attend que le Deck & `streamdeckc` répondent, puis bascule en **page 1**.
* **Services systemd (user)** fournis :

  * `streamdeck-ui.service` : lance **streamdeck-linux-gui** en arrière-plan (`-n`).
  * `aw-deckd.service`, `aw-deck-sync.service`
  * `deck-bootstrap.service` (oneshot)
  * `deck-before-sleep.service` (optionnel) : repasse **page 0** avant la mise en veille.

---

## 📦 Prérequis (à faire une fois sur une machine neuve)

> Tu peux exécuter tout ça **avant** d’installer ce repo.

1. **ActivityWatch (serveur)**

    ```bash
    sudo snap install activitywatch
    systemctl --user enable --now aw-server.service
    # Vérif rapide (facultatif) :
    curl -s http://localhost:5600/api/0/info | jq .
    ```

2. **Outils systèmes**

    ```bash
      sudo apt update
      sudo apt install -y curl jq inotify-tools
    ```

3. **Stream Deck**
    * **Backend/GUI** : `streamdeck-linux-gui` (binaire `streamdeck`) – installe-le de ta méthode habituelle (AppImage, .deb, build local…).
      Place le binaire dans `~/.local/bin/streamdeck` (ou ajuste le service `streamdeck-ui.service`).
    * **CLI `streamdeckc`** : fourni par **StreamController** (ou équivalent). Assure-toi d’avoir la commande `streamdeckc` disponible dans `$PATH`.

    > Astuce : un `which streamdeckc` te dira le chemin réel. Idem pour `which streamdeck`.

---

## 🛠️ Installation de ce repo (ou réinstallation)

Depuis le dossier du repo :

```bash
./install.sh
```

Ce script :

* copie les binaires dans `~/.local/bin/`,
* installe/active les services **user** dans `~/.config/systemd/user/`,
* démarre **d’abord** `streamdeck-ui.service`, puis `aw-deckd` et `aw-deck-sync`,
* déclenche `deck-bootstrap` (oneshot) pour afficher **page 1** quand tout est prêt,
* active `deck-before-sleep` si présent.

### Vérifications rapides

```bash
systemctl --user status streamdeck-ui.service
systemctl --user status aw-deckd.service
systemctl --user status aw-deck-sync.service
journalctl --user -u aw-deck-sync.service -f
```

---

## 🎛️ Mappage des pages & comportements

* **Page 0** : “veille/marche/arrêt” — affichée :

  * au login **puis** remplacée par la page 1 quand prêt,
  * **avant la veille** (via `deck-before-sleep.service`).
* **Page 1 (clients)** : colonnes (haut/milieu/bas) par client :

  * Colonne **Owapp** : boutons `0 5 10`
  * **Stelivo** : `1 6 11`
  * **JuicyWeb** : `2 7 12`
  * **GreenCompany** : `3 8 13`
  * **Stop** : bouton `9`
* **Pages projets** :

  * **Page 2 (Owapp)** : `1:Owapp`, `2:Ensemble`, `3:client seul`
  * **Page 3 (Stelivo)** : `1:SextingApps`, `2:NCMEC`, `3:Popunder`, `4:client seul`
  * **Page 4 (JuicyWeb)** : `1:CarsApi`, `2:Automarket`, `3:Carsloc`, `4:client seul`
  * **Page 5 (GreenCompany)** : `1:Resval`, `2:Pricecat`, `3:Autoparts`, `4:client seul`

> Les **états visuels** (0/1/2) sont appliqués par `bin/aw-deck-sync` via `streamdeckc`.

---

## ⌨️ Utilisation (CLI)

```bash
# Démarrer/commuter une activité
aw-deckctl start <client> [-p <projet>] [-t <tache>]
aw-deckctl switch <client> [-p <projet>] [-t <tache>]   # alias de start

# Stopper l’activité en cours
aw-deckctl stop

# Voir l’état brut (JSON)
aw-deckctl status
```

Exemples :

```bash
aw-deckctl start Owapp -p Owapp
aw-deckctl switch Owapp -p "Ensemble"
aw-deckctl stop
```

Le fichier d’état est **toujours** ici : `~/.local/state/aw-deck/state.json`.

---

## ⚙️ Paramètres (daemon → ActivityWatch)

Dans `~/.config/systemd/user/aw-deckd.service` :

```ini
[Service]
Environment=INTERVAL=10    # heartbeat toutes les 10 s
Environment=PULSETIME=30   # fusionne les pulses ≤ 30 s côté AW
```

Appliquer après modification :

```bash
systemctl --user daemon-reload
systemctl --user restart aw-deckd.service
```

---

## 🔁 Mise à jour du repo

Après un `git pull` (ou des modifs dans `bin/` / `systemd-user/`) :

```bash
./update.sh
```

Le script recopie les fichiers, `daemon-reload`, et redémarre ce qu’il faut.

---

## 🗑️ Désinstallation propre

```bash
./uninstall.sh
```

Désactive/arrête les services, supprime binaires et units, puis `daemon-reload`.

---

## 🧪 Vérifs & debug

* **Buckets AW** :

  * UI : `http://localhost:5600/#/buckets`
  * API : `curl -s http://localhost:5600/api/0/buckets/ | jq`
* **Logs** :

  ```bash
  journalctl --user -u streamdeck-ui.service -f
  journalctl --user -u aw-deckd.service -f
  journalctl --user -u aw-deck-sync.service -f
  ```

* **Test express** :

  ```bash
  aw-deckctl start TEST -p Demo
  sleep 12
  aw-deckctl stop
  ```

---

## ❗Points d’attention (à relire quand tu répliques dans quelques mois)

1. **Chemins des binaires**

   * `streamdeck` (GUI) : par défaut ce repo le lance via `%h/.local/bin/streamdeck` (voir `systemd-user/streamdeck-ui.service`).
     Si tu l’installes ailleurs, modifie `ExecStart=`.

2. **Ordre de démarrage**

   * `streamdeck-ui.service` **doit** démarrer avant `aw-deck-sync.service` et avant `deck-bootstrap.service`.

3. **USB/permissions**

   * Si le Deck n’est pas détecté par `streamdeck-linux-gui`, vérifie udev/permissions USB (dépend de ta méthode d’installation).

---

## 📎 Référence des services (résumé)

* `systemd-user/streamdeck-ui.service`
  Lance **streamdeck-linux-gui** *sans* ouvrir la fenêtre (`-n`) et le garde en arrière-plan.
* `systemd-user/deck-bootstrap.service` *(oneshot, au login)*
  Force la **page 0** puis bascule en **page 1** quand l’UI répond.
* `systemd-user/aw-deckd.service`
  Lit le JSON et envoie des **heartbeats** à ActivityWatch.
* `systemd-user/aw-deck-sync.service`
  Applique les **états des boutons/pages** en fonction du JSON.
* `systemd-user/deck-before-sleep.service` *(optionnel)*
  Met la **page 0** juste avant la **veille**.

---

## ✅ Checklist “nouveau PC”

1. Installer **ActivityWatch** et l’activer en user : `systemctl --user enable --now aw-server.service`
2. Installer `curl jq inotify-tools`
3. Installer **streamdeck-linux-gui** et placer `streamdeck` dans `~/.local/bin/` (ou adapter le service)
4. Installer `streamdeckc` (et vérifier son chemin)
5. Cloner ce repo et lancer `./install.sh`
6. Vérifier les services (`status`) puis tester :
   `aw-deckctl start Owapp -p Owapp`, observer la colonne/états, `aw-deckctl stop`

---

## 💡 Idées d’amélioration

* Bouton “⏱ Pause 15 min” : script qui bascule `active:false` puis remet l’état précédent.
* Ajout d’un champ “tag” / “note” temporaire via un bouton dédié (`aw-deckctl switch ACME -p SiteWeb -t "Debug SSL"`).
* Exploiter l’UI/queries d’ActivityWatch pour des exports (CSV/rapports).

---

## Licence

Fais-en ce que tu veux.
