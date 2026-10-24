# KeijinUI Changelog

Patch notes for KeijinUI (Modern AS UI), newest first. English first, [Deutsch below](#deutsch).
Every version that is uploaded to GitHub gets its entry here before the upload.

## English

### 4.0.2 (2026-10-24, release v4.0.2)

* **Chat window size (issue #1):** the General tab keeps its native fade and right click menu. Unlock the chat through the tab, then drag an edge or the new small grip at the bottom right to change its width and height. The frame and background follow the size immediately while dragging, and resizing ends when the mouse button is released. The size and position survive a reload; Alt and the mouse wheel still change the scale. The jump to newest button sits beside the grip.

### 4.0.1 (2026-10-24, release v4.0.1)

* **Party window follows the header style:** with section titles set to small or off, the party window's header now shrinks or disappears like the other windows, and the window gets shorter accordingly.

### 4.0.0 (2026-10-24, release v4.0.0)

* **All game languages:** besides English, German and Simplified Chinese, KeijinUI can now be shown in French, Spanish, Portuguese, Polish, Czech, Romanian, Turkish, Russian, Ukrainian, Japanese and Korean. Choose it under General, Language, or with `/kui lang <code>`. Ability names follow the game's own translations (Turkish keeps the English names, as the game does).
* **Machine translated:** only English and German are checked by hand. All other languages are machine translated and not yet reviewed by native speakers; please report wrong or cut off texts with a screenshot.
* **Fonts:** French, Spanish and Portuguese use the game's font. Polish, Czech, Romanian, Turkish, Russian, Ukrainian, Chinese, Japanese and Korean use the bundled font, also in tooltips and chat. Romanian uses ş and ţ with a cedilla, because the font has no comma below t.
* **Run count in other languages:** the message "This is your ... run" shows the plain number instead of an English ending like 3rd.
* **Co-op (requested by Bersh, Shandrax and Mr8endiix):** the damage meter has a new Party tab with the damage and DPS of every hero in your party (class colours, your own hero framed, strongest spell in the tooltip). A new party window shows up to four teammates with health, offline and downed status and the revive progress, and how far your own revive has come while you are down. Move it with Alt, resize with Alt and the mouse wheel; it can be switched off under Modules. `/kui party debug` lists what the game reports for the party. Not yet tested in a real co-op run: please report what you see.

### 3.7.1 (2026-10-23, release v3.7.1)

* **Cooldown on the icon (requested by JayMasta):** the build overview now shows each spell's cooldown in this run in a dark, chamfered tab docked to the top of its icon, in seconds (two decimals below 1 s, one decimal below 10 s). Values below one second are gold. The window grows a few pixels upwards for it (downwards only while it is attached below another window) and returns to its original size when the option is off. Its bottom edge now stays in place, also when a second spell row appears; saved positions are taken over without a jump. That way you see at a glance how low a cooldown already is, without hovering. Switch: Layout & Display, "Cooldown on the icon". It is on by default.
* **Active cooldowns only removed:** the option "Active cooldowns only" for the action bar is gone. The new number on the icon replaces it, and the action bar always shows all spells again.
* **Chinese font in tooltips and chat:** with the Chinese interface, the game's tooltips (title, text and small text) and the chat now use the bundled CJK font too, so KeijinUI messages and Chinese names are readable there.
* **Short damage summary is back:** with section titles switched off, the Run damage summary shows the short form again (total and DPS) instead of the long text.

### 3.7.0-beta.1 (2026-10-23, release v3.7.0-beta.1)

* **Build panel position:** dragging the panel, its icons or its advice area now uses the same saved layout as the layout handle. The saved edge stays fixed when the panel changes height, and releasing Alt completes the move even if a drag-stop event is missed.
* **DPS:** the Run damage meter now shows damage per second over the last 10 run seconds, excluding pauses. Total damage, bars and ordering still cover the run or the period since Reset. The tooltip keeps average DPS; the Boss and Healing tabs keep their native fight or run averages. Measurement starts with fresh observations and restarts after missing reports.
* **Endless bosses:** the run overview shows the game's countdown to the next endless boss instead of keeping the finished normal boss schedule on screen. Missing countdowns show a question mark.
* **Account pace:** an optional second pace line compares all locally recorded classes under the same zone, difficulty and modifiers. Class pace remains separate. Up to 120 reference runs are kept; existing recorded samples can be used immediately.
* **Guardian return timers:** optional countdowns below lair markers on the minimap use the same return data as the run overview. Stale data shows a question mark. Enabled by default, with a switch under Guardians.
* **Active cooldowns:** the existing action bar can show only spells with a running cooldown, hiding the bar while all spells are ready. The full action bar remains the default.
* **Simplified Chinese:** choose 简体中文 in General or use `/kui lang zh`. Adds translated interface texts and ability names from game data, with a bundled CJK and Latin font. Unrecognized names stay as supplied by the game. Chinese wording and the new displays still need in-game validation.

### 3.6.1 (2026-10-23, release v3.6.1)

* **Tooltips for abilities outside the spellbook:** abilities that have no spellbook entry, such as **Call of Flame**, now show the game's own description when you hover them in the spell list. KeijinUI finds the matching action slot by name in every game language.
* **Talent icons for game 0.112:** the talent list moved inside the game data. KeijinUI reads it again and the damage meter shows icons for new talents such as **Trauma** and **Bloodlust**, with updated names in all game languages.

### 3.6.0 (2026-10-22, release v3.6.0)

* **Summons bar:** a new bar shows your active summons, for every class: a Warlock's demons (Imp, Felguard, Infernals and the rest), a Hunter's beast, Druid Treants, Spirit Wolves and the Water Elemental. Each kind gets one icon with the count at the bottom right (from 2) and the time left of the first one to go below it; permanent summons show no time. Hover an icon for name, count, how many are permanent or timed and when the next one ends. It shows during a run only and needs game 0.110 or newer (older versions simply show nothing). Hold Alt to move it, Alt and mouse wheel to resize; it can be switched off as the new module **Summons**. Asked for by Bersh.
* **Damage number size slider:** a slider in the Combat settings (50 to 200 percent) sets the font size of the floating damage numbers. Only the text grows or shrinks; the combat text anchor and its Alt mouse wheel scale stay as they are. The preview follows it.
* **Absorb shield on your health bar:** a light, translucent layer shows your absorb shield from your current health to the right. Beyond your maximum health it is cut off at the bar end and a bright edge marks the overflow. The health text adds the shield as +x.
* **Blue and green lair skulls easier to tell apart:** the blue skull is now a deeper, more saturated blue and the green one a yellow green.

### 3.5.6 (2026-10-22, release v3.5.6)

* **Spell tooltips for new spells:** some spells, such as **Demonic Empowerment**, **Penance** and the hunter traps, are listed in your spellbook under another name. The spell list now also looks for them there, so hovering them can show the game's description like other spells. Demonic Empowerment also uses the game's own icon now.

### 3.5.5 (2026-10-22, release v3.5.5)

* **Build tips in every game language:** the damage upgrades of your spells are now read in all languages the game offers, not just English and German, so the build tips work the same in Russian, Polish, French, Chinese and the others.
* **New spells in the spell list:** spells added by a game patch, such as **Demonic Empowerment** or the druid's **Shred**, now show their icon and proper name instead of a question mark.
* **More accurate build tips:** an upgrade that gives damage reduction is no longer counted as extra damage.

### 3.5.4 (2026-10-22, release v3.5.4)

* **Class resources read the game's own count:** soul shards, combo points and Bloodrage now show exactly what the game counts, instead of being worked out from your mana or energy. A soul shard only counts once it is full.
* **Warlock demons in the damage meter:** the Imp, Felhunter, Voidwalker, Succubus, Infernal, Doomguard, Felguard and Pit Lord now show their own icon in the damage meter, the **Biggest critical hits** window and the floating damage numbers. Their attacks Firebolt, Felseeker, Doom Bringer and Brutal Momentum and the spell Demonic Empowerment have icons too, in every game language.

### 3.5.3 (2026-10-21, release v3.5.3)

* **Damage meter icons in every game language:** spell, ability and talent icons now also appear when the game runs in Russian, Ukrainian, Polish, French, Spanish, Portuguese, Czech, Romanian, Turkish, Chinese, Japanese or Korean. Before, only English and German names found their icon. A few names that stand for two different abilities in one language stay without an icon.

### 3.5.2 (2026-10-21, release v3.5.2)

* **Item icons in the damage meter:** damage that comes from one of your items now shows the icon of that item next to its name, in the damage meter, the **Biggest critical hits** window and the floating damage numbers. The icon stays even after the item is taken off, for example after death or victory. Sources without a known icon keep an empty space.
* **Talent icons in the damage meter:** damage from talents, for example **Seal of Command**, now shows the talent's icon as well. KeijinUI knows the icons of all talents of every class in English and German.

### 3.5.1 (2026-10-21, release v3.5.1)

* **Spell icons in the damage meter (new, requested by the community):** the damage meter can now show the icon of each spell next to its name, in the Run, Boss and Healing views and in the **Biggest critical hits** window. Melee shows your weapon. Switch it on with `/kui`, Combat, Damage meter, **Show spell icons**. It starts switched off, so nothing changes until you turn it on.
* **Loot list hides while empty:** in the list and icon modes the loot window now only appears once you have looted something in the run, instead of showing "No loot in this run yet". Hold Alt or use the layout editor to see and move it while it is empty.

### 3.5.0 (2026-10-21, release v3.5.0)

* **Lair markers (new):** every guardian lair now has its own symbol for the whole run. You see the same symbol on the minimap and in front of the guardian's name in the run overview, so you always know which lair is which, no matter how the list is sorted or how far away a lair is.
* **Five styles to choose from.** The default is **Coloured skulls with number**: the familiar boss skull in six colours, each with its lair number. The alternatives are **Creatures** (six small skulls of an orc, troll, tauren, dragon, demon and undead), **Raid markers** (star, circle, diamond, triangle, moon, square, shown freely without a plate), **Seals with number** and **Classic** (the plain gold, orange and grey skull as before).
* **Status at a glance:** a lair in combat shows a small **!**, an empty lair is dimmed and shows a small **x**. A waiting lair still tells you when it is due in the run overview.
* **Where to change it:** open `/kui`, go to Layout & Display, Guardians, and pick the style under **Lair markers**. The change shows immediately on the minimap and in the run overview.
* **Lair marker size:** a new slider below the marker style sets minimap markers from 50 to 200 percent (default 100). Numbers and status badges scale with them, with room at the map edge and fading near your player arrow. The small symbols in the run overview keep their size.
* The switch **Lair markers instead of game flag** (formerly "Guardian skulls instead of game flag") turns all of this off at once. Then the run overview looks exactly as before and the game's own flag stays.
* The settings search finds the new option with words like "marker", "raid marker", "skull" or "creatures".
* **Smoother minimap symbols:** guardian lair markers and cache chests now glide along with the map while you run, instead of stuttering slightly.
* **Your player arrow is easier to see:** markers and chests close to the middle of the minimap turn see-through, so they cover your arrow much less.
* **Unit frames stay put when you switch portraits:** turning **Show portraits** on or off no longer shifts your frames. Your player frame keeps the right end of its health bar in place and the target frame the left end, so only the portrait appears or disappears. Positions you saved earlier are taken over without a jump.
* **Class resources sit right under your health bar:** with **Attached to player** the resource bar is now centred directly below the health bar, with and without portraits. In this mode it moves together with your player frame and can no longer be dragged on its own. Choose **Free** under resource position if you want to place it yourself.
* **Free slots in the spell and item list:** the list now shows how much room is left. Empty spell slots appear as blank fields, empty item slots show a small neck, ring or trinket symbol, and hovering them names the free slot.

### 3.4.2 (2026-10-20, release v3.4.2)

* **Cache icon size (new, requested by the community):** you can now choose how big the chest symbols on the minimap are. Open `/kui`, go to Layout & Display, Caches, and move the new **Cache icon size** slider anywhere from 50 to 200 percent. 100 percent is the size you know, so nothing changes until you move it.
* Bigger chests are easier to spot in the middle of a fight, smaller ones keep a crowded minimap tidy.
* Large symbols always stay fully on the minimap. If a chest sits too close to the edge for its symbol, the edge arrow points to it instead.
* The slider works while **Cache icons** is switched on.
* Prefer the chat? `/kui caches size 150` sets the same value (50 to 200).
* The settings search finds the slider with words like "chest size", "cache icon size" or "minimap".

### 3.4.1 (2026-10-20, release v3.4.1)

* **Action bar cooldowns:** now run clockwise by default, like the game's standard action buttons. The previous shade from top to bottom can be chosen again under Frames, Cooldown. The remaining time as a number stays.
* The action bar help text now describes the current rule: when one of our windows is off, the game's matching one appears.

### 3.4.0 (2026-10-20, release v3.4.0)

* **Minimap button:** middle click reloads the UI.
* **Show portraits off now gives a compact frame:** instead of the dark circle, player and target show their own closed frame without portrait (170 wide, 48 high), with the same gradient, class colours, elite and rare marks, tooltip and background opacity. Switching acts at once, positions, sizes and docking are kept, class resources and target debuffs follow the new lower edge, and the 30 percent marker moves to the new bar. This delivers what 3.3.0 announced; the default (portraits on) is unchanged.
* **Core and modules:** the settings now separate what always belongs to KeijinUI (core) from features you can switch off (modules). The new **Modules** page in the sidebar lists 13 modules, each with a short description of what it does and what you get when it is off: Combat text, Nameplates, Minimap, Caches, Guardians, Run analysis, Character attributes, Loot, Jewelry collection, Build tips, Stored levels, Achievement alerts and Input aids (cursor tracker and auto run key).
* **A module that is off is really off:** its scripts stop, its settings disappear from every page, from the sidebar links and from the settings search (searching "cache" with Caches off shows the Caches module switch instead), and the rows below move up. Where the game has its own version it comes back: combat text, nameplates, minimap (at the game's own size and place, without the minimap button; `/kui` still works), the red guardian flag, the loot notice and the normal level choice. Switching acts at once; after switching the minimap off or on, reload if something stays behind (the page has a button).
* **All modules are on by default.** Your saved settings are never reset. Modules you had switched off before stay off: the merged modules keep that state (Damage numbers and Healing text became Combat text, Guardian navigation became Guardians, Cursor tracker became Input aids, Jewelry cooldowns joined the Jewelry collection, XP and extra resources became Run analysis). Build tips and achievement alerts you had turned off stay off.
* **Frames:** the section "Run displays" is now called **Frames** and only holds the core windows to show or hide. **Spells & jewelry** and **Action bar** are two separate switches now (before, one switch did both); if you had the bar off, both stay off. `/kbb` still switches both together. Every window with a game counterpart follows one rule: ours on, the game's hidden; ours off, the game's shown, even if it was hidden before. Spells & jewelry pairs with the game's spell and jewelry rows, Action bar with the game's action bar, and likewise Kills and gold, Damage meter, Encounters and Run overview (run clock).
* **Module settings moved into their module:** guardians in the run overview, Pace indicator, lives and rerolls and XP rate sit with their module (Guardians, Run analysis). The old section "Spells & items" is gone. The Input aids page is only in the sidebar while the module is on. The unit frame options, class resources and the 30 percent marker stay core, as do the damage meter option, run history and language.
* **Also:** Run analysis now includes the Pace indicator, Jewelry cooldowns have their own switch in the Jewelry collection.

### 3.3.0 (2026-10-19, release v3.3.0)

* **Background opacity** (Size & Position): new slider from 20 to 100 percent, default 91 as before. Applies to window backgrounds, tooltips and the player and target frames. The settings window itself stays opaque.
* **Show portraits** (Unit frames): new switch, default on. With portraits off a dark circle stays where the portrait was.
* **Coming next:** this is a first step for portraits. A dedicated portrait free unit frame for a cleaner look is planned and will clearly improve this.

### 3.2.0 (2026-10-19, release v3.2.0)

* **Settings search:** live search across all settings, in English and German whatever your UI language (player/Spieler, target/Ziel and so on). Results are the real switches and sliders. Clear with the x or Escape.
* **Guardian skulls** (game 0.102+): every lair shows a skull on the minimap from the start of the run: gold while a guardian holds it, orange with ! in combat, grey with x when empty. The game's red flag stays hidden while the skulls are on.
* **Layout:** windows snap flush to the screen edges. Windows docked above the chat stay attached and grow upward. The upper windows share a 300 point width; player, target, action bar, counters and XP keep their sizes. Buffs match the action bar width so both stack cleanly.
* **New installs and Reset:** a clean start layout without overlaps, minimap at 80 percent.
* **Minimap button:** larger and in the lower left corner by default; new option with eight fixed positions. A saved position is now applied correctly after loading.
* **Chat:** small copy button at the chat window (moved out of the settings).
* **Also:** character attributes follow the section titles setting, run history opens on your current zone, the loot frame keeps its sizes per mode, the font option is removed for now.

### 3.1.1 (2026-10-19, release v3.1.1)

* Hotfix for game version 0.101: frames could not be dragged to the screen edges and saved positions were shifted, because the game reports a different UIParent size than the area it covers. Placement, clamping, snapping and saved positions now use the real screen edges. /kui grid debug shows both sizes.

### 3.1.0 (2026-10-19, release v3.1.0)

* Fixed for game version 0.101: "DamageText.lua:281: SetText(): Font not set" after the first hit. New floating numbers get their font before their text.
* Layout grid: the lines now hang from the screen centre and run edge to edge, so the middle line stays centred. Snapping uses the same centre, so frames now line up with the visible grid. /kui grid debug reports the sizes the game gives the addon.
* Guardians: the minimap skulls with three states are back and replace the game's red guardian flag (game version 0.102 or newer): gold while a guardian holds its lair, orange with "!" in combat, grey with "x" once the lair is empty. Empty lairs only get a skull after their guardian was seen alive in this run. Status, return time and distance on hover. The game's flag is hidden only while the skulls are drawn and comes back when the option is off, data is missing, during loading screens and at logout. The option is now called "Guardian skulls instead of game flag". On older game versions only defeated guardians get a grey skull and the game's flag stays.

### 3.0.1 (2026-10-19)

* Fixed for game version 0.101 (Lua 5.0): the error "UIPanelTemplates.lua:245: attempt to concatenate a nil value" at login. The chat copy window's scroll frame now has a name. The build tip tooltip no longer uses _G, which the new client no longer provides.
* Fixed for game version 0.101: "Statistics.lua: attempt to index a nil value" and settings or panel titles staying partly in English. The new game Lua loses loop variables used inside later called functions; the affected labels, tooltips and choice menus now keep their own copy.
* New diagnostic command /kui menu: for 60 seconds, reports in the chat whether ESC opens the game menu (GameMenuFrame) and whether the options window (BenillaOptionsFrame) is shown.

### 3.0.0 (2026-10-19, release v3.0.0)

* Settings: Display and Layout are now one category, "Layout & Display". The active category shows its sections as links in the sidebar. New sliders for menu size and the whole UI.
* New third meter tab "Healing": healing by source with HPS and shares.
* Boss and guardian bars now show their debuffs: icon, stacks and remaining time, details on hover.
* Guardians: small direction arrows next to guardian names in the run overview, and a skull on the minimap for defeated guardians. Skulls only appear for guardians that were seen alive and defeated, none at the start of a run. Living guardians keep the game's own flag. Both can be switched off.
* Caches: guidance now also works inside instances.
* New button for stored level-ups; the "Store Level-Ups" game option can be switched in Controls.
* New optional displays: XP per minute with time to next level, lives and rerolls (free rerolls first, then the price of the next one), a 30 percent marker on enemy health bars.
* Character values: 29 selectable values with a reorderable list, in their own settings section.
* Damage taken: the tooltip shows damage by source, hits, average, min/max and crit rate.
* Jewelry: searchable diary of the items you found, with the values you saw. Game cooldowns show on the jewelry icons.
* Optional extra combat text: healing and damage on the player.
* The Boss view of the damage meter returns to Run after the last boss (optional).
* Loot list much improved: the small list shows a green check for new items and a red cross for collected ones instead of cut-off text, item names get more room, and lists and icon grids no longer drift left after reloads.
* New: font choice, optional short run messages, and optional modules you can switch off.
* Improved: XP bar matches the other windows, boss timer improved, calmer damage numbers in the fixed position, better performance.

### 2.4.9 (2026-10-19)

* Minimap skulls now appear only for defeated minibosses, using the native empty-lair state, and disappear on respawn. Living and fighting guardians keep their native flags until a proven selective hide function exists. Removed occupied/fighting skull styles and status badges. Existing independent switches, guardian-row arrows, tooltips and map-edge handling remain; settings and documentation explain the policy.

### 2.4.8 (2026-10-19)

* Removed precise frame placement, numeric inputs and layout profiles from the active addon, including their settings page, helper functions and translations. The code is archived separately for possible future reuse. Normal dragging, mouse-wheel resizing, saved positions, grid and reset remain. Native font selection now lives in the smaller Fonts.lua module; the installer backs up and removes LayoutTools.lua.

### 2.4.7 (2026-10-19)

* Removed historical boss sections from tooltips, their setting and their data collection. New Pace records and victory snapshots no longer copy boss sections. Current-run boss timings and the existing Pace comparison remain. The installer backs up and removes the retired BossHistory.lua module.

### 2.4.6 (2026-10-19)

* Removed the unframed floating jewelry effect list, its separate layout handle and its redundant setting. Effects remain available in the existing native tooltips on the item icons. Native cooldowns and their switches remain. The installer backs up and removes the retired GearDetails.lua module.

### 2.4.5 (2026-10-19)

* Removed the world-map pin option, its optional-module entry and its runtime projection/pins. Old saved toggles no longer activate it. The installer removes the retired module file after backing up the previous installation. Cache and guardian minimap navigation remains available.

### 2.4.4 (2026-10-19)

* The XP bar now shares the bronze panel housing, dark background and chamfered edges of the other windows, with a padded violet progress track. Optional XP/min and next-level estimates are centered inside the track instead of floating above it. The panel stays 400 points wide and fits below the default build bar. Existing custom top positions, visibility and estimation rules remain supported.

### 2.4.3 (2026-10-19)

* Lives and rerolls now form an optional second row inside the existing kills, gold and cache panel, sharing its bronze housing, fonts and movement. Removed the separate floating resources strip. Zero remains visible; unavailable fields and disabled rows collapse. The next reroll price is explicitly named only on hover, not displayed as an ambiguous next purchase.
* The combined panel grows upward from its bottom edge to keep space above the build bar. Existing saved panel positions and layout profiles are converted once to preserve that edge. Existing visibility and module switches remain effective.

### 2.4.2 (2026-10-19)

* Added the short /kui heal diagnostic command; /kui heal debug remains supported. Lists every validated native healing source with its original name, exact healing and HPS, and states whether Holy Shock is reported separately. Unknown or previous-run data is explicitly unavailable. This diagnoses the missing source; it does not invent healing or claim the gameplay issue is fixed.

### 2.4.1 (2026-10-19)

* Guardian minimap skulls now have transparent backgrounds without bronze boxes. Fighting and empty status symbols sit centered beside the complete skull instead of covering its lower corner. Increased edge clearance keeps the wider markers inside the minimap.

### 2.4.0 (2026-10-19)

* Added optional XP/min and next-level estimates from received native run time. Require multiple gains and enough history, bridge one level transition, and reset on gaps or unknown intermediate level requirements. Added optional native lives and rerolls.
* Expanded selectable character attributes to 29 verified native values with their actual units; arrows reorder selected values. Added native damage-taken sources and observed per-source hit counts, normal average/min/max and critical rate on hover. Optional 30 percent markers preserve health colors.
* Added a searchable persistent jewelry diary of observed finds and native tooltip ranges, native inventory cooldowns and optional compact effect text. Unknown items and unobserved values remain unknown. Added native world-map cache/lair pins that select guidance without changing the browsed map; unsupported projection stays hidden.
* Added precise frame position/scale controls, eight layout profiles, native font selection, chat copy and optional compact run introductions. Eleven optional engines can suspend their callbacks and subscriptions while shared run storage and diagnostics remain active. Extra settings remain within the four existing categories.
* Added optional historical boss-section comparisons and separate healing/incoming text using native interval totals. The existing Pace calculation remains unchanged. Native guardian minimap flags remain unresolved; in-game visual verification is pending.

### 2.3.11 (2026-10-19)

* Boss and guardian encounter bars now show native debuffs by spawn ID, including icons, stacks, known remaining times and details on hover. Identical names stay separate. Unknown timing is marked with a question mark; permanent effects have no countdown. Timers follow the native run clock through pauses and card choices.
* Eight icons per bar and an overflow tooltip keep the group compact. Its existing screen height limit and mouse wheel navigation remain; missing native debuff support hides only the added effects. Target and nameplate debuff presentation stays unchanged.

### 2.3.10 (2026-10-18)

* In Fixed position only, ordinary floating damage fades earlier, lasts about 0.55 to 0.65 seconds and travels a shorter distance. Periodic and small hits also clear quickly. Critical hits keep their existing longer lifetime and fade.
* In Fixed position only, bounded the starting offset of consecutive Rising hits so bursts cannot push a growing column of numbers toward the screen edge. The settings preview and live text share the same fade curve; icons fade with their number. Nameplate presentation remains unchanged.

### 2.3.9 (2026-10-18)

* Fixed compact loot lists and icon grids moving left after repeated reloads. Their actual display width is now set before applying and clamping saved positions, including late saved-variable loading. Existing freely placed frames stay where they are.
* A position already shifted and saved by an older version needs to be moved back once. The addon does not guess or overwrite a previous intended position.

### 2.3.8 (2026-10-18)

* Display and Layout are now one Layout & Display category. It also contains unit frame appearance, nameplates, minimap, caches and guardian navigation, with direct section links. Spells, jewelry and the action bar now have a shared display switch.
* Both stored level options move to General. Main categories have persistent bronze borders, brighter gold labels and explicit left alignment, clearly separated from smaller section links. Existing preferences and commands remain.

### 2.3.7 (2026-10-18)

* Completed boss row backgrounds now span the entire row, including the name and both time columns. Existing pace colors and timings remain.
* Small guardian direction arrows now sit directly to the right of each name, with room reserved before the status column.

### 2.3.6 (2026-10-18)

* Lair pins now remain visible when empty. Unified bronze frames contain gold skulls for occupied lairs, orange skulls with ! while fighting, or grey skulls with X when empty. Hover for the shared guardian status, return countdown and distance. Direction arrows still lead only to occupied lairs.
* Known limitation: native game flags have not been disabled. The current client exposes no documented control to hide them individually. Native flag overlap remains unresolved.

### 2.3.5 (2026-10-18)

* Run statistics now use the same native effective healing total as the Healing meter. The tooltip shows run HPS and up to six strongest sources with shares, excluding overhealing. HP sampling and gross estimates no longer replace native data. The panel keeps its size.
* Missing, invalid or previous run healing stays unknown instead of falling back to an unrelated estimate. Valid empty data means zero. Older clients without the API retain an explicitly labeled observed healing fallback. /kui heal debug reports native totals where supported.

### 2.3.4 (2026-10-18)

* Small loot list now uses the existing green check mark for new items and red cross for collected items instead of truncated status text. Item names gain space, while localized status text remains in the tooltip. The collection status toggle also controls these symbols. Unknown status stays unmarked.

### 2.3.3 (2026-10-18)

* The active settings category expands its section headings as smaller links in the left sidebar. Click a heading to jump directly to that section on the right. Other categories stay collapsed. The selected section is highlighted and follows manual scrolling.
* Links use the existing headings and translations, retain the category while choosing character attributes, and keep all categories above the footer.

### 2.3.2 (2026-10-18)

* Layout now has percentage sliders for Menu size (70 to 100%) and Entire UI (64 to 150%). Entire UI uses the native uiScale setting, scaling game windows and KeijinUI together while preserving individual frame scale settings. Nothing changes automatically at startup.
* Percentages preview while dragging and apply on release. The settings window fits the screen after scale or resolution changes. Reset UI sizes restores menu size to 80% and native UI scale to 90%.

### 2.3.1 (2026-10-18)

* Guardian navigation now uses a small gold direction arrow before each occupied guardian name in the existing run overview. The separate large guide and its layout handle have been removed. Distance and lair guidance remain available on hover; the overview keeps its size and status column.
* Arrows disappear for empty lairs, unknown positions and on leaving the run. They move and scale with the overview. The arrow and minimap pin settings remain independent and retain saved preferences.

### 2.3.0 (2026-10-18)

* Cache guidance prefers native world position and facing, including instance maps and valid zero/negative coordinates. Older builds retain the measured map fallback.
* New movable guardian guide: distance and direction to an occupied lair, stable target selection, click/wheel cycling and nearest selection by right-click. Minimap skulls select a lair; empty lairs disappear. Guide and pins can be toggled independently.
* New movable stored level-up button shows waiting native choices. Click while playing to open them. Controls offers the game's Store Level-Ups setting; startup never changes that preference or spends choices. Unsupported clients keep their native HUD.
* Healing is a third meter tab with native effective healing by source, HPS, shares and the existing source colors. Manual selection wins over boss automation. Reset remains limited to the Run tab. Tabs and summary also fit thin and hidden headers.

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

### 4.0.2 (2026-10-24, Release v4.0.2)

* **Chatgröße (Issue #1):** Der Reiter General behält das native Einblenden und Rechtsklickmenü. Den Chat über den Reiter entsperren und dann an einer Kante oder der neuen kleinen Ziehfläche unten rechts Breite und Höhe ändern. Rahmen und Hintergrund folgen der Größe bereits während des Ziehens; beim Loslassen der Maustaste endet die Größenänderung. Größe und Position bleiben nach einem Reload erhalten; Alt und Mausrad ändern weiterhin die Skalierung. Der Knopf für die neuesten Nachrichten sitzt neben der Ziehfläche.

### 4.0.1 (2026-10-24, Release v4.0.1)

* **Partyfenster folgt dem Überschriftenstil:** Sind die Überschriften auf klein oder aus gestellt, wird der Kopf des Partyfensters jetzt wie bei den anderen Fenstern kleiner oder ausgeblendet, und das Fenster wird entsprechend flacher.

### 4.0.0 (2026-10-24, Release v4.0.0)

* **Alle Spielsprachen:** neben Englisch, Deutsch und vereinfachtem Chinesisch gibt es KeijinUI jetzt auch auf Französisch, Spanisch, Portugiesisch, Polnisch, Tschechisch, Rumänisch, Türkisch, Russisch, Ukrainisch, Japanisch und Koreanisch. Auswahl unter Allgemein, Sprache, oder mit `/kui lang <Code>`. Fähigkeitsnamen folgen den Übersetzungen des Spiels (Türkisch behält wie das Spiel die englischen Namen).
* **Maschinell übersetzt:** nur Englisch und Deutsch sind von Hand geprüft. Alle anderen Sprachen sind maschinell übersetzt und noch nicht muttersprachlich geprüft; falsche oder abgeschnittene Texte bitte mit Screenshot melden.
* **Schriften:** Französisch, Spanisch und Portugiesisch nutzen die Spielschrift. Polnisch, Tschechisch, Rumänisch, Türkisch, Russisch, Ukrainisch, Chinesisch, Japanisch und Koreanisch nutzen die mitgelieferte Schrift, auch in Tooltips und Chat. Rumänisch verwendet ş und ţ mit Cedille, weil der Schrift das t mit Komma fehlt.
* **Rundenzahl in anderen Sprachen:** die Meldung "Das ist dein ... Lauf" zeigt die reine Zahl statt einer englischen Endung wie 3rd.
* **Koop (auf Wunsch von Bersh, Shandrax und Mr8endiix):** Die Schadensanzeige hat einen neuen Reiter Party mit Schaden und DPS jedes Helden deiner Party (Klassenfarben, dein eigener Held umrahmt, stärkster Zauber im Tooltip). Ein neues Partyfenster zeigt bis zu vier Mitstreiter mit Leben, Status offline oder am Boden und dem Fortschritt der Wiederbelebung, und wie weit deine eigene Wiederbelebung ist, solange du am Boden liegst. Mit Alt verschieben, mit Alt und Mausrad skalieren; unter Module abschaltbar. `/kui party debug` listet, was das Spiel zur Party meldet. Noch nicht in einer echten Koop Runde getestet: bitte melde, was du siehst.

### 3.7.1 (2026-10-23, Release v3.7.1)

* **Abklingzeit am Symbol (auf Wunsch von JayMasta):** Die Buildübersicht zeigt jetzt die Abklingzeit jedes Zaubers im Run in einem dunklen, abgeschrägten Plättchen an der Oberkante seines Symbols, in Sekunden (unter 1 s zwei, unter 10 s eine Nachkommastelle). Werte unter einer Sekunde sind golden. Das Fenster wird dafür ein paar Pixel nach oben größer (nach unten nur, solange es unter einem anderen Fenster angedockt ist) und hat bei ausgeschalteter Option wieder seine Originalgröße. Seine Unterkante bleibt jetzt fest, auch wenn eine zweite Zauberreihe dazukommt; gespeicherte Positionen werden ohne Sprung übernommen. So siehst du ohne Hover, wie niedrig eine Abklingzeit schon ist. Schalter: Layout & Anzeige, "Abklingzeit am Symbol". Standardmäßig an.
* **"Nur laufende Abklingzeiten" entfernt:** Die Option für die Aktionsleiste gibt es nicht mehr. Die neue Zahl am Symbol ersetzt sie, die Aktionsleiste zeigt wieder immer alle Zauber.
* **Chinesische Schrift in Tooltips und Chat:** Bei chinesischer Oberfläche nutzen auch die Tooltips des Spiels (Titel, Text und kleiner Text) und der Chat die mitgelieferte CJK Schrift. KeijinUI Meldungen und chinesische Namen sind dort lesbar.
* **Kurzform der Schadenszusammenfassung wieder da:** Bei ausgeblendeten Überschriften zeigt die Zusammenfassung im Reiter Run wieder die Kurzform (Gesamtschaden und DPS) statt des langen Textes.

### 3.7.0-beta.1 (2026-10-23, Release v3.7.0-beta.1)

* **Position des Buildpanels:** Verschieben über das Panel, seine Symbole oder den Tippbereich verwendet jetzt denselben Layoutspeicher wie der Layoutgriff. Die gespeicherte Kante bleibt bei Höhenänderungen fest. Loslassen von Alt beendet das Verschieben auch bei fehlendem Abschlussereignis.
* **DPS:** Der Reiter Run zeigt jetzt den Schaden pro Sekunde der letzten 10 Spielsekunden, ohne Pausen. Gesamtschaden, Balken und Reihenfolge beziehen sich weiterhin auf den Run oder die Zeit seit Reset. Der Tooltip behält die durchschnittlichen DPS. Boss und Heilung behalten ihre nativen Kampfwerte beziehungsweise Rundendurchschnitte. Die Messung beginnt mit neuen Beobachtungen und startet nach Datenlücken erneut.
* **Endlosbosse:** Die Runübersicht zeigt den Spielcountdown bis zum nächsten Endlosboss statt des abgeschlossenen normalen Bossplans. Bei fehlendem Countdown erscheint ein Fragezeichen.
* **Account Pace:** Eine optionale zweite Zeile vergleicht alle lokal gespeicherten Klassen bei gleicher Zone, Schwierigkeit und gleichen Modifikatoren. Der Klassenvergleich bleibt getrennt. Bis zu 120 Referenzrunden werden behalten; vorhandene Messpunkte können sofort verwendet werden.
* **Rückkehrzeit der Wächter:** Optionale Timer unter den Hortmarkern auf der Minimap verwenden dieselben Rückkehrdaten wie die Runübersicht. Veraltete Daten zeigen ein Fragezeichen. Standardmäßig aktiv, abschaltbar unter Wächter.
* **Laufende Abklingzeiten:** Die vorhandene Aktionsleiste kann nur Zauber mit laufender Abklingzeit zeigen. Sind alle bereit, wird sie ausgeblendet. Standard bleibt die vollständige Leiste.
* **Vereinfachtes Chinesisch:** Unter Allgemein 简体中文 wählen oder `/kui lang zh` verwenden. Übersetzte Oberflächentexte und Fähigkeitsnamen aus den Spieldaten sowie eine mitgelieferte Schrift für chinesische und lateinische Zeichen. Unbekannte Namen bleiben wie vom Spiel geliefert. Übersetzung und neue Anzeigen müssen noch im Spiel geprüft werden.

### 3.6.1 (2026-10-23, Release v3.6.1)

* **Tooltips für Fähigkeiten ohne Zauberbucheintrag:** Fähigkeiten, die nicht im Zauberbuch stehen, etwa **Ruf der Flamme**, zeigen beim Überfahren in der Zauberliste jetzt die Beschreibung des Spiels. KeijinUI findet den passenden Aktionsplatz über den Namen, in jeder Spielsprache.
* **Talentsymbole für Spiel 0.112:** die Talentliste liegt in den Spieldaten an anderer Stelle. KeijinUI liest sie wieder und der Schadensmesser zeigt Symbole für neue Talente wie **Trauma** und **Kampfrausch**, mit aktualisierten Namen in allen Spielsprachen.

### 3.6.0 (2026-10-22, Release v3.6.0)

* **Beschwörungsleiste:** eine neue Leiste zeigt deine aktiven Beschwörungen für jede Klasse: die Dämonen des Hexenmeisters (Wichtel, Teufelswache, Infernos und die übrigen), das Tier des Jägers, Treants des Druiden, Geisterwölfe und den Wasserelementar. Jede Art bekommt ein Symbol mit der Anzahl unten rechts (ab 2) und darunter der Restzeit der Ersten, die geht; dauerhafte Beschwörungen zeigen keine Zeit. Beim Überfahren erscheinen Name, Anzahl, wie viele dauerhaft oder zeitlich sind und wann die nächste endet. Die Leiste erscheint nur im Lauf und braucht Spiel 0.110 oder neuer (ältere Versionen zeigen einfach nichts). Alt halten zum Verschieben, Alt und Mausrad zum Skalieren; als neues Modul **Beschwörungen** abschaltbar. Auf Wunsch von Bersh.
* **Regler für die Größe der Schadenszahlen:** ein Regler in den Kampfeinstellungen (50 bis 200 Prozent) stellt die Schriftgröße der schwebenden Schadenszahlen ein. Nur der Text wird größer oder kleiner, der Kampftext Anker und seine Skalierung mit Alt und Mausrad bleiben, wie sie sind. Die Vorschau folgt ihm.
* **Absorbschild auf dem Lebensbalken:** eine helle, halbtransparente Schicht zeigt dein Absorbschild vom aktuellen Leben aus nach rechts. Über dem Maximalleben wird sie am Balkenende abgeschnitten und ein heller Rand markiert den Überlauf. Der Lebenstext ergänzt das Schild als +x.
* **Blaue und grüne Hortschädel besser unterscheidbar:** der blaue Schädel ist jetzt ein dunkleres, satteres Blau und der grüne ein Gelbgrün.

### 3.5.6 (2026-10-22, Release v3.5.6)

* **Tooltips für neue Zauber:** manche Zauber wie **Dämonische Ermächtigung**, **Sühne** und die Fallen des Jägers stehen im Zauberbuch unter einem anderen Namen. Die Zauberliste sucht sie jetzt auch dort, damit beim Überfahren die Beschreibung des Spiels wie bei anderen Zaubern erscheinen kann. Dämonische Ermächtigung nutzt außerdem jetzt das Symbol des Spiels.

### 3.5.5 (2026-10-22, Release v3.5.5)

* **Buildtipps in jeder Spielsprache:** die Schadensverbesserungen deiner Zauber werden jetzt in allen Sprachen des Spiels erkannt, nicht nur auf Englisch und Deutsch. Die Buildtipps funktionieren damit auch auf Russisch, Polnisch, Französisch, Chinesisch und in den übrigen Sprachen.
* **Neue Zauber in der Zauberliste:** Zauber aus einem Spielpatch, etwa **Dämonische Ermächtigung** oder **Schreddern** des Druiden, zeigen jetzt ihr Symbol und ihren richtigen Namen statt eines Fragezeichens.
* **Genauere Buildtipps:** eine Verbesserung mit Schadensreduktion zählt nicht mehr als zusätzlicher Schaden.

### 3.5.4 (2026-10-22, Release v3.5.4)

* **Klassenressourcen zeigen den Wert des Spiels:** Seelensplitter, Combopunkte und Blutrausch zeigen jetzt genau das, was das Spiel zählt, statt aus Mana oder Energie errechnet zu werden. Ein Seelensplitter zählt erst, wenn er ganz voll ist.
* **Dämonen des Hexenmeisters in der Schadensanzeige:** Wichtel, Teufelsjäger, Leerwandler, Sukkubus, Höllenbestie, Verdammniswache, Teufelswache und Grubenlord zeigen jetzt ihr eigenes Symbol in der Schadensanzeige, im Fenster **Größte kritische Treffer** und bei den Schadenszahlen. Auch ihre Angriffe Feuerblitz, Teufelssucher, Verdammnisbringer und Brutaler Schwung und der Zauber Dämonische Ermächtigung haben Symbole, in jeder Spielsprache.

### 3.5.3 (2026-10-21, Release v3.5.3)

* **Symbole in der Schadensanzeige in allen Spielsprachen:** Zauber, Fähigkeiten und Talente zeigen ihr Symbol jetzt auch, wenn das Spiel auf Russisch, Ukrainisch, Polnisch, Französisch, Spanisch, Portugiesisch, Tschechisch, Rumänisch, Türkisch, Chinesisch, Japanisch oder Koreanisch läuft. Bisher fanden nur englische und deutsche Namen ihr Symbol. Einige wenige Namen, die in einer Sprache für zwei verschiedene Fähigkeiten stehen, bleiben ohne Symbol.

### 3.5.2 (2026-10-21, Release v3.5.2)

* **Itemsymbole in der Schadensanzeige:** Schaden, der von einem deiner Items kommt, zum Beispiel **Das Auge Hakkars**, zeigt jetzt das Symbol dieses Items neben dem Namen, in der Schadensanzeige, im Fenster **Größte kritische Treffer** und bei den Schadenszahlen. Das Symbol bleibt auch, wenn das Item abgelegt wird, etwa nach Tod oder Sieg. Quellen ohne bekanntes Symbol behalten einen leeren Platz.
* **Talentsymbole in der Schadensanzeige:** Schaden von Talenten, zum Beispiel **Siegel des Befehls**, zeigt jetzt ebenfalls das Symbol des Talents. KeijinUI kennt die Symbole aller Talente jeder Klasse auf Englisch und Deutsch.

### 3.5.1 (2026-10-21, Release v3.5.1)

* **Spellsymbole in der Schadensanzeige (neu, Wunsch aus der Community):** die Schadensanzeige kann jetzt neben jedem Namen das Symbol des Zaubers zeigen, in den Ansichten Run, Boss und Heilung und im Fenster **Größte kritische Treffer**. Nahkampf zeigt deine Waffe. Einschalten unter `/kui`, Kampf, Schadensanzeige, **Spellsymbole anzeigen**. Die Option ist zu Beginn aus, es ändert sich also nichts, bis du sie einschaltest.
* **Beuteliste bleibt leer unsichtbar:** in den Listen und Symbolmodi erscheint das Beutefenster erst, wenn du im Run etwas erbeutet hast, statt "Noch keine Beute in diesem Run" zu zeigen. Mit gedrückter Alt Taste oder im Layout Editor siehst und verschiebst du es auch leer.

### 3.5.0 (2026-10-21, Release v3.5.0)

* **Hortmarker (neu):** Jeder Wächterhort hat jetzt für den ganzen Run sein eigenes Symbol. Dasselbe Symbol siehst du auf der Minimap und vor dem Namen des Wächters in der Runübersicht. So weißt du immer, welcher Hort welcher ist, egal wie die Liste sortiert ist oder wie weit ein Hort entfernt liegt.
* **Fünf Stile zur Auswahl.** Standard sind die **Farbschädel mit Ziffer**: der bekannte Bosstotenkopf in sechs Farben, jeweils mit der Nummer des Horts. Als Alternativen gibt es **Kreaturen** (sechs kleine Totenköpfe von Orc, Troll, Tauren, Drache, Dämon und Untotem), **Raidmarker** (Stern, Kreis, Diamant, Dreieck, Mond, Quadrat, frei ohne Unterlage), **Siegel mit Ziffer** und **Klassisch** (der schlichte goldene, orange und graue Totenkopf wie bisher).
* **Zustand auf einen Blick:** Ein Hort im Kampf zeigt ein kleines **!**, ein leerer Hort ist abgedunkelt und zeigt ein kleines **x**. Wann ein wartender Hort fällig ist, steht weiterhin in der Runübersicht.
* **Wo du es einstellst:** Öffne `/kui`, dann Layout & Anzeige, Wächter, und wähle unter **Hortmarker** den Stil. Die Änderung ist sofort auf der Minimap und in der Runübersicht zu sehen.
* **Hortmarkergröße:** Ein neuer Regler unter der Markerwahl stellt Minimapmarker zwischen 50 und 200 Prozent ein (Standard 100). Ziffern und Statuszeichen wachsen mit, mit passendem Randabstand und Ausblendung am Spielerpfeil. Die kleinen Symbole in der Runübersicht behalten ihre Größe.
* Der Schalter **Hortmarker statt Spielflagge** (früher "Wächtertotenköpfe statt Spielflagge") schaltet das alles auf einmal aus. Dann sieht die Runübersicht genau so aus wie vorher und die Flagge des Spiels bleibt.
* Die Einstellungssuche findet die neue Option mit Wörtern wie "Marker", "Raidmarker", "Totenkopf" oder "Kreaturen".
* **Flüssigere Minimap Symbole:** Die Hortmarker der Wächter und die Cache Truhen gleiten jetzt beim Laufen flüssig mit der Karte mit, statt leicht zu ruckeln.
* **Dein Spielerpfeil ist besser zu sehen:** Marker und Truhen nahe der Minimapmitte werden durchsichtig und verdecken deinen Pfeil kaum noch.
* **Einheitenrahmen bleiben beim Porträtwechsel stehen:** Wenn du **Porträts anzeigen** ein oder ausschaltest, verrutschen deine Rahmen nicht mehr. Der Spielerrahmen hält das rechte Ende seines Lebensbalkens fest, der Zielrahmen das linke. Es kommt also nur das Porträt dazu oder fällt weg. Früher gespeicherte Positionen werden ohne Sprung übernommen.
* **Klassenressourcen direkt unter dem Lebensbalken:** Bei **Am Spieler** sitzt der Ressourcenbalken jetzt mittig direkt unter dem Lebensbalken, mit und ohne Porträt. In diesem Modus bewegt er sich mit deinem Spielerrahmen und lässt sich nicht mehr einzeln ziehen. Wenn du ihn selbst platzieren willst, wähle bei der Ressourcenposition **Frei**.
* **Freie Plätze in der Spell und Itemliste:** Die Liste zeigt jetzt, wie viel Platz noch frei ist. Leere Spellplätze erscheinen als leere Felder, leere Itemplätze zeigen ein kleines Symbol für Hals, Ring oder Schmuckstück, und beim Darüberfahren steht, welcher Platz frei ist.

### 3.4.2 (2026-10-20, Release v3.4.2)

* **Cache Symbolgröße (neu, Wunsch aus der Community):** Du kannst jetzt selbst festlegen, wie groß die Truhensymbole auf der Minimap sind. Öffne `/kui`, dann Layout & Anzeige, Caches, und stelle den neuen Regler **Cache Symbolgröße** zwischen 50 und 200 Prozent ein. 100 Prozent ist die gewohnte Größe, ohne Änderung bleibt also alles wie bisher.
* Größere Truhen fallen mitten im Kampf schneller auf, kleinere halten eine volle Minimap übersichtlich.
* Große Symbole bleiben immer vollständig auf der Minimap. Liegt eine Truhe zu nah am Rand, zeigt der Randpfeil auf sie.
* Der Regler wirkt, solange **Cache Symbole** eingeschaltet ist.
* Lieber per Chat? `/kui caches size 150` stellt denselben Wert ein (50 bis 200).
* Die Suche in den Einstellungen findet den Regler zum Beispiel mit „Truhen Größe“, „Cache Symbolgröße“ oder „Minikarte“.

### 3.4.1 (2026-10-20, Release v3.4.1)

* **Abklingzeit auf der Aktionsleiste:** läuft jetzt standardmäßig wie bei den normalen Aktionsknöpfen im Uhrzeigersinn ab. Die bisherige Abdunklung von oben nach unten lässt sich unter Fenster, Abklingzeit wieder wählen. Die Restzeit als Zahl bleibt.
* Der Hilfetext zur Aktionsleiste beschreibt jetzt die geltende Regel: Ist eines unserer Fenster aus, erscheint das passende des Spiels.

### 3.4.0 (2026-10-20, Release v3.4.0)

* **Minimapknopf:** Mittelklick lädt die Oberfläche neu.
* **Porträts anzeigen aus zeigt jetzt einen kompakten Rahmen:** statt des dunklen Kreises haben Spieler und Ziel einen eigenen geschlossenen Rahmen ohne Porträt (170 breit, 48 hoch) mit demselben Verlauf, Klassenfarben, Elite und Rare Kennzeichen, Tooltip und Hintergrund-Deckkraft. Das Umschalten wirkt sofort, Positionen, Größen und Andockverbindungen bleiben erhalten, Klassenressourcen und Zieldebuffs folgen der neuen Unterkante und die 30 Prozent Markierung wandert an den neuen Balken. Damit ist die Ankündigung aus 3.3.0 eingelöst; der Standard (Porträts an) bleibt unverändert.
* **Core und Module:** Die Einstellungen trennen jetzt, was immer zu KeijinUI gehört (Core), von Funktionen, die du abschalten kannst (Module). Die neue Seite **Module** in der Seitenleiste führt 13 Module mit einer kurzen Beschreibung, was sie tun und was beim Ausschalten erscheint: Kampftext, Namensplaketten, Minimap, Caches, Wächter, Run-Analyse, Charakterwerte, Beute, Schmucksammlung, Buildtipps, Gespeicherte Level, Erfolgsmeldungen und Eingabehilfen (Cursortracker und Taste für Automatisch laufen).
* **Ein ausgeschaltetes Modul ist wirklich aus:** Seine Skripte laufen nicht mehr, seine Einstellungen verschwinden von allen Seiten, aus den Sprunglinks und aus der Suche (wer bei ausgeschalteten Caches nach "Cache" sucht, findet stattdessen den Modulschalter), und die Zeilen darunter rücken nach oben. Wo das Spiel etwas Eigenes hat, kommt es zurück: Kampftext, Namensplaketten, Minimap (in Größe und Position des Spiels, ohne Minimapknopf; `/kui` funktioniert weiter), die rote Wächterflagge, die Beutemeldung und die normale Levelauswahl. Das Umschalten wirkt sofort; nach dem Ein- oder Ausschalten der Minimap neu laden, falls etwas hängen bleibt (die Seite hat einen Knopf dafür).
* **Alle Module sind standardmäßig an.** Gespeicherte Einstellungen werden nie zurückgesetzt. Module, die du vorher ausgeschaltet hattest, bleiben aus: Die zusammengelegten Module übernehmen das (Schadenszahlen und Heiltext wurden Kampftext, Wächternavigation wurde Wächter, Cursortracker wurde Eingabehilfen, Schmuckcooldowns gingen in die Schmucksammlung, XP und Zusatzressourcen wurden Run-Analyse). Ausgeschaltete Buildtipps und Erfolgsmeldungen bleiben ebenfalls aus.
* **Fenster:** Der Abschnitt "Runanzeigen" heißt jetzt **Fenster** und enthält nur die Core Fenster zum Ein- und Ausblenden. **Zauber & Schmuck** und **Aktionsleiste** sind jetzt zwei getrennte Schalter (vorher schaltete einer beide); war die Leiste bei dir aus, bleiben beide aus. `/kbb` schaltet weiterhin beide zusammen. Für jedes Fenster mit einem Gegenstück im Spiel gilt: unseres an, das des Spiels aus; unseres aus, das des Spiels an, auch wenn es vorher ausgeblendet war. Zauber & Schmuck gehört zu den Zauber- und Schmuckzeilen des Spiels, die Aktionsleiste zur Aktionsleiste des Spiels, ebenso Kills und Gold, Schadensanzeige, Begegnungen und Runübersicht (Runuhr).
* **Moduleinstellungen wohnen im Modul:** Wächter in der Runübersicht, Pace-Indikator, Leben und Rerolls und XP Rate stehen bei ihrem Modul (Wächter, Run-Analyse). Der alte Abschnitt "Zauber & Gegenstände" entfällt. Die Seite Eingabehilfen steht nur in der Seitenleiste, solange das Modul an ist. Einheitenrahmen, Klassenressourcen und die 30 Prozent Markierung bleiben Core, ebenso die Schadensanzeige Option, die Rundenhistorie und die Sprache.
* **Außerdem:** Die Run-Analyse enthält jetzt den Pace-Indikator, die Schmuckcooldowns haben in der Schmucksammlung einen eigenen Schalter.

### 3.3.0 (2026-10-19, Release v3.3.0)

* **Hintergrund-Deckkraft** (Größe & Position): neuer Regler von 20 bis 100 Prozent, Standard wie bisher 91. Gilt für Fensterhintergründe, Tooltips sowie Spieler- und Zielrahmen. Das Einstellungsfenster selbst bleibt deckend.
* **Porträts anzeigen** (Einheitenrahmen): neuer Schalter, Standard an. Ohne Porträt bleibt ein dunkler Kreis stehen.
* **Ausblick:** Das ist ein erster Schritt bei den Porträts. Ein eigener Einheitenrahmen ohne Porträt für einen cleaneren Look ist geplant und wird das deutlich verbessern.

### 3.2.0 (2026-10-19, Release v3.2.0)

* **Suche in den Einstellungen:** Livesuche über alle Einstellungen, auf Deutsch und Englisch unabhängig von der UI Sprache (Spieler/player, Ziel/target usw.). Treffer sind direkt die echten Schalter und Regler. Leeren mit x oder Escape.
* **Wächtertotenköpfe** (ab Spiel 0.102): Jeder Hort zeigt ab Runbeginn einen Totenkopf auf der Minimap, gold bei besetztem Hort, orange mit ! im Kampf, grau mit x bei leerem Hort. Die rote Flagge des Spiels bleibt ausgeblendet, solange die Totenköpfe an sind.
* **Layout:** Fenster rasten bündig am Bildschirmrand ein. Über dem Chat angedockte Fenster bleiben verbunden und wachsen nach oben. Die oberen Fenster sind einheitlich 300 Punkte breit; Spieler, Ziel, Aktionsleiste, Zähler und EP behalten ihre Größe. Buffs haben die Breite der Aktionsleiste und lassen sich sauber darüber stapeln.
* **Neuinstallation und Zurücksetzen:** aufgeräumtes Startlayout ohne Überlappungen, Minimap mit 80 Prozent.
* **Minimapknopf:** größer und standardmäßig unten links; neue Option mit acht festen Positionen. Eine gespeicherte Position wird nach dem Laden jetzt richtig übernommen.
* **Chat:** kleiner Kopierknopf am Chatfenster (aus den Einstellungen dorthin verlegt).
* **Außerdem:** Charakterwerte folgen der Einstellung Abschnittstitel, die Rundenhistorie öffnet auf der aktuellen Zone, das Lootfenster behält seine Größen je Modus, die Schriftoption ist vorerst entfernt.

### 3.1.1 (2026-10-19, Release v3.1.1)

* Hotfix für Spielversion 0.101: Fenster ließen sich nicht bis an den Bildschirmrand ziehen und gespeicherte Positionen waren verschoben, weil das Spiel eine andere UIParent Größe meldet als die Fläche, die es abdeckt. Platzierung, Begrenzung, Einrasten und gespeicherte Positionen nutzen jetzt die echten Bildschirmränder. /kui grid debug zeigt beide Größen.

### 3.1.0 (2026-10-19, Release v3.1.0)

* Behoben für Spielversion 0.101: „DamageText.lua:281: SetText(): Font not set“ nach dem ersten Treffer. Neue Schadenszahlen bekommen ihre Schrift vor dem Text.
* Layoutraster: Die Linien gehen jetzt von der Bildschirmmitte aus und laufen von Rand zu Rand, die Mittellinie bleibt mittig. Das Einrasten nutzt dieselbe Mitte, Fenster richten sich jetzt am sichtbaren Raster aus. /kui grid debug meldet die Größen, die das Spiel dem Addon liefert.
* Wächter: Die Minimap Totenköpfe mit drei Zuständen sind zurück und ersetzen die rote Wächterflagge des Spiels (ab Spielversion 0.102): gold, solange ein Wächter seinen Hort hält, orange mit „!“ im Kampf, grau mit „x“ bei leerem Hort. Leere Horte bekommen erst einen Totenkopf, wenn ihr Wächter in diesem Run lebend gesehen wurde. Status, Rückkehrzeit und Entfernung beim Überfahren. Die Flagge des Spiels ist nur ausgeblendet, solange die Totenköpfe gezeichnet werden, und kehrt zurück bei ausgeschalteter Option, fehlenden Daten, im Ladebildschirm und beim Ausloggen. Die Option heißt jetzt „Wächtertotenköpfe statt Spielflagge“. Auf älteren Spielversionen bekommen nur besiegte Wächter einen grauen Totenkopf und die Flagge des Spiels bleibt.

### 3.0.1 (2026-10-19)

* Behoben für Spielversion 0.101 (Lua 5.0): der Fehler „UIPanelTemplates.lua:245: attempt to concatenate a nil value“ beim Einloggen. Das Scrollfenster der Chatkopie hat jetzt einen Namen. Der Buildtipp Tooltip nutzt kein _G mehr, das der neue Client nicht mehr bereitstellt.
* Behoben für Spielversion 0.101: „Statistics.lua: attempt to index a nil value“ und teilweise englisch bleibende Einstellungen und Fenstertitel. Das neue Spiel Lua verliert Schleifenvariablen in später aufgerufenen Funktionen; die betroffenen Beschriftungen, Tooltips und Auswahlmenüs halten jetzt eine eigene Kopie.
* Neuer Diagnosebefehl /kui menu: meldet 60 Sekunden lang im Chat, ob ESC das Spielmenü (GameMenuFrame) öffnet und ob das Optionsfenster (BenillaOptionsFrame) sichtbar ist.

### 3.0.0 (2026-10-19, Release v3.0.0)

* Einstellungen: Anzeige und Layout sind jetzt eine Kategorie „Layout & Anzeige“. Die aktive Kategorie zeigt ihre Abschnitte als Links in der Seitenleiste. Neue Regler für Menügröße und gesamte UI.
* Neuer dritter Reiter „Heilung“ in der Schadensanzeige: Heilung nach Quelle mit HPS und Anteilen.
* Boss und Wächterbalken zeigen ihre Debuffs: Symbol, Stapel und Restzeit, Details per Mauszeiger.
* Wächter: kleine Richtungspfeile neben den Wächternamen in der Runübersicht und ein Totenkopf auf der Minimap für besiegte Wächter. Totenköpfe erscheinen nur bei Wächtern, die lebend gesehen und besiegt wurden, keine am Runbeginn. Lebende Wächter behalten die Flagge des Spiels. Beides ist abschaltbar.
* Caches: Wegführung funktioniert jetzt auch in Instanzen.
* Neuer Button für gespeicherte Levelaufstiege; die Spieloption „Levelaufstiege speichern“ lässt sich unter Bedienung schalten.
* Neue optionale Anzeigen: EP pro Minute mit Zeit bis zum nächsten Level, Leben und Rerolls (zuerst freie Rerolls, dann der Preis des nächsten), eine 30 Prozent Markierung an Gegnerbalken.
* Charakterwerte: 29 wählbare Werte mit änderbarer Reihenfolge, in einem eigenen Abschnitt der Einstellungen.
* Schaden erlitten: Der Tooltip zeigt Schaden je Quelle, Treffer, Durchschnitt, Min/Max und Kritquote.
* Schmuck: durchsuchbares Tagebuch deiner Funde mit den gesehenen Werten. Abklingzeiten des Spiels erscheinen auf den Schmucksymbolen.
* Optionaler zusätzlicher Kampftext: Heilung und Schaden am Spieler.
* Die Bossansicht der Schadensanzeige springt nach dem letzten Boss zurück zu Run (optional).
* Beuteliste deutlich verbessert: Die kleine Liste zeigt für neue Gegenstände einen grünen Haken und für bereits gesammelte ein rotes Kreuz statt abgeschnittenem Text, Gegenstandsnamen haben mehr Platz, und Listen und Symbolraster verschieben sich nach dem Neuladen nicht mehr nach links.
* Neu: Schriftwahl, optionale kurze Run Meldungen und optionale Module, die sich abschalten lassen.
* Verbessert: EP Balken passt zu den anderen Fenstern, Bosstimer verbessert, ruhigere Schadenszahlen an fester Position, bessere Leistung.

### 2.4.9 (2026-10-19)

* Totenköpfe auf der Minimap erscheinen nur noch für besiegte Minibosse gemäß nativem Zustand leerer Hort und verschwinden beim Wiedererscheinen. Lebende und kämpfende Wächter behalten die native Flagge, bis eine nachgewiesene gezielte Abschaltfunktion verfügbar ist. Lebende Totenkopfvarianten und Statuszusätze entfernt. Getrennte Schalter, Richtungspfeile in der Wächterliste, Tooltips und Kartenrandbegrenzung bleiben erhalten; Einstellungen und Dokumentation erklären die Regel.

### 2.4.8 (2026-10-19)

* Rahmen genau einstellen, Zahlenfelder und Layoutprofile aus dem aktiven Addon entfernt, einschließlich Einstellungsseite, Hilfsfunktionen und Übersetzungen. Der Code liegt separat für eine mögliche spätere Verwendung. Normales Ziehen, Größenänderung per Mausrad, gespeicherte Positionen, Raster und Zurücksetzen bleiben erhalten. Die native Schriftwahl liegt im kleineren Modul Fonts.lua; der Installer sichert und entfernt LayoutTools.lua.

### 2.4.7 (2026-10-19)

* Historische Bossabschnitte aus Tooltips, Einstellung und Datenerfassung entfernt. Neue Pace Einträge und Sieg Snapshots übernehmen keine Bossabschnitte mehr. Bosszeiten des aktuellen Runs und der bestehende Pace Vergleich bleiben erhalten. Der Installer sichert und entfernt das ausgediente Modul BossHistory.lua.

### 2.4.6 (2026-10-19)

* Frei schwebende Schmuckeffektliste ohne Rahmen, ihren eigenen Layoutgriff und den zusätzlichen Schalter entfernt. Die Effekte bleiben in den vorhandenen nativen Tooltips der Gegenstandssymbole erreichbar. Native Cooldowns und ihre Schalter bleiben erhalten. Die Installation sichert und entfernt die ausgediente Datei GearDetails.lua.

### 2.4.5 (2026-10-19)

* Weltkartenoption, zugehörigen Moduleintrag und die Funktion für Projektion und Pins entfernt. Alte gespeicherte Schalter aktivieren die Funktion nicht mehr. Die Installation entfernt die ausgediente Moduldatei nach Sicherung des vorherigen Stands. Cache und Wächternavigation auf der Minimap bleiben verfügbar.

### 2.4.4 (2026-10-19)

* Der EP Balken hat jetzt dasselbe Bronzegehäuse, den dunklen Hintergrund und die abgeschrägten Ecken wie die anderen Fenster, mit einer eingerückten violetten Fortschrittsleiste. Optionale XP Rate und Levelschätzung stehen zentriert innerhalb der Leiste, statt darüber zu schweben. Der Rahmen bleibt 400 Punkte breit und passt unter die normale Buildleiste. Bestehende eigene obere Positionen, Sichtbarkeit und Schätzregeln bleiben unterstützt.

### 2.4.3 (2026-10-19)

* Zusatzleben und Rerolls bilden eine optionale zweite Reihe im bestehenden Rahmen für Kills, Gold und Caches, mit gemeinsamer Bronzeoptik, Schrift und Positionierung. Die separate schwebende Ressourcenzeile entfällt. Null bleibt sichtbar; unbekannte Werte und ausgeschaltete Reihen werden ausgeblendet. Der Preis eines weiteren Rerolls steht eindeutig benannt nur im Tooltip, statt als missverständlicher nächster Kauf.
* Die gemeinsame Anzeige wächst von ihrer Unterkante nach oben und hält Abstand zur Buildleiste. Gespeicherte Positionen und Layoutprofile werden einmalig auf diesen Anker umgestellt. Bestehende Anzeigeoptionen und Modulschalter bleiben wirksam.

### 2.4.2 (2026-10-19)

* Kurzen Diagnosebefehl /kui heal ergänzt; /kui heal debug bleibt erhalten. Zeigt jede geprüfte native Heilquelle mit Originalname, genauer Heilung und HPS sowie ausdrücklich, ob Holy Shock separat gemeldet wird. Fehlende oder alte Daten werden als nicht verfügbar benannt. Die Diagnose erfindet keine Heilwerte und behauptet keine Behebung der fehlenden Heilquelle.

### 2.4.1 (2026-10-19)

* Wächter auf der Minimap erscheinen mit transparentem Hintergrund ohne schwarze Kästchen und Bronzerahmen. Kampfstatus und leere Horte stehen zentriert neben dem vollständigen Totenkopf, statt dessen untere Ecke zu verdecken. Mehr Abstand zum Kartenrand hält die breiteren Symbole innerhalb der Minimap.

### 2.4.0 (2026-10-19)

* Optionale XP pro Minute und Levelschätzung aus empfangener nativer Runzeit. Die Schätzung benötigt mehrere Zuwächse und ausreichend Verlauf, überbrückt einen Levelwechsel und beginnt bei Messlücken oder unbekannten Zwischenleveln neu. Optionale native Zusatzleben und Rerolls ergänzt.
* Charakterauswahl auf 29 belegte native Werte mit ihren tatsächlichen Einheiten erweitert; Pfeile sortieren ausgewählte Werte. Native Quellen erlittenen Schadens sowie beobachtete Trefferanzahl, normaler Mittelwert/Min/Max und Kritquote pro Quelle im Tooltip ergänzt. Optionale 30 Prozent Markierungen erhalten die Lebensfarben.
* Durchsuchbare dauerhafte Schmucksammlung beobachteter Funde und nativer Tooltipbereiche, native Inventarcooldowns und optionale kompakte Effekttexte ergänzt. Unbekannte Gegenstände und nicht beobachtete Werte bleiben unbekannt. Native Weltkartenpins für Caches und Horte wählen die Navigation ohne Kartenwechsel; nicht unterstützte Projektionen bleiben unsichtbar.
* Genaue Rahmenpositionen und Größen, acht Layoutprofile, native Schriftauswahl, Chatkopie und optional kurze Run Einleitungen ergänzt. Elf optionale Module können ihre Aufrufe und Ereignisabonnements aussetzen, während gemeinsame Rundenspeicherung und Diagnose aktiv bleiben. Die zusätzlichen Einstellungen bleiben in den vier vorhandenen Kategorien.
* Optionale historische Bossabschnitte und getrennte Heilzahlen/eingehende Zahlen aus nativen Intervallsummen ergänzt. Die vorhandene Pace Berechnung bleibt unverändert. Native Wächterfähnchen bleiben offen; ein Sichttest im Spiel steht aus.

### 2.3.11 (2026-10-19)

* Boss und Wächter zeigen an ihren Begegnungsbalken native Debuffs nach Spawn ID: Symbole, Stapel, bekannte Restzeiten und Details beim Darüberfahren. Gleichnamige Gegner bleiben getrennt. Unbekannte Zeiten erhalten ein Fragezeichen; dauerhafte Effekte keinen Countdown. Zeiten folgen der nativen Runzeit auch in Pausen und Kartenauswahl.
* Acht Symbole pro Balken und ein Tooltip für weitere Effekte halten die Gruppe kompakt. Die bisherige Höhenbegrenzung und Mausradnavigation bleiben erhalten; ohne native Debuffschnittstelle entfallen nur die zusätzlichen Effekte. Ziel und Namensplaketten zeigen ihre Debuffs wie bisher.

### 2.3.10 (2026-10-18)

* Nur bei Feste Stelle blenden normale Schadenszahlen früher aus, bleiben etwa 0,55 bis 0,65 Sekunden und bewegen sich kürzer. Auch periodische und kleine Treffer verschwinden zügig. Kritische Treffer behalten ihre bisherige längere Dauer und Ausblendung.
* Nur bei Feste Stelle ist der Startversatz aufeinanderfolgender aufsteigender Treffer begrenzt, damit Flächentreffer keine immer höhere Zahlensäule bilden. Vorschau und Spiel verwenden dieselbe Ausblendung; Symbole blenden mit ihrer Zahl aus. Die Darstellung an Namensplaketten bleibt unverändert.

### 2.3.9 (2026-10-18)

* Kleine Lootlisten und Symbolraster wandern nach dem Neuladen nicht mehr nach links. Die tatsächliche Anzeigebreite wird vor dem Anwenden und Begrenzen gespeicherter Positionen gesetzt, auch bei später geladenen Spielerdaten. Frei platzierte Rahmen behalten ihre Position.
* Eine von einer älteren Version bereits verschobene und gespeicherte Position muss einmal zurückgezogen werden. Das Addon errät und überschreibt keine frühere Wunschposition.

### 2.3.8 (2026-10-18)

* Anzeige und Layout sind jetzt gemeinsam unter Layout & Anzeige zu finden. Auch Einheitenrahmen, Namensplaketten, Minimap, Caches und Wächternavigation sind dort mit direkten Abschnittslinks erreichbar. Zauber, Schmuck und Aktionsleiste haben einen gemeinsamen Anzeigeschalter.
* Beide Optionen für gespeicherte Level liegen unter Allgemein. Hauptmenüpunkte bleiben bronzeumrandet, heller goldfarben und ausdrücklich linksbündig, deutlich getrennt von den kleinen Abschnittslinks. Vorhandene Einstellungen und Befehle bleiben erhalten.

### 2.3.7 (2026-10-18)

* Der Hintergrund besiegter Bosse reicht jetzt über die gesamte Zeile einschließlich Name und beider Zeitspalten. Die bisherigen Pacefarben und Zeiten bleiben erhalten.
* Kleine Richtungspfeile für Wächter stehen jetzt direkt rechts neben dem jeweiligen Namen. Die Statusspalte behält ihren Platz.

### 2.3.6 (2026-10-18)

* Hortmarkierungen bleiben auch leer sichtbar. Einheitliche bronzefarbene Rahmen enthalten goldene Totenköpfe für besetzte Horte, orange mit ! für kämpfende Wächter oder graue mit X für leere Horte. Status, Rückkehrzeit und Entfernung stehen im Tooltip. Richtungspfeile führen weiterhin nur zu besetzten Horten.
* Offener Punkt: Die Standardfähnchen des Spiels wurden nicht abgeschaltet. Im aktuellen Client fehlt eine dokumentierte gezielte Steuerung. Mögliche Überlappungen mit diesen Fähnchen sind noch nicht gelöst.

### 2.3.5 (2026-10-18)

* Die Runstatistik verwendet dieselbe native effektive Heilungssumme wie der Heilungsreiter. Der Tooltip zeigt HPS des Runs und bis zu sechs stärkste Quellen mit Anteilen, ohne Überheilung. Lebensabtastung und Bruttoschätzung ersetzen keine nativen Daten mehr. Die Anzeige behält ihre Größe.
* Fehlende, ungültige oder alte Heilungsdaten bleiben unbekannt; es wird keine andere Schätzung eingesetzt. Eine gültige leere Liste bedeutet null. Ältere Clients ohne API behalten einen ausdrücklich als beobachtet bezeichneten Ersatz. /kui heal debug zeigt bei unterstützten Clients die nativen Summen.

### 2.3.4 (2026-10-18)

* Liste klein verwendet den vorhandenen grünen Haken für neue und das rote X für gesammelte Gegenstände statt abgeschnittenem Statustext. Gegenstandsnamen erhalten mehr Platz; der ausgeschriebene Status bleibt im Tooltip. Sammelstatus anzeigen steuert auch diese Symbole. Unbekannter Status bleibt ohne Markierung.

### 2.3.3 (2026-10-18)

* Der aktive Einstellungstab zeigt seine Abschnittstitel als kleine Unterpunkte links. Ein Klick springt direkt zur entsprechenden Stelle rechts. Die anderen Tabs bleiben eingeklappt. Der gewählte Abschnitt wird hervorgehoben und folgt beim manuellen Scrollen.
* Die Sprunglinks verwenden die vorhandenen Titel und Übersetzungen. Die Charakterwerte Unterseite bleibt der Anzeige zugeordnet; alle Tabs bleiben oberhalb der Fußleiste erreichbar.

### 2.3.2 (2026-10-18)

* Unter Layout gibt es Prozentregler für Menügröße (70 bis 100%) und Gesamte UI (64 bis 150%). Gesamte UI verwendet die native Spielskalierung uiScale; Spielfenster und KeijinUI wachsen gemeinsam, individuelle Rahmengrößen bleiben erhalten. Beim Laden wird keine Größe verändert.
* Beim Ziehen wird der Prozentwert angezeigt, beim Loslassen übernommen. Das Einstellungsfenster passt sich an Skalierung und Auflösung an. UI Größen zurücksetzen stellt Menügröße auf 80% und die Spielskalierung auf 90%.

### 2.3.1 (2026-10-18)

* Die Wächternavigation zeigt einen kleinen goldenen Richtungspfeil vor jedem belegten Wächternamen in der bestehenden Runübersicht. Die große Zusatzanzeige und ihr Layoutanker entfallen. Entfernung und Hinweise zum Hort stehen im Tooltip; Größe und Statusspalte der Übersicht bleiben erhalten.
* Leere Horte, unbekannte Positionen und das Verlassen des Runs blenden die Pfeile aus. Sie folgen Position und Skalierung der Übersicht. Pfeile und Minimap Symbole bleiben unabhängig schaltbar; gespeicherte Einstellungen gelten weiter.

### 2.3.0 (2026-10-18)

* Cachehilfe verwendet bevorzugt native Weltposition und Blickrichtung, auch in Instanzen sowie bei null und negativen Koordinaten. Ältere Spielversionen behalten den vermessenen Kartenfallback.
* Neue verschiebbare Wächterhilfe: Entfernung und Richtung zum belegten Hort, feste Zielauswahl, Wechsel per Klick/Mausrad und nächster Hort per Rechtsklick. Totenköpfe auf der Minimap wählen einen Hort; leere Horte verschwinden. Hilfe und Symbole sind getrennt abschaltbar.
* Neuer verschiebbarer Levelaufstieg Button zeigt wartende native Auswahlen. Im laufenden Kampf öffnet ein Klick die Auswahl. Unter Bedienung lässt sich die Spieloption zum Speichern umschalten; Laden verändert sie nicht und gibt keine Level aus. Ohne passende Schnittstelle bleibt die native Anzeige erhalten.
* Heilung als dritter Meterreiter mit nativer effektiver Heilung je Quelle, HPS, Anteilen und den bisherigen Quellenfarben. Eigene Auswahl hat Vorrang vor Bossautomatik. Reset gilt weiter nur für Run. Reiter und Summe passen auch bei schmalen und ausgeblendeten Titeln.

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
