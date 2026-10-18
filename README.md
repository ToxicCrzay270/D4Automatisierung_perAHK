# D4Automatisierung_perAHK

AutoHotkey-v2-Skripte für die Okkultistin und den Horadrischen Würfel in Diablo IV. Die Skripte bearbeiten bis zu 33 Inventarplätze mit festen Bildschirmkoordinaten.

## Beispielvideo

[Beispielvideo ansehen: So arbeitet das Skript (Medal.tv)](https://medal.tv/games/diablo-4/clips/nKFjRYUpU_McCvNA8?invite=cr-MSw5NU4sNTg0NTAzMDEz)

## Voraussetzungen und Start

1. Windows und [AutoHotkey v2](https://www.autohotkey.com/) installieren. AutoHotkey v1 wird nicht unterstützt.
2. Das Repository herunterladen oder klonen und Diablo IV mit der passenden Auflösung öffnen.
3. `Run-Occultistin-Cube.cmd` starten und die Auflösung auswählen. Alternativ die passende `.ahk`-Datei direkt mit AutoHotkey v2 öffnen.
4. Den einmaligen Vorbereitungshinweis bestätigen. Für F6 zuerst bei der Okkultistin das gewünschte Item einlegen und so suchen, dass der gewünschte Aspekt ganz oben steht. Für F5 das Würfelmenü öffnen.
5. Diablo IV in den Vordergrund bringen und F6 oder F5 drücken.

| Datei | Auflösung |
| --- | --- |
| `Occultistin-Cube_automated_4k.ahk` | 3840 × 2160 |
| `Occultistin-Cube_automated_2k.ahk` | 2560 × 1440 (QHD) |
| `Occultistin-Cube_automated_FullHD.ahk` | 1920 × 1080 |

Immer nur eine Variante gleichzeitig starten, da alle dieselben Tasten verwenden. Ein Hinweis oben links zeigt die aktive Version an. Python oder weitere Laufzeitbibliotheken werden nicht benötigt.

## Tasten

| Taste | Funktion |
| --- | --- |
| F6 | Anzahl von 1 bis 33 eingeben und Okkultistin-Ablauf starten |
| F5 | Würfel-Ablauf starten; die letzte gültige F6-Anzahl steht als änderbarer Vorschlag im Dialog |
| `+` rechts neben Ü oder Nummernblock-`+` | Mausposition anzeigen und als `{x: ..., y: ...}` in die Zwischenablage kopieren |
| Alt + F6 | Skript sofort beenden, auch während Wartezeiten oder eines Dialogs |

Die F6-Anzahl wird nur bis zum Beenden des Skripts gespeichert. Anfangs ist der F5-Vorschlag 1. Eine Änderung im F5-Dialog überschreibt die gespeicherte F6-Anzahl nicht. Eine Inventarreihe enthält 11 Items; verarbeitet werden die Positionen 1 bis zur eingegebenen Anzahl, zeilenweise von links nach rechts.

## Abläufe

**F6:** Für jedes Item: Rechtsklick auf den Inventarplatz, danach jeweils ein Linksklick auf die vier festen Okkultistin-Positionen.

**F5:** Für jedes Item: Rechtsklick auf den Inventarplatz, Linksklick auf „Transfigure Item“, Linksklick auf Würfelposition 2, Maus zu Würfelposition 3, dort 1000 ms warten und dann links klicken.

Vor „Transfigure Item“ liest F5 für jedes Item einen Pixel an der Ziffer in „Item Modification (4/5)“. Helle RGB-Kanäle (alle mindestens 160) wählen die Position für 4, dunkle Kanäle (alle höchstens 60) die Position für 5. Bei einem Zwischenwert oder einem Lesefehler stoppt der Ablauf vor diesem Klick.

| Auflösung | Prüfpixel X/Y | Transfigure bei 4 X/Y | Transfigure bei 5 X/Y |
| --- | --- | --- | --- |
| 4K | 1839 / 366 | 1701 / 906 | 1680 / 1049 |
| QHD | 1226 / 244 | 1134 / 604 | 1120 / 699 |
| Full HD | 920 / 183 | 851 / 453 | 840 / 525 |

F5 und F6 können nicht gleichzeitig ablaufen. Vor jeder Mausbewegung und jedem Klick wird geprüft, ob das beim Start erfasste Diablo-IV-Fenster noch im Vordergrund ist. Bei Fokusverlust stoppt die Folge. Die Eingabedialoge und die Taste `+` reagieren auch außerhalb des Spiels.

## Koordinaten und Timing anpassen

Die Koordinaten gelten für den gesamten Bildschirm mit Ursprung links oben am Hauptmonitor. Die gewählte Auflösung, Fensterposition, UI-Skalierung und Scrollposition müssen zur Einrichtung passen. Die QHD- und Full-HD-Werte wurden aus 4K umgerechnet; ihre Pixel-Erkennung ist im Spiel noch nicht bestätigt. Schrift-Rasterung kann eine manuelle Anpassung des Prüfpixels erfordern.

Mit `+` die gewünschte Position kopieren und im jeweiligen Skript eintragen:

- `Positionen`: 33 Inventarplätze.
- `OkkultistinPositionen`: vier feste Klickpunkte für F6.
- `CubePositionen`: drei feste Klickpunkte für F5, erster Punkt für Variante 4.
- `CubePosition1Bei5`: abweichender erster Punkt für Variante 5.
- `CubeVariantenPixel`: fester Messpunkt in der Ziffer 4/5.

Die Wartezeiten stehen am Dateianfang: `PauseVorKlickMs`, `PauseNachKlickMs`, `StartVerzoegerungMs` und `CubeWartezeitMs`. `Fahrgeschwindigkeit` steuert die Mausbewegung (0 = sofort).

Die Erkennung ist ein Helligkeitsvergleich eines einzelnen Pixels. Sie prüft weder den Item-Inhalt noch die Bereitschaft des Menüs. Nach Änderungen zunächst mit einem Item prüfen; die Spielreaktion und das Timing sind kein Bestandteil der Offline-Prüfung.

## Offline-Prüfung

Der Prüfer unter `Tests/Test-AhkScripts.ps1` läuft unter Windows PowerShell 5.1 oder PowerShell 7. Er prüft die Syntax aller drei Skripte mit AutoHotkey v2 und testet die Klickfolgen mit simulierten Maus-, Fenster- und Pixelzugriffen. Dabei werden keine Spielklicks ausgeführt.

```powershell
.\Tests\Test-AhkScripts.ps1 -AutoHotkeyPath 'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe'
```

Die Prüfung ersetzt keinen Test der Bildschirmkoordinaten und Spielreaktionen in der jeweiligen Auflösung.
