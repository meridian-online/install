#!/usr/bin/env bash
#
# Brightfield installer
# https://meridian.online
#
# Detects architecture, downloads the correct pre-built macOS binary from
# GitHub Releases, verifies its SHA256 checksum, and installs it to a
# versioned directory with a latest symlink.
#
# Brightfield is a macOS-only GUI app (Apple silicon and Intel).
#
# Usage:
#   curl -fsSL https://install.meridian.online/brightfield | bash
#   curl -fsSL https://install.meridian.online/brightfield | bash -s -- v0.1.0
#
set -euo pipefail

REPO="meridian-online/brightfield"
INSTALL_DIR="${HOME}/.brightfield/cli"
LOCAL_BIN="${HOME}/.local/bin"

# Download workspace, created by main(). Kept at file scope (not local to
# main) so the EXIT trap can still see it after main returns — a local would
# be out of scope by then and trip `set -u` with "unbound variable".
tmp_dir=""

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

info()  { printf '  %s\n' "$*"; }
warn()  { printf '  \033[33mwarning:\033[0m %s\n' "$*" >&2; }
error() { printf '  \033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }

need_cmd() {
  if ! command -v "$1" &>/dev/null; then
    error "need '$1' (command not found)"
  fi
}

# Defense in depth: the version flows into a download URL and a filesystem
# path, so reject anything that is not a plain semver-ish tag before it does.
# Covers both the `-s -- <version>` override and the API-parsed value.
validate_version() {
  if [[ ! "$1" =~ ^v[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.]+)?$ ]]; then
    error "unexpected version string: $1"
  fi
}

cleanup() {
  [[ -n "${tmp_dir}" ]] && rm -rf "${tmp_dir}"
}
trap cleanup EXIT

# ---------------------------------------------------------------------------
# Detect platform
# ---------------------------------------------------------------------------

detect_target() {
  local os arch target

  os="$(uname -s)"
  arch="$(uname -m)"

  # Brightfield is a macOS-only GUI app for now. Bail cleanly on any other
  # OS rather than constructing a target for which no asset is published.
  if [[ "${os}" != "Darwin" ]]; then
    error "Brightfield is macOS-only for now — Apple silicon and Intel."
  fi
  os="apple-darwin"

  case "${arch}" in
    x86_64|amd64)   arch="x86_64" ;;
    aarch64|arm64)  arch="aarch64" ;;
    *)              error "unsupported architecture: ${arch}" ;;
  esac

  target="${arch}-${os}"
  echo "${target}"
}

# ---------------------------------------------------------------------------
# Resolve version
# ---------------------------------------------------------------------------

resolve_version() {
  local version="$1"

  if [[ -n "${version}" ]]; then
    # Ensure the version starts with 'v'
    if [[ "${version}" != v* ]]; then
      version="v${version}"
    fi
    validate_version "${version}"
    echo "${version}"
    return
  fi

  # Brightfield releases are published as prereleases, and the GitHub
  # "releases/latest" endpoint excludes prereleases — it would 404 here.
  # Query the releases LIST instead (newest-first, includes prereleases)
  # and take the first entry's tag_name.
  local api_url="https://api.github.com/repos/${REPO}/releases"
  local response tag

  response="$(curl -fsSL "${api_url}")" \
    || error "could not reach the GitHub releases API"

  # Extract the first (newest) tag_name with bash's own regex engine rather
  # than a `grep | head | sed` pipe: the POSIX whitespace class is portable
  # (BSD sed does not understand \s), and with no `head` closing the pipe
  # early there is nothing to SIGPIPE-abort under `set -o pipefail`.
  local re='"tag_name"[[:space:]]*:[[:space:]]*"([^"]+)"'
  if [[ "${response}" =~ $re ]]; then
    tag="${BASH_REMATCH[1]}"
  else
    tag=""
  fi

  if [[ -z "${tag}" ]]; then
    error "could not determine latest version from GitHub API"
  fi

  validate_version "${tag}"
  echo "${tag}"
}

# ---------------------------------------------------------------------------
# Download and verify
# ---------------------------------------------------------------------------

download_and_verify() {
  local version="$1"
  local target="$2"
  local tmp_dir="$3"

  local archive="brightfield-${version}-${target}.tar.gz"
  local checksum_file="${archive}.sha256"
  local base_url="https://github.com/${REPO}/releases/download/${version}"

  info "downloading ${archive}..."
  curl -fSL --progress-bar -o "${tmp_dir}/${archive}" "${base_url}/${archive}" \
    || error "failed to download ${archive} -- does release ${version} exist?"

  info "downloading checksum..."
  curl -fsSL -o "${tmp_dir}/${checksum_file}" "${base_url}/${checksum_file}" \
    || error "failed to download checksum file"

  # Verify SHA256
  info "verifying checksum..."
  local expected actual
  expected="$(awk '{print $1}' "${tmp_dir}/${checksum_file}")"

  if command -v shasum &>/dev/null; then
    actual="$(shasum -a 256 "${tmp_dir}/${archive}" | awk '{print $1}')"
  elif command -v sha256sum &>/dev/null; then
    actual="$(sha256sum "${tmp_dir}/${archive}" | awk '{print $1}')"
  else
    error "no SHA256 tool found (need shasum or sha256sum)"
  fi

  if [[ "${expected}" != "${actual}" ]]; then
    error "checksum mismatch!\n  expected: ${expected}\n  actual:   ${actual}"
  fi

  info "checksum verified."
}

# ---------------------------------------------------------------------------
# Install
# ---------------------------------------------------------------------------

install_binary() {
  local version="$1"
  local tmp_dir="$2"
  local target="$3"

  local archive="brightfield-${version}-${target}.tar.gz"
  local version_dir="${INSTALL_DIR}/${version}"
  local latest_link="${INSTALL_DIR}/latest"

  # Create versioned directory
  mkdir -p "${version_dir}"

  # Extract binary. Brightfield's tarball nests everything under a top-level
  # "brightfield-<version>-<target>/" directory (binary + LICENSE + examples),
  # so strip that leading component to land the binary directly in the
  # versioned directory.
  info "extracting to ${version_dir}..."
  tar xzf "${tmp_dir}/${archive}" -C "${version_dir}" --strip-components=1

  local installed_bin="${version_dir}/brightfield"

  # Confirm the extraction produced an executable binary before pointing any
  # symlinks at it.
  if [[ ! -f "${installed_bin}" ]]; then
    error "extraction did not produce a brightfield binary in ${version_dir}"
  fi
  chmod +x "${installed_bin}"
  if [[ ! -x "${installed_bin}" ]]; then
    error "${installed_bin} is not executable"
  fi

  # Update latest symlink
  ln -sfn "${version_dir}" "${latest_link}"
  info "updated ${latest_link} -> ${version_dir}"

  # Optionally symlink into ~/.local/bin
  if [[ -d "${LOCAL_BIN}" && -w "${LOCAL_BIN}" ]]; then
    ln -sf "${latest_link}/brightfield" "${LOCAL_BIN}/brightfield"
    info "symlinked ${LOCAL_BIN}/brightfield -> ${latest_link}/brightfield"
  fi
}

# ---------------------------------------------------------------------------
# PATH guidance
# ---------------------------------------------------------------------------

print_path_help() {
  local on_path=false

  # Check if either location is already on PATH
  if command -v brightfield &>/dev/null; then
    on_path=true
  fi

  if [[ "${on_path}" == true ]]; then
    return
  fi

  echo ""
  warn "brightfield is not on your PATH."
  echo ""

  if [[ -d "${LOCAL_BIN}" ]]; then
    info "Add ~/.local/bin to your PATH:"
  else
    info "Add the Brightfield install directory to your PATH:"
  fi

  echo ""

  local shell_name
  shell_name="$(basename "${SHELL:-bash}")"

  local target_dir
  if [[ -d "${LOCAL_BIN}" ]]; then
    target_dir="\$HOME/.local/bin"
  else
    target_dir="\$HOME/.brightfield/cli/latest"
  fi

  case "${shell_name}" in
    zsh)
      info "  echo 'export PATH=\"${target_dir}:\$PATH\"' >> ~/.zshrc"
      info "  source ~/.zshrc"
      ;;
    fish)
      info "  fish_add_path ${target_dir}"
      ;;
    *)
      info "  echo 'export PATH=\"${target_dir}:\$PATH\"' >> ~/.bashrc"
      info "  source ~/.bashrc"
      ;;
  esac

  echo ""
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  echo ""
  echo "           ☼☼☼☼               "
  echo "        ☼☼☼☼☼☼☼☼              "
  echo "                ☼☼☼☼☼☼☼☼☼☼    "
  echo "                  ☼☼☼☼☼☼☼☼☼☼  "
  echo "   ☼☼☼☼☼☼☼☼☼☼☼☼               "
  echo "  ☼☼☼☼☼☼☼☼☼☼☼☼☼☼              "
  echo "                ☼☼☼☼☼☼☼☼☼☼☼☼☼☼"
  echo "                 ☼☼☼☼☼☼☼☼☼☼☼☼ "
  echo "     ☼☼☼☼☼☼☼☼☼☼               "
  echo "      ☼☼☼☼☼☼☼☼☼☼              "
  echo "                ☼☼☼☼☼☼☼☼      "
  echo "                 ☼☼☼☼         "
  echo ""
  echo "          MERIDIAN"
  echo ""
  echo "  Brightfield installer"
  echo ""

  # Check dependencies
  need_cmd curl
  need_cmd tar
  need_cmd uname
  need_cmd awk
  need_cmd mktemp

  # Detect platform
  local target
  target="$(detect_target)"
  info "detected platform: ${target}"

  # Resolve version (use first argument if provided)
  local version
  version="$(resolve_version "${1:-}")"
  info "version: ${version}"
  echo ""

  # Create temp directory for downloads (cleaned up by the EXIT trap)
  tmp_dir="$(mktemp -d)"

  # Download, verify, install
  download_and_verify "${version}" "${target}" "${tmp_dir}"
  install_binary "${version}" "${tmp_dir}" "${target}"

  echo ""
  echo "  Brightfield ${version} installed successfully!"
  echo ""

  # Brightfield is a GUI app: launching it opens a window rather than printing
  # to the terminal, so there is no --version flag to probe here. Because this
  # binary arrived via the install-command channel (curl attaches no macOS
  # quarantine attribute), Gatekeeper won't block the first launch.
  if command -v brightfield &>/dev/null; then
    info "Run \`brightfield\` to open it — it launches a window."
  elif [[ -e "${LOCAL_BIN}/brightfield" ]]; then
    info "Run \`brightfield\` to open it — it launches a window."
    info "Launcher: ${LOCAL_BIN}/brightfield"
  else
    info "Run \`brightfield\` to open it — it launches a window."
    info "Launcher: ${INSTALL_DIR}/latest/brightfield"
  fi

  print_path_help
}

main "$@"
