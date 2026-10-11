#!/usr/bin/env bash
# Screen recording script using wf-recorder & rofi for Hyprland

THEME="$HOME/.config/rofi/minimal.rasi"
VIDEOS_DIR="$HOME/Videos/Recordings"
PID_FILE="/tmp/wf-recorder.pid"
NAME_FILE="/tmp/wf-recorder-name.txt"

mkdir -p "$VIDEOS_DIR"

# --- TOGGLE: STOP IF ALREADY RECORDING ---
if pidof wf-recorder >/dev/null 2>&1; then
    kill -2 $(pidof wf-recorder) 2>/dev/null
    
    # Wait for file to close properly
    while pidof wf-recorder >/dev/null 2>&1; do
        sleep 0.2
    done
    
    RECORDED_FILE=""
    if [ -f "$NAME_FILE" ]; then
        RECORDED_FILE=$(cat "$NAME_FILE")
        rm -f "$NAME_FILE" "$PID_FILE"
    fi
    
    if [ -n "$RECORDED_FILE" ] && [ -f "$RECORDED_FILE" ]; then
        BASENAME=$(basename "$RECORDED_FILE")
        notify-send -i media-record "Enregistrement terminé" "Vidéo sauvegardée :\n$BASENAME"
    else
        notify-send -i media-record "Enregistrement terminé" "Vidéo enregistrée dans ~/Videos/Recordings/"
    fi
    exit 0
fi

# --- MODE SELECTION ---
AUDIO=false
GEOM=""

MODE="$1"

if [ -z "$MODE" ]; then
    CHOICE=$(echo -e "󰕧  Plein écran (avec audio)\n󰒉  Zone sélectionnée (avec audio)\n󰕧  Plein écran (sans audio)\n󰒉  Zone sélectionnée (sans audio)" | \
        rofi -dmenu -p "󰕧 Enregistrement" \
        -theme-str 'window { width: 440px; } entry { placeholder: "Choisir le mode d'\''enregistrement..."; }' \
        -theme "$THEME")

    [ -z "$CHOICE" ] && exit 0

    case "$CHOICE" in
        *"Plein écran (avec audio)"*)
            AUDIO=true
            ;;
        *"Zone sélectionnée (avec audio)"*)
            AUDIO=true
            GEOM=$(slurp 2>/dev/null)
            [ -z "$GEOM" ] && exit 0
            ;;
        *"Plein écran (sans audio)"*)
            AUDIO=false
            ;;
        *"Zone sélectionnée (sans audio)"*)
            AUDIO=false
            GEOM=$(slurp 2>/dev/null)
            [ -z "$GEOM" ] && exit 0
            ;;
        *)
            exit 0
            ;;
    esac
else
    case "$MODE" in
        --area)
            GEOM=$(slurp 2>/dev/null)
            [ -z "$GEOM" ] && exit 0
            AUDIO=false
            ;;
        --area-audio)
            GEOM=$(slurp 2>/dev/null)
            [ -z "$GEOM" ] && exit 0
            AUDIO=true
            ;;
        --fullscreen-audio)
            AUDIO=true
            ;;
        --fullscreen|*)
            AUDIO=false
            ;;
    esac
fi

OUTPUT_FILE="$VIDEOS_DIR/recording_$(date +'%Y-%m-%d_%H-%M-%S').mp4"
echo "$OUTPUT_FILE" > "$NAME_FILE"

# Build wf-recorder command
CMD=(wf-recorder)

if [ "$AUDIO" = true ]; then
    CMD+=(-a)
fi

if [ -n "$GEOM" ]; then
    CMD+=(-g "$GEOM")
fi

CMD+=(-f "$OUTPUT_FILE")

# Launch wf-recorder
"${CMD[@]}" >/dev/null 2>&1 &
REC_PID=$!
echo "$REC_PID" > "$PID_FILE"

sleep 0.3
if ps -p "$REC_PID" >/dev/null 2>&1; then
    notify-send -i media-record -t 3000 "Enregistrement démarré" "🔴 Enregistrement en cours...\nRappuyez sur le raccourci pour arrêter."
else
    notify-send -u critical -i dialog-error "Erreur" "Impossible de démarrer l'enregistrement vidéo."
    rm -f "$PID_FILE" "$NAME_FILE"
fi
