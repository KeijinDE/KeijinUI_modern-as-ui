# KeijinUI Changelog

Patch notes for KeijinUI (Modern AS UI), newest first. English first, [Deutsch below](#deutsch).
Every version that is uploaded to GitHub gets its entry here before the upload.

## English

### 2.2.0 (2026-10-18, release v2.2.0)

* **Loot list.** New choice in Settings, Display, Loot: "Notice" (default, as before), "List", "Small list" or "Icons only". The list collects the items of the current run in the loot panel, newest first, with symbol, name in quality color, slot and run time when you got it, and a grey "Collected" or green "New" hint. Up to 8 rows are visible, the mouse wheel scrolls, hovering shows the item tooltip. The small list is a compact line list (small symbol, small name, status, 12 lines). "Icons only" shows symbols in a grid with a quality frame, a green check mark for new and a red cross for already collected items, and a tooltip with name and status. A reload keeps the list of the same run, a new run empties it.
* **New loot only.** New switch: show only items that are new to your collection. KeijinUI reads this from the game's own loot line, which marks known items as "(already collected)". It applies to all four displays.
* **Loot switches.** New switches "Icons" (hides the symbols in the list and the small list, the text moves left) and "Show collection status" (hides New/Collected and the check mark/cross). Both are on by default and greyed out where they do nothing. The help text of the loot section is shorter and no longer cut off.
* **Grow upwards.** New choice in Settings, Display, Loot: "Growth", "Downwards" (default, as before) or "Upwards". Upwards puts the title at the bottom of the loot window and the newest loot directly above it; older entries move up and the icon view fills from the bottom. The bottom edge stays fixed while the window grows, so it can be attached to the bottom edge of the screen. The mouse wheel scrolls towards older entries upwards, and the thin or hidden headers work there too. Switching keeps the window where it is on screen.
* **Commands.** `/kui loot clear` empties the list, `/kui loot debug` shows mode and entries.
* **Loot follows the section headers.** The section header setting normal, thin or off now also applies to the loot window; list and icons move up with it.

### 2.1.0 (2026-10-18, release v2.1.0)

* **Movable combat text.** The floating damage numbers start in an invisible anchor. Hold Alt to show and move it, Alt and mouse wheel change the number size. New choice in Settings, Combat: Position "At the enemy" (default, unchanged: numbers rise above the nameplate) or "Fixed spot" (all numbers start in the anchor and follow no nameplate). Without a nameplate the numbers now start in the anchor instead of the screen center; the anchor sits at the old spot until you move it.
* **Boss damage.** The damage meter has two tabs, Run and Boss. Boss lists the damage dealt to bosses in the last boss fight, with total and DPS per source, and says "running" while a boss is alive. Reset only applies to the Run tab. New option in Settings, Combat: switch to Boss automatically while a boss lives and back afterwards (off by default; your own tab choice always wins).
* **Rising style.** New damage number style: numbers rise straight up and fade out slowly, more compact than Scrolling, with school colours and spell icons.
* **Own numbers only.** Position, spell icons and merging apply to the Compact, Scrolling and Rising styles. In the Game style the game draws the numbers itself and no addon can move them; these options are greyed out then, with a note saying why.

### 2.0.1 (2026-10-18, release v2.0.1)

* A lag no longer wipes boss times, healing and critical hits. Restart detection now uses the run time reported by the game and allows 3 seconds of fall back, as the run history already did.
* Pace keeps its comparison after a reload during a run, when the game does not resend the zone data.
* `/kui pace debug` shows the comparison key of the current run and the stored runs.

### 2.0.0 (2026-10-18, release v2.0.0)

The biggest update so far. Highlights:

* **New settings window.** Clear pages on the left (Display, Combat, Units, Controls, Layout, General), real checkboxes and a live preview of the combat numbers.
* **Your wins are safe.** A win is saved the moment it happens, even if you go straight back to the menu. Endless mode no longer touches your win time, and very short runs no longer count.
* **Pace.** Shows during a run whether you are faster or slower than in your earlier runs with the same class and zone (green, yellow, red). Boss kill times get colors too.
* **Caches.** Instead of an estimated time you now see how much gold you still need for the next cache: red, yellow, or green when you can open it.
* **New optional displays.** A cursor ring and a compact panel with your character attributes (crit, haste, lifesteal and more). Both are off by default.
* Shamans are shown in blue everywhere, and many small fixes.

The detailed notes for the test builds 1.2.0 to 1.3.4 follow below.

### 1.3.4 (2026-10-18)

Shamans appear in dark blue in the run overview and the run start message instead of the paladin pink of the 1.12 class color table, matching the player and target frames. One shared class color function now serves all three places.

### 1.3.3 (2026-10-18)

The counter row no longer estimates the time until the next cache is affordable. It shows the gold still missing for the next cache instead (never below zero, "Ready" once enough gold is there), updated with gold and price. Color: green when affordable, yellow when at most 25% of the cache price is missing, red when more is missing. The 25% boundary is a starting value for in-game review.

### 1.3.2 (2026-10-18)

Pace is enabled by default when no preference has been saved. It can still be disabled in Display; an explicitly saved disabled preference survives updates and reloads. The comparison, weighting and neutral states are unchanged.

### 1.3.1 (2026-10-18)

Pace now combines kill progress (70%) with damage per second over the last 30 native run seconds (30%), comparing the same timestamp and window with the median of matching prior runs. Both components use the same reference runs; class, zone, difficulty and modifiers must match. The DPS contribution is capped at 150% of its reference to limit burst distortion. Existing green/yellow/red thresholds remain 90% / 70%.

Samples now retain native cumulative damage alongside kills. Missing or reset damage, gaps and old kill-only history do not become fabricated DPS; the indicator explicitly falls back to kills only. Hover shows current/reference kills, current/reference recent DPS, sample count and weighting. Victory snapshots retain the new samples without changing their fixed result. Reference review confirms SurvivorUI uses rolling kill rate and boss stretches, not DPS; this calculation is original.

### 1.3.0 (2026-10-18)

Victory creates an immediate, separate snapshot with fixed win time, identity, progress samples and available run totals. Unsignaled post-win packets cannot extend the recorded result. Only the game's explicit endless flag permits a separate total-duration extension; victory time and victory totals stay fixed. Up to 40 snapshots are kept. `/kui runs check` distinguishes a newly captured receipt from one actually loaded back from saved data. A read-only checker and a menu/exit/restart test procedure accompany the change; there is no claim of an immediate disk flush through the addon API.

Optional Pace in Display compares kill progress against the median of up to 30 matching previous runs at the same run time, with identical class, zone, difficulty and modifiers. Good is green from 90%, Slow yellow from 70%, Very slow red below 70%; absent references and endless mode stay neutral. Existing aggregate-only history is not turned into invented progress samples.

Defeated bosses receive a subtle background behind their times: green below 1:30, yellow through 3:00, red above. Final bosses initially receive 50% more time (2:15 / 4:30). Missing historical death times remain neutral. Existing frame colors and thin/off headers are retained.

### 1.2.4 (2026-10-18)

Run messages confirm a win immediately after its overview entry is written and checked; other completed runs are confirmed at their end. Messages include zone, class, race and time. Runs shorter than 90 seconds without a win explicitly report that they were not counted. Repeated packets and reloads do not repeat the confirmation. Continuing after a win reports the final updated duration without counting another win. A missing or unconfirmed entry receives no success message. These messages follow the existing Run message setting.

### 1.2.3 (2026-10-18)

Settings always open on Display at the top of the page, including after using another category or reloading the interface.

### 1.2.2 (2026-10-18)

Run recording processes incoming run and zone messages directly, independently of HUD updates and native API listener order. Victory phase is recognized even without a numeric won flag; a win in the last death message is credited before closing the run. Win time and last-run values are stored immediately, including when returning directly to the menu. Repeated victory messages, reloads and endless continuation retain a single run and win.

Character identity prefers the run's own class, race and hero metadata. Restart detection uses reported run time so delayed packets do not create extra runs through clock interpolation. A bounded diagnostic trail keeps recent recording transitions; `/kui runs debug` includes the win flag and recent decisions. Existing history is retained.

### 1.2.1 (2026-10-18)

Settings open at 80% size by default; Layout offers 70–100% menu scaling. Layout mode shows movement instructions and can be closed with its Done button or Escape. Attached class resources are centered below the entire player frame. The critical-hit panel no longer shows the interface-load caption and uses less vertical space.

Combat preview now animates labeled normal hits, critical hits and two area hits using the live combat-text presentation rules. Style, spell icons and merging update immediately. Off and Game modes show their actual status; spell icons apply to Scrolling style. Sample hits stay inside settings and do not enter combat statistics.

### 1.2.0 (2026-10-18)

New settings based on the approved left navigation design: Display, Combat, Units, Controls, Layout and General. Explicit checkboxes and choice menus replace cycling text rows; only the content area scrolls. The window fits smaller viewports and keeps saved category and position. Character-attribute selection and local previews remain usable while the corresponding HUD display is off. Existing setting keys, frame layouts, commands and native auto-run bindings are retained.

Optional cursor ring (off by default), with size and color selection, follows the native cursor without intercepting input. Optional character attributes (off by default) show selected native values; unknown or stale-after-new-run values are shown as unknown until a new report arrives. The pace indicator is labeled as a future feature, with no simulated rating.

### 1.1.1 (2026-10-17, release v1.1.1)

Run timeline: border, fill and boss checkpoints now share the display pixel grid, including fractional UI scaling and moved panels. The top and bottom border use the same thickness, all checkpoints have equal widths and symmetric clearances. The fill follows the inner chamfer without crossing the border. Bronze coloring is retained.

Thin section headers: titles are vertically centered in the header strip while retaining their left alignment and existing content spacing.

### 1.1.0 (2026-10-17)

Run tracker: the progress bar uses the same complete chamfered border as the other bars. Boss checkpoints have dark outlines and a brighter green for defeated bosses, which is also used on the boss rows.

Combat text: the full text and icon footprint is kept clear of player, target, skills, counters and class resources throughout the animation, including moving nameplates and the largest crit pop. Text is drawn behind the HUD. Bursts of the same ability and damage kind within 0.12 seconds are summed as total damage and hit count (for example `200 x20`); crits, periodic hits and different abilities remain separate. Toggle merging in Settings, Controls.

Target debuffs appear both below the target frame and on its nameplate by default. Settings, Controls, Debuffs in both places restores the previous nameplate-first behavior when switched off. The four HUD panels (run tracker, statistics, damage and crits) have Normal, Thin and Off header modes; content moves up and panels become shorter without resetting saved positions. Dialogs retain their headers and the meter Reset button remains available.

Settings gain a Controls tab. Auto run can be assigned to a key, modifier combination, mouse button (including mouse button 5) or wheel using the client's native TOGGLEAUTORUN binding. An occupied key requires a second press before replacement; Escape cancels. Removing or changing the custom binding restores its earlier action only while the addon still owns the key. Other native auto-run keys remain unchanged, and loading the addon never edits bindings.

### 1.0.3 (2026-10-17, release v1.0.3)

Minimap: a clock (hours and minutes) in UTC plus the time zone set in Settings, General, "Clock time zone" (left click one hour later, right click one hour earlier; the game reports the system time only as UTC and the server time is not the local time) at the top right of the minimap panel, on the line of the zone name.

Run overview: the progress bar under the run time shows a thin checkpoint mark at the spawn time of every scheduled boss before the final boss, colored like its row (upcoming light, up orange, defeated green).

### 1.0.2 (2026-10-17, release v1.0.2)

Run overview window: the race follows the interface language. The game names the race in English even in a German client ("Paladin, Dwarf"); German now shows "Paladin, Zwerg".

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

### 2.2.0 (2026-10-18, Release v2.2.0)

* **Beuteliste.** Neue Auswahl unter Einstellungen, Anzeige, Beute: "Meldung" (Standard, wie bisher), "Liste", "Liste klein" oder "Nur Symbole". Die Liste sammelt die Gegenstände des laufenden Runs im Beute-Panel, neueste oben, mit Symbol, Name in Qualitätsfarbe, Platz und Runzeit beim Erhalt sowie dem Hinweis "Neu" (grün) oder "Gesammelt" (grau). Bis zu 8 Zeilen sind sichtbar, das Mausrad blättert, der Mauszeiger zeigt den Gegenstands-Tooltip. Die kleine Liste ist eine kompakte Zeilenliste (kleines Symbol, kleine Schrift, Status, 12 Zeilen). "Nur Symbole" zeigt Symbole in einem Raster mit Qualitätsrahmen, einem grünen Haken für neue und einem roten X für bereits gesammelte Gegenstände sowie einem Tooltip mit Name und Status. Ein Neuladen behält die Liste desselben Runs, ein neuer Run leert sie.
* **Nur neuer Loot.** Neuer Schalter: nur Gegenstände anzeigen, die neu in deiner Sammlung sind. KeijinUI liest das aus der Beutezeile des Spiels, die bekannte Gegenstände mit "(bereits gesammelt)" kennzeichnet. Er gilt für alle vier Anzeigen.
* **Beute-Schalter.** Neue Schalter "Symbole" (blendet die Symbole in Liste und Liste klein aus, der Text rückt nach links) und "Sammelstatus anzeigen" (blendet Neu/Gesammelt bzw. Haken/X aus). Beide sind standardmäßig an und ausgegraut, wo sie nichts bewirken. Der Hilfetext im Abschnitt Beute ist kürzer und wird nicht mehr abgeschnitten.
* **Nach oben wachsen.** Neue Auswahl unter Einstellungen, Anzeige, Beute: "Wachstum", "Nach unten" (Standard, wie bisher) oder "Nach oben". Nach oben setzt den Titel des Beutefensters nach unten und die neueste Beute direkt darüber; ältere Einträge wandern nach oben und die Symbolansicht füllt sich von unten. Der untere Rand bleibt beim Wachsen fest, das Fenster lässt sich also am unteren Bildschirmrand anheften. Das Mausrad blättert nach oben zu älteren Einträgen, schmale oder ausgeblendete Titel funktionieren auch dort. Beim Umschalten bleibt das Fenster an seiner Stelle auf dem Bildschirm.
* **Befehle.** `/kui loot clear` leert die Liste, `/kui loot debug` zeigt Modus und Einträge.
* **Beute folgt den Abschnittstiteln.** Die Einstellung Abschnittstitel normal, schmal oder aus gilt jetzt auch für das Beutefenster; Liste und Symbole rücken mit nach oben.

### 2.1.0 (2026-10-18, Release v2.1.0)

* **Verschiebbarer Kampftext.** Die schwebenden Schadenszahlen starten in einem unsichtbaren Anker. Mit Alt wird er sichtbar und verschiebbar, Alt und Mausrad ändern die Zahlengröße. Neue Auswahl unter Einstellungen, Kampf: Position "Am Gegner" (Standard, unverändert: Zahlen steigen über der Namensplakette) oder "Feste Stelle" (alle Zahlen starten im Anker und folgen keiner Plakette). Ohne Plakette starten die Zahlen jetzt im Anker statt in der Bildschirmmitte; der Anker liegt an der alten Stelle, bis du ihn verschiebst.
* **Bossschaden.** Die Schadensanzeige hat zwei Reiter, Run und Boss. Boss listet den Schaden am Boss im letzten Bosskampf mit Gesamtschaden und DPS je Quelle und zeigt "läuft", solange ein Boss lebt. Reset gilt nur im Reiter Run. Neue Option unter Einstellungen, Kampf: automatisch auf Boss umschalten, solange ein Boss lebt, und danach zurück (standardmäßig aus; deine eigene Reiterwahl hat immer Vorrang).
* **Stil Aufsteigend.** Neuer Stil für Schadenszahlen: Die Zahlen steigen senkrecht nach oben und blenden langsam aus, kompakter als Scrollend, mit Schulfarben und Zaubersymbolen.
* **Nur für eigene Zahlen.** Position, Zaubersymbole und Bündeln gelten nur für die Stile Kompakt, Scrollend und Aufsteigend. Im Stil Spiel zeichnet das Spiel die Zahlen selbst und kein Addon kann sie verschieben; diese Optionen sind dann ausgegraut und ein Hinweis nennt den Grund.

### 2.0.1 (2026-10-18, Release v2.0.1)

* Ein Lag löscht keine Bosszeiten, Heilung und kritischen Treffer mehr. Die Erkennung eines neuen Runs nutzt jetzt die vom Spiel gemeldete Runzeit und erlaubt 3 Sekunden Rücksprung, wie es die Rundenübersicht bereits tat.
* Pace behält den Vergleich nach einem Reload mitten im Run, wenn das Spiel die Zonendaten nicht erneut sendet.
* `/kui pace debug` zeigt den Vergleichsschlüssel des laufenden Runs und der gespeicherten Runs.

### 2.0.0 (2026-10-18, Release v2.0.0)

Das bisher größte Update. Das Wichtigste:

* **Neues Optionsfenster.** Übersichtliche Seiten links (Anzeige, Kampf, Einheiten, Bedienung, Layout, Allgemein), echte Checkboxen und eine Livevorschau der Kampfzahlen.
* **Deine Siege sind sicher.** Ein Sieg wird sofort gespeichert, auch wenn du direkt ins Menü zurückgehst. Endlos verändert deine Siegzeit nicht mehr, und sehr kurze Runs zählen nicht mehr.
* **Pace.** Zeigt während des Runs, ob du schneller oder langsamer bist als in deinen früheren Runs mit derselben Klasse und Zone (grün, gelb, rot). Auch die Bosszeiten bekommen Farben.
* **Caches.** Statt einer geschätzten Zeit siehst du jetzt, wie viel Gold dir für den nächsten Cache noch fehlt: rot, gelb oder grün, sobald du ihn öffnen kannst.
* **Neue optionale Anzeigen.** Ein Cursorring und eine kompakte Tafel mit deinen Charakterwerten (Krit, Tempo, Lebensraub und mehr). Beide sind standardmäßig aus.
* Schamanen erscheinen überall blau, dazu viele kleine Korrekturen.

Die ausführlichen Notizen der Teststände 1.2.0 bis 1.3.4 stehen darunter.

### 1.3.4 (2026-10-18)

Schamanen erscheinen in der Rundenübersicht und in der Startmeldung eines Laufs dunkelblau statt im Paladin Rosa der Klassenfarbtabelle von 1.12, passend zu Spieler und Zielrahmen. Eine gemeinsame Klassenfarbfunktion bedient jetzt alle drei Stellen.

### 1.3.3 (2026-10-18)

Die Zählerzeile schätzt nicht mehr die Zeit, bis der nächste Cache bezahlbar ist. Sie zeigt stattdessen das noch fehlende Gold für den nächsten Cache (nie unter null, „Bereit“, sobald genug Gold da ist) und aktualisiert sich mit Gold und Preis. Farbe: Grün, wenn bezahlbar, Gelb, wenn höchstens 25% des Cachepreises fehlen, Rot, wenn mehr fehlt. Die Grenze von 25% ist ein Startwert für die Prüfung im Spiel.

### 1.3.2 (2026-10-18)

Pace ist standardmäßig eingeschaltet, wenn noch keine Auswahl gespeichert wurde. Unter Anzeige bleibt es abschaltbar; eine ausdrücklich gespeicherte Deaktivierung bleibt bei Updates und Neuladen erhalten. Vergleich, Gewichtung und neutrale Zustände bleiben unverändert.

### 1.3.1 (2026-10-18)

Pace kombiniert jetzt Gegnerfortschritt (70%) mit Schaden pro Sekunde über die letzten 30 nativen Spielsekunden (30%). Verglichen werden derselbe Zeitpunkt und dasselbe Zeitfenster mit dem Median passender früherer Runden. Beide Anteile verwenden dieselben Vergleichsrunden; Klasse, Zone, Schwierigkeit und Modifikatoren müssen übereinstimmen. Der DPS Beitrag ist bei 150% seines Vergleichswerts begrenzt, damit einzelne Schadensspitzen weniger verzerren. Die Grenzen für Grün, Gelb und Rot bleiben bei 90% / 70%.

Fortschrittsproben enthalten jetzt neben Kills auch den nativen Gesamtschaden. Fehlender oder zurückgesetzter Schaden, Datenlücken und alte reine Killdaten werden nicht zu erfundenen DPS; der Indikator kennzeichnet den Rückfall auf reine Gegnerdaten. Der Tooltip zeigt aktuelle und historische Kills, aktuelle und historische DPS, Anzahl der Vergleichsrunden und Gewichtung. Sieg Snapshots behalten die neuen Proben bei unverändert festem Ergebnis. Die Quellenprüfung bestätigt: SurvivorUI verwendet eine gleitende Killrate und Bossabschnitte, keine DPS. Unsere Berechnung ist eigenständig.

### 1.3.0 (2026-10-18)

Ein Sieg erzeugt sofort einen eigenen Snapshot mit fester Siegzeit, Identität, Fortschrittsproben und verfügbaren Rundensummen. Spätere Meldungen ohne Endlossignal verlängern das Ergebnis nicht. Erst das ausdrückliche Endlosfeld des Spiels erlaubt eine gesonderte Gesamtzeit; Siegzeit und Siegwerte bleiben unverändert. Bis zu 40 Snapshots bleiben erhalten. `/kui runs check` unterscheidet einen gerade erfassten Stand von einem tatsächlich wieder aus gespeicherten Daten geladenen Stand. Eine Dateiprüfung und ein Testablauf für Menü, Beenden und Neustart liegen bei. Ein sofortiges Schreiben auf den Datenträger durch die Addon API wird nicht behauptet.

Der optionale Pace Indikator unter Anzeige vergleicht den Gegnerfortschritt zur gleichen Runzeit mit dem Median von bis zu 30 passenden vorherigen Runden derselben Klasse, Zone, Schwierigkeit und Modifikatoren. Gut ist ab 90% grün, Langsam ab 70% gelb und Sehr langsam darunter rot; fehlende Vergleichsdaten und Endlos bleiben neutral. Aus alten reinen Rundensummen werden keine Fortschrittsdaten erfunden.

Besiegte Bosse bekommen einen dezenten Hintergrund hinter ihren Zeiten: grün unter 1:30, gelb bis einschließlich 3:00, darüber rot. Für Endbosse gelten zunächst 50% längere Grenzen (2:15 / 4:30). Unbekannte historische Todeszeiten bleiben neutral. Bestehende Rahmenfarben und schmale oder ausgeblendete Titel bleiben erhalten.

### 1.2.4 (2026-10-18)

Run Meldungen bestätigen einen Sieg sofort nach dem Schreiben und Prüfen des Eintrags in der Rundenübersicht; andere abgeschlossene Runden werden am Ende bestätigt. Die Nachricht nennt Zone, Klasse, Volk und Zeit. Runden unter 90 Sekunden ohne Sieg melden ausdrücklich, dass sie nicht gezählt wurden. Wiederholte Spielmeldungen und Neuladen erzeugen keine doppelte Bestätigung. Wird nach einem Sieg weitergespielt, meldet das Ende die aktualisierte Dauer, ohne einen zweiten Sieg zu zählen. Bei fehlendem oder nicht bestätigtem Eintrag erscheint keine Erfolgsmeldung. Die Nachrichten beachten die bestehende Einstellung Run Meldung.

### 1.2.3 (2026-10-18)

Die Einstellungen öffnen immer auf Anzeige am Seitenanfang, auch nach dem Besuch einer anderen Kategorie oder dem Neuladen der Oberfläche.

### 1.2.2 (2026-10-18)

Die Rundenerfassung verarbeitet eingehende Runden und Zonenmeldungen direkt, unabhängig von HUD Aktualisierungen und der Reihenfolge der nativen API Listener. Die Siegphase zählt auch ohne numerische Siegkennung; ein Sieg in der letzten Todesmeldung wird vor dem Abschließen verbucht. Siegzeit und letzte Rundenwerte werden sofort gespeichert, auch beim direkten Wechsel ins Menü. Wiederholte Siegmeldungen, Neuladen und anschließendes Endlosspiel bleiben eine Runde mit einem Sieg.

Klasse, Volk und Held stammen bevorzugt aus den Daten der Runde. Die Neustarterkennung verwendet die gemeldete Rundenzeit, damit verspätete Meldungen durch eine weitergelaufene Anzeigeuhr keine zusätzlichen Runden erzeugen. Ein begrenztes Diagnoseprotokoll hält die letzten Übergänge fest; `/kui runs debug` zeigt auch die Siegkennung und die letzten Entscheidungen. Die bestehende Historie bleibt erhalten.

### 1.2.1 (2026-10-18)

Die Einstellungen öffnen standardmäßig mit 80% Größe; unter Layout lässt sich die Menügröße zwischen 70 und 100% wählen. Der Layoutmodus zeigt Bedienhinweise und lässt sich über Fertig oder Escape beenden. Angeheftete Klassenressourcen sitzen mittig unter dem gesamten Spielerrahmen. Im Kritfenster entfällt der Hinweis zum Laden der Oberfläche samt überflüssigem Platz.

Die Kampfvorschau animiert beschriftete normale Treffer, kritische Treffer und zwei Flächentreffer mit denselben Darstellungsregeln wie der Kampftext. Stil, Zaubersymbole und Bündelung reagieren sofort. Aus und Spiel zeigen ihren tatsächlichen Status; Zaubersymbole gehören zum scrollenden Stil. Die Beispieltreffer bleiben innerhalb der Einstellungen und fließen nicht in die Kampfstatistik ein.

### 1.2.0 (2026-10-18)

Neue Einstellungen nach dem abgestimmten Entwurf mit linker Navigation: Anzeige, Kampf, Einheiten, Bedienung, Layout und Allgemein. Klare Checkboxen und Auswahlmenüs ersetzen durchschaltbare Textzeilen; nur der Inhaltsbereich scrollt. Das Fenster passt sich kleineren Auflösungen an und merkt Kategorie und Position. Werteauswahl und lokale Vorschauen bleiben auch bei ausgeschalteter HUD Anzeige nutzbar. Bestehende Einstellungsschlüssel, Rahmenpositionen, Befehle und native Laufbelegungen bleiben erhalten.

Optionaler Cursorring (standardmäßig aus) mit Größenwahl und Farbe folgt dem nativen Cursor, ohne Eingaben abzufangen. Optionale Charakterwerte (standardmäßig aus) zeigen ausgewählte native Werte; fehlende oder nach einem Runwechsel veraltete Werte bleiben bis zur neuen Meldung unbekannt. Der Pace-Indikator ist als künftige Funktion gekennzeichnet, ohne vorgetäuschte Bewertung.

### 1.1.1 (2026-10-17, Release v1.1.1)

Rundenfortschritt: Rahmen, Fuellung und Bossmarkierungen liegen auch bei ungerader UI Skalierung und verschobenen Fenstern auf demselben Bildschirmraster. Oberer und unterer Rand sind gleich dick, alle Markierungen gleich breit und mit symmetrischen Abstaenden versehen. Die Fuellung folgt der inneren Abschraegung ohne den Rand zu beruehren. Der Bronzeton bleibt erhalten.

Schmale Abschnittstitel sitzen vertikal mittig im Titelstreifen. Linke Ausrichtung und Inhaltsabstaende bleiben erhalten.

### 1.1.0 (2026-10-17)

Rundentracker: Der Fortschrittsbalken verwendet denselben vollstaendigen abgeschraegten Rand wie die anderen Balken. Bossmarkierungen erhalten eine dunkle Kontur und fuer besiegte Bosse ein helleres Gruen, das auch in den Bosszeilen verwendet wird.

Kampftext: Die vollstaendige Text und Symbolflaeche haelt waehrend der gesamten Animation Abstand zu Spieler, Ziel, Aktionsleiste, Zaehlern und Klassenressourcen, auch bei bewegten Namensplaketten und vergroesserten Krits. Die Zahlen liegen hinter dem HUD. Treffer derselben Faehigkeit und Schadensart innerhalb von 0,12 Sekunden werden als Gesamtschaden mit Trefferzahl gebuendelt, zum Beispiel `200 x20`. Krits, periodische Treffer und andere Faehigkeiten bleiben getrennt. Die Buendelung ist unter Einstellungen, Bedienung abschaltbar.

Debuffs erscheinen standardmaessig gleichzeitig unter dem Zielframe und an seiner Namensplakette. Einstellungen, Bedienung, Debuffs an beiden Stellen stellt ausgeschaltet das bisherige Verhalten wieder her. Die vier HUD Anzeigen Runuebersicht, Statistik, Schaden und Krits bieten normale, schmale oder ausgeblendete Titel. Inhalt und Hoehe werden angepasst, gespeicherte Positionen bleiben erhalten. Dialoge behalten ihre Titel und Reset der Schadensanzeige bleibt erreichbar.

Neuer Tab Bedienung in den Einstellungen. Automatisches Laufen wird ueber die native TOGGLEAUTORUN Belegung einer Taste, Tastenkombination, Maustaste einschliesslich Maustaste 5 oder dem Mausrad zugewiesen. Belegte Tasten muessen zum Ersetzen zweimal gedrueckt werden; Escape bricht ab. Entfernen oder Wechseln stellt die vorherige Aktion nur wieder her, solange die eigene Belegung noch besteht. Andere native Lauftasten bleiben erhalten. Beim Laden werden keine Tastenbelegungen veraendert.

### 1.0.3 (2026-10-17, Release v1.0.3)

Minimap: Eine Uhr (Stunden und Minuten) in UTC plus der Zeitzone aus Einstellungen, Allgemein, "Zeitzone der Uhr" (Linksklick eine Stunde später, Rechtsklick eine früher; die Systemzeit liefert das Spiel nur als UTC, die Serverzeit ist nicht die Ortszeit) oben rechts im Minimap Feld, in der Zeile des Zonennamens.

Runübersicht: Der Fortschrittsbalken unter der Runzeit zeigt bei der Erscheinungszeit jedes geplanten Bosses vor dem Endboss einen schmalen Strich, gefärbt wie seine Zeile (kommend hell, aktiv orange, besiegt grün).

### 1.0.2 (2026-10-17, Release v1.0.2)

Fenster Rundenübersicht: Das Volk folgt der Sprache der Oberfläche. Das Spiel nennt das Volk auch im deutschen Client englisch ("Paladin, Dwarf"); auf Deutsch steht jetzt "Paladin, Zwerg".

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
