# KeijinUI 2.1.0

Interface addon for Azeroth Survivors (WoW 1.12, Interface 11200). English first, German below.
Repository: https://github.com/KeijinDE/KeijinUI_modern-as-ui

Deutsche Fassung: siehe [Deutsch](#deutsch).

# English

## Overview

KeijinUI replaces the stock Azeroth Survivors interface with one consistent interface. Run overview below the minimap,
run statistics, damage meter and critical hits on the left, your own player and target frames
(round portrait and health bar joined into one shape), a square minimap, a symmetric action bar with ranks and
cooldowns (mana is not shown), a build overview, modern nameplates, damage numbers in the world, loot notice,
achievement popup and one chat window in the KeijinUI frame.

From 0.4.0 the whole interface is bilingual. English is the default; German is chosen by hand (settings window or
`/kui lang de`).

## Features

* Movable combat text: the floating damage numbers start in an invisible anchor that you move with Alt (Alt and mouse wheel change its size). Settings, Combat, Position: "At the enemy" (default, above the nameplate as before) or "Fixed spot" (all numbers start in the anchor).
* Boss damage: the damage meter has two tabs, Run and Boss. Boss shows the damage dealt to bosses in the last boss fight with total and DPS per source. Optional switch to Boss while a boss lives (Settings, Combat, off by default).
* Settings use a left navigation with six categories, explicit checkboxes and choice menus, a scrollable content area and previews. The optional cursor ring and selectable character attributes start off. Cursor size and color are configurable. Character attributes use current native values; missing values show a question mark. Optional Pace compares kill progress and recent DPS with your own matching runs; hover for the calculation. Existing settings, layouts, commands and native auto-run assignments stay intact.

* Settings, Controls: Normal / Thin / Off HUD headers, target debuffs in both places, area-hit merging, and a native auto-run key assignment (including mouse button 5). Existing layouts and other auto-run keys stay intact.

* Class resources below the player health bar: five red rogue combo points, five smaller purple warlock soul shards, a copper rage bar for warriors, and a golden Lightwell countdown bar for priests. Requires the learned proc ability and supported native power values. Defaults to attached to the player; Alt dragging or scaling detaches it. Units settings switch the display off or restore attachment.
* One original chamfered contour for rectangular panels, bars and icon frames. Player and target free ends use the same short diagonal; portraits and combo points stay round.

* Run overview with zone, run clock, progress bar and bosses with two time columns: boss time (active time since the boss appeared) and run time. Example: `3:23 | 0:23` means the boss died at 3:23 run time after 23 seconds. Stopped times turn green. Bosses that died before the interface loaded show question marks, because the game provides no past times of death. Below the bosses the guardian lairs of the map: asleep, fighting with health, or empty with the time until the next guardian comes; hover a row for the lair position. Switch it in Settings, Display, or with `/kui guardians on|off` (on by default).
* Run statistics: elites, guardians and bosses defeated, damage taken, effective healing, gold earned. A counter row below shows kills, gold, chest price, caches opened and the gold still missing for the next cache (green when affordable, yellow when at most a quarter of the price is missing, red otherwise).
* Damage meter and list of biggest critical hits. Every ability keeps one fixed color. Each meter row shows total damage and DPS over the same period as the summary (since run start, or since the last meter reset). Critical hits are read from the native combat messages and are collected from the moment the interface loads.
* Player and target frames: the round portrait and the health bar form one shape with a single outline, the health color reaches right up to the portrait edge. Name and level stand above the bar, current health points on the left and percent on the right inside the player bar; the target also mirrors the text layout, with percent and level on the left and health points and name on the right. Exact values are in the tooltip. The player bar loses health toward the portrait from the right, the mirrored target bar from the left. Class colored health bars (switchable to green and red). The target frame appears only with a target, marks elite (`+`) and rare (`R`) targets by the level text and the outline color, and shows the target's debuffs below it.
* Square minimap in the panel style (Settings, Display: "Minimap in KeijinUI style"). Zone name in gold at the top, mouse wheel zooms, movable like every other element, the run overview hangs below it. Turning the option off restores the original round minimap. The native round border, zoom buttons, toggle button, zone name and day/night indicator are hidden while the style is on; tracking, mail and battleground icons stay where they are.
* Caches on the minimap: a chest symbol for every cache waiting to be opened (caches closer than 10 yards share one symbol with a number), an arrow at the minimap border toward the nearest cache when it is out of sight, and an optional large screen arrow with distance and price (off by default, movable with Alt). The scale of the zone map is measured from the cache and lair positions the game reports; until it is measured nothing is drawn. Each part has its own switch (Settings, Units, Caches) and there is an optional chat notice for a new cache (off by default). `/kui caches debug` prints scale, minimap zoom, player map position and which source gives the facing direction; `/kui caches source auto|facing|model|move|north` forces a direction source for the screen arrow.
* Run overview (`/kui runs`, or Settings, General): per zone and per class and race the runs, wins, last time, fastest win and longest survival, one page per zone with arrows, rows in class color, the hero name in the tooltip, stored account wide and counted from the installation on. A chat line at the start of every run names the zone, the class and the number of the run (for example "This is your 4th run. Fastest win 15:42, longest survival 28:40."); switch it with `/kui runs msg` (on by default).
* Minimap button (left click: settings, right click: run overview, drag: move along the map edge, square or round to match the minimap style); switch it in Settings, General, or with `/kui button on|off` (on by default).
* The tooltip of the healing row shows an estimated gross breakdown (leech, heal per kill, regeneration, including overhealing), integrated with the value valid at each moment. The main number stays the effective healing.
* Action bar with six skills and the racial ability on the right, showing ranks and cooldowns only. Build overview below with all spells (rank badge) and jewelry, plus a build tip (`/kbb`).
* Encounter group at the top center for every living boss, elite or rare in a fight. Mouse wheel scrolls further rows.
* Nameplates with metal frames. Modes: all enemies, only boss, elite and rare, or off. Debuffs of the current target appear on the target plate.
* Damage numbers in the world, five styles: off; compact (normal hits small and white, critical hits large and yellow, rising straight up); scrolling (numbers rise, drift slightly and fall back a little at the end, alternating left and right, coloured by damage school, with the spell icon on the left, the main hand weapon for melee hits and no icon for unknown spells; normal hits are small, crits large, and normal hits under half of your running average are small and grey; crits and misses start with a short pop; the numbers follow the enemy nameplate; your own misses, dodges, parries, blocks, evades, immunes and resists are shown as text; periodic damage is smaller and fainter; the default); rising (like scrolling, but straight up without drift, a shorter way, smaller numbers and a slow fade, more compact); game (KeijinUI draws nothing, the game shows its own numbers).
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
* `/kui guardians on|off`: guardian lairs in the run overview.
* `/kui runs`: open or close the run overview. `/kui runs msg`: the start message on or off.
* `/kui button on|off`: the minimap button on or off (without argument: toggle).
* `/kui meter reset`: start the damage meter from now on (run statistics stay complete). `/kui crits reset`: clear observed critical hits.
* `/kui text`: switch the damage number style one step (off, compact, scrolling, rising, game). `/kui text off|compact|scroll|rise|game` sets it directly.
* `/kui text icons`: switches the spell icons next to the scrolling numbers on or off (also a row in the options, on by default).
* `/kui plates all|bosses|off`: nameplates on all enemies, only boss, elite and rare, or off. `/kui plates debug`: show what the client provides.
* `/kui bosses debug`, `/kui heal debug`: diagnostics in the chat.
* `/kui tooltip reset`: back to the normal tooltip position.
* `/kbb`: spells and jewelry on or off. `/kbb tips`: build tips on or off. `/kbb focus damage|boss|survival|balanced`: build focus (the German words `tipps`, `fokus schaden|boss|ueberleben|ausgewogen` work too).
* `/kachi test|move|lock|reset|on|off|sound`: achievement popup.

## Language

English is the default. `GetLocale()` returns a fixed value in this client and the game data can still be English after a language change in the game, so KeijinUI does not detect the language. Choose it in the settings window (General tab) or with `/kui lang de` and `/kui lang en`. `/kui lang` shows the current language. Changing the language reloads the interface, so that all texts are switched. Old settings with `auto` become English.

Ability names (recommendation title, tooltips, meter) follow the language: German names in German, English names otherwise. Names that come from the game itself (boss names, items, achievement names, chat) are not translated. The parser for combat messages works the same in every language.

## Data

Class resources read native active power rather than counting combat events. The reported Survivors encoding uses 20 absolute units per point or shard, with a native maximum of 100. Other ranges stay hidden. Rage accepts native maximum 100 or 1000 and shows progress to full. These adapters are covered by fixture tests; the packaged game value transitions still require confirmation. `/kui resources debug` prints current native inputs without saving them.

Run time, level, kills, elites, guardians, bosses, gold, cache count and damage totals come straight from the game interface. Pause and card choice use the stopped game time. Missing values show as question marks. The damage meter takes over all sources of the native meter, including talents and items. The native reset does not affect this interface. Frames you move yourself can overlap again.

## Changelog

All changes are listed in [CHANGELOG.md](CHANGELOG.md).

## Credits

SurvivorsDragonUi and Survivor UI served as inspiration and functional models for what an interface for Azeroth Survivors can show. KeijinUI contains no code or images from them. Remaining Blizzard textures are only referenced by their client path and are not shipped.

## Tests

The integration is checked with Lua 5.1 and the extracted game interface (`py -3.12 development/keijinui/test_keijinui.py`). These tests do not replace a visual check in the running game.

# Deutsch

## Überblick

KeijinUI ersetzt die Standardoberfläche von Azeroth Survivors durch eine einheitliche Oberfläche. Runübersicht unter der
Minimap, Runstatistiken, Schadensanzeige und kritische Treffer links, eigene Spieler und Zielframes
(rundes Porträt und Lebensbalken als eine gemeinsame Form), eine eckige Minimap, eine symmetrische
Aktionsleiste mit Rängen und Abklingzeiten (Mana wird nicht angezeigt), eine Buildübersicht, moderne Namensplaketten,
Schadenszahlen in der Spielwelt, Beutemeldung, Erfolgsmeldung und ein einzelnes Chatfenster im KeijinUI Rahmen.

Ab 0.4.0 ist die ganze Oberfläche zweisprachig. Englisch ist der Standard, Deutsch wählst du von Hand (Optionsfenster oder
`/kui lang de`).

## Funktionen

* Verschiebbarer Kampftext: Die Schadenszahlen starten in einem unsichtbaren Anker, den du mit Alt verschiebst (Alt und Mausrad ändern die Größe). Einstellungen, Kampf, Position: "Am Gegner" (Standard, wie bisher über der Namensplakette) oder "Feste Stelle" (alle Zahlen starten im Anker).
* Bossschaden: Die Schadensanzeige hat zwei Reiter, Run und Boss. Boss zeigt den Schaden am Boss im letzten Bosskampf mit Gesamtschaden und DPS je Quelle. Optional wechselt die Anzeige auf Boss, solange ein Boss lebt (Einstellungen, Kampf, standardmäßig aus).
* Einstellungen mit linker Navigation, sechs Kategorien, Checkboxen, Auswahlmenüs, scrollbarem Inhalt und Vorschauen. Optionaler Cursorring und auswählbare Charakterwerte starten ausgeschaltet. Größe und Farbe des Rings sind einstellbar. Charakterwerte stammen aus aktuellen nativen Daten; fehlende Werte erscheinen als Fragezeichen. Der optionale Pace Indikator vergleicht Gegnerfortschritt und aktuelle DPS mit passenden eigenen Runden; Details stehen im Tooltip. Bestehende Einstellungen, Layouts, Befehle und native Laufbelegungen bleiben erhalten.

* Klassenressourcen unter dem Spielerbalken: fünf rote Combopunkte beim Schurken, fünf kleinere violette Seelensplitter beim Hexenmeister eine kupferrote Wutleiste beim Krieger und ein goldener Lichtbrunnen Countdown beim Priester. Nur mit gelernter Fähigkeit und unterstützten nativen Werten. Folgt zunächst dem Spieler; Alt und Ziehen oder Skalieren löst die Bindung. Im Tab Einheiten abschaltbar und wieder anheftbar.
* Eigene gemeinsame Kontur mit kurzen Schrägen für rechteckige Panels, Leisten und Symbolrahmen. Auch die freien Enden der Spieler und Zielframes sind abgeschrägt. Porträts und Combopunkte bleiben rund.

* Runübersicht mit Zone, Runuhr, Fortschrittsbalken und Bossen mit zwei Zeitspalten: Bosszeit (aktive Zeit seit dem Erscheinen) und Runzeit. Beispiel: `3:23 | 0:23` bedeutet, dass der Boss bei 3:23 Runzeit nach 23 Sekunden besiegt wurde. Gestoppte Zeiten werden grün. Bosse, die vor dem Laden der Oberfläche besiegt wurden, zeigen Fragezeichen, weil die Spielschnittstelle keine vergangenen Todeszeitpunkte liefert.
* Runstatistiken: Eliten, Wächter und Bosse besiegt, Schaden erlitten, Heilung (effektiv), Gold verdient. Eine Zählerzeile darunter zeigt Kills, Gold, Cachepreis, geöffnete Caches und das noch fehlende Gold bis zum nächsten Cache (grün, wenn bezahlbar, gelb, wenn höchstens ein Viertel des Preises fehlt, sonst rot).
* Schadensanzeige und Liste der größten kritischen Treffer. Jede Fähigkeit behält eine feste Farbe. Jede Meterzeile zeigt Gesamtschaden und DPS über denselben Zeitraum wie die Gesamtrate (seit Runbeginn oder seit dem letzten Meterreset). Kritische Treffer werden aus den nativen Kampfnachrichten gelesen und ab dem Laden der Oberfläche gesammelt.
* Spieler und Zielframes: Rundes Porträt und Lebensbalken bilden eine gemeinsame Form mit einer Kontur, die Lebensfarbe reicht bis direkt an die Porträtkante. Name und Level stehen über dem Balken, aktuelle Lebenspunkte links und Prozent rechts im Spielerbalken. Der Zielrahmen spiegelt auch die Texte: Prozent und Level links, Lebenspunkte und Name rechts. Genaue Werte zeigt der Tooltip. Der Spielerbalken verliert Leben von rechts zum Porträt hin, der gespiegelte Zielbalken von links. Lebensbalken in Klassenfarbe (umschaltbar auf Grün und Rot). Der Zielframe erscheint nur mit Ziel, kennzeichnet Elite (`+`) und Rare (`R`) über den Leveltext und die Konturfarbe und zeigt die Debuffs des Ziels darunter.
* Eckige Minimap im Panelstil (Einstellungen, Anzeige: "Minimap im KeijinUI Stil"). Zonenname oben in Gold, Mausrad zoomt, verschiebbar wie jedes andere Element, die Runübersicht hängt darunter. Ausschalten stellt die ursprüngliche runde Minimap wieder her. Der native runde Rand, die Zoomknöpfe, der Ein/Aus Knopf, der Zonenname und die Tag/Nacht Anzeige sind bei eingeschaltetem Stil ausgeblendet; Symbole für Spurensuche, Post und Schlachtfeld bleiben an ihrem Platz.
* Caches auf der Minimap: ein Truhensymbol für jede Cache, die noch geöffnet werden kann (Caches unter 10 Yards Abstand teilen sich ein Symbol mit Zahl), ein Pfeil am Minimaprand zur nächsten Cache, wenn sie außer Sicht ist, und ein optionaler großer Bildschirmpfeil mit Entfernung und Preis (Standard aus, mit Alt verschiebbar). Der Maßstab der Zonenkarte wird aus den Positionen von Caches und Lairs gemessen, die das Spiel meldet; solange er nicht gemessen ist, wird nichts gezeichnet. Jeder Teil hat einen eigenen Schalter (Einstellungen, Einheiten, Caches), dazu eine optionale Chatmeldung bei einer neuen Cache (Standard aus). `/kui caches debug` zeigt Maßstab, Minimapzoom, Kartenposition des Spielers und die Quelle der Blickrichtung; `/kui caches source auto|facing|model|move|north` erzwingt eine Richtungsquelle für den Bildschirmpfeil.
* Rundenübersicht (`/kui runs` oder Einstellungen, Allgemein): je Zone und je Klasse und Volk Runs, Siege, letzte Zeit, schnellster Sieg und längstes Überleben, eine Seite pro Zone mit Pfeilen, Zeilen in Klassenfarbe, der Heldenname im Tooltip, kontoweit gespeichert und ab der Installation gezählt. Eine Chatzeile zu Beginn jedes Runs nennt Zone, Klasse und die Nummer des Runs (zum Beispiel "Das ist dein 4. Lauf. Schnellster Sieg 15:42, längstes Überleben 28:40."); schaltbar mit `/kui runs msg` (Standard an).
* Minimapknopf (Linksklick: Einstellungen, Rechtsklick: Rundenübersicht, Ziehen: am Kartenrand verschieben, quadratisch oder rund passend zum Minimapstil); schaltbar unter Einstellungen, Allgemein, oder mit `/kui button on|off` (Standard an).
* Der Tooltip der Heilungszeile zeigt eine geschätzte Brutto Aufschlüsselung (Lebensraub, Heilung pro Kill, Regeneration, inklusive Überheilung), fortgeschrieben mit dem jeweils gültigen Wert. Die Hauptzahl bleibt die effektive Heilung.
* Aktionsleiste mit sechs Skills und der Volksfähigkeit rechts, nur Ränge und Abklingzeiten. Darunter die Buildübersicht mit allen Spells (Rang als Badge) und Schmuck sowie ein Buildtipp (`/kbb`).
* Begegnungsgruppe oben mittig für jeden lebenden Boss, Elite oder Rare im Kampf. Das Mausrad blättert zu weiteren Zeilen.
* Namensplaketten mit Metallrahmen. Modi: alle Gegner, nur Boss, Elite und Rare, oder aus. Debuffs des aktuellen Ziels erscheinen an der Zielplakette.
* Schadenszahlen in der Spielwelt, fünf Stile: aus; kompakt (normale Treffer klein und weiß, kritische Treffer groß und gelb, steigen gerade auf); scrollend (Zahlen steigen nach oben, driften leicht und fallen am Ende etwas zurück, abwechselnd nach links und rechts, nach Zauberschule gefärbt, mit dem Zaubersymbol links, bei Nahkampftreffern mit der Waffe der Haupthand und ohne Symbol bei unbekannten Zaubern; normale Treffer klein, Krits groß, und normale Treffer unter der Hälfte deines gleitenden Durchschnitts klein und grau; Krits und Fehlschläge starten mit kurzem Pop; die Zahlen folgen der Namensplakette des Gegners; eigene Fehlschläge, Ausweichen, Parieren, Blocken, Entkommen, Immun und Widerstanden erscheinen als Text; periodischer Schaden kleiner und blasser; Standard); aufsteigend (wie scrollend, aber senkrecht ohne Drift, kürzerer Weg, kleinere Zahlen und langsames Ausblenden, kompakter); Spiel (KeijinUI zeichnet nichts, das Spiel zeigt seine eigenen Zahlen).
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
* `/kui runs`: Rundenübersicht öffnen oder schließen. `/kui runs msg`: Startmeldung ein oder aus.
* `/kui button on|off`: Minimapknopf ein oder aus (ohne Angabe: umschalten).
* `/kui meter reset`: Schadensanzeige ab jetzt neu beginnen (die Runstatistik bleibt vollständig). `/kui crits reset`: beobachtete kritische Treffer zurücksetzen.
* `/kui text`: schaltet den Stil der Schadenszahlen einen Schritt weiter (aus, kompakt, scrollend, aufsteigend, Spiel). `/kui text off|compact|scroll|rise|game` setzt ihn direkt.
* `/kui text icons`: schaltet die Zaubersymbole neben den scrollenden Zahlen an oder aus (auch eine Zeile in den Optionen, standardmäßig an).
* `/kui plates all|bosses|off`: Namensplaketten auf allen Gegnern, nur Boss, Elite und Rare, oder aus. `/kui plates debug`: zeigt, was der Client liefert.
* `/kui bosses debug`, `/kui heal debug`: Diagnose im Chat.
* `/kui tooltip reset`: zurück zur normalen Tooltip Position.
* `/kbb`: Zauber und Schmuckanzeige ein oder aus. `/kbb tipps`: Buildtipps ein oder aus. `/kbb fokus schaden|boss|ueberleben|ausgewogen`: Buildfokus (die englischen Wörter `tips`, `focus damage|boss|survival|balanced` gehen ebenfalls).
* `/kachi test|move|lock|reset|on|off|sound`: Erfolgsmeldung bedienen.

## Sprache

Englisch ist der Standard. `GetLocale()` liefert in diesem Client einen festen Wert, und die Spieldaten können nach einem Sprachwechsel im Spiel noch englisch sein, deshalb erkennt KeijinUI die Sprache nicht. Wähle sie im Optionsfenster (Tab Allgemein) oder mit `/kui lang de` und `/kui lang en`. `/kui lang` zeigt die aktuelle Sprache. Ein Sprachwechsel lädt die Oberfläche neu, damit alle Texte umgestellt sind. Alte Einstellungen mit `auto` werden zu Englisch.

Fähigkeitsnamen (Titel der Empfehlung, Tooltips, Meter) folgen der Sprache: deutsche Namen auf Deutsch, sonst englische. Namen aus dem Spiel selbst (Bossnamen, Gegenstände, Erfolgsnamen, Chat) werden nicht übersetzt. Der Parser für Kampfnachrichten arbeitet in jeder Sprache gleich.

## Daten

Klassenressourcen lesen die aktive native Ressource statt Kampfeignisse zu zählen. Die berichtete Survivors Zuordnung verwendet 20 absolute Einheiten pro Punkt oder Splitter bei einem nativen Maximum von 100. Andere Bereiche werden ausgeblendet. Wut unterstützt ein natives Maximum von 100 oder 1000 und zeigt den Fortschritt bis voll. Die Adapter sind mit Testdaten geprüft; die Wertübergänge im ausgelieferten Spiel müssen noch bestätigt werden. Der Lichtbrunnen Countdown stammt aus `AZS_SPELLS` (`cd`, `cdmax`) und läuft zwischen den Updates anhand der Laufzeit weiter. `/kui resources debug` gibt aktuelle native Eingaben aus (beim Priester zusätzlich cd, cdmax und Mana), ohne sie zu speichern.

Runzeit, Level, Kills, Eliten, Wächter, Bosse, Goldverdienst, Cacheanzahl und Schadenssummen kommen direkt aus der Spielschnittstelle. Pause und Kartenwahl verwenden die angehaltene Spielzeit. Fehlende Werte erscheinen als Fragezeichen. Die Schadensanzeige übernimmt alle Quellen des nativen Meters, einschließlich Talenten und Gegenständen. Der native Reset beeinflusst diese Schnittstelle nicht. Selbst verschobene Rahmen können wieder Überlappungen erzeugen.

## Änderungen

Alle Änderungen stehen in [CHANGELOG.md](CHANGELOG.md#deutsch).

## Dank

SurvivorsDragonUi und Survivor UI dienten als Inspiration und funktionale Vorbilder dafür, was eine Oberfläche für Azeroth Survivors zeigen kann. KeijinUI enthält keinen Code und keine Bilder daraus. Verbliebene Blizzard Texturen werden nur über ihren Clientpfad referenziert und nicht mitgeliefert.

## Prüfung

Die Integration wird mit Lua 5.1 und der extrahierten Spielschnittstelle geprüft (`py -3.12 development/keijinui/test_keijinui.py`). Diese Tests ersetzen keine Sichtprüfung im laufenden Spiel.

## Bedienung und Lesbarkeit

Im neuen Tab Bedienung lassen sich die Titel der vier HUD Anzeigen normal, schmal oder ausgeblendet darstellen. Debuffs erscheinen standardmaessig am Gegner und am Zielframe. Flächentreffer werden kurzzeitig als Summe mit Trefferzahl gebuendelt; die Option ist abschaltbar. Krits bleiben getrennt. Automatisches Laufen kann einer Taste oder Maustaste zugewiesen werden. Eine belegte Taste muss zweimal gedrueckt werden; Escape bricht ab. Die eigene Belegung kann entfernt werden, ohne die anderen nativen Lauftasten zu loeschen.
