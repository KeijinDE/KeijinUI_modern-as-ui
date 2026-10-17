# KeijinUI Changelog

Patch notes for KeijinUI (Modern AS UI), newest first. English first, [Deutsch below](#deutsch).
Every version that is uploaded to GitHub gets its entry here before the upload.

## English

### 1.0.1 (2026-10-17, release v1.0.1)

Run overview window: one row per class and race. All heroes of an account carry the account name while class and race change from run to run, so 0.9 and 1.0.0 counted every class in one row (with the class of the last counted run, and the start message counted all classes together). Rows are now kept per class and race, sorted by class and then race, in class color; the column is called "Class and race" and the hero name is in the tooltip. Because the old data mixed classes and cannot be split, the run history is cleared once when 1.0.1 loads.

"Again" after a death: the boss bar of the fight in which the hero died no longer stays in the new run. The game sends the unit and lair lists only when they change, and the new run does not reload the interface; data older than the start of the current run is now ignored until the game sends new data.

Guardians: a waiting lair without a game message for more than five seconds shows "?" instead of a frozen countdown. `/kui guardians debug` prints the lairs and guardian units the game delivers.

### 1.0.0 (2026-10-17, release v1.0.0)

Guardians in the run overview. Below the boss schedule, separated by a faint line, the run overview lists the guardian lairs of the map, one line each: "asleep", "fighting" with the guardian's health, "back in 1:23" while a lair waits for its next guardian, "due" once that time is up. The header shows how many guardians are up, for example "2 of 4 up". The tooltip of a row gives the lair position on the map. The data comes from the game (AZS_LAIRS); between two updates the countdown runs on for at most two seconds. Switch it in Settings, Display, "Guardians in the run overview", or with `/kui guardians on|off` (on by default). The settings window is a little taller for the new row.

### 0.9.1 (2026-10-17, release v0.9.1)

Settings window: the window is a little taller, so the Close button no longer touches the Minimap button row on the General tab. The README on GitHub shows the minimap button and the General tab.

### 0.9.0 (2026-10-17, release v0.9.0)

Run overview. A new window (`/kui runs`, or Settings, General, Run overview) lists, per zone and character, the number of runs, wins, the last time, the fastest win and the longest survival. One page per zone, switched with the arrows; zones follow the order of the game, characters appear in their class color, missing values show a dash. The data is stored account wide, so all characters appear together. The game reports only the run in progress, so the overview counts from this version on; earlier runs cannot be added.

As soon as you enter the zone for a new run (before the first move) a chat line names the zone, the class (in class color), the number of the run and, once there are any, the fastest win and the longest survival, for example "Elwynn Forest, Priest: This is your 4th run. Fastest win 15:42, longest survival 28:40." The first run says "This is your first run here." The line follows the interface language and appears once per run, not again after a reload in the middle of a run or while waiting to start. It can be switched off in Settings, General, or with `/kui runs msg` (on by default). `/kui runs debug` prints what the game reports (phase, run time, zone, open run) for troubleshooting.

A run counts once it has lasted 90 seconds (or earlier with a win); shorter runs are not stored at all and do not use up a run number. A win is stored at the moment the game reports the final boss dead; endless mode after a win stays the same run, with a longer survival time. Runs that end by death or by leaving count with the time reached. A reload in the middle of a run is recognized through the open run kept in the saved variables and counts nothing twice.

Minimap button. A small button with the wordmark "Kui" at the edge of the minimap, by default at the right middle: left click opens or closes the settings, right click the run overview, dragging with the left mouse button moves it around the map. On the square KeijinUI minimap it runs along the square edge, on the original minimap along the circle; the angle is saved and the button follows when the minimap style is switched. The tooltip lists the clicks. Switch it in Settings, General, or with `/kui button on|off` (on by default).

### 0.8.0 (2026-10-16, release v0.8.0)

Caches on the minimap. Every cache waiting to be opened gets a chest symbol on the minimap (own artwork); caches closer than 10 yards share one symbol with a number, and the tooltip shows the count, the distance and the price of the next cache. When the nearest cache is out of sight, a small arrow at the minimap border points toward it, clamped to the square border of the KeijinUI minimap (or the circle of the original one). An optional large screen arrow (off by default, movable in the layout editor) shows direction, distance and price of the nearest cache. The game gives no scale for the zone map, so it is measured from the world and map positions of caches and lairs; without a measurement nothing is drawn. The minimap diameter per zoom level follows the client's own table. The facing direction comes from `GetPlayerFacing` if it exists, else from the minimap arrow model, else from the direction of movement, else north. A chat notice for a new cache is optional (off by default). Settings, Units, Caches has a switch for the symbols, the edge arrow, the screen arrow and the notice. `/kui caches debug` prints what the game delivers (scale, zoom, map position, facing sources) and `/kui caches source` forces a direction source.

While the KeijinUI damage text runs (compact or scroll), the game's own floating combat text over the character is paused; the red "-N" numbers no longer appear twice. In the native mode and on logout the game setting is restored.

### 0.7.4 (2026-10-16, release v0.7.4)

Level and experience move from the run tracker into the run statistics: one row for the level, one for the experience of the current level with the share to the next level in the tooltip. The game provides no run total of experience, so none is shown. The tracker is one line shorter, and the default layout moves the damage meter and critical hits down accordingly. Saved layouts follow once on the first load: a damage meter below the statistics moves down only as far as the taller panel would otherwise cover it, critical hits below only as far as the full meter needs. Frames with room to spare stay put.

### 0.7.3 (2026-10-16, release v0.7.3)

Priests see the Lightwell countdown under the player frame, taken from the game's spell cooldown data.

### 0.7.2 (2026-10-16, release v0.7.2)

Removes a remaining piece of the old name shoulder at the portrait join, shared by player and mirrored target frames. Warms the normal unit-frame metal tint to bronze after the continuous bright outline made it look paler. Keeps the corrected uniform rail widths, complete bar ends and symmetric shard outlines. Elite gold and rare silver markers retain their colours.

### 0.7.1 (2026-10-16)

Fixes inconsistent lower borders on player and target frames with one continuous housing contour. Restores complete vertical ends and even inward outlines on list bars and shared chamfered frames. Empty and filled soul shards now share a closed symmetric outline measured in their displayed aspect ratio. Retains portrait artwork, resource mechanics, layouts and settings.

### 0.7.0 (2026-10-16)

Adds class resources under the player frame: rogue combo points, smaller warlock shards with space above and below, and warrior rage. Shows only learned mechanics with supported native values. Resources follow the player or can be detached through Alt dragging/scaling; settings, reload recovery and combined screen bounds are included. Round portraits and points stay round; rectangular housings, player/target free ends, panels, bars, minimap border, tooltips, action/build/buff/debuff icons and achievement frames use original chamfered artwork. Preserves 0.6.8 icon fallback and shaman colour and 0.6.9 per-frame nameplate updates. Native resource transitions and final game rendering still need an in-game check.

### 0.6.9 (2026-10-16)

Nameplates update every frame, so new plates no longer flash the stock look or jump.

### 0.6.8 (2026-10-16)

Spell icons fall back to a fixed table when the spellbook has no match; fixed missing quickslot textures; shaman class colour is dark blue.

### 0.6.7 (2026-10-16, release v0.6.7)

New setting for damage numbers with four styles: off, compact (the previous look), scrolling (new default: numbers rise in a light arc that falls back slightly, alternating left and right, coloured by damage school with spell icons, small normal numbers, large crits with a pop, small hits in grey, following the nameplate and showing misses) and game (the native numbers). Set in the options or with `/kui text off|compact|scroll|game`; the spell icons can be switched with `/kui text icons`. Earlier "off" choices carry over.

### 0.6.6 (2026-10-16, release v0.6.6)

More room between unit levels and the curved rim. Target text layout fully mirrors the player: level and health percent on the left, name and health points toward its portrait on the right. Each damage-meter row now shows total damage and DPS in separate columns, using the same time interval as the summary and the Reset button.

### 0.6.5 (2026-10-16)

Player and target frames have one sculpted housing with a dark name shoulder, a raised portrait bezel and a softly tapered end. The health opening stays tall, flush with the portrait at the bottom, with colour reaching the portrait edge. Original geometric artwork, no imported Dragonflight assets. Warlock abilities have deliberate, stable colours instead of repeated blue hash colours; damage and critical-hit lists still match in both languages.

### 0.6.4 (2026-10-16)

Calmer lists: run statistics are plain key and value lines with a faint separator instead of framed bars. Damage meter and critical hits use own bars with corner radius 4, a 1 unit outline with a slightly brighter top edge, and a fill that keeps the rounded left end at every value.

### 0.6.3 (2026-10-16)

The health color of the unit frames now fills the whole inside of the outline, without a dark stripe at the top and the ends. The rows of statistics, damage meter, critical hits, run progress and nameplates get a plain line of one unit as border instead of the soft metal frame.

### 0.6.2 (2026-10-16)

New unit frames "Freier Verbund": round portrait and health bar share one outline without a box, the health color reaches the portrait edge, the bar is taller (158 × 30). Health points left, percent right, name and level above. The target bar is now mirrored and stays attached to its portrait. Own geometric artwork in media/soft.

### 0.6.1 (2026-10-15, published)

Thinner frames: the bar border is less than half as thick, panel and unit frame borders use edge size 10 instead of 14, the minimap border 8 instead of 10. Panels and buttons use edge size 7, the bar border has slightly rounded corners and the fill now reaches both ends. The chosen language now survives the reload (the client loads saved variables after the addon files), and the boss schedule in the run overview is kept across a reload, since the game sends it only when it changes.

### 0.6.0 (2026-10-15, first public release)

Everything in the package is now original work: the combat message reader (`CombatParser.lua`) is a new implementation that derives its line shapes from the client's own combat strings, and the bar graphics (frame pieces and fill) are generated by `development/keijinui/prepare_bar_art.py`. The unused unit frame images in `media/units` and the unused blue fill are removed, and the license and source notes that belonged to them are gone. New tests cover every combat template that is read.

### 0.5.3 (before the public release)

Language only by hand (English or German, default English); the automatic detection is removed because it read outdated English game data after a language change and switched wrongly. Changing the language reloads the interface. The native displays (clock, kills bar, damage meter, boss bars, spell bar) stay hidden as long as the matching KeijinUI element is switched on, even without game data, so nothing appears twice; they come back when the element is switched off. A native display that the game switches on again is hidden again at the next update.

### 0.5.2 (before the public release)

`/kachi debug` records system messages (persistent, last 60, `/kachi log`, `/kachi log clear`) to check whether achievement lines reach addons. Achievements are also recognized in the general form `Text: [Name] (N ...)`, since no German client text is known.

### 0.5.1 (before the public release)

Default layout: all elements start in the arrangement of the author (fresh install and "reset layout"); the default is not stored, so later changes of it apply, and saved positions keep priority. Nameplates default to bosses, elites and rares.

### 0.5.0 (before the public release)

Player and target frames in the panel style (square portrait box, metal health bar, heading strip). Square minimap in the KeijinUI style with zoom by mouse wheel, layout key `minimap` and a switch in the settings. Estimated healing breakdown (leech, heal per kill, regeneration) in the tooltip of the healing row.

### 0.4.2 (before the public release)

Settings window with tabs (Display, Units, Layout, General), switches as clickable rows, the last tab is remembered. Automatic language detection now always runs along: `/kui lang auto` applies the detected language at once, without evidence the stored detection stays, the majority of known names decides.

### 0.4.1 (before the public release)

Bar fill and background of list rows (encounters, meter) stay inside the rounded border corners.

### 0.4.0 (before the public release)

Bilingual interface (German or English), detection and `/kui lang`, `/kui reload`, English arguments for `/kbb`, bilingual README.

### 0.3.7 (before the public release)

The build tip names abilities in the interface language, even if the spell book reports English names.

### 0.3.6 (before the public release)

Grid and snapping in layout mode.

### 0.3.5 (before the public release)

Buffs can be left aligned.

### 0.3.4 (before the public release)

Damage numbers never cover frames. The build rating maps meter values through ability keys.

### 0.3.3 (before the public release)

Statistic row "Healing (effective)" and `/kui heal debug`.

### 0.3.2 (before the public release)

Shorter statistics. 0.3.1: Encounters without UnitAffectingCombat. 0.3.0: Own chat window, damage numbers in the world, target debuffs.

### 0.2.x (before the public release)

Action bar, build overview, class colored health bars, nameplates.

## Deutsch

Änderungen an KeijinUI (Modern AS UI), neueste zuerst. Jede Version, die auf GitHub hochgeladen wird, bekommt vorher hier ihren Eintrag.

### 1.0.1 (2026-10-17, Release v1.0.1)

Fenster Rundenübersicht: eine Zeile je Klasse und Volk. Alle Helden eines Kontos tragen den Kontonamen, Klasse und Volk wechseln von Run zu Run; 0.9 und 1.0.0 zählten deshalb alle Klassen in einer Zeile (mit der Klasse des zuletzt gezählten Runs, und die Startmeldung zählte alle Klassen zusammen). Die Zeilen werden jetzt je Klasse und Volk geführt, nach Klasse und dann Volk sortiert, in Klassenfarbe; die Spalte heißt "Klasse und Volk", der Heldenname steht im Tooltip. Weil die alten Daten Klassen vermischen und sich nicht trennen lassen, wird die Rundenübersicht beim ersten Laden von 1.0.1 einmalig geleert.

"Nochmal" nach dem Tod: Die Bossleiste des Kampfes, in dem der Held starb, bleibt im neuen Run nicht mehr stehen. Das Spiel schickt Einheiten und Horte nur bei Änderungen, und der neue Run lädt die Oberfläche nicht neu; Daten, die älter als der Start des laufenden Runs sind, werden jetzt ignoriert, bis das Spiel neue schickt.

Wächter: Ein wartender Hort ohne Spielmeldung seit mehr als fünf Sekunden zeigt "?" statt eines stehenden Countdowns. `/kui guardians debug` gibt die Horte und Wächtereinheiten aus, die das Spiel liefert.

### 1.0.0 (2026-10-17, Release v1.0.0)

Wächter in der Runübersicht. Unter dem Bosszeitplan, abgesetzt durch eine feine Linie, listet die Runübersicht die Wächterhorte der Karte, je eine Zeile: "schläft", "im Kampf" mit dem Leben des Wächters, "zurück in 1:23", solange ein Hort auf den nächsten Wächter wartet, "fällig", sobald die Zeit abgelaufen ist. Die Kopfzeile zeigt, wie viele Wächter da sind, etwa "2 von 4 da". Der Tooltip einer Zeile nennt die Lage des Horts auf der Karte. Die Daten kommen vom Spiel (AZS_LAIRS); zwischen zwei Meldungen läuft der Countdown höchstens zwei Sekunden weiter. Schalter in Einstellungen, Anzeige, "Wächter in der Runübersicht", oder `/kui guardians on|off` (standardmäßig an). Das Optionsfenster ist für die neue Zeile etwas höher.

### 0.9.1 (2026-10-17, Release v0.9.1)

Optionsfenster: Das Fenster ist etwas höher, damit der Knopf Schließen im Reiter Allgemein nicht mehr an die Zeile Minimapknopf stößt. Die README auf GitHub zeigt den Minimapknopf und den Reiter Allgemein.

### 0.9.0 (2026-10-17, Release v0.9.0)

Rundenübersicht. Ein neues Fenster (`/kui runs` oder Einstellungen, Allgemein, Rundenübersicht) listet je Zone und Charakter die Anzahl der Runs, die Siege, die letzte Zeit, den schnellsten Sieg und das längste Überleben. Pro Zone eine Seite, per Pfeil umschaltbar; die Zonen folgen der Reihenfolge des Spiels, die Charaktere erscheinen in Klassenfarbe, fehlende Werte zeigen einen Strich. Die Daten liegen kontoweit, alle Charaktere erscheinen also zusammen. Das Spiel meldet nur den laufenden Run, deshalb zählt die Übersicht ab dieser Version; frühere Runs lassen sich nicht nachtragen.

Sobald du die Zone für einen neuen Run betrittst (vor der ersten Bewegung), nennt eine Chatzeile die Zone, die Klasse (in Klassenfarbe), die Nummer des Runs und, sobald vorhanden, den schnellsten Sieg und das längste Überleben, zum Beispiel "Elwynn Forest, Priester: Das ist dein 4. Lauf. Schnellster Sieg 15:42, längstes Überleben 28:40." Der erste Lauf lautet "Das ist dein erster Lauf hier." Die Zeile folgt der Sprache der Oberfläche und erscheint einmal pro Run, nicht erneut nach einem Reload mitten im Run oder beim Warten auf den Start. Sie lässt sich in den Einstellungen unter Allgemein oder mit `/kui runs msg` abschalten (Standard an). `/kui runs debug` gibt zur Fehlersuche aus, was das Spiel meldet (Phase, Laufzeit, Zone, offener Run).

Ein Run zählt, sobald er 90 Sekunden gedauert hat (oder früher mit einem Sieg); kürzere Runs werden gar nicht gespeichert und verbrauchen keine Nummer. Ein Sieg wird in dem Moment gespeichert, in dem das Spiel den Endboss als besiegt meldet; Endless nach einem Sieg bleibt derselbe Run, mit längerer Überlebenszeit. Runs, die durch Tod oder Verlassen enden, zählen mit der erreichten Zeit. Ein Reload mitten im Run wird über den in den gespeicherten Variablen offen gehaltenen Run erkannt und zählt nichts doppelt.

Minimapknopf. Ein kleiner Knopf mit dem Schriftzug "Kui" am Rand der Minimap, standardmäßig rechts in der Mitte: Linksklick öffnet oder schließt die Einstellungen, Rechtsklick die Rundenübersicht, Ziehen mit der linken Maustaste verschiebt ihn um die Karte. Auf der quadratischen KeijinUI Minimap läuft er am quadratischen Rand entlang, auf der Originalminimap am Kreis; der Winkel wird gespeichert und der Knopf folgt beim Umschalten des Minimapstils. Der Tooltip nennt die Klicks. Schaltbar unter Einstellungen, Allgemein, oder mit `/kui button on|off` (Standard an).

### 0.8.0 (2026-10-16, Release v0.8.0)

Caches auf der Minimap. Jede Cache, die noch geöffnet werden kann, bekommt ein Truhensymbol auf der Minimap (eigene Grafik); Caches unter 10 Yards Abstand teilen sich ein Symbol mit Zahl, der Tooltip nennt Anzahl, Entfernung und Preis der nächsten Cache. Liegt die nächste Cache außer Sicht, zeigt ein kleiner Pfeil am Minimaprand in ihre Richtung, begrenzt auf den quadratischen Rand der KeijinUI Minimap (bei der Originalminimap auf den Kreis). Ein optionaler großer Bildschirmpfeil (Standard aus, im Layouteditor verschiebbar) zeigt Richtung, Entfernung und Preis der nächsten Cache. Das Spiel liefert keinen Maßstab für die Zonenkarte, deshalb wird er aus den Welt und Kartenpositionen von Caches und Lairs gemessen; ohne Messung wird nichts gezeichnet. Der Minimapdurchmesser je Zoomstufe folgt der Tabelle des Clients. Die Blickrichtung kommt aus `GetPlayerFacing`, falls vorhanden, sonst aus dem Pfeilmodell der Minimap, sonst aus der Bewegungsrichtung, sonst Norden. Eine Chatmeldung bei einer neuen Cache ist optional (Standard aus). Unter Einstellungen, Einheiten, Caches gibt es je einen Schalter für Symbole, Randpfeil, Bildschirmpfeil und Meldung. `/kui caches debug` zeigt, was das Spiel liefert (Maßstab, Zoom, Kartenposition, Richtungsquellen), `/kui caches source` erzwingt eine Richtungsquelle.

Solange der KeijinUI Kampftext läuft (kompakt oder scrollend), pausiert der Kampftext des Spiels über der Figur; die roten "-N" Zahlen erscheinen nicht mehr doppelt. Im nativen Modus und beim Ausloggen gilt wieder die Spieleinstellung.

### 0.7.4 (2026-10-16, Release v0.7.4)

Level und Erfahrung wandern vom Rundentimer in die Runstatistik: eine Zeile für das Level, eine für die Erfahrung im aktuellen Level, der Anteil bis zum nächsten Level steht im Tooltip. Eine Gesamtsumme der Erfahrung im Run liefert das Spiel nicht, daher wird keine angezeigt. Der Rundentimer ist eine Zeile kürzer, im Standardlayout rücken Schadensanzeige und kritische Treffer entsprechend nach unten. Gespeicherte Layouts ziehen beim ersten Laden einmalig nach: Eine Schadensanzeige unter der Statistik rückt nur so weit, wie die höhere Statistik sie sonst überdecken würde, die kritischen Treffer darunter nur so weit, wie die volle Schadensanzeige es braucht. Fenster mit genug Abstand bleiben stehen.

### 0.7.3 (2026-10-16, Release v0.7.3)

Priester sehen den Lichtbrunnen Countdown unter dem Spielerrahmen, aus den Abklingzeitdaten des Spiels.

### 0.7.2 (2026-10-16, Release v0.7.2)

Entfernt einen verbliebenen Rest der alten Namenskante am Portraetuebergang bei Spieler und gespiegeltem Ziel. Die normale Metalltoenung der Unitframes wird waermer und bronzefarben, da die durchgehend helle Kontur blasser wirkte. Gleichmaessige Rahmenstaerke, vollstaendige Balkenenden und symmetrische Splitter bleiben erhalten. Goldene Elitemarker und silberne Raremarker behalten ihre Farben.

### 0.7.1 (2026-10-16)

Einheitliche Unterkante an Spieler und Ziel durch eine durchgehende Rahmenkontur. Vollstaendige senkrechte Abschluesse und gleichmaessige innenliegende Raender an Meterleisten und gemeinsam genutzten abgeschraegten Rahmen. Leere und volle Seelensplitter erhalten dieselbe geschlossene symmetrische Kontur, deren Staerke im angezeigten Seitenverhaeltnis berechnet wird. Portraetgrafik, Ressourcenmechanik, Positionen und Einstellungen bleiben erhalten.

### 0.7.0 (2026-10-16)

Klassenressourcen unter dem Spielerframe: Combopunkte, kleinere Seelensplitter mit Luft oben und unten und Wut. Nur gelernte Mechaniken mit unterstützten nativen Werten erscheinen. Die Anzeige folgt dem Spieler oder wird durch Alt und Ziehen beziehungsweise Skalieren gelöst; Einstellungen, Wiederherstellung nach Reload und gemeinsame Bildschirmbegrenzung sind enthalten. Runde Porträts und Punkte bleiben rund. Rechteckige Fassungen, freie Spieler und Zielenden, Panels, Balken, Minimaprand, Tooltips, Aktionsfelder, Buildsymbole, Buffs, Debuffs und Erfolgsrahmen erhalten eigene abgeschrägte Grafiken. Zaubersymbolrückfall und Schamanenfarbe aus 0.6.8 sowie die Aktualisierung der Namensplaketten pro Frame aus 0.6.9 bleiben erhalten. Die nativen Ressourcenübergänge und die endgültige Darstellung müssen noch im Spiel geprüft werden.

### 0.6.9 (2026-10-16)

Namensplaketten werden jeden Frame aktualisiert, neue Plaketten blitzen nicht mehr im Spielstil auf und springen nicht.

### 0.6.8 (2026-10-16)

Zaubersymbole fallen auf eine feste Tabelle zurück, wenn das Zauberbuch keinen Treffer hat; fehlende Quickslot Texturen behoben; die Klassenfarbe des Schamanen ist dunkelblau.

### 0.6.7 (2026-10-16, Release v0.6.7)

Neue Einstellung für Schadenszahlen mit vier Stilen: aus, kompakt (das bisherige Aussehen), scrollend (neuer Standard: Zahlen steigen in einem leichten Bogen, der am Ende etwas abfällt, abwechselnd links und rechts, nach Zauberschule gefärbt mit Zaubersymbolen, kleine normale Zahlen, große Krits mit Pop, kleine Treffer grau, folgen der Namensplakette und zeigen Fehlschläge) und Spiel (die eigenen Zahlen des Spiels). Einstellbar in den Optionen oder mit `/kui text off|compact|scroll|game`; die Zaubersymbole schaltet `/kui text icons`. Frühere Aus Einstellungen bleiben erhalten.

### 0.6.6 (2026-10-16, Release v0.6.6)

Mehr Abstand zwischen Level und gebogener Außenkante. Der Zielrahmen spiegelt jetzt auch die Texte vollständig: Level und Lebensprozent links, Name und Lebenspunkte rechts am Porträt. Jede Zeile der Schadensanzeige zeigt Gesamtschaden und DPS in eigenen Spalten, mit demselben Zeitraum wie die Gesamtrate und der Resetfunktion.

### 0.6.5 (2026-10-16)

Spieler und Zielframe erhalten eine gemeinsame modellierte Fassung mit dunkler Namensfläche, schmaler Porträtkante und weich auslaufendem Ende. Die Lebensfläche bleibt hoch, unten bündig und reicht farbig bis an die Porträtkante. Eigene geometrische Grafiken ohne übernommene Dragonflight Bilder. Hexenmeisterfähigkeiten erhalten bewusst festgelegte Farben statt mehrfach derselben blauen Zufallszuordnung; Schaden und kritische Treffer bleiben in beiden Sprachen gleich gefärbt.

### 0.6.4 (2026-10-16)

Ruhigere Listen: Die Runstatistik zeigt Beschriftung und Wert als schlichte Zeilen mit schwacher Trennlinie statt gerahmter Balken. Schadensanzeige und kritische Treffer nutzen eigene Balken mit Eckenradius 4, einer Kontur von einer Einheit mit leicht hellerer Oberkante und einer Füllung, die bei jedem Wert das runde linke Ende behält.

### 0.6.3 (2026-10-16)

Die Lebensfarbe der Unitframes füllt jetzt die ganze Innenfläche der Kontur, ohne dunklen Streifen oben und an den Enden. Die Zeilen von Statistik, Schadensanzeige, kritischen Treffern, Runfortschritt und Namensplaketten erhalten statt des weichen Metallrahmens eine einfache Linie von einer Einheit.

### 0.6.2 (2026-10-16)

Neue Unitframes „Freier Verbund“: Rundes Porträt und Lebensbalken teilen eine Kontur ohne Kasten, die Lebensfarbe reicht bis an die Porträtkante, der Balken ist höher (158 × 30). Lebenspunkte links, Prozent rechts, Name und Level darüber. Der Zielbalken ist jetzt gespiegelt und bleibt an seinem Porträt angeschlossen. Eigene geometrische Grafiken in media/soft.

### 0.6.1 (2026-10-15, veröffentlicht)

Dünnere Rahmen: Der Balkenrahmen ist weniger als halb so dick, Panel und Einheitenrahmen nutzen Randstärke 10 statt 14, die Minimap 8 statt 10. Panels und Knöpfe nutzen Randstärke 7, der Balkenrahmen hat nur leicht abgerundete Ecken und die Füllung reicht bis an beide Enden. Die gewählte Sprache bleibt nach dem Neuladen erhalten (der Client lädt die gespeicherten Einstellungen erst nach den Addon Dateien), und die Bossliste der Runübersicht übersteht ein Neuladen, weil das Spiel sie nur bei Änderungen schickt.

### 0.6.0 (2026-10-15, erste Veröffentlichung)

Alles im Paket ist jetzt eigene Arbeit: Der Leser für Kampfnachrichten (`CombatParser.lua`) ist neu geschrieben und leitet die Zeilenformen aus den Kampftexten des Clients ab; die Balkengrafiken (Rahmenteile und Füllung) erzeugt `development/keijinui/prepare_bar_art.py`. Die ungenutzten Rahmenbilder in `media/units` und die ungenutzte blaue Füllung sind entfernt, ebenso die zugehörigen Lizenz und Herkunftsdateien. Neue Tests decken jede gelesene Kampftextvorlage ab.

### 0.5.3 (vor der Veröffentlichung)

Sprache nur noch von Hand (Englisch oder Deutsch, Standard Englisch); die automatische Erkennung entfällt, weil sie nach einem Sprachwechsel veraltete englische Spieldaten las und falsch umschaltete. Ein Sprachwechsel lädt die Oberfläche neu. Die eigenen Anzeigen des Spiels (Uhr, Kill Leiste, Schadensmeter, Bossleisten, Zauberleiste) bleiben versteckt, solange das passende KeijinUI Element eingeschaltet ist, auch ohne Spieldaten, sodass nichts doppelt erscheint; sie kommen zurück, wenn das Element ausgeschaltet wird. Schaltet das Spiel eine Anzeige selbst wieder ein, wird sie beim nächsten Update erneut versteckt.

### 0.5.2 (vor der Veröffentlichung)

`/kachi debug` zeichnet Systemmeldungen auf (bleibt über Neustarts aktiv, letzte 60, `/kachi log`, `/kachi log clear`), um zu prüfen, ob Erfolgszeilen bei Addons ankommen. Erfolge werden zusätzlich in der allgemeinen Form `Text: [Name] (N ...)` erkannt, da kein deutscher Clienttext bekannt ist.

### 0.5.1 (vor der Veröffentlichung)

Standardlayout: Alle Elemente starten in der Anordnung des Autors (Neuinstallation und "Layout zurücksetzen"); der Standard wird nicht gespeichert, spätere Änderungen daran greifen also, gespeicherte Positionen haben Vorrang. Namensplaketten standardmäßig für Boss, Elite und Rare.

### 0.5.0 (vor der Veröffentlichung)

Spieler und Zielframes im Panelstil (eckiger Porträtkasten, Metall Lebensbalken, Titelleiste). Eckige Minimap im KeijinUI Stil mit Zoom per Mausrad, Layoutschlüssel `minimap` und Schalter in den Einstellungen. Geschätzte Heilungsaufschlüsselung (Lebensraub, Heilung pro Kill, Regeneration) im Tooltip der Heilungszeile.

### 0.4.2 (vor der Veröffentlichung)

Optionsfenster mit Tabs (Anzeige, Einheiten, Layout, Allgemein), Schalter als anklickbare Zeilen, der zuletzt gewählte Tab wird gemerkt. Die automatische Spracherkennung läuft jetzt immer mit: bei `/kui lang auto` gilt sofort wieder die erkannte Sprache, ohne Belege bleibt die gespeicherte Erkennung, die Mehrheit der bekannten Namen entscheidet.

### 0.4.1 (vor der Veröffentlichung)

Füllung und Hintergrund der Listenzeilen (Begegnungen, Schadensliste) bleiben innerhalb der runden Rahmenecken.

### 0.4.0 (vor der Veröffentlichung)

Zweisprachige Oberfläche (Deutsch oder Englisch), Erkennung und `/kui lang`, `/kui reload`, englische Argumente für `/kbb`, zweisprachige README.

### 0.3.7 (vor der Veröffentlichung)

Die Buildempfehlung nennt Fähigkeiten in der Sprache der Oberfläche, auch wenn das Zauberbuch englische Namen liefert.

### 0.3.6 (vor der Veröffentlichung)

Raster und Einrasten im Layoutmodus.

### 0.3.5 (vor der Veröffentlichung)

Buffs lassen sich linksbündig ausrichten.

### 0.3.4 (vor der Veröffentlichung)

Schadenszahlen liegen nie über Frames. Die Buildbewertung ordnet Meterwerte über Fähigkeitsschlüssel zu.

### 0.3.3 (vor der Veröffentlichung)

Statistikzeile "Heilung (effektiv)" und `/kui heal debug`.

### 0.3.2 (vor der Veröffentlichung)

Kürzere Statistik. 0.3.1: Begegnungen ohne UnitAffectingCombat. 0.3.0: Eigenes Chatfenster, Schadenszahlen in der Spielwelt, Debuffs am Ziel.

### 0.2.x (vor der Veröffentlichung)

Aktionsleiste, Buildübersicht, Lebensbalken in Klassenfarbe, Namensplaketten.
