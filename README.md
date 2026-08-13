# Spider-Verse: Midtown After Dark

Ein spielbares Godot-4-Action-Projekt mit dem hochgeladenen Spider-Man-Modell. Die Stadt wird beim Start prozedural aufgebaut, damit das ZIP klein bleibt und du die Welt später leicht erweitern kannst.

## Was enthalten ist

- Third-Person-Steuerung mit WASD, Sprint, Sprung und Wall-Jump
- Web-Swinging auf Gebäudeflächen mit sichtbarer Web-Leine
- Reel-In/Reel-Out für mehr Kontrolle über den Schwung
- Spider-Man Brand New Day FBX-Modell mit Diffuse- und Normal-Texturen
- Neon-Midtown mit Gebäuden, Straßen, Dachlichtern und prozeduralem Himmel
- Hunter-Drohnen mit Orbit-KI, Schaden und Nahkampf
- Mission: Beacon erreichen, Hunter-Welle beseitigen, danach Free Roam
- XP, Combo, Health, Daten-Shards und HUD
- Godot-Editor-Projekt ohne externe Plugins

## Starten

1. Installiere Godot 4.7 oder neuer von https://godotengine.org/download/archive/
2. Entpacke dieses ZIP vollständig.
3. Öffne Godot und wähle **Import**.
4. Wähle die Datei `project.godot` im entpackten Ordner.
5. Starte das Projekt mit **F6/F5** oder dem Play-Button.

Beim ersten Import kann Godot das FBX-Modell kurz verarbeiten. Falls der Importer auf deinem System kein FBX unterstützt, zeigt das HUD den Trainings-Silhouetten-Modus an; das Spiel bleibt trotzdem spielbar.

## Steuerung

| Taste | Aktion |
| --- | --- |
| W A S D | Laufen |
| Shift | Sprint |
| Space | Springen / Wall-Jump |
| F oder linke Maustaste | Web anheften / beim Loslassen abspringen |
| Z / X | Web einholen / ausgeben |
| Q oder rechte Maustaste | Spider-Strike |
| Escape | Maus freigeben bzw. wieder einfangen |

## Als EXE exportieren

### Über den Godot-Editor

1. Öffne das Projekt.
2. Gehe zu **Project > Export**.
3. Klicke **Add... > Windows Desktop**.
4. Klicke **Export Project**.
5. Speichere als `build/SpiderVerseMidtown.exe`.

Godot erstellt neben der EXE die benötigten Spieldateien. Verschiebe nicht nur die EXE allein; verteile den gesamten Export-Ordner oder packe ihn wieder als ZIP.

### Über CMD

Öffne **CMD** im Projektordner. Setze den Pfad auf deine Godot-Konsole und führe aus:

```cmd
mkdir build
"C:\Godot\Godot_v4.7-stable_win64_console.exe" --headless --path . --export-release "Windows Desktop" "build\SpiderVerseMidtown.exe"
```

Der Name `Windows Desktop` muss exakt dem Export-Preset im Projekt entsprechen. Beim ersten Mal müssen die passenden **Export Templates** in Godot installiert sein.

## Mit CMD auf GitHub pushen

Ersetze `DEIN-USERNAME` und `DEIN-REPOSITORY` durch deine GitHub-Daten. Erstelle das leere Repository vorher auf GitHub; füge dort keine README und keine `.gitignore` hinzu, damit es keinen Merge-Konflikt gibt.

```cmd
cd C:\Pfad\zu\SpiderVerseMidtown
git init
git add .
git commit -m "Create Spider-Verse Midtown After Dark"
git branch -M main
git remote add origin https://github.com/DEIN-USERNAME/DEIN-REPOSITORY.git
git push -u origin main
```

Wenn Git nach deinem GitHub-Namen oder einem Token fragt, nutze GitHub CLI oder einen persönlichen GitHub-Token. Niemals Passwörter oder Tokens in dieses Projekt oder in die README schreiben.

## GitHub Actions: EXE automatisch bauen

Eine fertige Workflow-Datei liegt bereits unter `.github/workflows/build-windows.yml`. Nach jedem Push auf `main`:

1. Öffne dein Repository auf GitHub.
2. Gehe zu **Actions**.
3. Öffne **Build Windows EXE**.
4. Warte, bis der Lauf grün ist.
5. Lade unter **Artifacts** das Paket `SpiderVerse-Midtown-Windows` herunter.

Die Datei `export_presets.cfg` enthält das benötigte Preset `Windows Desktop`. Falls Godot 4.7.0 noch nicht als Template verfügbar ist, ändere die `version` im Workflow auf die von dir installierte Godot-4-Version und passe bei Bedarf das Preset an.

## Asset-Hinweis

Das Modell und die Texturen stammen aus dem hochgeladenen Asset-Paket. Prüfe vor einer öffentlichen Veröffentlichung, ob du die nötigen Rechte zur Weitergabe und Nutzung des Spider-Man-Modells besitzt.