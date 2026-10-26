#!/data/data/com.termux/files/usr/bin/bash
# codex-ter-ui - Termux terminal theme
# Install:   curl -fsSL https://raw.githubusercontent.com/YOUR_USER/codex-ter-ui/main/install.sh | bash
# Uninstall: codex-ter-ui uninstall

VER="1.0.0"
REPO_RAW="https://raw.githubusercontent.com/YOUR_USER/codex-ter-ui/main/install.sh"
FONT_URL="https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/JetBrainsMono/Ligatures/Regular/JetBrainsMonoNerdFont-Regular.ttf"

DIR="$HOME/.codex-ter-ui"
BK="$DIR/backup"
T="$HOME/.termux"
RC="$HOME/.bashrc"

R=$'\e[38;5;196m'; G=$'\e[38;5;245m'; N=$'\e[0m'
say() { printf "%s❯%s %s\n" "$R" "$N" "$*"; }

if [ ! -d /data/data/com.termux ]; then
  echo "codex-ter-ui works on Termux only."; exit 1
fi

if [ "$1" = "--uninstall" ]; then
  [ -f "$DIR/uninstall.sh" ] && exec bash "$DIR/uninstall.sh"
  echo "codex-ter-ui is not installed."; exit 0
fi

echo
say "Installing codex-ter-ui v$VER"
mkdir -p "$DIR" "$BK" "$T"

# ---- backups (only the first time, so the original is never lost) ----
for f in "$T/colors.properties" "$T/termux.properties" "$T/font.ttf"; do
  b="$BK/$(basename "$f")"
  if [ ! -e "$b" ] && [ ! -e "$b.none" ]; then
    if [ -f "$f" ]; then cp "$f" "$b"; else touch "$b.none"; fi
  fi
done

# ---- optional tools ----
say "Installing tools (eza, bat)..."
pkg install -y eza bat >/dev/null 2>&1

# ---- colors ----
cat > "$T/colors.properties" <<'EOF_COLORS'
background=#000000
foreground=#d0d0d0
cursor=#ff1a1a
color0=#000000
color1=#ff1a1a
color2=#3ddc84
color3=#f5c542
color4=#4f8cff
color5=#ff2d95
color6=#2fd6d6
color7=#d0d0d0
color8=#5c5c5c
color9=#ff4d4d
color10=#5af78e
color11=#ffe66d
color12=#7aa2ff
color13=#ff6ec7
color14=#5ff3f3
color15=#ffffff
EOF_COLORS

# ---- extra keys ----
P="$T/termux.properties"
if [ -f "$P" ]; then
  grep -vE '^(extra-keys|bell-character|# codex-ter-ui)' "$P" > "$P.tmp"
else
  : > "$P.tmp"
fi
cat >> "$P.tmp" <<'EOF_PROPS'
# codex-ter-ui
extra-keys = [['ESC','/','-','HOME','UP','END','PGUP'],['TAB','CTRL','ALT','LEFT','DOWN','RIGHT','PGDN']]
bell-character = ignore
EOF_PROPS
mv "$P.tmp" "$P"

# ---- font ----
say "Downloading font..."
if curl -fsSL "$FONT_URL" -o "$T/font.ttf.tmp" 2>/dev/null && [ "$(stat -c%s "$T/font.ttf.tmp")" -gt 100000 ]; then
  mv "$T/font.ttf.tmp" "$T/font.ttf"
else
  rm -f "$T/font.ttf.tmp"; say "Font skipped (no connection)"
fi

# ---- the theme itself (banner + prompt + aliases) ----
cat > "$DIR/theme.sh" <<'EOF_THEME'
# codex-ter-ui theme
_cx_banner() {
  local rows=(
    "█████ █████ ████  █████ █   █"
    "█     █   █ █   █ █      █ █ "
    "█     █   █ █   █ ████    █  "
    "█     █   █ █   █ █      █ █ "
    "█████ █████ ████  █████ █   █"
  )
  local shades=(196 160 124 88 52) i
  clear
  echo
  for i in 0 1 2 3 4; do
    printf ' \e[38;5;%sm%s\e[0m\n' "${shades[$i]}" "${rows[$i]}"
  done
  echo
  printf ' \e[38;5;245m[ TERMINAL UI v%s ]  \e[38;5;196mcodex-ter-ui\e[0m\n' "$(cat "$HOME/.codex-ter-ui/version")"
  printf ' \e[38;5;240mupdate  ll  mkcd  myip  ports  codex-ter-ui\e[0m\n\n'
}

PS1='\[\e[38;5;196m\]codex\[\e[38;5;245m\]@\[\e[38;5;196m\]termux \[\e[38;5;131m\]\w \[\e[38;5;196m\]❯ \[\e[0m\]'

command -v eza >/dev/null && alias ls='eza --icons --group-directories-first' && alias ll='eza -lah --icons --group-directories-first'
command -v bat >/dev/null && alias cat='bat --paging=never'
alias ..='cd ..'
alias update='pkg update -y && pkg upgrade -y'
alias myip='curl -s ifconfig.me; echo'
alias ports='ss -tulpn'
mkcd() { mkdir -p "$1" && cd "$1"; }
shopt -s autocd cdspell histappend 2>/dev/null
export HISTCONTROL=ignoreboth:erasedups

_cx_banner
EOF_THEME
echo "$VER" > "$DIR/version"
echo "$REPO_RAW" > "$DIR/url"

# ---- hook into .bashrc ----
touch "$RC"
sed -i '/# >>> codex-ter-ui >>>/,/# <<< codex-ter-ui <<</d' "$RC"
cat >> "$RC" <<'EOF_RC'

# >>> codex-ter-ui >>>
[[ $- == *i* ]] && [ -f "$HOME/.codex-ter-ui/theme.sh" ] && source "$HOME/.codex-ter-ui/theme.sh"
# <<< codex-ter-ui <<<
EOF_RC

touch "$HOME/.hushlogin"

# ---- uninstaller ----
cat > "$DIR/uninstall.sh" <<'EOF_UN'
#!/data/data/com.termux/files/usr/bin/bash
DIR="$HOME/.codex-ter-ui"; BK="$DIR/backup"; T="$HOME/.termux"
sed -i '/# >>> codex-ter-ui >>>/,/# <<< codex-ter-ui <<</d' "$HOME/.bashrc"
for n in colors.properties termux.properties font.ttf; do
  if [ -f "$BK/$n" ]; then cp "$BK/$n" "$T/$n"
  elif [ -f "$BK/$n.none" ]; then rm -f "$T/$n"; fi
done
rm -f "$PREFIX/bin/codex-ter-ui"
rm -rf "$DIR"
termux-reload-settings 2>/dev/null
echo "codex-ter-ui removed. Restart Termux."
EOF_UN

# ---- command: codex-ter-ui [uninstall|update|banner] ----
cat > "$PREFIX/bin/codex-ter-ui" <<'EOF_BIN'
#!/data/data/com.termux/files/usr/bin/bash
D="$HOME/.codex-ter-ui"
case "$1" in
  uninstall) bash "$D/uninstall.sh" ;;
  update)    curl -fsSL "$(cat "$D/url")" | bash ;;
  banner)    source "$D/theme.sh" ;;
  *) echo "codex-ter-ui v$(cat "$D/version")"; echo "usage: codex-ter-ui [update|uninstall|banner]" ;;
esac
EOF_BIN
chmod +x "$PREFIX/bin/codex-ter-ui" "$DIR/uninstall.sh"

termux-reload-settings 2>/dev/null
echo
say "Done. Close Termux completely and open it again."
echo
