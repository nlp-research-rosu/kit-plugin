#!/bin/sh
set -eu

base=https://github.com/nlp-research-rosu/kit-plugin/releases/download/v0.1.1
case "$(uname -s)-$(uname -m)" in
  Darwin-arm64) asset=kprover-darwin-arm64.tar.gz ;;
  Darwin-x86_64) asset=kprover-darwin-x64.tar.gz ;;
  Linux-x86_64) asset=kprover-linux-x64.tar.gz ;;
  Linux-aarch64|Linux-arm64) asset=kprover-linux-arm64.tar.gz ;;
  *) echo "kprover: unsupported platform $(uname -s)/$(uname -m)" >&2; exit 1 ;;
esac

work=$(mktemp -d "${TMPDIR:-/tmp}/kprover-install.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
curl --proto '=https' --tlsv1.2 -LsSf "$base/$asset" -o "$work/$asset"
curl --proto '=https' --tlsv1.2 -LsSf "$base/$asset.sha256" -o "$work/checksum"
expected=$(awk '{print $1}' "$work/checksum")
if command -v sha256sum >/dev/null 2>&1; then
  actual=$(sha256sum "$work/$asset" | awk '{print $1}')
else
  actual=$(shasum -a 256 "$work/$asset" | awk '{print $1}')
fi
test "$actual" = "$expected" || { echo "kprover: checksum mismatch" >&2; exit 1; }

tar -xzf "$work/$asset" -C "$work"
destination=${KPROVER_INSTALL_DIR:-"${HOME}/.local/bin"}
mkdir -p "$destination"
destination=$(cd "$destination" && pwd)
install -m 0755 "$work/kprover" "$destination/kprover"
"$destination/kprover" --version

quote() {
  quoted=$1
  if [ "${2:-sh}" = fish ]; then
    quoted=$(printf '%s' "$quoted" | sed 's/\\/\\\\/g')
  fi
  printf "'%s'" "$(printf '%s' "$quoted" | sed "s/'/'\\\\''/g")"
}
env_dir=${XDG_CONFIG_HOME:-"$HOME/.config"}/kprover
mkdir -p "$env_dir"
env_dir=$(cd "$env_dir" && pwd)
quoted_destination=$(quote "$destination")
printf 'case ":$PATH:" in\n  *:%s:*) ;;\n  *) export PATH=%s:"$PATH" ;;\nesac\n' \
  "$quoted_destination" "$quoted_destination" > "$env_dir/env"
source_line=". $(quote "$env_dir/env")"
add_to_profile() {
  mkdir -p "$(dirname "$1")"
  if ! grep -Fqx "$source_line" "$1" 2>/dev/null; then
    printf '\n%s\n' "$source_line" >> "$1"
  fi
}
login_shell=${SHELL:-/bin/sh}
case "${login_shell##*/}" in
  zsh) add_to_profile "${ZDOTDIR:-$HOME}/.zshenv" ;;
  bash)
    add_to_profile "$HOME/.bashrc"
    if [ -f "$HOME/.bash_profile" ]; then
      add_to_profile "$HOME/.bash_profile"
    elif [ -f "$HOME/.bash_login" ]; then
      add_to_profile "$HOME/.bash_login"
    else
      add_to_profile "$HOME/.profile"
    fi
    ;;
  fish)
    quoted_destination=$(quote "$destination" fish)
    printf 'if not contains -- %s $PATH\n  set -gx PATH %s $PATH\nend\n' \
      "$quoted_destination" "$quoted_destination" > "$env_dir/env.fish"
    source_line="source $(quote "$env_dir/env.fish" fish)"
    add_to_profile "${XDG_CONFIG_HOME:-$HOME/.config}/fish/conf.d/kprover.fish"
    ;;
  sh|dash|ksh|ash) add_to_profile "$HOME/.profile" ;;
  *) echo "kprover: add $destination to PATH in your $login_shell configuration"; exit 0 ;;
esac
printf 'Open a new terminal, or run this command in your current shell:\n  %s\n' "$source_line"
echo "Then run kprover health and kprover semantics."
