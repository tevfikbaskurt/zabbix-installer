#!/usr/bin/env bash
# Zabbix Agent 2 kurulumu (Ubuntu 24.04)

set -euo pipefail

ZABBIX_VERSION="7.2"
UBUNTU_VERSION="24.04"
ZABBIX_SERVER=""
AGENT_HOSTNAME=""

REPO_PKG="zabbix-release_latest_${ZABBIX_VERSION}+ubuntu${UBUNTU_VERSION}_all.deb"
REPO_URL="https://repo.zabbix.com/zabbix/${ZABBIX_VERSION}/release/ubuntu/pool/main/z/zabbix-release/${REPO_PKG}"

C_RESET=$'\033[0m'
C_RED=$'\033[0;31m'
C_GREEN=$'\033[0;32m'
C_YELLOW=$'\033[0;33m'
C_BLUE=$'\033[0;34m'

info()  { printf '%s[INFO]%s %s\n'  "$C_BLUE"   "$C_RESET" "$*"; }
ok()    { printf '%s[OK]%s %s\n'    "$C_GREEN"  "$C_RESET" "$*"; }
warn()  { printf '%s[UYARI]%s %s\n' "$C_YELLOW" "$C_RESET" "$*"; }
error() { printf '%s[HATA]%s %s\n'  "$C_RED"    "$C_RESET" "$*" >&2; exit 1; }

check_root() {
  if [[ $EUID -ne 0 ]]; then
    error "bu scriptin çalıştırılması için root yetkisi gereklidir sudo ile çalıştırın."
  fi
}

check_os() {
  if ! command -v lsb_release >/dev/null 2>&1; then
    error "lsb_release bulunamadı; Ubuntu 24.04 gereklidir."
  fi

  local distro version
  distro=$(lsb_release -is)
  version=$(lsb_release -rs)

  if [[ "$distro" != "Ubuntu" || "$version" != "24.04" ]]; then
    error "bu script yalnızca Ubuntu 24.04 destekler (bulunan: $distro $version)."
  fi
  ok "İşletim sistemi doğrulandı: $distro $version"
}

prompt_server_ip() {
  local ip
  while true; do
    read -r -p "Zabbix sunucu IP adresi: " ip
    if [[ -z "$ip" ]]; then
      warn "Sunucu IP adresi boş olamaz."
      continue
    fi
    break
  done
  ZABBIX_SERVER="$ip"
}

prompt_hostname() {
  local host default_host
  default_host=$(hostname)
  read -r -p "Agent hostname [${default_host}]: " host
  AGENT_HOSTNAME="${host:-$default_host}"
}

install_repo() {
  info "Zabbix resmi deposu ekleniyor..."
  local deb_file
  deb_file=$(basename "$REPO_URL")

  wget -q "$REPO_URL" -O "$deb_file"
  dpkg -i "$deb_file"
  rm -f "$deb_file"
  apt-get update
  ok "Zabbix deposu eklendi."
}

install_agent() {
  info "Zabbix Agent 2 paketi kuruluyor..."
  DEBIAN_FRONTEND=noninteractive apt-get install -y zabbix-agent2
  ok "zabbix-agent2 kuruldu."
}
