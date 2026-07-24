# Install

## Ubuntu install

These packages cover the expected interactive shell, editor, search, clipboard, archive, media, and image tooling used by the managed dotfiles.

Install the expected command-line tools:

```sh
sudo apt update
sudo apt install -y zsh vim fzf lsd curl jq unzip ca-certificates git build-essential
sudo apt install -y zoxide ffmpeg 7zip 7zip-rar poppler-utils fd-find ripgrep bat xclip wl-clipboard imagemagick
```

Interactive SSH opens zsh without an automatic multiplexer. Install, start, or deploy Herdr on an Ubuntu host only when that host is explicitly selected and the remote change is confirmed.

## T3 Code headless LAN host

An Ubuntu machine can run the [T3 Code](https://github.com/pingdotgg/t3code) server without the desktop AppImage. Install Node.js and authenticate a supported coding agent such as Codex first, then install and start T3:

```sh
npm install --global t3
t3 serve --host 0.0.0.0 --port 3773 --no-browser
```

T3 prints one-time pairing details. On another laptop on the same trusted network, add the Ubuntu machine using its private LAN address on port 3773 and complete the pairing. Treat pairing tokens as secrets.

For unattended use, run the same command from a `systemd --user` service, use the absolute `t3` path reported by `command -v t3`, enable the service, and enable user lingering so it starts at boot. Pin the npm version on long-lived hosts and upgrade it deliberately.

Keep access LAN-only: restrict TCP port 3773 to the trusted network, never forward it from the public internet, and use T3 Connect or Tailscale for access away from home. Prefer the headless server on Ubuntu, keep the AppArmor unprivileged-user-namespace restriction enabled, and let Codex use its packaged `bubblewrap` profile.
