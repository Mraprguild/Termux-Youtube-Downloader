#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

rm -rf "$HOME/.termux-ytd"
rm -f "$PREFIX/bin/ytd"

echo "Termux YouTube Downloader removed."
echo "Downloaded media was not deleted."
