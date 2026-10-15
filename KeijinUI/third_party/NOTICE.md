# Herkunft

Seit Version 0.6.0 besteht KeijinUI vollständig aus eigener Arbeit.

* Der Leser für Kampfnachrichten in `CombatParser.lua` ist eine eigene
  Implementierung. Er leitet die Zeilenformen zur Laufzeit aus den Kampftexten
  des Spielclients ab (GlobalStrings) und enthält keinen Code aus anderen Addons.
* Die Balkengrafiken in `media/` (Rahmenteile und Füllung) erzeugt das Skript
  `development/keijinui/prepare_bar_art.py` prozedural. `MinimapMask.tga`
  erzeugt `development/keijinui/prepare_minimap_mask.py`.
* Die Namens und Fähigkeitstabellen in `modules/` stammen aus dem installierten
  Spielclient.

Dank an SurvivorsDragonUi (migwynkriid13) und Survivor UI (morderous). Beide
dienten als Inspiration und funktionale Vorbilder dafür, was eine Oberfläche
für Azeroth Survivors anzeigen kann. Ihr Code und ihre Texturen sind nicht
Teil dieses Pakets und werden nicht geladen.

Blizzard Texturen aus dem Spielclient (zum Beispiel Symbole, Statusleisten und
Porträts) werden nur über ihren Clientpfad referenziert und nicht mitgeliefert.
Blizzard behält die Rechte daran.

Referenzen:

* https://github.com/migwynkriid13/SurvivorsDragonUi
* https://github.com/morderous/survivor-ui
