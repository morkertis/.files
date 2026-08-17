#!/usr/bin/env bash
# Set up this machine from the dotfiles in this repo.
# Safe to re-run: what is already installed is skipped, replaced files are backed up.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

info() { printf '\n==> %s\n' "$1"; }
ok() { printf '    ok: %s\n' "$1"; }
warn() { printf '    warning: %s\n' "$1" >&2; }

# Root needs no sudo, and containers and CI images often have none installed. Staying
# empty when sudo is missing lets the package step below detect that and skip itself.
SUDO=""
if [[ $EUID -ne 0 ]] && command -v sudo >/dev/null; then
	SUDO=sudo
fi

# Clone a repo unless it is already there. Checking for .git rather than the directory
# means an interrupted clone gets retried instead of counting as done.
clone_once() {
	local repo="$1" dest="$2"
	if [[ -d "$dest/.git" ]]; then
		ok "$(basename "$dest")"
	else
		rm -rf "$dest"
		git clone --depth=1 "$repo" "$dest"
	fi
}

# Install nice-to-have packages with $PM. Both apt and dnf fail the whole transaction
# when one name is unknown, and these names drift between releases, so fall back to
# installing them one at a time and report only the ones that are really unavailable.
install_extras() {
	if $SUDO "$PM" install -y "$@"; then
		return
	fi
	warn "batch install failed - retrying one package at a time"
	local pkg
	for pkg in "$@"; do
		$SUDO "$PM" install -y "$pkg" >/dev/null 2>&1 || warn "skipped $pkg (unavailable)"
	done
}

# Symlink $DOTFILES/$1 to ~/$2, backing up whatever is in the way.
link() {
	local src="$DOTFILES/$1" dest="$HOME/$2"
	if [[ "$(readlink "$dest" 2>/dev/null)" == "$src" ]]; then
		ok "~/$2"
		return
	fi
	if [[ -e "$dest" || -L "$dest" ]]; then
		mv "$dest" "$dest.backup-$(date +%Y%m%d%H%M%S)"
		printf '    backed up existing ~/%s\n' "$2"
	fi
	ln -s "$src" "$dest"
	printf '    linked ~/%s -> %s\n' "$2" "$src"
}

case "$OSTYPE" in
linux*)
	# Every glibc distro reports linux-gnu, so dispatch on the package manager that is
	# actually present instead of assuming the OS name implies one.
	# In each case: the first install is required, the second is best-effort, because
	# those package names drift between releases and one miss must not abort the setup.
	if [[ $EUID -ne 0 && -z "$SUDO" ]]; then
		warn "not root and sudo is not installed - skipping package installs"
	elif command -v apt-get >/dev/null; then
		# Debian, Ubuntu and derivatives: Mint, Pop!_OS, Raspberry Pi OS, WSL Ubuntu.
		info "Detected Linux with apt - installing packages"
		PM=apt-get
		$SUDO apt-get update
		$SUDO apt-get install -y zsh git curl
		# Build deps for compiling Python (uv python install), the editors whose
		# configs this repo links, and everyday tools.
		install_extras \
			build-essential htop llvm make nano ncdu screen unzip wget \
			libbz2-dev libffi-dev liblzma-dev libncurses-dev libreadline-dev \
			libsqlite3-dev libssl-dev python3-openssl tk-dev xz-utils zlib1g-dev
	elif command -v dnf >/dev/null; then
		# Fedora, Amazon Linux 2023, RHEL and its rebuilds: CentOS Stream, Rocky,
		# AlmaLinux, Oracle Linux. chsh lives in util-linux-user on these.
		info "Detected Linux with dnf - installing packages"
		PM=dnf
		$SUDO dnf install -y zsh git curl util-linux-user
		install_extras \
			gcc gcc-c++ make patch htop nano ncdu screen unzip wget \
			bzip2 bzip2-devel libffi-devel ncurses-devel openssl-devel \
			readline-devel sqlite sqlite-devel tk-devel xz-devel zlib-devel
	else
		# Arch (pacman), Alpine (apk), openSUSE (zypper), Gentoo (emerge), NixOS...
		# Not fatal: everything after this block is distro-agnostic, and the tool
		# check below reports whatever is actually missing.
		warn "no apt-get or dnf found - skipping package installs"
	fi
	;;
darwin*)
	info "Detected macOS - installing packages with brew"
	if ! command -v brew >/dev/null; then
		echo "Homebrew is required. Install it from https://brew.sh and re-run this script." >&2
		exit 1
	fi
	# nano: the system /usr/bin/nano is really pico and ignores ~/.nanorc entirely.
	for pkg in nano uv zsh; do
		if brew list --formula "$pkg" &>/dev/null; then
			ok "$pkg"
		else
			brew install "$pkg"
		fi
	done
	;;
*)
	echo "Unsupported OSTYPE: $OSTYPE" >&2
	exit 1
	;;
esac

# Everything below is distro-agnostic, so an unknown package manager is not fatal -
# it only means these have to be there already.
info "Checking required tools"
missing=""
for cmd in zsh git curl; do
	command -v "$cmd" >/dev/null || missing="$missing $cmd"
done
if [[ -n "$missing" ]]; then
	echo "Missing required tools:$missing" >&2
	echo "Install them with your package manager, then re-run this script." >&2
	exit 1
fi
ok "zsh, git, curl"

if [[ "$OSTYPE" == linux* ]]; then
	info "Installing uv"
	if command -v uv >/dev/null; then
		ok "uv"
	else
		# INSTALLER_NO_MODIFY_PATH: without it the installer appends a PATH line to
		# ~/.zshrc, which is a symlink into this repo. zsh/.zshrc exports it itself.
		curl -LsSf https://astral.sh/uv/install.sh | env INSTALLER_NO_MODIFY_PATH=1 sh
	fi
fi

info "Installing oh-my-zsh"
if [[ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]]; then
	ok "oh-my-zsh"
else
	# Download first and assign to a variable: inside sh -c "$(curl ...)" a failed
	# download is invisible to set -e and would leave a half-installed shell behind.
	omz_installer="$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	# --unattended keeps the installer from spawning a new shell and stalling the script.
	# KEEP_ZSHRC stops it from clobbering the .zshrc we link below.
	RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$omz_installer" "" --unattended
	if [[ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]]; then
		echo "oh-my-zsh install did not complete - stopping before linking .zshrc" >&2
		exit 1
	fi
fi

info "Installing zsh plugins and theme"
clone_once https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
clone_once https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
clone_once https://github.com/romkatv/powerlevel10k "$ZSH_CUSTOM/themes/powerlevel10k"

info "Linking dotfiles"
link zsh/.zshrc .zshrc
link screen/.screenrc .screenrc
link nano/.nanorc .nanorc

# Last step on purpose: chsh is the only part that routinely fails (a mistyped
# password, an LDAP/AD-managed account), and by now everything else is in place.
info "Setting zsh as the default shell"
# Compare by name, not full path: brew zsh and /bin/zsh are both fine, and
# comparing full paths would re-run chsh (password prompt) on every run.
if [[ "$(basename "${SHELL:-}")" == "zsh" ]]; then
	ok "already zsh"
else
	zsh_path="$(command -v zsh)"
	if ! grep -qxF "$zsh_path" /etc/shells; then
		echo "$zsh_path" | $SUDO tee -a /etc/shells >/dev/null ||
			warn "could not add $zsh_path to /etc/shells"
	fi
	chsh -s "$zsh_path" || warn "could not change the default shell; run: chsh -s $zsh_path"
fi

info "Done - open a new terminal to pick up the new shell."
if [[ ! -f "$DOTFILES/zsh/.private.zsh" ]]; then
	printf '    tip: cp %s/zsh/.private.zsh.example %s/zsh/.private.zsh for secrets and machine-local config\n' \
		"$DOTFILES" "$DOTFILES"
fi
