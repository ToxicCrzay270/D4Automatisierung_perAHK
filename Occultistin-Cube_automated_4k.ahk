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

; 4K-Version: 3840 x 2160 Pixel.
VersionsName := "4K (3840x2160)"

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
    {x: 2589, y: 1519}, ; 01
    {x: 2699, y: 1527}, ; 02
    {x: 2817, y: 1523}, ; 03
    {x: 2926, y: 1523}, ; 04
    {x: 3037, y: 1519}, ; 05
    {x: 3145, y: 1517}, ; 06
    {x: 3251, y: 1521}, ; 07
    {x: 3360, y: 1519}, ; 08
    {x: 3475, y: 1519}, ; 09
    {x: 3584, y: 1525}, ; 10
    {x: 3694, y: 1519}, ; 11
    {x: 2589, y: 1684}, ; 12
    {x: 2703, y: 1686}, ; 13
    {x: 2815, y: 1678}, ; 14
    {x: 2920, y: 1680}, ; 15
    {x: 3026, y: 1676}, ; 16
    {x: 3143, y: 1679}, ; 17
    {x: 3255, y: 1681}, ; 18
    {x: 3363, y: 1678}, ; 19
    {x: 3475, y: 1685}, ; 20
    {x: 3587, y: 1680}, ; 21
    {x: 3696, y: 1680}, ; 22
    {x: 2587, y: 1846}, ; 23
    {x: 2705, y: 1838}, ; 24
    {x: 2814, y: 1841}, ; 25
    {x: 2925, y: 1847}, ; 26
    {x: 3035, y: 1842}, ; 27
    {x: 3144, y: 1842}, ; 28
    {x: 3253, y: 1843}, ; 29
    {x: 3365, y: 1846}, ; 30
    {x: 3480, y: 1843}, ; 31
    {x: 3586, y: 1839}, ; 32
    {x: 3691, y: 1850}  ; 33
]

; Die vier festen Okkultistin-Positionen in Klickreihenfolge.
; Zum Anpassen: Maus auf den Punkt halten, + druecken und das Koordinatenpaar ersetzen.
; Diese vier Punkte werden bei JEDEM Item in derselben Reihenfolge angeklickt.
; Leere Werte verhindern den Start der Klickfolge.
OkkultistinPositionen := [
    {x: 713, y: 1009},  ; Okkultistin 1
    {x: 677, y: 673},   ; Okkultistin 2
    {x: 969, y: 1830},  ; Okkultistin 3
    {x: 1775, y: 1325}  ; Okkultistin 4
]

; Cube-Punkte fuer F5. Punkt 1 wird fuer jedes Item per Pixel zwischen 4/5 gewaehlt.
CubePositionen := [
    {x: 1701, y: 906},  ; Cube 1 bei Ziffer 4: Transfigure Item
    {x: 690, y: 1704},  ; Cube 2: Linksklick
    {x: 705, y: 1454}   ; Cube 3: 1000 ms warten, dann Linksklick
]
CubePosition1Bei5 := {x: 1680, y: 1049} ; Transfigure Item bei Ziffer 5
CubeVariantenPixel := {x: 1839, y: 366} ; 4 = hell, 5 = dunkel

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
