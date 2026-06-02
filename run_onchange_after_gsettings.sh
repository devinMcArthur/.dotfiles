#!/usr/bin/env bash
# Desktop-level gsettings that live in dconf's binary store and therefore
# aren't captured by chezmoi's file management. Declared here so chezmoi
# re-asserts them whenever this script's content changes (values are
# idempotent, so re-running is harmless).
set -euo pipefail

# Needs a running session bus (skip on headless/SSH applies).
if ! command -v gsettings >/dev/null 2>&1 || [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
  echo "gsettings/D-Bus session unavailable — skipping desktop gsettings."
  exit 0
fi

# Dark mode: advertise a dark preference through xdg-desktop-portal so
# prefers-color-scheme-aware apps follow it — Firefox and Firefox PWAs
# (the work Outlook PWA is set to "System Settings", so this is what
# flips it to dark), plus libadwaita/GTK4 apps.
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

echo "Applied desktop gsettings (color-scheme=prefer-dark)."
