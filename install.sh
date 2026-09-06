#!/bin/sh
# Reproduce the capy agent workspace on a fresh macOS machine.
# Installs upstream tools from their own sources, then applies this repo's config.
# Never logs you into anything. It stops and tells you what to do instead.
set -e

WORKSPACE="${CAPY_WORKSPACE:-$HOME/capy-agent-workspace}"
HERE="$(cd "$(dirname "$0")" && pwd)"

say() { printf '\n==> %s\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

# ---------------------------------------------------------------- base tools
say "Checking base tools"
for c in git curl; do
  have "$c" || { echo "missing: $c"; exit 1; }
done

if ! have brew; then
  echo "Homebrew is required. See https://brew.sh/"
  exit 1
fi

for c in gh jq node; do
  if have "$c"; then
    echo "ok      $c"
  else
    say "Installing $c"
    brew install "$c"
  fi
done

# ~/.local/bin holds the installer-script binaries. Keep it on PATH.
mkdir -p "$HOME/.local/bin"
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) echo "Add this to your shell config: export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
esac

# Deliberately NOT setting an npm prefix. This machine uses nvm, and a fixed
# prefix breaks nvm version switching. The nvm bin directory is already on PATH.

# ---------------------------------------------------------------- harnesses
say "Installing agent harnesses"
have pi || npm install -g --ignore-scripts @earendil-works/pi-coding-agent
have herdr || curl -fsSL https://herdr.dev/install.sh | sh
herdr integration install pi

# ---------------------------------------------------------------- crew tools
say "Installing crew tools"
have treehouse || curl -fsSL https://kunchenguid.github.io/treehouse/install.sh | sh
have no-mistakes || curl -fsSL https://raw.githubusercontent.com/kunchenguid/no-mistakes/main/docs/install.sh | sh

say "Installing axi command line tools"
npm install -g gh-axi chrome-devtools-axi lavish-axi tasks-axi quota-axi
gh-axi setup hooks
chrome-devtools-axi setup hooks
lavish-axi setup hooks

say "Installing the menu bar app"
brew install --cask kunchenguid/tap/baby-menu || echo "skipped: baby-menu"

# ---------------------------------------------------------------- workspace
if [ -d "$WORKSPACE" ]; then
  say "Workspace already exists at $WORKSPACE"
else
  say "Cloning firstmate into $WORKSPACE"
  git clone https://github.com/kunchenguid/firstmate.git "$WORKSPACE"
fi

say "Applying config"
mkdir -p "$WORKSPACE/config" "$WORKSPACE/.claude"
cp "$HERE/config/backend"            "$WORKSPACE/config/backend"
cp "$HERE/config/crew-harness"       "$WORKSPACE/config/crew-harness"
cp "$HERE/config/crew-dispatch.json" "$WORKSPACE/config/crew-dispatch.json"
cp "$HERE/claude/settings.local.json" "$WORKSPACE/.claude/settings.local.json"
echo "ok      config/ and the delegation guard are in place"

# ---------------------------------------------------------------- verify
say "Verifying"
missing=""
for c in git gh jq node npm pi herdr treehouse no-mistakes \
         gh-axi chrome-devtools-axi lavish-axi tasks-axi quota-axi; do
  have "$c" || missing="$missing $c"
done
if [ -n "$missing" ]; then
  echo "MISSING:$missing"
  echo "Open a new terminal so PATH picks up ~/.local/bin, then re-run."
  exit 1
fi
echo "ok      every command resolves"

# Silence from this script means nothing is missing. It only speaks on a problem.
( cd "$WORKSPACE" && ./bin/fm-bootstrap.sh )
echo "ok      workspace bootstrap is clean"

# ---------------------------------------------------------------- what is left
cat <<EOF

==> Three steps need you. None can be automated.

1. Authenticate GitHub:
     gh auth login

2. Log Pi into a model provider. Start pi, then type /login.
     pi
   Pick GitHub Copilot to match the routing in config/crew-dispatch.json.

3. Approve Keychain access once, so quota routing can read live numbers:
     quota-axi --allow-keychain-prompt

Then start a session:
     cd $WORKSPACE && herdr
   and in the first pane:
     claude --model opus --effort xhigh
EOF
