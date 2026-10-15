# KeijinUI 0.6.0

Interface addon for Azeroth Survivors (WoW 1.12, Interface 11200). English first, German below.
Repository: https://github.com/KeijinDE/modern-as-ui

Deutsche Fassung: siehe [Deutsch](#deutsch).

# English

## Overview

KeijinUI replaces the stock Azeroth Survivors interface with one consistent interface. Run overview below the minimap,
run statistics, damage meter and critical hits on the left, your own player and target frames in the same panel style
(flat dark frame, name in a heading strip, health bar in a metal frame, round portrait in a square box), a square minimap, a symmetric action bar with ranks and
cooldowns (mana is not shown), a build overview, modern nameplates, damage numbers in the world, loot notice,
achievement popup and one chat window in the KeijinUI frame.

From 0.4.0 the whole interface is bilingual. English is the default; German is chosen by hand (settings window or
`/kui lang de`).

## Features

* Run overview with zone, run clock, progress bar and bosses with two time columns: boss time (active time since the boss appeared) and run time. Example: `3:23 | 0:23` means the boss died at 3:23 run time after 23 seconds. Stopped times turn green. Bosses that died before the interface loaded show question marks, because the game provides no past times of death.
* Run statistics: elites, guardians and bosses defeated, damage taken, effective healing, gold earned. A counter row below shows kills, gold, chest price, caches opened and the estimated time until the next cache is affordable (an estimate, not a chest timer).
* Damage meter and list of biggest critical hits. Every ability keeps one fixed color. Critical hits are read from the native combat messages and are collected from the moment the interface loads.
* Player and target frames in the style of the panels: flat dark fill with the panel border, name in a gold heading strip, health bar in the metal frame of the list rows, portrait in a square box with the same border (the client cuts portraits to a circle). Class colored health bars (switchable to green and red). Health is shown as percent and points, for example `99% / 403`. The target frame appears only with a target, marks elite (`+`) and rare (`R`) targets by the level text and the border color, and shows the target's debuffs below it.
* Square minimap in the panel style (Settings, Display: "Minimap in KeijinUI style"). Zone name in gold at the top, mouse wheel zooms, movable like every other element, the run overview hangs below it. Turning the option off restores the original round minimap. The native round border, zoom buttons, toggle button, zone name and day/night indicator are hidden while the style is on; tracking, mail and battleground icons stay where they are.
* The tooltip of the healing row shows an estimated gross breakdown (leech, heal per kill, regeneration, including overhealing), integrated with the value valid at each moment. The main number stays the effective healing.
* Action bar with six skills and the racial ability on the right, showing ranks and cooldowns only. Build overview below with all spells (rank badge) and jewelry, plus a build tip (`/kbb`).
* Encounter group at the top center for every living boss, elite or rare in a fight. Mouse wheel scrolls further rows.
* Nameplates with metal frames. Modes: all enemies, only boss, elite and rare, or off. Debuffs of the current target appear on the target plate.
* Damage numbers in the world: normal hits small and white, critical hits large and yellow.
* Loot notice that replaces the fixed native boss loot notice (last own loot for eight seconds, with item icon and tooltip).
* Achievement popup (`/kachi`).
* Layout mode: hold Alt to show labeled frames, drag them with the left mouse button, change size with Alt and the mouse wheel (50 to 180 percent). A grid and snapping help to line frames up (hold Shift while releasing to skip snapping). Frames are kept inside the screen.
* Position, size and options are saved immediately.

## Installation

Copy the folder `KeijinUI` into the addon folder of the game and enable it. Disable SurvivorsDragonUi, SurvivorUI,
KeijinBuildBar, KeijinRunCounters and KeijinAchievements, because KeijinUI contains all of their modules. Their saved
settings can stay. After changing the enabled addons, restart the game completely. The camera addon is a separate package.

## Commands

* `/kui`: open the settings window with tabs (movable, remembers its position and the last tab).
* `/kui edit`: open or close layout editing. `/kui reset`: reset positions and sizes. `/kui grid`: grid and snapping on or off.
* `/kui lang de|en`: language. `/kui lang` shows the current language. `/kui reload`: reload the interface.
* `/kui meter reset`: start the damage meter from now on (run statistics stay complete). `/kui crits reset`: clear observed critical hits.
* `/kui text`: damage numbers on or off.
* `/kui plates all|bosses|off`: nameplates on all enemies, only boss, elite and rare, or off. `/kui plates debug`: show what the client provides.
* `/kui bosses debug`, `/kui heal debug`: diagnostics in the chat.
* `/kui tooltip reset`: back to the normal tooltip position.
* `/kbb`: spells and jewelry on or off. `/kbb tips`: build tips on or off. `/kbb focus damage|boss|survival|balanced`: build focus (the German words `tipps`, `fokus schaden|boss|ueberleben|ausgewogen` work too).
* `/kachi test|move|lock|reset|on|off|sound`: achievement popup.

## Language

English is the default. `GetLocale()` returns a fixed value in this client and the game data can still be English after a language change in the game, so KeijinUI does not detect the language. Choose it in the settings window (General tab) or with `/kui lang de` and `/kui lang en`. `/kui lang` shows the current language. Changing the language reloads the interface, so that all texts are switched. Old settings with `auto` become English.

Ability names (recommendation title, tooltips, meter) follow the language: German names in German, English names otherwise. Names that come from the game itself (boss names, items, achievement names, chat) are not translated. The parser for combat messages works the same in every language.

## Data

Run time, level, kills, elites, guardians, bosses, gold, cache count and damage totals come straight from the game interface. Pause and card choice use the stopped game time. Missing values show as question marks. The damage meter takes over all sources of the native meter, including talents and items. The native reset does not affect this interface. Frames you move yourself can overlap again.

## Changelog

* 0.6.0: Everything in the package is now original work: the combat message reader (`CombatParser.lua`) is a new implementation that derives its line shapes from the client's own combat strings, and the bar graphics (frame pieces and fill) are generated by `development/keijinui/prepare_bar_art.py`. The unused unit frame images in `media/units` and the unused blue fill are removed, and the license and source notes that belonged to them are gone. New tests cover every combat template that is read.
* 0.5.3: Language only by hand (English or German, default English); the automatic detection is removed because it read outdated English game data after a language change and switched wrongly. Changing the language reloads the interface. The native displays (clock, kills bar, damage meter, boss bars, spell bar) stay hidden as long as the matching KeijinUI element is switched on, even without game data, so nothing appears twice; they come back when the element is switched off. A native display that the game switches on again is hidden again at the next update.
* 0.5.2: `/kachi debug` records system messages (persistent, last 60, `/kachi log`, `/kachi log clear`) to check whether achievement lines reach addons. Achievements are also recognized in the general form `Text: [Name] (N ...)`, since no German client text is known.
* 0.5.1: Default layout: all elements start in the arrangement of the author (fresh install and "reset layout"); the default is not stored, so later changes of it apply, and saved positions keep priority. Nameplates default to bosses, elites and rares.
* 0.5.0: Player and target frames in the panel style (square portrait box, metal health bar, heading strip). Square minimap in the KeijinUI style with zoom by mouse wheel, layout key `minimap` and a switch in the settings. Estimated healing breakdown (leech, heal per kill, regeneration) in the tooltip of the healing row.
* 0.4.2: Settings window with tabs (Display, Units, Layout, General), switches as clickable rows, the last tab is remembered. Automatic language detection now always runs along: `/kui lang auto` applies the detected language at once, without evidence the stored detection stays, the majority of known names decides.
* 0.4.1: Bar fill and background of list rows (encounters, meter) stay inside the rounded border corners.
* 0.4.0: Bilingual interface (German or English), detection and `/kui lang`, `/kui reload`, English arguments for `/kbb`, bilingual README.
* 0.3.7: The build tip names abilities in the interface language, even if the spell book reports English names.
* 0.3.6: Grid and snapping in layout mode.
* 0.3.5: Buffs can be left aligned.
* 0.3.4: Damage numbers never cover frames. The build rating maps meter values through ability keys.
* 0.3.3: Statistic row "Healing (effective)" and `/kui heal debug`.
* 0.3.2: Shorter statistics. 0.3.1: Encounters without UnitAffectingCombat. 0.3.0: Own chat window, damage numbers in the world, target debuffs.
* 0.2.x: Action bar, build overview, class colored health bars, nameplates.

## Credits

SurvivorsDragonUi and Survivor UI served as inspiration and functional models for what an interface for Azeroth Survivors can show. KeijinUI contains no code or images from them. Remaining Blizzard textures are only referenced by their client path and are not shipped.

## Tests

The integration is checked with Lua 5.1 and the extracted game interface (`py -3.12 development/keijinui/test_keijinui.py`). These tests do not replace a visual check in the running game.

# Deutsch

## Überblick

KeijinUI ersetzt die Standardoberfläche von Azeroth Survivors durch eine einheitliche Oberfläche. Runübersicht unter der
Minimap, Runstatistiken, Schadensanzeige und kritische Treffer links, eigene Spieler und Zielframes im gleichen Panelstil
(flache dunkle Fläche, Name in einer Titelleiste, Lebensbalken im Metallrahmen, rundes Porträt im eckigen Kasten), eine eckige Minimap, eine symmetrische
Aktionsleiste mit Rängen und Abklingzeiten (Mana wird nicht angezeigt), eine Buildübersicht, moderne Namensplaketten,
Schadenszahlen in der Spielwelt, Beutemeldung, Erfolgsmeldung und ein einzelnes Chatfenster im KeijinUI Rahmen.

Ab 0.4.0 ist die ganze Oberfläche zweisprachig. Englisch ist der Standard, Deutsch wählst du von Hand (Optionsfenster oder
`/kui lang de`).

## Funktionen

* Runübersicht mit Zone, Runuhr, Fortschrittsbalken und Bossen mit zwei Zeitspalten: Bosszeit (aktive Zeit seit dem Erscheinen) und Runzeit. Beispiel: `3:23 | 0:23` bedeutet, dass der Boss bei 3:23 Runzeit nach 23 Sekunden besiegt wurde. Gestoppte Zeiten werden grün. Bosse, die vor dem Laden der Oberfläche besiegt wurden, zeigen Fragezeichen, weil die Spielschnittstelle keine vergangenen Todeszeitpunkte liefert.
* Runstatistiken: Eliten, Wächter und Bosse besiegt, Schaden erlitten, Heilung (effektiv), Gold verdient. Eine Zählerzeile darunter zeigt Kills, Gold, Cachepreis, geöffnete Caches und die geschätzte Zeit, bis der nächste Cache bezahlbar ist (eine Schätzung, kein Kistentimer).
* Schadensanzeige und Liste der größten kritischen Treffer. Jede Fähigkeit behält eine feste Farbe. Kritische Treffer werden aus den nativen Kampfnachrichten gelesen und ab dem Laden der Oberfläche gesammelt.
* Spieler und Zielframes im Stil der Panels: flache dunkle Fläche mit dem Panelrand, Name in einer goldenen Titelleiste, Lebensbalken im Metallrahmen der Listenzeilen, Porträt in einem eckigen Kasten mit demselben Rand (der Client schneidet Porträts selbst rund). Lebensbalken in Klassenfarbe (umschaltbar auf Grün und Rot). Das Leben steht als Prozent und Punkte da, beispielsweise `99% / 403`. Der Zielframe erscheint nur mit Ziel, kennzeichnet Elite (`+`) und Rare (`R`) über den Leveltext und die Randfarbe und zeigt die Debuffs des Ziels darunter.
* Eckige Minimap im Panelstil (Einstellungen, Anzeige: "Minimap im KeijinUI Stil"). Zonenname oben in Gold, Mausrad zoomt, verschiebbar wie jedes andere Element, die Runübersicht hängt darunter. Ausschalten stellt die ursprüngliche runde Minimap wieder her. Der native runde Rand, die Zoomknöpfe, der Ein/Aus Knopf, der Zonenname und die Tag/Nacht Anzeige sind bei eingeschaltetem Stil ausgeblendet; Symbole für Spurensuche, Post und Schlachtfeld bleiben an ihrem Platz.
* Der Tooltip der Heilungszeile zeigt eine geschätzte Brutto Aufschlüsselung (Lebensraub, Heilung pro Kill, Regeneration, inklusive Überheilung), fortgeschrieben mit dem jeweils gültigen Wert. Die Hauptzahl bleibt die effektive Heilung.
* Aktionsleiste mit sechs Skills und der Volksfähigkeit rechts, nur Ränge und Abklingzeiten. Darunter die Buildübersicht mit allen Spells (Rang als Badge) und Schmuck sowie ein Buildtipp (`/kbb`).
* Begegnungsgruppe oben mittig für jeden lebenden Boss, Elite oder Rare im Kampf. Das Mausrad blättert zu weiteren Zeilen.
* Namensplaketten mit Metallrahmen. Modi: alle Gegner, nur Boss, Elite und Rare, oder aus. Debuffs des aktuellen Ziels erscheinen an der Zielplakette.
* Schadenszahlen in der Spielwelt: normale Treffer klein und weiß, kritische Treffer groß und gelb.
* Beutemeldung, die die feste native Beutemeldung der Bosse ersetzt (letzte eigene Beute acht Sekunden lang, mit Symbol und Tooltip).
* Erfolgsmeldung (`/kachi`).
* Layoutmodus: Alt halten zeigt beschriftete Rahmen, mit der linken Maustaste verschieben, Alt und Mausrad ändern die Größe (50 bis 180 Prozent). Raster und Einrasten helfen beim Ausrichten (Shift beim Loslassen schaltet das Einrasten aus). Rahmen bleiben im Bild.
* Positionen, Größen und Optionen werden sofort gespeichert.

## Installation

Den Ordner `KeijinUI` in den Addonordner des Spiels kopieren und aktivieren. SurvivorsDragonUi, SurvivorUI,
KeijinBuildBar, KeijinRunCounters und KeijinAchievements deaktivieren, weil KeijinUI alle deren Module enthält. Die
gespeicherten Einstellungen können erhalten bleiben. Nach einer Änderung der aktivierten Addons das Spiel vollständig
neu starten. Das Kameraaddon ist ein eigenes Paket.

## Befehle

* `/kui`: Einstellungsfenster mit Tabs öffnen (verschiebbar, merkt sich Position und letzten Tab).
* `/kui edit`: Bearbeitung öffnen oder schließen. `/kui reset`: Positionen und Größen zurücksetzen. `/kui grid`: Raster und Einrasten ein oder aus.
* `/kui lang de|en`: Sprache. `/kui lang` zeigt die aktuelle Sprache. `/kui reload`: Oberfläche neu laden.
* `/kui meter reset`: Schadensanzeige ab jetzt neu beginnen (die Runstatistik bleibt vollständig). `/kui crits reset`: beobachtete kritische Treffer zurücksetzen.
* `/kui text`: Schadenszahlen ein oder aus.
* `/kui plates all|bosses|off`: Namensplaketten auf allen Gegnern, nur Boss, Elite und Rare, oder aus. `/kui plates debug`: zeigt, was der Client liefert.
* `/kui bosses debug`, `/kui heal debug`: Diagnose im Chat.
* `/kui tooltip reset`: zurück zur normalen Tooltip Position.
* `/kbb`: Zauber und Schmuckanzeige ein oder aus. `/kbb tipps`: Buildtipps ein oder aus. `/kbb fokus schaden|boss|ueberleben|ausgewogen`: Buildfokus (die englischen Wörter `tips`, `focus damage|boss|survival|balanced` gehen ebenfalls).
* `/kachi test|move|lock|reset|on|off|sound`: Erfolgsmeldung bedienen.

## Sprache

Englisch ist der Standard. `GetLocale()` liefert in diesem Client einen festen Wert, und die Spieldaten können nach einem Sprachwechsel im Spiel noch englisch sein, deshalb erkennt KeijinUI die Sprache nicht. Wähle sie im Optionsfenster (Tab Allgemein) oder mit `/kui lang de` und `/kui lang en`. `/kui lang` zeigt die aktuelle Sprache. Ein Sprachwechsel lädt die Oberfläche neu, damit alle Texte umgestellt sind. Alte Einstellungen mit `auto` werden zu Englisch.

Fähigkeitsnamen (Titel der Empfehlung, Tooltips, Meter) folgen der Sprache: deutsche Namen auf Deutsch, sonst englische. Namen aus dem Spiel selbst (Bossnamen, Gegenstände, Erfolgsnamen, Chat) werden nicht übersetzt. Der Parser für Kampfnachrichten arbeitet in jeder Sprache gleich.

## Daten

Runzeit, Level, Kills, Eliten, Wächter, Bosse, Goldverdienst, Cacheanzahl und Schadenssummen kommen direkt aus der Spielschnittstelle. Pause und Kartenwahl verwenden die angehaltene Spielzeit. Fehlende Werte erscheinen als Fragezeichen. Die Schadensanzeige übernimmt alle Quellen des nativen Meters, einschließlich Talenten und Gegenständen. Der native Reset beeinflusst diese Schnittstelle nicht. Selbst verschobene Rahmen können wieder Überlappungen erzeugen.

## Änderungen

* 0.6.0: Alles im Paket ist jetzt eigene Arbeit: Der Leser für Kampfnachrichten (`CombatParser.lua`) ist neu geschrieben und leitet die Zeilenformen aus den Kampftexten des Clients ab; die Balkengrafiken (Rahmenteile und Füllung) erzeugt `development/keijinui/prepare_bar_art.py`. Die ungenutzten Rahmenbilder in `media/units` und die ungenutzte blaue Füllung sind entfernt, ebenso die zugehörigen Lizenz und Herkunftsdateien. Neue Tests decken jede gelesene Kampftextvorlage ab.
* 0.5.3: Sprache nur noch von Hand (Englisch oder Deutsch, Standard Englisch); die automatische Erkennung entfällt, weil sie nach einem Sprachwechsel veraltete englische Spieldaten las und falsch umschaltete. Ein Sprachwechsel lädt die Oberfläche neu. Die eigenen Anzeigen des Spiels (Uhr, Kill Leiste, Schadensmeter, Bossleisten, Zauberleiste) bleiben versteckt, solange das passende KeijinUI Element eingeschaltet ist, auch ohne Spieldaten, sodass nichts doppelt erscheint; sie kommen zurück, wenn das Element ausgeschaltet wird. Schaltet das Spiel eine Anzeige selbst wieder ein, wird sie beim nächsten Update erneut versteckt.
* 0.5.2: `/kachi debug` zeichnet Systemmeldungen auf (bleibt über Neustarts aktiv, letzte 60, `/kachi log`, `/kachi log clear`), um zu prüfen, ob Erfolgszeilen bei Addons ankommen. Erfolge werden zusätzlich in der allgemeinen Form `Text: [Name] (N ...)` erkannt, da kein deutscher Clienttext bekannt ist.
* 0.5.1: Standardlayout: Alle Elemente starten in der Anordnung des Autors (Neuinstallation und "Layout zurücksetzen"); der Standard wird nicht gespeichert, spätere Änderungen daran greifen also, gespeicherte Positionen haben Vorrang. Namensplaketten standardmäßig für Boss, Elite und Rare.
* 0.5.0: Spieler und Zielframes im Panelstil (eckiger Porträtkasten, Metall Lebensbalken, Titelleiste). Eckige Minimap im KeijinUI Stil mit Zoom per Mausrad, Layoutschlüssel `minimap` und Schalter in den Einstellungen. Geschätzte Heilungsaufschlüsselung (Lebensraub, Heilung pro Kill, Regeneration) im Tooltip der Heilungszeile.
* 0.4.2: Optionsfenster mit Tabs (Anzeige, Einheiten, Layout, Allgemein), Schalter als anklickbare Zeilen, der zuletzt gewählte Tab wird gemerkt. Die automatische Spracherkennung läuft jetzt immer mit: bei `/kui lang auto` gilt sofort wieder die erkannte Sprache, ohne Belege bleibt die gespeicherte Erkennung, die Mehrheit der bekannten Namen entscheidet.
* 0.4.1: Füllung und Hintergrund der Listenzeilen (Begegnungen, Schadensliste) bleiben innerhalb der runden Rahmenecken.
* 0.4.0: Zweisprachige Oberfläche (Deutsch oder Englisch), Erkennung und `/kui lang`, `/kui reload`, englische Argumente für `/kbb`, zweisprachige README.
* 0.3.7: Die Buildempfehlung nennt Fähigkeiten in der Sprache der Oberfläche, auch wenn das Zauberbuch englische Namen liefert.
* 0.3.6: Raster und Einrasten im Layoutmodus.
* 0.3.5: Buffs lassen sich linksbündig ausrichten.
* 0.3.4: Schadenszahlen liegen nie über Frames. Die Buildbewertung ordnet Meterwerte über Fähigkeitsschlüssel zu.
* 0.3.3: Statistikzeile "Heilung (effektiv)" und `/kui heal debug`.
* 0.3.2: Kürzere Statistik. 0.3.1: Begegnungen ohne UnitAffectingCombat. 0.3.0: Eigenes Chatfenster, Schadenszahlen in der Spielwelt, Debuffs am Ziel.
* 0.2.x: Aktionsleiste, Buildübersicht, Lebensbalken in Klassenfarbe, Namensplaketten.

## Dank

SurvivorsDragonUi und Survivor UI dienten als Inspiration und funktionale Vorbilder dafür, was eine Oberfläche für Azeroth Survivors zeigen kann. KeijinUI enthält keinen Code und keine Bilder daraus. Verbliebene Blizzard Texturen werden nur über ihren Clientpfad referenziert und nicht mitgeliefert.

## Prüfung

Die Integration wird mit Lua 5.1 und der extrahierten Spielschnittstelle geprüft (`py -3.12 development/keijinui/test_keijinui.py`). Diese Tests ersetzen keine Sichtprüfung im laufenden Spiel.
