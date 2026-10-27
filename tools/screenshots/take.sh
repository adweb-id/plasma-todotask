#!/bin/sh
# Takes the README / KDE Store screenshots: a whole Plasma desktop (Breeze
# Light, 1440x900) with Todo Task in the system tray and demo data
# (demo-todo.md). It runs in a virtual KWin with its own Wayland display,
# D-Bus session, home, config and data folders: nothing appears on your screen,
# nothing of your screen is captured, and your own files, settings and theme
# are never touched. ScreenshotDriver.qml puts the widget in each scenario,
# Spectacle captures the virtual screen.
# Output: docs/screenshots/*.png
#
#   sh tools/screenshots/take.sh            # all scenarios
#   sh tools/screenshots/take.sh menu       # just one
#
# Needs plasmashell, kwin_wayland, spectacle, kate and python3.
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
OUT="$ROOT/docs/screenshots"
WORK="$(mktemp -d)"
mkdir -p "$OUT"

# Every process of the demo desktop has HOME=$WORK/home. The session's D-Bus
# starts services (kactivitymanagerd, ksecretd, xdg-desktop-portal ...) that
# can outlive it as orphan processes, so all of them are ended afterwards.
sweep() {
    for sig in TERM KILL; do
        found=0
        for dir in /proc/[0-9]*; do
            [ -r "$dir/environ" ] || continue
            if tr '\0' '\n' 2>/dev/null < "$dir/environ" | grep -qx "HOME=$WORK/home"; then
                kill -s "$sig" "${dir#/proc/}" 2>/dev/null && found=1
            fi
        done
        [ "$found" = 1 ] || break
        sleep 1
    done
}
trap 'sweep; rm -rf "$WORK"' EXIT

# Runs $WORK/session.sh as the session of a virtual KWin, with only KDE's
# own defaults (XDG_CONFIG_DIRS without your kdedefaults)
desktop() {
    (
        export XDG_CONFIG_DIRS=/etc/xdg HOME="$WORK/home" XDG_CONFIG_HOME="$WORK/home/.config" \
            XDG_DATA_HOME="$WORK/home/.local/share" XDG_CACHE_HOME="$WORK/home/.cache" XDG_STATE_HOME="$WORK/home/.local/state"
        mkdir -p "$XDG_CACHE_HOME" "$XDG_STATE_HOME"
        timeout 90 dbus-run-session -- kwin_wayland --virtual --no-lockscreen --no-global-shortcuts \
            --socket "todotask-shot-$$" --width 1440 --height 900 \
            --exit-with-session "$WORK/session.sh" > "$WORK/kwin.log" 2>&1 || true
    )
    sweep
}

# A fresh home: demo task file, Breeze Light, Kate without its path bar and
# placed left of the popup, the widget installed with the scenario driver
fresh_home() {
    scenario=$1
    rm -rf "$WORK/home"
    mkdir -p "$WORK/home/Documents/todotask" "$WORK/home/.config" "$WORK/home/.local/share"
    sed -e "s/@TODAY@/$(date +%F)/g" -e "s/@D1@/$(date -d '1 day ago' +%F)/g" \
        -e "s/@D2@/$(date -d '2 days ago' +%F)/g" -e "s/@D9@/$(date -d '9 days ago' +%F)/g" \
        "$HERE/demo-todo.md" > "$WORK/home/Documents/todotask/todo.md"
    echo "XDG_DOCUMENTS_DIR=\"$WORK/home/Documents\"" > "$WORK/home/.config/user-dirs.dirs"
    cp /usr/share/color-schemes/BreezeLight.colors "$WORK/home/.config/kdeglobals"
    printf '\n[General]\nColorScheme=BreezeLight\n\n[Icons]\nTheme=breeze\n\n[KDE]\nLookAndFeelPackage=org.kde.breeze.desktop\n' >> "$WORK/home/.config/kdeglobals"
    printf '[Theme]\nname=default\n' > "$WORK/home/.config/plasmarc"
    printf '[General]\nShow Url Nav Bar=false\n' > "$WORK/home/.config/katerc"
    printf '[General]\ncount=1\nrules=1\n\n[1]\nDescription=Kate\nwmclass=kate\nwmclassmatch=2\nposition=36,70\npositionrule=3\nsize=900,720\nsizerule=3\n' > "$WORK/home/.config/kwinrulesrc"
    [ -f "$WORK/layout" ] && cp "$WORK/layout" "$WORK/home/.config/plasma-org.kde.plasma.desktop-appletsrc"
    rm -rf "$WORK/pkg" && mkdir -p "$WORK/pkg"
    cp -r "$ROOT/metadata.json" "$ROOT/contents" "$WORK/pkg/"
    sed "s/@SCENARIO@/$scenario/" "$HERE/ScreenshotDriver.qml" > "$WORK/pkg/contents/ui/ScreenshotDriver.qml"
    sed -i '$ d' "$WORK/pkg/contents/ui/main.qml"
    printf '\n    ScreenshotDriver { widget: root }\n}\n' >> "$WORK/pkg/contents/ui/main.qml"
    XDG_DATA_HOME="$WORK/home/.local/share" kpackagetool6 -t Plasma/Applet -i "$WORK/pkg" >/dev/null 2>&1
}

# Plasma's default layout, then: Todo Task shown in the tray, a taller tray
# popup, and only KDE apps pinned in the task bar
make_layout() {
    fresh_home none
    printf '#!/bin/sh\nplasmashell --no-respawn >/dev/null 2>&1 &\nsleep 10\n' > "$WORK/session.sh"
    chmod +x "$WORK/session.sh"
    desktop
    python3 - "$WORK/home/.config/plasma-org.kde.plasma.desktop-appletsrc" "$WORK/layout" <<'PY'
import re, sys
text = open(sys.argv[1]).read()
groups = re.findall(r"^\[(.*)\]$", text, re.M)
def section(name):
    m = re.search(r"^\[" + re.escape(name) + r"\]\n(.*?)(?=^\[|\Z)", text, re.M | re.S)
    return m
def find(plugin):
    for g in groups:
        m = section(g)
        if m and re.search(r"^plugin=" + re.escape(plugin) + r"$", m.group(1), re.M):
            return g
    raise SystemExit("no " + plugin + " in the default layout")
def put(group, key, value):
    global text
    m = section(group)
    if not m:
        text += "\n[" + group + "]\n" + key + "=" + value + "\n"
        return
    body = m.group(1)
    if re.search(r"^" + re.escape(key) + r"=", body, re.M):
        body = re.sub(r"^" + re.escape(key) + r"=.*$", key + "=" + value, body, flags=re.M)
    else:
        body = key + "=" + value + "\n" + body
    text = text[:m.start(1)] + body + text[m.end(1):]
tray = find("org.kde.plasma.systemtray")
put(tray, "popupHeight", "700")
put(tray, "popupWidth", "440")
general = section(tray + "][General").group(1)
for key in ("extraItems", "knownItems"):
    items = re.search(r"^" + key + r"=(.*)$", general, re.M).group(1)
    put(tray + "][General", key, "com.adweb.todotask," + items)
put(tray + "][General", "shownItems", "com.adweb.todotask")
tasks = find("org.kde.plasma.icontasks")
put(tasks + "][Configuration][General", "launchers", ",".join("applications:" + a for a in
    ["org.kde.dolphin.desktop", "org.kde.konsole.desktop", "org.kde.kate.desktop", "systemsettings.desktop", "org.kde.discover.desktop"]))
open(sys.argv[2], "w").write(text)
PY
}

# name|scenario|Kate open with the task file
SCENARIOS='overview|overview|kate
search|search|
menu|menu|
reminder|reminder|kate
settings|settings|'

shoot() {
    name=$1 scenario=$2 kate=$3
    fresh_home "$scenario"
    extra=""
    [ -n "$kate" ] && extra="(sleep 3; kate -n '$WORK/home/Documents/todotask/todo.md' >/dev/null 2>&1) &"
    printf '#!/bin/sh\nplasmashell --no-respawn >/dev/null 2>&1 &\n%s\nsleep 20\nspectacle -b -n -f -o %s >/dev/null 2>&1\nsleep 1\n' \
        "$extra" "$OUT/$name.png" > "$WORK/session.sh"
    chmod +x "$WORK/session.sh"
    rm -f "$OUT/$name.png"
    desktop
    if [ -s "$OUT/$name.png" ]; then
        echo "$name.png"
    else
        echo "$name.png FAILED" >&2
        tail -15 "$WORK/kwin.log" >&2
    fi
}

make_layout
printf '%s\n' "$SCENARIOS" | while IFS='|' read -r name scenario kate; do
    if [ -z "$1" ] || [ "$1" = "$name" ]; then
        shoot "$name" "$scenario" "$kate"
    fi
done
