# Herkunft

## Schrift für vereinfachtes Chinesisch

`media/fonts/KeijinCJK.ttf` kombiniert Droid Sans und Droid Sans Fallback aus
dem Android Open Source Project, Apache License 2.0. Die Schrift wurde mit
FontTools zusammengeführt und auf einheitliche Maße skaliert. Sie wird nur für
Oberflächen mit fehlenden Schriftzeichen als Ersatz und für die CJK Sprachen verwendet. Lizenz und Copyright Hinweise stehen
in `DroidSansFallback-LICENSE.md`.

Quellen und reproduzierbarer Aufbau: `development/keijinui/prepare_chinese_font.py`.
Upstream: https://android.googlesource.com/platform/frameworks/base/+/ecf4015032e9/data/fonts/

## Schriften zur Auswahl

Die Schriftauswahl nutzt zusätzlich drei Schriften unter der SIL Open Font License 1.1.
Die Lizenztexte stehen neben dieser Datei. Quelle: https://github.com/google/fonts (Verzeichnis `ofl/`).

* `media/fonts/PTSans-Regular.ttf` (PT Sans, ParaType, `OFL-PTSans.txt`)
* `media/fonts/PTSansNarrow-Regular.ttf` (PT Sans Narrow, ParaType, `OFL-PTSansNarrow.txt`)
* `media/fonts/FiraSans-Regular.ttf` (Fira Sans, Mozilla Foundation und Telefonica S.A., `OFL-FiraSans.txt`)

Die Dateien sind unverändert. Friz Quadrata und Arial Narrow stammen aus dem Spielclient
und werden nur über ihren Clientpfad referenziert. Droid Sans (`KeijinCJK.ttf`, siehe oben)
steht ebenfalls zur Auswahl. Abdeckung und Größenfaktoren erzeugt
`development/keijinui/prepare_fonts.py` (`KeijinUI/FontCatalog.lua`).

## Expressway Free 2.100

`media/fonts/Expressway.ttf` ist die unveränderte TrueType Fassung Expressway Free,
Version 2.100, Copyright 2005 Typodermic / Ray Larabie. Sie wird zusammen mit der
zugehörigen älteren Typodermic Freeware Lizenz weitergegeben:
`Expressway-Free-2.100-LICENSE.txt`. Deren Abschnitt 1 erlaubt die unveränderte
Weitergabe mit Copyright und Lizenztext. Dies ist keine aktuelle Expressway
Fassung unter der heutigen Desktoplizenz.

Quelle der identischen Schrift und des zugehörigen Lizenztexts:
https://github.com/NeticSoul/DragonUI/tree/82a6c52c93ad5eae8eda520c14204f9db72e868e/DragonUI
Dateiquellen und SHA256: `development/keijinui/expressway-source.json` im Projekt.
SHA256 der unveränderten Schrift:
`08a0e5532d6ea2e829c9661862293e4e04d929b06f51850ceb2a9b036e2c60c1`.
SHA256 des mitgelieferten Lizenztexts:
`d0ec51772929df44c151ce33ed599991b3c0d8ad833722fe4646a3bf947ce98c`.

Der vorangestellte Readme Teil dieses älteren Lizenztexts enthält zusätzlich
Einschränkungen zu gemeinsamen Fontarchiven und zur Einbindung in Software.
Für die Weitergabe in diesem kostenfreien Addon wird die ausdrückliche
Weitergabeklausel in Abschnitt 1 zugrunde gelegt. Die Schrift wird nicht verändert
oder gesondert verkauft; der vollständige zugehörige Lizenztext bleibt beigefügt.

Lua Code und erzeugte Grafiken von KeijinUI sind seit Version 0.6.0 eigene Arbeit.
Die separat lizenzierten Schriften sind oben beschrieben.

* Der Leser für Kampfnachrichten in `CombatParser.lua` ist eine eigene
  Implementierung. Er leitet die Zeilenformen zur Laufzeit aus den Kampftexten
  des Spielclients ab (GlobalStrings) und enthält keinen Code aus anderen Addons.
* Die Konturen in `media/chamfer/`, die Klassenressourcen in `media/resources/`
  und die neuen Endstücke in `media/list/` erzeugt
  `development/keijinui/prepare_ui_art.py` aus eigener Geometrie. Die eigenen
  verbundenen Unitframegrafiken in `media/soft/` behalten ihren Porträtring;
  dasselbe Skript ergänzt das freie schräge Ende in allen drei Texturlagen.
* Die weiße Statusfüllung erzeugt `development/keijinui/prepare_bar_art.py`.
  `MinimapMask.tga`
  erzeugt `development/keijinui/prepare_minimap_mask.py`.
* Die Namens und Fähigkeitstabellen in `modules/` stammen aus dem installierten
  Spielclient.

Dank an SurvivorsDragonUi (migwynkriid13) und Survivor UI (morderous). Beide
dienten als Inspiration und funktionale Vorbilder dafür, was eine Oberfläche
für Azeroth Survivors anzeigen kann. Ihr Code und ihre Texturen sind nicht
Teil dieses Pakets und werden nicht geladen.

BossMods 1.0.2 (vom Nutzer bereitgestelltes Archiv) diente zusätzlich zur
fachlichen Prüfung der Endloskennung und der Aussagekraft von Boss Timern.
Die Snapshot und Pace Implementierungen in KeijinUI sind eigene Arbeit.

Blizzard Texturen aus dem Spielclient (zum Beispiel Symbole, Statusleisten und
Porträts) werden nur über ihren Clientpfad referenziert und nicht mitgeliefert.
Blizzard behält die Rechte daran.

Referenzen:

* https://github.com/migwynkriid13/SurvivorsDragonUi
* https://github.com/morderous/survivor-ui
