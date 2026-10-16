# Modern AS UI (KeijinUI)

Many thanks to [SurvivorsDragonUi](https://github.com/migwynkriid13/SurvivorsDragonUi) and [Survivor UI](https://github.com/morderous/survivor-ui), the two projects that inspired this interface.

A complete, consistent interface for **Azeroth Survivors** (WoW 1.12 client, Interface 11200).
English first, [Deutsch below](#deutsch).

![KeijinUI overview](screenshots/overview.jpg)

## English

### What it is

KeijinUI replaces the stock Azeroth Survivors HUD with one interface in a single visual style:

* Run overview with zone, run clock, progress and boss schedule (boss time and run time)
* Run statistics: elites, guardians and bosses defeated, damage taken, effective healing, gold earned
* Damage meter with total and DPS per ability, list of the biggest critical hits
* Player and target frames with round portrait and joined health bar, square minimap, action bar with ranks and cooldowns
* Build overview with spells, jewelry and a build tip
* Encounter bars for bosses, elites and rares, modern nameplates, scrolling combat text with spell icons
* Loot notice, achievement popup and one chat window in the same frame style
* Settings window with tabs, layout mode with grid and snapping, a ready made default layout
* Class resources: rogue combo points, warlock soul shards and warrior rage; attached to the player or movable with Alt
* Original chamfered frames with warm bronze unit borders
* English and German interface

![Layout mode with grid](screenshots/layout-mode.jpg)

### Installation

1. Download `KeijinUI-x.y.z.zip` from the latest [release](https://github.com/KeijinDE/KeijinUI_modern-as-ui/releases/latest) (not "Source code").
2. Unpack it into the AddOns folder of the game, so that `AddOns/KeijinUI/KeijinUI.toc` exists.
3. Disable SurvivorsDragonUi, SurvivorUI, KeijinBuildBar, KeijinRunCounters and KeijinAchievements, because KeijinUI contains their functions.
4. Restart the game completely.

### First steps

* `/kui` opens the settings window.
* Hold **Alt** to see all frames, drag them with the left mouse button, Alt and mouse wheel changes the size.
* `/kui lang de` switches to German, `/kui lang en` back to English (default).
* `/kui reset` restores the default layout.

![Settings window](screenshots/settings.png)

All commands and details are in [KeijinUI/README.md](KeijinUI/README.md). The full version history is in [CHANGELOG.md](KeijinUI/CHANGELOG.md).

### Credits

* KeijinUI is my own work: code and bundled graphics were written or generated for this project. No code or textures of other addons are included.
* SurvivorsDragonUi and Survivor UI served as inspiration and functional models for what an Azeroth Survivors interface can show.
* Icons, portraits and some status bars are referenced from the game client by path and are not shipped. They belong to Blizzard Entertainment.

## Deutsch

Vielen Dank an [SurvivorsDragonUi](https://github.com/migwynkriid13/SurvivorsDragonUi) und [Survivor UI](https://github.com/morderous/survivor-ui), die beiden Projekte, die als Inspiration für diese Oberfläche dienten.

Eine vollständige, einheitliche Oberfläche für **Azeroth Survivors** (WoW 1.12 Client, Interface 11200).

### Was es ist

KeijinUI ersetzt die Standardanzeigen von Azeroth Survivors durch eine Oberfläche in einem Stil:

* Runübersicht mit Zone, Runuhr, Fortschritt und Bossplan (Bosszeit und Runzeit)
* Runstatistiken: Eliten, Wächter und Bosse besiegt, Schaden erlitten, effektive Heilung, Gold verdient
* Schadensanzeige mit Gesamtschaden und DPS je Fähigkeit, Liste der größten kritischen Treffer
* Spieler und Zielframe mit rundem Porträt und angeschlossenem Lebensbalken, eckige Minimap, Aktionsleiste mit Rängen und Abklingzeiten
* Buildübersicht mit Zaubern, Schmuck und Buildtipp
* Begegnungsbalken für Bosse, Eliten und Rares, moderne Namensplaketten, scrollender Kampftext mit Zaubersymbolen
* Beutemeldung, Erfolgsmeldung und ein Chatfenster im gleichen Rahmenstil
* Optionsfenster mit Tabs, Layoutmodus mit Raster und Einrasten, fertiges Standardlayout
* Klassenressourcen: Combopunkte, Seelensplitter und Wut; am Spieler befestigt oder mit Alt frei beweglich
* Eigene abgeschrägte Rahmen mit warmen bronzefarbenen Unitkanten
* Oberfläche auf Englisch und Deutsch

### Installation

1. `KeijinUI-x.y.z.zip` aus dem neuesten [Release](https://github.com/KeijinDE/KeijinUI_modern-as-ui/releases/latest) herunterladen (nicht „Source code“).
2. In den AddOns Ordner des Spiels entpacken, sodass `AddOns/KeijinUI/KeijinUI.toc` existiert.
3. SurvivorsDragonUi, SurvivorUI, KeijinBuildBar, KeijinRunCounters und KeijinAchievements deaktivieren, weil KeijinUI deren Funktionen enthält.
4. Das Spiel vollständig neu starten.

### Erste Schritte

* `/kui` öffnet das Optionsfenster.
* **Alt** halten zeigt alle Rahmen, mit der linken Maustaste verschieben, Alt und Mausrad ändern die Größe.
* `/kui lang de` stellt auf Deutsch um, `/kui lang en` zurück auf Englisch (Standard).
* `/kui reset` stellt das Standardlayout wieder her.

Alle Befehle und Details stehen in [KeijinUI/README.md](KeijinUI/README.md). Der vollständige Versionsverlauf steht in [CHANGELOG.md](KeijinUI/CHANGELOG.md).

### Danksagung

* KeijinUI ist eigene Arbeit: Code und mitgelieferte Grafiken wurden für dieses Projekt geschrieben oder erzeugt. Code oder Texturen anderer Addons sind nicht enthalten.
* SurvivorsDragonUi und Survivor UI dienten als Inspiration und funktionale Vorbilder dafür, was eine Oberfläche für Azeroth Survivors anzeigen kann.
* Symbole, Porträts und einige Statusleisten werden aus dem Spielclient über ihren Pfad referenziert und nicht mitgeliefert. Sie gehören Blizzard Entertainment.
