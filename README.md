# chrome-reinstall-ubuntu

A one-shot script (plus optional desktop launcher) to cleanly uninstall and freshly reinstall **Google Chrome** on Ubuntu/Debian.

Useful when Chrome is misbehaving, has a corrupted profile, or you just want a guaranteed-clean install without hunting down leftover apt/snap packages and repo entries by hand.

## What it does

1. Detects how Chrome is currently installed (`apt`/`.deb` or `snap`) and removes it.
2. Cleans up the stale `google-chrome.list` apt repo entry.
3. Optionally purges your Chrome profile (`~/.config/google-chrome`) for a fully clean slate.
4. Downloads the latest `google-chrome-stable` `.deb` directly from Google.
5. Installs it via `apt install`, which resolves dependencies automatically.
6. Verifies the install by printing `google-chrome --version`.

## Requirements

- Ubuntu/Debian with `apt-get`
- amd64/x86_64 architecture (Google only ships Chrome stable for this arch)
- `sudo` privileges
- `wget` or `curl`

## Usage

```bash
chmod +x reinstall_chrome.sh

# Reinstall, keeping your existing profile (bookmarks, history, saved logins, extensions)
./reinstall_chrome.sh

# Reinstall AND wipe your profile for a truly fresh Chrome (logged out, no history/extensions)
./reinstall_chrome.sh --purge
```

## Desktop launcher (optional)

`Reinstall Chrome.desktop` lets you double-click to run the script from your file manager. It opens a terminal so you can see progress and enter your `sudo` password.

To use it:

1. Copy `reinstall_chrome.sh` to your home directory (`~/reinstall_chrome.sh`), or edit the `Exec=` line in the `.desktop` file to point wherever you keep it.
2. Copy `Reinstall Chrome.desktop` to `~/Desktop/` (or `~/.local/share/applications/` to have it appear in your app launcher instead).
3. Make both files executable: `chmod +x reinstall_chrome.sh "Reinstall Chrome.desktop"`.
4. Double-click the launcher. On first run, GNOME Files (Nautilus) may ask you to trust/allow the launcher — approve it.

## Notes

- Chrome's official `.deb` is only built for amd64. On ARM (e.g. Raspberry Pi), this script will exit with an error — use Chromium instead.
- Without `--purge`, only the package is removed/reinstalled; your personal profile data under `~/.config/google-chrome` is left untouched.
