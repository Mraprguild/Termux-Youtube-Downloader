#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

APP_NAME="Termux YouTube Downloader"
APP_DIR="$HOME/.termux-ytd"
BIN_DIR="$PREFIX/bin"

printf '\033[1;36m%s\033[0m\n' "Installing $APP_NAME..."

if ! command -v pkg >/dev/null 2>&1; then
  echo "This installer must be run inside Termux."
  exit 1
fi

pkg update -y
pkg install -y python python-pip ffmpeg deno curl

python -m pip install --upgrade pip
python -m pip install --upgrade "yt-dlp[default]"

mkdir -p "$APP_DIR" "$HOME/storage/downloads/YouTube"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$SCRIPT_DIR/ytd.sh" "$APP_DIR/ytd.sh"
chmod +x "$APP_DIR/ytd.sh"

cat > "$BIN_DIR/ytd" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
exec "$APP_DIR/ytd.sh" "\$@"
EOF
chmod +x "$BIN_DIR/ytd"

echo
echo "Storage permission is required."
termux-setup-storage || true

echo
printf '\033[1;32mInstallation complete.\033[0m\n'
echo "Run: ytd"
echo "Downloads: Internal Storage/Download/YouTube"
