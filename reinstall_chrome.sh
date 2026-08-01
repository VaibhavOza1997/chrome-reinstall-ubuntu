#!/usr/bin/env bash
#
# reinstall_chrome.sh — Uninstall any existing Google Chrome and do a fresh install on Ubuntu/Debian.
#
# Usage:
#   ./reinstall_chrome.sh            # uninstall + fresh install, keeps ~/.config/google-chrome (bookmarks, history, etc.)
#   ./reinstall_chrome.sh --purge    # also wipes user profile data for a truly clean slate (all logged-out, no history/extensions)
#   ./reinstall_chrome.sh --help
#
set -euo pipefail

PURGE_PROFILE=false
DEB_URL="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
TMP_DEB=""

log()  { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mWARNING:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

cleanup() {
  [[ -n "$TMP_DEB" && -f "$TMP_DEB" ]] && rm -f "$TMP_DEB"
}
trap cleanup EXIT

usage() {
  cat <<EOF
Reinstall Google Chrome cleanly on Ubuntu/Debian.

Options:
  --purge     Also delete ~/.config/google-chrome (history, cookies, extensions, saved passwords)
              for a completely fresh profile. Without this flag, your Chrome profile data is kept.
  -h, --help  Show this help.
EOF
}

for arg in "${@:-}"; do
  case "$arg" in
    --purge) PURGE_PROFILE=true ;;
    -h|--help) usage; exit 0 ;;
    "") ;;
    *) die "Unknown option: $arg (use --help)" ;;
  esac
done

# --- sanity checks -----------------------------------------------------

[[ "$(uname -s)" == "Linux" ]] || die "This script only supports Linux."
command -v apt-get >/dev/null 2>&1 || die "apt-get not found — this script targets Ubuntu/Debian."

ARCH="$(dpkg --print-architecture 2>/dev/null || uname -m)"
if [[ "$ARCH" != "amd64" && "$ARCH" != "x86_64" ]]; then
  die "Google Chrome's official .deb only supports amd64. Detected architecture: $ARCH. (Consider Chromium via snap/apt instead.)"
fi

if [[ $EUID -eq 0 ]]; then
  SUDO=""
else
  command -v sudo >/dev/null 2>&1 || die "This script needs root privileges; install sudo or run as root."
  SUDO="sudo"
  log "This script will prompt for your sudo password when needed."
fi

# --- 1. Uninstall existing Chrome --------------------------------------

log "Checking for an existing Google Chrome installation..."

if dpkg -s google-chrome-stable >/dev/null 2>&1; then
  log "Found google-chrome-stable (deb package). Removing it..."
  $SUDO apt-get remove --purge -y google-chrome-stable
elif command -v snap >/dev/null 2>&1 && snap list 2>/dev/null | grep -qw '^google-chrome'; then
  log "Found google-chrome installed via snap. Removing it..."
  $SUDO snap remove google-chrome
else
  log "No existing Google Chrome installation detected via apt or snap."
fi

# Remove Google's apt repo listing so a fresh one is written cleanly (the .deb reinstalls it anyway)
if [[ -f /etc/apt/sources.list.d/google-chrome.list ]]; then
  log "Removing stale Google Chrome apt repo entry..."
  $SUDO rm -f /etc/apt/sources.list.d/google-chrome.list
fi

if $PURGE_PROFILE; then
  if [[ -d "$HOME/.config/google-chrome" ]]; then
    log "Purging user profile data at ~/.config/google-chrome (history, cookies, extensions, passwords)..."
    rm -rf "$HOME/.config/google-chrome"
  fi
  if [[ -d "$HOME/.cache/google-chrome" ]]; then
    rm -rf "$HOME/.cache/google-chrome"
  fi
else
  if [[ -d "$HOME/.config/google-chrome" ]]; then
    warn "Keeping existing profile data at ~/.config/google-chrome. Re-run with --purge for a fully clean profile."
  fi
fi

$SUDO apt-get autoremove -y || true

# --- 2. Fresh install ---------------------------------------------------

log "Downloading the latest Google Chrome stable .deb..."
TMP_DEB="$(mktemp --suffix=.deb)"

if command -v wget >/dev/null 2>&1; then
  wget -q --show-progress -O "$TMP_DEB" "$DEB_URL"
elif command -v curl >/dev/null 2>&1; then
  curl -fL -o "$TMP_DEB" "$DEB_URL"
else
  die "Neither wget nor curl is available to download Chrome."
fi

log "Installing Google Chrome (apt will resolve dependencies automatically)..."
$SUDO apt-get update -y
$SUDO apt install -y "$TMP_DEB"

# --- 3. Verify -----------------------------------------------------------

if command -v google-chrome >/dev/null 2>&1 || command -v google-chrome-stable >/dev/null 2>&1; then
  BIN="$(command -v google-chrome || command -v google-chrome-stable)"
  log "Success! Installed: $("$BIN" --version)"
else
  die "Installation finished but google-chrome binary was not found on PATH — something went wrong."
fi

log "Done."
