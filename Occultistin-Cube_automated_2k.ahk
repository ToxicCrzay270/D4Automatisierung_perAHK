#Requires AutoHotkey v2.0
#SingleInstance Force
#MaxThreadsPerHotkey 1

StartHinweisBestaetigt := false

; F6: Anzahl 1-33 eingeben und die Item-/Okkultistin-Klickfolge starten.
; F5: Cube-Klickfolge; die letzte F6-Anzahl wird als Vorschlag eingetragen.
; +: Mausposition anzeigen und als {x: ..., y: ...} kopieren.
; Alt+F6: Skript sofort beenden.
; Koordinaten beziehen sich auf den gesamten Bildschirm, Ursprung links oben
; am Hauptmonitor. Auf weiteren Monitoren sind negative Werte moeglich.
CoordMode "Mouse", "Screen"
CoordMode "Pixel", "Screen"
SendMode "Event"
Thread "Interrupt", 0

; 2K-Version: 2560 x 1440 Pixel.
; Klickpunkte und Pruefpixel proportional aus der 4K-Vorlage skaliert.
VersionsName := "2K (2560x1440)"

; HIER DEINEN TEXT FUER DAS POPUP EINTRAGEN:
DialogText := "Gebe die anzahl der zu bearbeitenen Items ein:`nHinweis: Eine Reihe enthaelt 11 Items."
; Mehrere Zeilen im Text werden mit `n getrennt.
StartHinweisText := "Bitte erst zur Occultistin  gehen das gewünschte item rein legen und so nach Suchen das der gewünschte aspect ganz oben angezeigt wird."

; Schneller Ablauf mit schneller Mausbewegung und kurzen Wartezeiten.
Fahrgeschwindigkeit := 2    ; 0 = sofort, 1 = schnell, 100 = langsam.
PauseVorKlickMs := 25       ; Kurze Pause nach der Mausbewegung.
PauseNachKlickMs := 75      ; Wartezeit nach jedem Klick.
StartVerzoegerungMs := 125  ; Kurze Pause nach dem Schliessen des Dialogs.
CubeWartezeitMs := 1000     ; Am dritten Cube-Punkt VOR dem Linksklick warten.
LetzteF6Anzahl := 1         ; Vorschlag fuer F5, bis erstmals F6 bestaetigt wurde.
AblaufAktiv := false       ; Gemeinsame Sperre fuer F5 und F6.

; 33 Koordinatenpaare, Index 1 bis 33.
; Beispiel: Positionen[1] := {x: 1234, y: 567}
; Zugriff: Positionen[1].x und Positionen[1].y
Positionen := [
    {x: 1726, y: 1013}, ; 01
    {x: 1799, y: 1018}, ; 02
    {x: 1878, y: 1015}, ; 03
    {x: 1951, y: 1015}, ; 04
    {x: 2025, y: 1013}, ; 05
    {x: 2097, y: 1011}, ; 06
    {x: 2167, y: 1014}, ; 07
    {x: 2240, y: 1013}, ; 08
    {x: 2317, y: 1013}, ; 09
    {x: 2389, y: 1017}, ; 10
    {x: 2463, y: 1013}, ; 11
    {x: 1726, y: 1123}, ; 12
    {x: 1802, y: 1124}, ; 13
    {x: 1877, y: 1119}, ; 14
    {x: 1947, y: 1120}, ; 15
    {x: 2017, y: 1117}, ; 16
    {x: 2095, y: 1119}, ; 17
    {x: 2170, y: 1121}, ; 18
    {x: 2242, y: 1119}, ; 19
    {x: 2317, y: 1123}, ; 20
    {x: 2391, y: 1120}, ; 21
    {x: 2464, y: 1120}, ; 22
    {x: 1725, y: 1231}, ; 23
    {x: 1803, y: 1225}, ; 24
    {x: 1876, y: 1227}, ; 25
    {x: 1950, y: 1231}, ; 26
    {x: 2023, y: 1228}, ; 27
    {x: 2096, y: 1228}, ; 28
    {x: 2169, y: 1229}, ; 29
    {x: 2243, y: 1231}, ; 30
    {x: 2320, y: 1229}, ; 31
    {x: 2391, y: 1226}, ; 32
    {x: 2461, y: 1233}  ; 33
]

; Die vier festen Okkultistin-Positionen in Klickreihenfolge.
; Zum Anpassen: Maus auf den Punkt halten, + druecken und das Koordinatenpaar ersetzen.
; Diese vier Punkte werden bei JEDEM Item in derselben Reihenfolge angeklickt.
; Leere Werte verhindern den Start der Klickfolge.
OkkultistinPositionen := [
    {x: 475, y: 673},  ; Okkultistin 1
    {x: 451, y: 449},   ; Okkultistin 2
    {x: 646, y: 1220},  ; Okkultistin 3
    {x: 1183, y: 883}  ; Okkultistin 4
]

; Cube-Punkte fuer F5. Punkt 1 wird fuer jedes Item per Pixel zwischen 4/5 gewaehlt.
CubePositionen := [
    {x: 1134, y: 604},  ; Cube 1 bei Ziffer 4: Transfigure Item
    {x: 460, y: 1136},  ; Cube 2: Linksklick
    {x: 470, y: 969}   ; Cube 3: 1000 ms warten, dann Linksklick
]
CubePosition1Bei5 := {x: 1120, y: 699} ; Transfigure Item bei Ziffer 5
CubeVariantenPixel := {x: 1226, y: 244} ; 4 = hell, 5 = dunkel

; Sichtbar, solange das Skript laeuft; nimmt dem Spiel nicht den Fokus.
StatusAnzeige := ErstelleStatusAnzeige()
; Genau ein Hinweis pro Skriptstart; bis zur Bestaetigung kein F5-/F6-Ablauf.
MsgBox StartHinweisText, "Vorbereitung - " VersionsName, "Iconi"
KeyWait "F5"
KeyWait "F6"
StartHinweisBestaetigt := true

F6::StarteAblauf("F6")
F5::StarteAblauf("F5")

StarteAblauf(Modus)
{
    global DialogText, Positionen, OkkultistinPositionen, CubePositionen
    global StartVerzoegerungMs, VersionsName, CubeWartezeitMs, LetzteF6Anzahl, AblaufAktiv
    global CubePosition1Bei5, CubeVariantenPixel
    global StartHinweisBestaetigt

    if !StartHinweisBestaetigt
        return

    ; Nur die kurze Pruefung/Zuweisung ist ununterbrechbar, nicht der Ablauf.
    Critical "On"
    if AblaufAktiv
    {
        Critical "Off"
        return
    }
    AblaufAktiv := true
    Critical "Off"

    try
    {
        KeyWait Modus
        SpielFenster := WinActive("ahk_exe Diablo IV.exe")
        Art := Modus = "F5" ? "Cube" : "Okkultistin"
        Vorschlag := Modus = "F5" ? String(LetzteF6Anzahl) : ""

        Loop
        {
            Eingabe := InputBox(
                DialogText "`n`nAnzahl (1-33):",
                Art " - Items bearbeiten - " VersionsName, "w480 h200", Vorschlag
            )
            if Eingabe.Result != "OK"
                return

            Wert := Trim(Eingabe.Value)
            if RegExMatch(Wert, "\A(?:[1-9]|[12][0-9]|3[0-3])\z")
            {
                Anzahl := Integer(Wert)
                break
            }

            MsgBox "Bitte eine ganze Zahl von 1 bis 33 eingeben.",
                "Ungueltige Eingabe", "Icon!"
        }

        if Modus = "F6"
            LetzteF6Anzahl := Anzahl

        try
        {
            if Modus = "F5"
            {
                if !IsInteger(CubePosition1Bei5.x) || !IsInteger(CubePosition1Bei5.y)
                    throw ValueError("Der alternative Transfigure-Punkt fuer Ziffer 5 fehlt.")
                if !IsInteger(CubeVariantenPixel.x) || !IsInteger(CubeVariantenPixel.y)
                    throw ValueError("Der Pruefpixel fuer die Cube-Variante fehlt.")
                Klickfolge := ErstelleKlickfolge(Anzahl, Positionen, CubePositionen, "Cube", CubeWartezeitMs)
            }
            else
                Klickfolge := ErstelleKlickfolge(Anzahl, Positionen, OkkultistinPositionen)
        }
        catch ValueError as Fehler
        {
            MsgBox Fehler.Message, "Positionen eintragen", "Icon!"
            return
        }

        if !SpielFenster
        {
            MsgBox "Zum Starten Diablo IV aktivieren und dort " Modus " druecken.",
                "Items bearbeiten", "Icon!"
            return
        }

        ToolTip
        Sleep StartVerzoegerungMs
        try
        {
            for Schritt in Klickfolge
                KlickAusfuehren(Schritt, SpielFenster)
        }
        catch Error as Fehler
            MsgBox "Ablauf gestoppt:`n" Fehler.Message, "Items bearbeiten", "Icon!"
    }
    finally
    {
        AblaufAktiv := false
    }
}

; Physische Plus-Taste rechts neben Ue auf einer deutschen Tastatur.
SC01B::MauspositionKopieren()
NumpadAdd::MauspositionKopieren()

MauspositionKopieren()
{
    MouseGetPos &x, &y
    A_Clipboard := "{x: " x ", y: " y "}"
    ToolTip "X: " x " px`nY: " y " px`nKoordinaten kopiert."
    SetTimer PositionAusblenden, -3000
}

PositionAusblenden()
{
    ToolTip
}

ErstelleStatusAnzeige()
{
    global VersionsName
    Anzeige := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x08000020", "Occultistin-Cube - " VersionsName)
    Anzeige.BackColor := "20242B"
    Anzeige.MarginX := 12
    Anzeige.MarginY := 8
    Anzeige.SetFont("s11 Bold cA5F3A8", "Segoe UI")
    Anzeige.AddText("vStatusText", "Skript aktiv | " VersionsName " | Alt+F6: Beenden")
    Anzeige.SetFont("s10 Norm cFFFFFF", "Segoe UI")
    Anzeige.AddText(, "F6: Okkultistin | F5: Cube | +: Position kopieren")
    ; Layered + Transparent macht die Anzeige durchklickbar.
    WinSetTransparent 245, Anzeige
    Anzeige.Show("x15 y15 NoActivate AutoSize")
    return Anzeige
}

; Stellt die vollstaendige Folge zusammen, ohne Mausbewegungen oder Klicks.
; Alle Koordinaten werden vor dem ersten Rechtsklick geprueft.
ErstelleKlickfolge(Anzahl, ItemPositionen, FestePositionen, Art := "Okkultistin", WarteVorLetztemKlickMs := 0)
{
    if !IsInteger(Anzahl) || Anzahl < 1 || Anzahl > 33
        throw ValueError("Bitte eine ganze Zahl von 1 bis 33 eingeben.")
    if Art != "Okkultistin" && Art != "Cube"
        throw ValueError("Unbekannter Ablauf.")
    if !IsInteger(WarteVorLetztemKlickMs) || WarteVorLetztemKlickMs < 0
        throw ValueError("Die Wartezeit muss eine nichtnegative ganze Zahl sein.")
    AnzahlFesterPunkte := Art = "Cube" ? 3 : 4
    if ItemPositionen.Length < Anzahl || FestePositionen.Length != AnzahlFesterPunkte
        throw ValueError("Es werden genuegend Item-Punkte und genau " AnzahlFesterPunkte " " Art "-Punkte benoetigt.")

    for Index, Punkt in FestePositionen
    {
        if !IsInteger(Punkt.x) || !IsInteger(Punkt.y)
            throw ValueError(Art "-Position " Index " fehlt. Mit + messen und im Array " Art "Positionen eintragen.")
    }

    Folge := []
    Loop Anzahl
    {
        Item := ItemPositionen[A_Index]
        if !IsInteger(Item.x) || !IsInteger(Item.y)
            throw ValueError("Item-Position " A_Index " ist unvollstaendig.")

        Folge.Push({x: Item.x, y: Item.y, Taste: "Right"})
        for Index, Punkt in FestePositionen
        {
            Schritt := {x: Punkt.x, y: Punkt.y, Taste: "Left"}
            if Art = "Cube" && Index = 1
                Schritt.CubeVariantePruefen := true
            if Index = AnzahlFesterPunkte && WarteVorLetztemKlickMs > 0
                Schritt.WarteVorKlickMs := WarteVorLetztemKlickMs
            Folge.Push(Schritt)
        }
    }
    return Folge
}

KlickAusfuehren(Schritt, SpielFenster)
{
    global Fahrgeschwindigkeit, PauseVorKlickMs, PauseNachKlickMs, CubePosition1Bei5

    if !WinActive("ahk_id " SpielFenster)
        throw Error("Diablo IV ist nicht mehr im Vordergrund.")
    ZielX := Schritt.x
    ZielY := Schritt.y
    if Schritt.HasOwnProp("CubeVariantePruefen") && Schritt.CubeVariantePruefen
    {
        if ErkenneCubeVariante() = 5
        {
            ZielX := CubePosition1Bei5.x
            ZielY := CubePosition1Bei5.y
        }
    }
    MouseMove ZielX, ZielY, Fahrgeschwindigkeit
    WartezeitMs := Schritt.HasOwnProp("WarteVorKlickMs") ? Schritt.WarteVorKlickMs : PauseVorKlickMs
    Sleep WartezeitMs
    if !WinActive("ahk_id " SpielFenster)
        throw Error("Diablo IV ist nicht mehr im Vordergrund.")

    ToolTip
    Click ZielX, ZielY, Schritt.Taste
    Sleep PauseNachKlickMs
}

; Liest pro Item genau den einen festen Pruefpixel, direkt vor Cube-Punkt 1.
ErkenneCubeVariante()
{
    global CubeVariantenPixel
    Farbe := PixelGetColor(CubeVariantenPixel.x, CubeVariantenPixel.y)
    return CubeVarianteAusFarbe(Farbe)
}

CubeVarianteAusFarbe(Farbe)
{
    Rot := (Farbe >> 16) & 0xFF
    Gruen := (Farbe >> 8) & 0xFF
    Blau := Farbe & 0xFF
    ; Referenzen aus den 4K-Bildern: 4 = 0xD8D5CF, 5 = 0x0E0C0A.
    if Min(Rot, Gruen, Blau) >= 160
        return 4
    if Max(Rot, Gruen, Blau) <= 60
        return 5
    throw Error("Cube-Variante unklar: Pixel-Farbe " Format("0x{:06X}", Farbe) ". Ablauf gestoppt.")
}

!F6::ExitApp
