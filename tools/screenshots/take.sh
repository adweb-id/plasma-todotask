#!/bin/sh
# Takes the README / KDE Store screenshots with demo data (demo-todo.md).
# Installs a throw-away copy of the widget under its own ID and runs it with
# plasmawindowed inside a virtual KWin (its own Wayland display and D-Bus
# session) with a config folder of its own: nothing appears on your screen,
# nothing of your screen is captured, and your own todo.md, settings and
# colours are never touched. ScreenshotDriver.qml puts
# the widget in each scenario and renders its window to a PNG.
# Output: docs/screenshots/*.png
#
#   sh tools/screenshots/take.sh            # all scenarios
#   sh tools/screenshots/take.sh menu       # just one
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
OUT="$ROOT/docs/screenshots"
ID="com.adweb.todotask.screenshots"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$OUT"

TODAY=$(date +%F)
YESTERDAY=$(date -d yesterday +%F)

# name|colours|width|height  (five scenarios: the KDE Store takes at most 5 images)
SCENARIOS='overview|BreezeDark|400|780
groups|BreezeDark|400|640
menu|BreezeDark|400|560
toast|BreezeDark|400|560
overview-light|BreezeLight|400|780'

# A config folder of its own: demo Documents folder, one Breeze colour scheme
sandbox() {
    colours=$1
    rm -rf "$WORK/cfg" "$WORK/docs"
    mkdir -p "$WORK/cfg" "$WORK/docs"
    echo "XDG_DOCUMENTS_DIR=\"$WORK/docs\"" > "$WORK/cfg/user-dirs.dirs"
    cp "/usr/share/color-schemes/$colours.colors" "$WORK/cfg/kdeglobals"
    icons=breeze
    [ "$colours" = BreezeDark ] && icons=breeze-dark
    # KDE's default fonts, so sizes match a stock desktop
    printf '\n[General]\nColorScheme=%s\nfont=Noto Sans,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1\nsmallestReadableFont=Noto Sans,8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1\nmenuFont=Noto Sans,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1\ntoolBarFont=Noto Sans,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1\n\n[Icons]\nTheme=%s\n' "$colours" "$icons" >> "$WORK/cfg/kdeglobals"
    printf '[Theme]\nname=default\n' > "$WORK/cfg/plasmarc"
    sed -e "s/@TODAY@/$TODAY/g" -e "s/@YESTERDAY@/$YESTERDAY/g" "$HERE/demo-todo.md" > "$WORK/docs/todo.md"
}

shoot() {
    name=$1 colours=$2 w=$3 h=$4
    scenario=${name%-light}

    # Throw-away package: own ID, the driver added to main.qml
    rm -rf "$WORK/pkg" && mkdir -p "$WORK/pkg"
    cp -r "$ROOT/metadata.json" "$ROOT/contents" "$WORK/pkg/"
    sed -i "s/\"com.adweb.todotask\"/\"$ID\"/" "$WORK/pkg/metadata.json"
    sed -e "s/@SCENARIO@/$scenario/" -e "s|@OUT@|$OUT/$name.png|" -e "s/@WIDTH@/$w/" -e "s/@HEIGHT@/$h/" \
        "$HERE/ScreenshotDriver.qml" > "$WORK/pkg/contents/ui/ScreenshotDriver.qml"
    sed -i '$ d' "$WORK/pkg/contents/ui/main.qml"
    printf '\n    ScreenshotDriver { widget: root }\n}\n' >> "$WORK/pkg/contents/ui/main.qml"
    kpackagetool6 -t Plasma/Applet -r "$ID" >/dev/null 2>&1 || true
    kpackagetool6 -t Plasma/Applet -i "$WORK/pkg" >/dev/null 2>&1

    sandbox "$colours"
    rm -f "$OUT/$name.png"
    printf '#!/bin/sh\nexec timeout 30 plasmawindowed "%s"\n' "$ID" > "$WORK/session.sh"
    chmod +x "$WORK/session.sh"
    XDG_CONFIG_HOME="$WORK/cfg" timeout 60 dbus-run-session -- kwin_wayland --virtual --no-lockscreen \
        --no-global-shortcuts --socket "todotask-shot-$$" --width 1200 --height 1000 \
        --exit-with-session "$WORK/session.sh" >"$WORK/log" 2>&1 || true
    if [ -s "$OUT/$name.png" ]; then
        python3 "$HERE/frame.py" "$OUT/$name.png" "/usr/share/color-schemes/$colours.colors" "$WORK/log"
        rm -f "$OUT/$name.menu.png"
        echo "$name.png"
    else
        echo "$name.png FAILED" >&2
        grep -v QThreadStorage "$WORK/log" | tail -15 >&2
    fi
}

printf '%s\n' "$SCENARIOS" | while IFS='|' read -r name colours w h; do
    if [ -z "$1" ] || [ "$1" = "$name" ]; then
        shoot "$name" "$colours" "$w" "$h"
    fi
done
kpackagetool6 -t Plasma/Applet -r "$ID" >/dev/null 2>&1 || true
