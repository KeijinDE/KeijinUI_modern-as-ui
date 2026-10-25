# KeijinUI 4.2.0

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

English is the default. Every language of the game client can be chosen in General or with `/kui lang <code>`
(de, en, fr, es, pt, pl, cs, ro, tr, ru, uk, zh, ja, ko). Only English and German are checked by hand; all other languages are machine translated and not yet
reviewed by native speakers, please report mistakes. General, Font offers seven interface fonts with a preview and a language fallback, including Expressway. Chat and game tooltips keep their language fonts. Font origins and licenses are listed in `third_party/NOTICE.md`.

The Run meter shows live DPS over the last 10 run seconds; total damage and ordering remain run based.
Average DPS stays in the tooltip. The run overview includes endless boss countdowns and optional account pace.
Guardian return timers can be shown below minimap markers; the action bar can filter to active cooldowns.

## V3 settings and testing

The addon list and settings header identify this release as KeijinUI 3.0.0. The four categories remain. One Run displays section groups run overview, guardian rows, Pace, encounters, statistics, damage/crit panels, tally and lives/rerolls, XP/estimates, character values (own section) and section titles (under Size & Position). Layout & Display groups fonts with size/position, XP estimates and lives/rerolls under Run displays, native jewelry cooldowns (always on) with spells/items and the 30 percent marker with unit frames. Combat groups interval healing/incoming numbers with damage text and source details with the meter. Chat copy is a small button on the chat window; General groups compact messages with Runs, plus collection recording and optional modules. Existing saved options and positions remain.

Reload with `/kui reload`, then test boss/guardian debuffs, minimap skulls in all three states from run start (0.102 or newer), the framed XP bar, lives/rerolls extra row, character-value order, source tooltips, execute marker, interval text, jewelry tooltips/cooldowns, collection recording, the chat copy button and module shutdown/resume. XP estimates require three gains and ten run seconds. Optional presentation switches start off. World-map pins, historical boss comparisons, floating jewelry effects and numeric layout/profile tools remain removed. Holy Shock healing is still unresolved; `/kui heal` reports the native sources without inventing missing healing.

Section titles sit under Size & Position, character values have their own small section under Layout & Display, and native jewelry cooldowns are always on (no checkbox).

## Features

* V3 additions: optional XP/min and estimated time to the next level, using received native run time, with gaps and unknown level requirements kept unknown. The XP bar uses the shared bronze panel skin; optional XP rate and level estimates sit inside its progress track. Optional extra lives and rerolls share an extra row of the kills, gold and cache panel; rerolls show the remaining free count, then the next native price with G when the count reaches zero (for example 25 G); the exact price remains in the tooltip. The character attributes selection now has 29 native values, including echo, extra targets, pickup range, XP/gold, thorns, lives and situational bonuses; arrows reorder selected values.
* Damage taken has a native source breakdown on hover. Run meter tooltips show observed hit counts, normal average/min/max and critical rate since loading. Optional 30 percent markers preserve health colors. Optional healing/incoming text reports native total changes per packet, not individual hits, and stays off in native combat-text mode.
* Layout & Display offers mouse-based frame movement and resizing. The Modules page switches 14 modules on or off as a whole, and General holds the searchable jewelry diary. The diary records observed loot and equipped native tooltip values only (500 item variants, up to 12 native text variants per item); unseen items and unobserved ranges stay unknown. Jewelry supports native inventory cooldowns; full effects stay in the existing item-icon tooltips, without an additional floating text panel. Chat copy is a small button on the chat window; General groups compact run introductions with run history, without filtering diagnostics.
* Minimap skulls mark every lair (game version 0.102 or newer): gold while a guardian holds it, orange with ! in combat, grey with x while empty. The game's red guardian flag is hidden while they are on. All new gameplay presentation switches start off unless stated otherwise; inventory cooldowns and observation of actual finds start on. Existing personal settings and positions are preserved.

* Loot display: Settings, Layout & Display, Loot. "Notice" (default) is the 8 second message as before. "List" collects the items of the current run in the same panel, newest first, with symbol, name in quality color, slot and run time (8 rows, mouse wheel scrolls, tooltip per row). "Small list" is a compact line list (small symbol and name, 12 lines). "Icons only" shows symbols in a grid with a green check mark (new) or a red cross (already collected) and a tooltip. List shows "New" or "Collected" per line; small list uses the same check mark/cross as the icon grid and keeps the status text in the tooltip. Switches "Icons" and "Show collection status" hide the symbols and the status. "New loot only" (all four) shows items that are new to your collection, as the game's own loot line reports them (known items are marked "already collected"). "Growth: Upwards" puts the title at the bottom and the newest loot directly above it; the bottom edge stays fixed while the window grows, so it can be attached to the bottom edge of the screen. A reload keeps the list of the same run, a new run empties it. `/kui loot clear` and `/kui loot debug`.
* Movable combat text: the floating damage numbers start in an invisible anchor that you move with Alt (Alt and mouse wheel change its size). Settings, Combat, Position: "At the enemy" (default, above the nameplate as before) or "Fixed spot" (all numbers start in the anchor).
* Boss damage: the meter has three tabs: Run, Boss and Healing. Boss shows the damage dealt to bosses in the last boss fight with total and DPS per source. Optional switch to Boss while a boss lives (Settings, Combat, off by default). With this option enabled, Boss returns to Run after the last boss, even if Boss was selected manually during the fight. Healing stays selected. Turning the option off releases an automatic Boss view and permits a persistent manual Boss view.
* Settings use a left navigation with five categories, explicit checkboxes and choice menus, a scrollable content area and previews. The optional cursor ring and selectable character attributes start off. Cursor size and color are configurable. Character attributes use current native values; missing values show a question mark. Optional Pace compares kill progress and recent DPS with your own matching runs; hover for the calculation. Existing settings, layouts, commands and native auto-run assignments stay intact.

* Settings, Layout & Display: Normal / Thin / Off HUD headers and target debuffs in both places. Combat holds area-hit merging, Input aids the native auto-run key assignment (including mouse button 5). Existing layouts and other auto-run keys stay intact.

* Class resources below the player health bar: five red rogue combo points, five smaller purple warlock soul shards, a copper rage bar for warriors, and a golden Lightwell countdown bar for priests. Requires the learned proc ability and supported native power values. Defaults to attached to the player; Alt dragging or scaling detaches it. Layout & Display settings switch the display off or restore attachment.
* One original chamfered contour for rectangular panels, bars and icon frames. Player and target free ends use the same short diagonal; portraits and combo points stay round.

* Run overview with zone, run clock, progress bar and bosses with two time columns: boss time (active time since the boss appeared) and run time. Example in the displayed boss-time | run-time order: `0:23 | 3:23` means the boss died at 3:23 run time after 23 seconds. Stopped times turn green. Bosses that died before the interface loaded show question marks, because the game provides no past times of death. Below the bosses the guardian lairs of the map: asleep, fighting with health, or empty with the time until the next guardian comes; hover a row for the lair position. Switch it in Settings, Layout & Display, or with `/kui guardians on|off` (on by default).
* Run statistics: elites, guardians and bosses defeated, damage taken and gold earned. A counter row below shows kills, gold, chest price, caches opened and the gold still missing for the next cache (green when affordable, yellow when at most a quarter of the price is missing, red otherwise).
* Damage meter and list of biggest critical hits. Every ability keeps one fixed color. Each meter row shows total damage and DPS over the same period as the summary (since run start, or since the last meter reset). Critical hits are read from the native combat messages and are collected from the moment the interface loads.
* Player and target frames: the round portrait and the health bar form one shape with a single outline, the health color reaches right up to the portrait edge. Name and level stand above the bar, current health points on the left and percent on the right inside the player bar; the target also mirrors the text layout, with percent and level on the left and health points and name on the right. Exact values are in the tooltip. The player bar loses health toward the portrait from the right, the mirrored target bar from the left. Class colored health bars (switchable to green and red). The target frame appears only with a target, marks elite (`+`) and rare (`R`) targets by the level text and the outline color, and shows the target's debuffs below it.
* Unit frames without portrait: with "Show portraits" off, player and target use a compact closed frame (170 x 48, no portrait and no circle) with the same colours, marks and tooltip. It switches at once; sizes, positions and docking stay.
* Square minimap in the panel style (Settings, Layout & Display: "Minimap in KeijinUI style"). Zone name in gold at the top, mouse wheel zooms, movable like every other element, the run overview hangs below it. Turning the option off restores the original round minimap. The native round border, zoom buttons, toggle button, zone name and day/night indicator are hidden while the style is on; tracking, mail and battleground icons stay where they are.
* Caches on the minimap: a chest symbol for every cache waiting to be opened (caches closer than 10 yards share one symbol with a number), an arrow at the minimap border toward the nearest cache when it is out of sight, and an optional large screen arrow with distance and price (off by default, movable with Alt). The scale of the zone map is measured from the cache and lair positions the game reports; until it is measured nothing is drawn. Each part has its own switch (Settings, Layout & Display, Caches) and there is an optional chat notice for a new cache (off by default). `/kui caches debug` prints scale, minimap zoom, player map position and which source gives the facing direction; `/kui caches source auto|facing|model|move|north` forces a direction source for the screen arrow.
* Run overview (`/kui runs`, or Settings, General): per zone and per class and race the runs, wins, last time, fastest win and longest survival, one page per zone with arrows, rows in class color, the hero name in the tooltip, stored account wide and counted from the installation on. A chat line at the start of every run names the zone, the class and the number of the run (for example "This is your 4th run. Fastest win 15:42, longest survival 28:40."); switch it with `/kui runs msg` (on by default).
* Minimap button (left click: settings, right click: run overview, drag: move along the map edge, square or round to match the minimap style); switch it in Settings, Layout & Display, or with `/kui button on|off` (on by default).
* Healing is shown in the Healing meter tab. The run statistics panel has no duplicate healing row or health-gain/gross-healing estimates. The /kui heal diagnostic command and optional healing combat text remain.
* Action bar with six skills and the racial ability on the right, showing ranks and cooldowns only. Build overview below with all spells (rank badge) and jewelry, plus a build tip (`/kbb`).
* Encounter group at the top center for every living boss, elite or rare in a fight. Boss and guardian bars show native debuff icons, stacks and known remaining times, even without targeting the enemy. Up to eight icons per bar; hover +N for further effects. Unknown timing stays unknown and permanent effects have no countdown. Timers follow the run clock and stop during pauses and card choices. Mouse wheel scrolls further rows within the existing height limit. Older clients without the native getter keep their health bars.
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

* `/kui`: open the settings window with tabs (movable, remembers its position; it opens on Layout & Display).
* `/kui edit`: open or close layout editing. `/kui reset`: reset positions and sizes. `/kui grid`: grid and snapping on or off.
* `/kui lang <code>`: language. `/kui lang` shows the current language. `/kui reload`: reload the interface.
* `/kui guardians on|off`: guardian lairs in the run overview.
* `/kui runs`: open or close the run overview. `/kui runs msg`: the start message on or off.
* `/kui button on|off`: the minimap button on or off (without argument: toggle).
* `/kui meter reset`: start the damage meter from now on (run statistics stay complete). `/kui crits reset`: clear observed critical hits.
* `/kui text`: switch the damage number style one step (off, compact, scrolling, rising, game). `/kui text off|compact|scroll|rise|game` sets it directly.
* `/kui text icons`: switches the spell icons next to the scrolling numbers on or off (also a row in the options, on by default).
* `/kui plates all|bosses|off`: nameplates on all enemies, only boss, elite and rare, or off. `/kui plates debug`: show what the client provides.
* `/kui bosses debug`: boss diagnostics. `/kui heal` (also `/kui heal debug`): every native healing source with exact values and a Holy Shock presence check; missing data stays unknown.
* `/kui tooltip reset`: back to the normal tooltip position.
* `/kbb`: spells and jewelry on or off. `/kbb tips`: build tips on or off. `/kbb focus damage|boss|survival|balanced`: build focus (the German words `tipps`, `fokus schaden|boss|ueberleben|ausgewogen` work too).
* `/kachi test|move|lock|reset|on|off|sound`: achievement popup.

## Language

English is the default. `GetLocale()` returns a fixed value in this client and the game data can still be English after a language change in the game, so KeijinUI does not detect the language. Choose it in the settings window (General tab) or with `/kui lang <code>` (de, en, fr, es, pt, pl, cs, ro, tr, ru, uk, zh, ja, ko). `/kui lang` shows the current language. Changing the language updates KeijinUI labels; existing layout and options remain. Old settings with `auto` become English.

Ability names (recommendation title, tooltips, meter) follow the language and come from the game's own translations; where the game has none (Turkish), the English name stays. Names that come from the game itself (boss names, items, achievement names, chat) are not translated. The parser for combat messages works the same in every language.

## Data

Class resources read the game's own count first (`AZS_RUN.proc`, `pv`, `pm`, game 0.105 and later) and fall back to native active power; they never count combat events. The reported Survivors encoding uses 20 absolute units per point or shard, with a native maximum of 100. Other ranges stay hidden. Rage accepts native maximum 100 or 1000 and shows progress to full. These adapters are covered by fixture tests; the packaged game value transitions still require confirmation. `/kui resources debug` prints current native inputs and the game's proc fields without saving them.

Run time, level, kills, elites, guardians, bosses, gold, cache count and damage totals come straight from the game interface. Pause and card choice use the stopped game time. Missing values show as question marks. The damage meter takes over all sources of the native meter, including talents and items. The native reset does not affect this interface. Frames you move yourself can overlap again.

## Changelog

All changes are listed in [CHANGELOG.md](CHANGELOG.md).

## Credits

SurvivorsDragonUi and Survivor UI served as inspiration and functional models for what an interface for Azeroth Survivors can show. KeijinUI contains no code or images from them. Remaining Blizzard textures are only referenced by their client path and are not shipped.

## Tests

The integration is checked with Lua 5.1 and the extracted game interface (`py -3.12 development/keijinui/test_keijinui.py`). These tests do not replace a visual check in the running game.

## Navigation, stored levels and healing

Caches prefer the game's world coordinates and facing, including instances, with the measured fallback on older clients. Small arrows to the right of occupied guardian names lead to their fixed lairs and move with the run overview. On game version 0.102 or newer every lair gets a minimap skull from the first lair message, including empty lairs at run start: gold while a guardian holds it, orange with ! in combat, grey with x while empty, and the game's red guardian flag stays hidden while the skull option is on, even before lair data arrives. Its previous visible or hidden state is restored when the option or guardianNav module is off, when leaving the world, and at logout. Older clients keep their flag and only show a grey skull for defeated guardians. Hover a skull for status, return countdown and distance; click an occupied lair to select it for guidance. The outlined x and ! sit directly on the lower-right corner of the bronze rim, without a background. The native player arrow is raised above the markers. Check both in the actual game. Arrows and skulls are independent switches under Settings, Layout & Display.

The native Store Level-Ups option is under Settings, General. It is never changed on loading. A waiting choice appears on the movable Level up button above the action bar; click it while playing to open the choices. During pause/selection it is dimmed and does not send a request. Settings, General can restore the game's original button. Older clients without the required HUD/getter API retain their original button.

The Healing meter tab reads native effective healing sources and HPS, excluding overhealing. It keeps the same source colors and does not reset with the Run damage view. Boss auto-switching respects a manual Healing selection. Diagnostics: `/kui navigation debug`, `/kui levels debug`.

## Matching panel widths

The styled minimap now has the same 300-point base width as the run overview, with a 280-point square map surface. The user's saved minimap scale is preserved; the overview keeps its own scale. At equal personal scales the windows are equally wide. Adjust them normally with Alt and the mouse wheel. There is no separate size-matching setting. The run overview's height still follows its content.

## Attached windows

Drag a window's bottom edge onto another window's top edge with snapping enabled. The attachment is saved: a window above the chat grows upward as more rows arrive, and windows stacked above it follow. Dragging away releases it; hold Shift on release to avoid attaching. Older layouts store positions only, so dock the relevant windows once again after this update. Normal free placement remains unchanged.

## Searching settings

The search bar filters live across every category, including individual character attributes and optional modules. Results are the original working controls, not links. German and English labels, help text, choice values and common aliases are searched together regardless of UI language; for example player/Spieler, target/Ziel, damage/Schaden and cooldown/Abklingzeit. Multiple words narrow the results. The x button or Escape in the search field clears the query and returns to the previous page and scroll position. Switching categories also clears it. Search text is not saved.

# Deutsch

## Überblick

KeijinUI ersetzt die Standardoberfläche von Azeroth Survivors durch eine einheitliche Oberfläche. Runübersicht unter der
Minimap, Runstatistiken, Schadensanzeige und kritische Treffer links, eigene Spieler und Zielframes
(rundes Porträt und Lebensbalken als eine gemeinsame Form), eine eckige Minimap, eine symmetrische
Aktionsleiste mit Rängen und Abklingzeiten (Mana wird nicht angezeigt), eine Buildübersicht, moderne Namensplaketten,
Schadenszahlen in der Spielwelt, Beutemeldung, Erfolgsmeldung und ein einzelnes Chatfenster im KeijinUI Rahmen.

Englisch ist der Standard. Jede Sprache des Spielclients wählst du unter Allgemein oder mit `/kui lang <Code>`
(de, en, fr, es, pt, pl, cs, ro, tr, ru, uk, zh, ja, ko). Nur Englisch und Deutsch sind von Hand geprüft; alle anderen Sprachen sind maschinell übersetzt und noch
nicht muttersprachlich geprüft, Fehler bitte melden. Polnisch, Tschechisch, Rumänisch, Türkisch, Russisch,
Ukrainisch, Chinesisch, Japanisch und Koreanisch verwenden bei Bedarf die mitgelieferte Ersatzschrift. Unter Allgemein, Schrift stehen sieben UI Schriften einschließlich Expressway mit Vorschau zur Wahl. Chat und Spieltooltips behalten ihre sprachabhängige Schrift. Herkunft und Lizenzen stehen in `third_party/NOTICE.md`.

Der Reiter Run zeigt Live DPS der letzten 10 Spielsekunden. Gesamtschaden und Reihenfolge bleiben runbezogen,
der Durchschnitt steht im Tooltip. Die Runübersicht ergänzt Endlosbosstimer und optional Account Pace.
Rückkehrzeiten können unter den Minimapmarkern erscheinen, die Aktionsleiste kann nur laufende Abklingzeiten zeigen.

## V3 Einstellungen und Test

Addonliste und Einstellungskopf zeigen KeijinUI 3.0.0. Alle Runanzeigen stehen zusammen unter Layout & Anzeige → Runanzeigen: Runübersicht/Wächter/Pace, Begegnungen, Statistiken, Schaden/Krit, Kills/Gold/Cache mit Leben/Rerolls, EP mit Schätzung, Charakterwerte (eigener Abschnitt). Die vier Kategorien bleiben: Layout & Anzeige enthält EP Schätzung und Leben/Rerolls bei Runanzeigen, native Schmuckcooldowns (immer aktiv) und die 30 Prozent Markierung bei Einheitenrahmen. Kampf ordnet zusätzliche Heilzahlen/eingehende Zahlen den Schadenszahlen zu und Quellenhinweise der Schadensanzeige. Chat kopieren liegt als kleiner Knopf am Chatfenster. Allgemein gruppiert kompakte Meldungen bei Runs sowie Schmucksammlung und optionale Module. Bestehende Einstellungen und Positionen bleiben erhalten.

Nach `/kui reload` prüfen: Boss/Wächter Debuffs, Totenköpfe in allen drei Zuständen ab Runbeginn (ab 0.102), EP Fenster, zweite Reihe für Leben/Rerolls, Reihenfolge der Charakterwerte, Quellentooltips, Execute Markierung, zusätzlichen Kampftext, Schmucktooltips/Cooldowns, Sammlungsaufzeichnung, Chatkopie, Schriften und Module aus/ein. Die EP Schätzung benötigt drei Zuwächse und zehn Runsekunden. Neue optionale Anzeigen sind zunächst ausgeschaltet. Weltkartenpins, historische Bossvergleiche, freie Schmucktexte und Zahlenfelder/Layoutprofile bleiben entfernt. Holy Shock Heilung bleibt ungeklärt; `/kui heal` nennt die tatsächlichen nativen Quellen.

Abschnittstitel stehen unter Größe & Position, Charakterwerte haben einen eigenen kleinen Abschnitt unter Layout & Anzeige, native Schmuckcooldowns sind immer aktiv (ohne Schalter).

## Funktionen

* Der EP Balken nutzt denselben Bronzerahmen wie die anderen Fenster. Die optionale XP Rate und Levelschätzung stehen innerhalb der Fortschrittsleiste.

* Zusatzleben und Rerolls stehen optional in einer zweiten Reihe der gemeinsamen Anzeige für Kills, Gold und Caches. Rerolls zeigen zunächst die freie Anzahl und bei null freien Rerolls den nächsten nativen Preis mit G (zum Beispiel 25 G). Der exakte Preis steht im Tooltip; ein unbekannter Preis erscheint als Fragezeichen. Die gemeinsame Anzeige wächst nach oben und wird als ein Rahmen verschoben.

* Beuteanzeige: Einstellungen, Layout & Anzeige, Beute. "Meldung" (Standard) ist die 8 Sekunden Meldung wie bisher. "Liste" sammelt die Gegenstände des laufenden Runs im selben Panel, neueste oben, mit Symbol, Name in Qualitätsfarbe, Platz und Runzeit (8 Zeilen, Mausrad blättert, Tooltip je Zeile). "Liste klein" ist eine kompakte Zeilenliste (kleines Symbol und Name, 12 Zeilen). "Nur Symbole" zeigt Symbole in einem Raster mit grünem Haken (neu) oder rotem X (bereits gesammelt) und Tooltip. Liste zeigt je Zeile "Neu" oder "Gesammelt"; Liste klein verwendet dieselben Haken/X Symbole wie das Symbolraster und behält den Statustext im Tooltip. Die Schalter "Symbole" und "Sammelstatus anzeigen" blenden Symbole und Status aus. "Nur neuer Loot" (für alle vier) zeigt Gegenstände, die neu in deiner Sammlung sind, so wie die Beutezeile des Spiels es meldet (bekannte sind mit "bereits gesammelt" gekennzeichnet). "Wachstum: Nach oben" setzt den Titel nach unten und die neueste Beute direkt darüber; der untere Rand bleibt beim Wachsen fest, das Fenster lässt sich also am unteren Bildschirmrand anheften. Ein Neuladen behält die Liste desselben Runs, ein neuer Run leert sie. `/kui loot clear` und `/kui loot debug`.
* Verschiebbarer Kampftext: Die Schadenszahlen starten in einem unsichtbaren Anker, den du mit Alt verschiebst (Alt und Mausrad ändern die Größe). Einstellungen, Kampf, Position: "Am Gegner" (Standard, wie bisher über der Namensplakette) oder "Feste Stelle" (alle Zahlen starten im Anker).
* Bossschaden: Die Schadensanzeige hat zwei Reiter, Run und Boss. Boss zeigt den Schaden am Boss im letzten Bosskampf mit Gesamtschaden und DPS je Quelle. Optional wechselt die Anzeige auf Boss, solange ein Boss lebt (Einstellungen, Kampf, standardmäßig aus). Bei aktiver Automatik kehrt die Bossansicht nach dem letzten Boss zu Run zurück, auch nach einer manuellen Bosswahl im Kampf. Heilung bleibt ausgewählt. Ausschalten löst die automatische Bossansicht; eine manuelle Bossansicht kann dann dauerhaft bleiben.
* Einstellungen mit linker Navigation, fünf Kategorien, Checkboxen, Auswahlmenüs, scrollbarem Inhalt und Vorschauen. Optionaler Cursorring und auswählbare Charakterwerte starten ausgeschaltet. Größe und Farbe des Rings sind einstellbar. Charakterwerte stammen aus aktuellen nativen Daten; fehlende Werte erscheinen als Fragezeichen. Der optionale Pace Indikator vergleicht Gegnerfortschritt und aktuelle DPS mit passenden eigenen Runden; Details stehen im Tooltip. Bestehende Einstellungen, Layouts, Befehle und native Laufbelegungen bleiben erhalten.

* Klassenressourcen unter dem Spielerbalken: fünf rote Combopunkte beim Schurken, fünf kleinere violette Seelensplitter beim Hexenmeister eine kupferrote Wutleiste beim Krieger und ein goldener Lichtbrunnen Countdown beim Priester. Nur mit gelernter Fähigkeit und unterstützten nativen Werten. Folgt zunächst dem Spieler; Alt und Ziehen oder Skalieren löst die Bindung. Im Tab Layout & Anzeige abschaltbar und wieder anheftbar.
* Eigene gemeinsame Kontur mit kurzen Schrägen für rechteckige Panels, Leisten und Symbolrahmen. Auch die freien Enden der Spieler und Zielframes sind abgeschrägt. Porträts und Combopunkte bleiben rund.

* Runübersicht mit Zone, Runuhr, Fortschrittsbalken und Bossen mit zwei Zeitspalten: Bosszeit (aktive Zeit seit dem Erscheinen) und Runzeit. Beispiel: `0:23 | 3:23` bedeutet, dass der Boss bei 3:23 Runzeit nach 23 Sekunden besiegt wurde. Gestoppte Zeiten werden grün. Bosse, die vor dem Laden der Oberfläche besiegt wurden, zeigen Fragezeichen, weil die Spielschnittstelle keine vergangenen Todeszeitpunkte liefert.
* Runstatistiken: Eliten, Wächter und Bosse besiegt, Schaden erlitten und Gold verdient. Eine Zählerzeile darunter zeigt Kills, Gold, Cachepreis, geöffnete Caches und das noch fehlende Gold bis zum nächsten Cache (grün, wenn bezahlbar, gelb, wenn höchstens ein Viertel des Preises fehlt, sonst rot).
* Schadensanzeige und Liste der größten kritischen Treffer. Jede Fähigkeit behält eine feste Farbe. Jede Meterzeile zeigt Gesamtschaden und DPS über denselben Zeitraum wie die Gesamtrate (seit Runbeginn oder seit dem letzten Meterreset). Kritische Treffer werden aus den nativen Kampfnachrichten gelesen und ab dem Laden der Oberfläche gesammelt.
* Spieler und Zielframes: Rundes Porträt und Lebensbalken bilden eine gemeinsame Form mit einer Kontur, die Lebensfarbe reicht bis direkt an die Porträtkante. Name und Level stehen über dem Balken, aktuelle Lebenspunkte links und Prozent rechts im Spielerbalken. Der Zielrahmen spiegelt auch die Texte: Prozent und Level links, Lebenspunkte und Name rechts. Genaue Werte zeigt der Tooltip. Der Spielerbalken verliert Leben von rechts zum Porträt hin, der gespiegelte Zielbalken von links. Lebensbalken in Klassenfarbe (umschaltbar auf Grün und Rot). Der Zielframe erscheint nur mit Ziel, kennzeichnet Elite (`+`) und Rare (`R`) über den Leveltext und die Konturfarbe und zeigt die Debuffs des Ziels darunter.
* Einheitenrahmen ohne Porträt: Ist "Porträts anzeigen" aus, nutzen Spieler und Ziel einen kompakten geschlossenen Rahmen (170 x 48, ohne Porträt und Kreis) mit denselben Farben, Kennzeichen und Tooltips. Das Umschalten wirkt sofort; Größen, Positionen und Andocken bleiben erhalten.
* Eckige Minimap im Panelstil (Einstellungen, Layout & Anzeige: "Minimap im KeijinUI Stil"). Zonenname oben in Gold, Mausrad zoomt, verschiebbar wie jedes andere Element, die Runübersicht hängt darunter. Ausschalten stellt die ursprüngliche runde Minimap wieder her. Der native runde Rand, die Zoomknöpfe, der Ein/Aus Knopf, der Zonenname und die Tag/Nacht Anzeige sind bei eingeschaltetem Stil ausgeblendet; Symbole für Spurensuche, Post und Schlachtfeld bleiben an ihrem Platz.
* Caches auf der Minimap: ein Truhensymbol für jede Cache, die noch geöffnet werden kann (Caches unter 10 Yards Abstand teilen sich ein Symbol mit Zahl), ein Pfeil am Minimaprand zur nächsten Cache, wenn sie außer Sicht ist, und ein optionaler großer Bildschirmpfeil mit Entfernung und Preis (Standard aus, mit Alt verschiebbar). Der Maßstab der Zonenkarte wird aus den Positionen von Caches und Lairs gemessen, die das Spiel meldet; solange er nicht gemessen ist, wird nichts gezeichnet. Jeder Teil hat einen eigenen Schalter (Einstellungen, Layout & Anzeige, Caches), dazu eine optionale Chatmeldung bei einer neuen Cache (Standard aus). `/kui caches debug` zeigt Maßstab, Minimapzoom, Kartenposition des Spielers und die Quelle der Blickrichtung; `/kui caches source auto|facing|model|move|north` erzwingt eine Richtungsquelle für den Bildschirmpfeil.
* Rundenübersicht (`/kui runs` oder Einstellungen, Allgemein): je Zone und je Klasse und Volk Runs, Siege, letzte Zeit, schnellster Sieg und längstes Überleben, eine Seite pro Zone mit Pfeilen, Zeilen in Klassenfarbe, der Heldenname im Tooltip, kontoweit gespeichert und ab der Installation gezählt. Eine Chatzeile zu Beginn jedes Runs nennt Zone, Klasse und die Nummer des Runs (zum Beispiel "Das ist dein 4. Lauf. Schnellster Sieg 15:42, längstes Überleben 28:40."); schaltbar mit `/kui runs msg` (Standard an).
* Minimapknopf (Linksklick: Einstellungen, Rechtsklick: Rundenübersicht, Ziehen: am Kartenrand verschieben, quadratisch oder rund passend zum Minimapstil); schaltbar unter Einstellungen, Layout & Anzeige, oder mit `/kui button on|off` (Standard an).
* Die Heilungszeile verwendet dieselbe native effektive Summe wie der Heilungsreiter. Im Tooltip stehen HPS und die stärksten Heilungsquellen mit Anteilen, ohne Überheilung. Nur ältere Clients ohne API zeigen ausdrücklich beobachtete Lebenszuwächse seit Laden und geschätzte Bruttoquellen; das ist keine vollständige Runsumme.
* Aktionsleiste mit sechs Skills und der Volksfähigkeit rechts, nur Ränge und Abklingzeiten. Darunter die Buildübersicht mit allen Spells (Rang als Badge) und Schmuck sowie ein Buildtipp (`/kbb`).
* Begegnungsgruppe oben mittig für jeden lebenden Boss, Elite oder Rare im Kampf. Boss und Wächter zeigen native Debuffs mit Symbolen, Stapeln und bekannten Restzeiten, auch ohne ausgewähltes Ziel. Acht Symbole pro Balken; weitere Effekte stehen beim Darüberfahren über +N im Tooltip. Unbekannte Zeiten bleiben unbekannt und dauerhafte Effekte haben keinen Countdown. Zeiten folgen der Runzeit und stehen bei Pausen und Kartenauswahl still. Die Gruppe bleibt in ihrer Höhenbegrenzung und mit dem Mausrad scrollbar. Ältere Clients ohne native Schnittstelle behalten ihre Lebensbalken.
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
* `/kui lang <Code>`: Sprache. `/kui lang` zeigt die aktuelle Sprache. `/kui reload`: Oberfläche neu laden.
* `/kui runs`: Rundenübersicht öffnen oder schließen. `/kui runs msg`: Startmeldung ein oder aus.
* `/kui button on|off`: Minimapknopf ein oder aus (ohne Angabe: umschalten).
* `/kui meter reset`: Schadensanzeige ab jetzt neu beginnen (die Runstatistik bleibt vollständig). `/kui crits reset`: beobachtete kritische Treffer zurücksetzen.
* `/kui text`: schaltet den Stil der Schadenszahlen einen Schritt weiter (aus, kompakt, scrollend, aufsteigend, Spiel). `/kui text off|compact|scroll|rise|game` setzt ihn direkt.
* `/kui text icons`: schaltet die Zaubersymbole neben den scrollenden Zahlen an oder aus (auch eine Zeile in den Optionen, standardmäßig an).
* `/kui plates all|bosses|off`: Namensplaketten auf allen Gegnern, nur Boss, Elite und Rare, oder aus. `/kui plates debug`: zeigt, was der Client liefert.
* `/kui bosses debug`: Bossdiagnose. `/kui heal` (auch `/kui heal debug`): jede native Heilquelle mit genauen Werten und Holy Shock Prüfung; fehlende Daten bleiben unbekannt.
* `/kui tooltip reset`: zurück zur normalen Tooltip Position.
* `/kbb`: Zauber und Schmuckanzeige ein oder aus. `/kbb tipps`: Buildtipps ein oder aus. `/kbb fokus schaden|boss|ueberleben|ausgewogen`: Buildfokus (die englischen Wörter `tips`, `focus damage|boss|survival|balanced` gehen ebenfalls).
* `/kachi test|move|lock|reset|on|off|sound`: Erfolgsmeldung bedienen.

## Sprache

Englisch ist der Standard. `GetLocale()` liefert in diesem Client einen festen Wert, und die Spieldaten können nach einem Sprachwechsel im Spiel noch englisch sein, deshalb erkennt KeijinUI die Sprache nicht. Wähle sie im Optionsfenster (Tab Allgemein) oder mit `/kui lang <Code>` (de, en, fr, es, pt, pl, cs, ro, tr, ru, uk, zh, ja, ko). `/kui lang` zeigt die aktuelle Sprache. Ein Sprachwechsel lädt die Oberfläche neu, damit alle Texte umgestellt sind. Alte Einstellungen mit `auto` werden zu Englisch.

Fähigkeitsnamen (Titel der Empfehlung, Tooltips, Meter) folgen der Sprache und stammen aus den Übersetzungen des Spiels; wo das Spiel keine hat (Türkisch), bleibt der englische Name. Namen aus dem Spiel selbst (Bossnamen, Gegenstände, Erfolgsnamen, Chat) werden nicht übersetzt. Der Parser für Kampfnachrichten arbeitet in jeder Sprache gleich.

## Daten

Klassenressourcen lesen zuerst den Wert des Spiels (`AZS_RUN.proc`, `pv`, `pm`, ab Spiel 0.105) und sonst die aktive native Ressource; Kampfeignisse werden nie gezählt. Die berichtete Survivors Zuordnung verwendet 20 absolute Einheiten pro Punkt oder Splitter bei einem nativen Maximum von 100. Andere Bereiche werden ausgeblendet. Wut unterstützt ein natives Maximum von 100 oder 1000 und zeigt den Fortschritt bis voll. Die Adapter sind mit Testdaten geprüft; die Wertübergänge im ausgelieferten Spiel müssen noch bestätigt werden. Der Lichtbrunnen Countdown stammt aus `AZS_SPELLS` (`cd`, `cdmax`) und läuft zwischen den Updates anhand der Laufzeit weiter. `/kui resources debug` gibt aktuelle native Eingaben und die Procfelder des Spiels aus (beim Priester zusätzlich cd, cdmax und Mana), ohne sie zu speichern.

Runzeit, Level, Kills, Eliten, Wächter, Bosse, Goldverdienst, Cacheanzahl und Schadenssummen kommen direkt aus der Spielschnittstelle. Pause und Kartenwahl verwenden die angehaltene Spielzeit. Fehlende Werte erscheinen als Fragezeichen. Die Schadensanzeige übernimmt alle Quellen des nativen Meters, einschließlich Talenten und Gegenständen. Der native Reset beeinflusst diese Schnittstelle nicht. Selbst verschobene Rahmen können wieder Überlappungen erzeugen.

## Änderungen

Alle Änderungen stehen in [CHANGELOG.md](CHANGELOG.md#deutsch).

## Dank

SurvivorsDragonUi und Survivor UI dienten als Inspiration und funktionale Vorbilder dafür, was eine Oberfläche für Azeroth Survivors zeigen kann. KeijinUI enthält keinen Code und keine Bilder daraus. Verbliebene Blizzard Texturen werden nur über ihren Clientpfad referenziert und nicht mitgeliefert.

## Prüfung

Die Integration wird mit Lua 5.1 und der extrahierten Spielschnittstelle geprüft (`py -3.12 development/keijinui/test_keijinui.py`). Diese Tests ersetzen keine Sichtprüfung im laufenden Spiel.

## Bedienung und Lesbarkeit

Unter Layout & Anzeige lassen sich die Titel der HUD Anzeigen (Runübersicht, Statistik, Schaden, Krits, Beute) normal, schmal oder ausgeblendet darstellen. Debuffs erscheinen standardmaessig am Gegner und am Zielframe. Unter Kampf werden Flächentreffer kurzzeitig als Summe mit Trefferzahl gebuendelt; die Option ist abschaltbar. Krits bleiben getrennt. Automatisches Laufen kann einer Taste oder Maustaste zugewiesen werden. Eine belegte Taste muss zweimal gedrueckt werden; Escape bricht ab. Die eigene Belegung kann entfernt werden, ohne die anderen nativen Lauftasten zu loeschen.


## Navigation, gespeicherte Level und Heilung

Caches verwenden Weltposition und Blickrichtung, auch in Instanzen; ältere Clients behalten den vermessenen Ersatz. Kleine Pfeile rechts neben belegten Wächternamen zeigen zum festen Hort und folgen der Runübersicht. Ab Spielversion 0.102 bekommt jeder Hort ab der ersten Hortnachricht einen Totenkopf auf der Minimap, auch bei anfangs leeren Horten: gold, solange ein Wächter ihn hält, orange mit ! im Kampf, grau mit x bei leerem Hort. Die rote Wächterflagge des Spiels bleibt bei eingeschalteter Totenkopfoption ausgeblendet, auch bevor Hortdaten ankommen. Ihr vorheriger sichtbarer oder ausgeblendeter Zustand kehrt zurück, wenn die Option oder das Modul guardianNav aus ist, beim Verlassen der Welt und beim Ausloggen. Ältere Clients behalten ihre Flagge und zeigen nur bei besiegten Wächtern einen grauen Totenkopf. Status, Rückkehrzeit und Entfernung stehen im Tooltip; ein Klick auf einen belegten Hort wählt ihn für den Wegweiser. Das x und ! mit Kontur sitzen ohne eigenen Hintergrund direkt an der unteren rechten Ecke des Bronzerands. Der native Spielerpfeil wird über die Markierungen angehoben. Beides im echten Spiel prüfen. Pfeile und Totenköpfe sind unter Einstellungen, Layout & Anzeige getrennt schaltbar.

Die Spieloption zum Speichern von Levelaufstiegen steht unter Einstellungen, Allgemein und wird beim Laden nicht verändert. Der verschiebbare Levelaufstieg Button über der Aktionsleiste zeigt wartende Auswahlen. Im laufenden Spiel öffnet ein Klick die Auswahl. Während Pause/Auswahl ist der Button gedimmt und sendet keine Anfrage. Einstellungen, Allgemein stellt bei Bedarf den ursprünglichen Spielbutton wieder her. Ohne passende HUD und Getter Schnittstelle bleibt die native Anzeige erhalten.

Der Reiter Heilung verwendet native effektive Heilung je Quelle und HPS ohne Überheilung. Quellenfarben bleiben gleich, Reset der Run Schadensansicht verändert diese Werte nicht. Die Bossautomatik respektiert eine selbst gewählte Heilungsansicht. Diagnose: `/kui navigation debug`, `/kui levels debug`.

## UI Größe

Unter Einstellungen, Layout & Anzeige stehen zwei Prozentregler: Menügröße (70 bis 100%) und Gesamte UI (64 bis 150%). Gesamte UI verwendet die native Spieloption uiScale und gilt auch für Spielfenster. Der Prozentwert wird beim Ziehen angezeigt und beim Loslassen übernommen. Einzelne Rahmengrößen mit Alt und Mausrad bleiben erhalten. UI Größen zurücksetzen stellt 80% Menügröße und 90% Gesamtgröße wieder her.

## Abschnitte in den Einstellungen

Der aktive Tab klappt links seine Abschnittstitel als kleinere Sprunglinks auf. Ein Klick zeigt den Abschnitt rechts. Beim Scrollen folgt die Hervorhebung der aktuellen Position. Beim Tabwechsel wird die vorherige Unterliste eingeklappt.

## Settings organization / Aufbau der Einstellungen

Since 3.4.0 the settings separate **core** from **modules**. Core settings are always shown: Size & Position, Frames (run overview, encounters, statistics, damage meter, critical hits, kills and gold, experience, Spells & jewelry and Action bar as two separate windows), Unit frames (with class resources and the 30 percent marker), the damage meter option on the Combat page, run history, language and the interface reset. The Modules page (own entry in the sidebar) switches 14 modules on or off as a whole: Combat text, Nameplates, Minimap, Caches, Guardians, Run analysis, Character attributes, Loot, Jewelry collection, Build tips, Stored levels, Achievement alerts, Summons and Input aids (cursor tracker and auto run key). Every module has a short description of what it does and what you get when it is off. A module that is off has no scripts and no events, its settings disappear from every page, from the sidebar links and from the search (the search then finds the module switch instead), and the game's own version returns where there is one (combat text, nameplates, minimap, guardian flag, loot notice, level choice). All modules are on by default; settings you stored are never reset. Modules that were off in 3.3.0 stay off. Switching acts at once; for the minimap a reload is advisable if something stays behind, the module page offers a button for it. `/kui` always works, also with the minimap module off.

Layout & Display now holds sizes and positions, Frames, unit frames, and the sections of the modules Character attributes, Loot, Nameplates, Minimap, Caches, Guardians and Run analysis. Combat keeps the combat text module and the damage meter option, Input aids the cursor and the auto run key, General language, stored levels, run history, jewelry collection, achievement preview and the interface reset. The section links stay directly accessible in the sidebar.

Seit 3.4.0 trennen die Einstellungen **Core** und **Module**. Core ist immer sichtbar: Größe & Position, Fenster (Runübersicht, Begegnungen, Statistiken, Schadensanzeige, Kritische Treffer, Kills und Gold, Erfahrung, dazu Zauber & Schmuck und Aktionsleiste als zwei getrennte Fenster), Einheitenrahmen (mit Klassenressourcen und 30 Prozent Markierung), die Schadensanzeige Option auf der Seite Kampf, Rundenhistorie, Sprache und Oberfläche. Die Seite Module (eigener Eintrag in der Seitenleiste) schaltet 14 Module als Ganzes: Kampftext, Namensplaketten, Minimap, Caches, Wächter, Run-Analyse, Charakterwerte, Beute, Schmucksammlung, Buildtipps, Gespeicherte Level, Erfolgsmeldungen, Beschwörungen und Eingabehilfen (Cursortracker und Taste für Automatisch laufen). Jedes Modul hat eine kurze Beschreibung, was es tut und was beim Ausschalten erscheint. Ein ausgeschaltetes Modul hat keine Skripte und keine Ereignisse, seine Einstellungen verschwinden von allen Seiten, aus den Sprunglinks und aus der Suche (die Suche findet dann den Modulschalter), und wo das Spiel etwas Eigenes hat, kommt es zurück (Kampftext, Namensplaketten, Minimap, Wächterflagge, Beutemeldung, Levelauswahl). Alle Module sind standardmäßig an; gespeicherte Einstellungen werden nie zurückgesetzt. In 3.3.0 ausgeschaltete Module bleiben aus. Das Umschalten wirkt sofort; bei der Minimap ist ein Neuladen ratsam, falls etwas hängen bleibt, die Modulseite bietet dafür einen Knopf. `/kui` funktioniert immer, auch bei ausgeschalteter Minimap.

Layout & Anzeige enthält Größen und Positionen, Fenster, Einheitenrahmen und die Abschnitte der Module Charakterwerte, Beute, Namensplaketten, Minimap, Caches, Wächter und Run-Analyse. Kampf behält das Modul Kampftext und die Schadensanzeige Option, Eingabehilfen den Cursor und die Laufbelegung, Allgemein Sprache, gespeicherte Level, Rundenhistorie, Schmucksammlung, Erfolgsvorschau und Oberfläche. Kleine Abschnittslinks bleiben links direkt erreichbar.

Compact loot lists and icon grids use their actual width before restoring and clamping the saved position, including after late saved-variable loading. This prevents repeated leftward movement at the right screen edge. A position already shifted and saved by an older version must be moved back once.

Kleine Lootlisten und Symbolraster verwenden vor dem Wiederherstellen und Begrenzen der Position bereits ihre tatsächliche Breite, auch wenn Spielerdaten erst nach den Addondateien geladen werden. Dadurch wandern sie am rechten Bildschirmrand nicht weiter nach links. Eine von einer älteren Version bereits verschobene und gespeicherte Position muss einmal zurückgezogen werden.

In Fixed position only, ordinary floating hits now fade early, last about 0.55 to 0.65 seconds and travel a shorter distance. Critical hits retain their longer 1.3 to 1.8 seconds depending on style. Consecutive Rising hits have a bounded starting offset, preventing tall stacks. The settings preview uses the same fade curve.

Nur bei Feste Stelle blenden normale Schadenszahlen früh aus, bleiben etwa 0,55 bis 0,65 Sekunden und bewegen sich kürzer. Kritische Treffer behalten je nach Stil ihre längere Dauer von 1,3 bis 1,8 Sekunden. Schnell aufeinanderfolgende aufsteigende Treffer haben einen begrenzten Startversatz, damit keine hohen Zahlenstapel entstehen. Die Vorschau verwendet dieselbe Ausblendung.

Nameplate mode keeps its original timing, movement and stacking, also when no nameplate is visible and it falls back to the anchor.
Der Modus Am Gegner behält Dauer, Bewegung und Stapelverhalten, auch wenn ohne sichtbare Namensplakette der Kampftextanker als Ersatz verwendet wird.

## Gleiche Fensterbreite

All movable KeijinUI HUD housings share a 300-point base width. This includes the minimap, overview, encounters, statistics, damage/healing, critical hits, attributes, chat, every loot mode, player/target, action/build bars, counters, XP, class resources, stored levels and achievements. Buff and tooltip placement anchors also use 300 points. Actual tooltips size to their contents; larger settings, history, collection and copy dialogs keep their required widths. Personal scale settings stay intact. At the same effective scale the HUD housings have the same visible width; responsive combat scaling can still reduce player/target, action and resource frames on smaller viewports. Alt and mouse wheel adjust each frame as before.

Alle verschiebbaren KeijinUI HUD Fenster haben 300 Punkte Grundbreite. Das gilt für Minimap, Runübersicht, Begegnungen, Statistik, Schaden/Heilung, Krits, Charakterwerte, Chat, alle Beutemodi, Spieler/Ziel, Aktionsleiste, Zauber/Gegenstände, Zähler, XP, Klassenressourcen, gespeicherte Level und Erfolge. Auch die Platzhalter für Buffs und Tooltips sind 300 Punkte breit. Tooltips selbst passen sich dem Inhalt an; größere Dialoge für Einstellungen, Historie, Sammlung und Chatkopie behalten ihre benötigte Breite. Persönliche Skalierungen bleiben erhalten. Bei gleicher effektiver Skalierung sind die HUD Fenster gleich breit; die automatische Anpassung an kleine Bildschirmflächen kann Spieler/Ziel, Aktionsleiste und Ressourcen weiterhin verkleinern. Alt und Mausrad passen die einzelnen Fenster wie gewohnt an.

Porträts, Schrift, Übergänge und Endkappen bleiben unverändert groß. Nur die geraden Teile der Spieler und Zielrahmen werden länger. Zusätzliche Aktionen und Zauber umbrechen innerhalb des Fensters. Die drei Zähler stehen über zwei Cachedetails, optionale Leben und Rerolls darunter. Die Minimap enthält eine quadratische Kartenfläche von 280 Punkten; die Höhe anderer Fenster folgt weiterhin ihrem Inhalt.

## Angedockte Fenster

Bei eingeschaltetem Einrasten die untere Fensterkante auf die obere Kante eines anderen Fensters ziehen. Die Verbindung wird gespeichert: Ein Fenster über dem Chat wächst bei weiteren Zeilen nach oben; darüber angeordnete Fenster folgen. Wegziehen löst die Verbindung, Shift beim Loslassen verhindert das Andocken. Ältere Layouts enthalten nur Positionen, deshalb die betroffenen Fenster nach diesem Update einmal erneut andocken. Freie Platzierungen bleiben unverändert.

## Einstellungen durchsuchen

Die Suchleiste filtert live über alle Kategorien, auch einzelne Charakterwerte und optionale Module. Treffer sind die ursprünglichen bedienbaren Steuerelemente, keine Links. Deutsche und englische Beschriftungen, Hilfetexte, Auswahlwerte und gängige Synonyme werden unabhängig von der UI Sprache gemeinsam durchsucht, etwa Player/Spieler, Target/Ziel, Damage/Schaden und Cooldown/Abklingzeit. Mehrere Wörter grenzen die Treffer ein. X oder Escape im Suchfeld leert die Suche und stellt die vorherige Seite samt Scrollposition wieder her. Ein Kategorienwechsel leert sie ebenfalls. Der Suchtext wird nicht gespeichert.
