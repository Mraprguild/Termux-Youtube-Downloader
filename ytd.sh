#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

APP_NAME="Mraprguild Termux YouTube Downloader"
VERSION="1.0.0"
DOWNLOAD_ROOT="$HOME/storage/downloads/YouTube"
ARCHIVE_FILE="$HOME/.termux-ytd/download-archive.txt"

C_RESET='\033[0m'
C_RED='\033[1;31m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_BLUE='\033[1;34m'
C_CYAN='\033[1;36m'
C_BOLD='\033[1m'

mkdir -p "$DOWNLOAD_ROOT" "$(dirname "$ARCHIVE_FILE")"

header() {
  clear
  printf "${C_CYAN}${C_BOLD}=============================================${C_RESET}\n"
  printf "${C_CYAN}${C_BOLD}  %s v%s${C_RESET}\n" "$APP_NAME" "$VERSION"
  printf "${C_CYAN}${C_BOLD}=============================================${C_RESET}\n"
  printf "Download folder: %s\n\n" "$DOWNLOAD_ROOT"
}

pause() {
  echo
  read -r -p "Press Enter to continue..." _
}

require_tools() {
  local missing=0
  for cmd in yt-dlp ffmpeg; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      printf "${C_RED}Missing dependency: %s${C_RESET}\n" "$cmd"
      missing=1
    fi
  done
  if (( missing )); then
    echo "Run install.sh again."
    exit 1
  fi
}

read_url() {
  local prompt="${1:-Paste video or playlist URL}"
  read -r -p "$prompt: " URL
  if [[ -z "${URL// }" ]]; then
    printf "${C_RED}URL cannot be empty.${C_RESET}\n"
    return 1
  fi
}

common_args=(
  --newline
  --no-mtime
  --continue
  --ignore-errors
  --restrict-filenames
  --windows-filenames
  --download-archive "$ARCHIVE_FILE"
  --paths "$DOWNLOAD_ROOT"
  --progress
)

download_best() {
  read_url || return
  yt-dlp "${common_args[@]}" \
    --format "bv*+ba/b" \
    --merge-output-format mp4 \
    --output "%(title)s [%(id)s].%(ext)s" \
    "$URL"
}

download_1080p() {
  read_url || return
  yt-dlp "${common_args[@]}" \
    --format "bv*[height<=1080]+ba/b[height<=1080]" \
    --merge-output-format mp4 \
    --output "%(title)s [%(id)s].%(ext)s" \
    "$URL"
}

download_720p() {
  read_url || return
  yt-dlp "${common_args[@]}" \
    --format "bv*[height<=720]+ba/b[height<=720]" \
    --merge-output-format mp4 \
    --output "%(title)s [%(id)s].%(ext)s" \
    "$URL"
}

download_mp3() {
  read_url || return
  yt-dlp "${common_args[@]}" \
    --extract-audio \
    --audio-format mp3 \
    --audio-quality 0 \
    --embed-thumbnail \
    --add-metadata \
    --output "Music/%(title)s [%(id)s].%(ext)s" \
    "$URL"
}

download_m4a() {
  read_url || return
  yt-dlp "${common_args[@]}" \
    --extract-audio \
    --audio-format m4a \
    --audio-quality 0 \
    --embed-thumbnail \
    --add-metadata \
    --output "Music/%(title)s [%(id)s].%(ext)s" \
    "$URL"
}

download_playlist() {
  read_url "Paste playlist URL" || return
  yt-dlp "${common_args[@]}" \
    --yes-playlist \
    --format "bv*[height<=1080]+ba/b[height<=1080]" \
    --merge-output-format mp4 \
    --output "Playlists/%(playlist_title)s/%(playlist_index)03d - %(title)s [%(id)s].%(ext)s" \
    "$URL"
}

download_subtitles() {
  read_url || return
  yt-dlp "${common_args[@]}" \
    --skip-download \
    --write-subs \
    --write-auto-subs \
    --sub-langs "all,-live_chat" \
    --sub-format "srt/best" \
    --output "Subtitles/%(title)s [%(id)s].%(ext)s" \
    "$URL"
}

show_formats() {
  read_url || return
  yt-dlp --list-formats "$URL"
}

custom_format() {
  read_url || return
  yt-dlp --list-formats "$URL"
  echo
  read -r -p "Enter format code or selector (example: 137+140): " FORMAT
  [[ -z "${FORMAT// }" ]] && { echo "Format cannot be empty."; return; }
  yt-dlp "${common_args[@]}" \
    --format "$FORMAT" \
    --merge-output-format mp4 \
    --output "%(title)s [%(id)s].%(ext)s" \
    "$URL"
}

update_app() {
  printf "${C_YELLOW}Updating yt-dlp...${C_RESET}\n"
  python -m pip install --upgrade "yt-dlp[default]"
  echo
  yt-dlp --version
}

open_folder() {
  if command -v termux-open >/dev/null 2>&1; then
    termux-open "$DOWNLOAD_ROOT" || true
  else
    echo "Folder: $DOWNLOAD_ROOT"
  fi
}

cli_mode() {
  case "${1:-}" in
    --video)
      URL="${2:-}"; [[ -n "$URL" ]] || { echo "Usage: ytd --video URL"; exit 2; }
      yt-dlp "${common_args[@]}"         --format "bv*+ba/b"         --merge-output-format mp4         --output "%(title)s [%(id)s].%(ext)s"         "$URL"
      ;;
    --audio)
      URL="${2:-}"; [[ -n "$URL" ]] || { echo "Usage: ytd --audio URL"; exit 2; }
      yt-dlp "${common_args[@]}" -x --audio-format mp3 --audio-quality 0 \
        --embed-thumbnail --add-metadata \
        --output "Music/%(title)s [%(id)s].%(ext)s" "$URL"
      ;;
    --playlist)
      URL="${2:-}"; [[ -n "$URL" ]] || { echo "Usage: ytd --playlist URL"; exit 2; }
      yt-dlp "${common_args[@]}" --yes-playlist \
        -f "bv*[height<=1080]+ba/b[height<=1080]" \
        --merge-output-format mp4 \
        -o "Playlists/%(playlist_title)s/%(playlist_index)03d - %(title)s [%(id)s].%(ext)s" "$URL"
      ;;
    --update)
      update_app
      ;;
    --help|-h)
      cat <<'EOF'
Usage:
  ytd                       Open interactive menu
  ytd --video URL           Download best video
  ytd --audio URL           Download MP3 audio
  ytd --playlist URL        Download playlist
  ytd --update              Update yt-dlp
EOF
      ;;
    *)
      return 1
      ;;
  esac
}

require_tools

if (($# > 0)); then
  cli_mode "$@" && exit 0
fi

while true; do
  header
  printf "${C_GREEN}1.${C_RESET} Best quality video\n"
  printf "${C_GREEN}2.${C_RESET} Video up to 1080p\n"
  printf "${C_GREEN}3.${C_RESET} Video up to 720p\n"
  printf "${C_GREEN}4.${C_RESET} MP3 audio\n"
  printf "${C_GREEN}5.${C_RESET} M4A audio\n"
  printf "${C_GREEN}6.${C_RESET} Download playlist\n"
  printf "${C_GREEN}7.${C_RESET} Download subtitles\n"
  printf "${C_GREEN}8.${C_RESET} List available formats\n"
  printf "${C_GREEN}9.${C_RESET} Custom format download\n"
  printf "${C_GREEN}10.${C_RESET} Update yt-dlp\n"
  printf "${C_GREEN}11.${C_RESET} Open download folder\n"
  printf "${C_RED}0.${C_RESET} Exit\n\n"

  read -r -p "Select an option: " choice
  echo

  case "$choice" in
    1) download_best; pause ;;
    2) download_1080p; pause ;;
    3) download_720p; pause ;;
    4) download_mp3; pause ;;
    5) download_m4a; pause ;;
    6) download_playlist; pause ;;
    7) download_subtitles; pause ;;
    8) show_formats; pause ;;
    9) custom_format; pause ;;
    10) update_app; pause ;;
    11) open_folder; pause ;;
    0) echo "Goodbye."; exit 0 ;;
    *) printf "${C_RED}Invalid option.${C_RESET}\n"; pause ;;
  esac
done
