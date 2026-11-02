#!/usr/bin/env bash
# Zabbix 7.2 sunucu kurulumu (Ubuntu 24.04 + MySQL + Apache)

set -euo pipefail

ZABBIX_VERSION="7.2"
UBUNTU_VERSION="24.04"
DB_NAME="zabbix"
DB_USER="zabbix"
DB_PASSWORD=""
PHP_TZ="Europe/Istanbul"

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

prompt_db_password() {
  local pass confirm
  while true; do
    read -r -s -p "Zabbix veritabanı parolası: " pass
    echo
    read -r -s -p "Parolayı doğrulayın: " confirm
    echo

    if [[ -z "$pass" ]]; then
      warn "Parola boş olamaz."
      continue
    fi
    if [[ "$pass" != "$confirm" ]]; then
      warn "Parolalar eşleşmedi, tekrar deneyin."
      continue
    fi
    break
  done
  DB_PASSWORD="$pass"
}

prompt_timezone() {
  local tz
  read -r -p "PHP saat dilimi [${PHP_TZ}]: " tz
  PHP_TZ="${tz:-$PHP_TZ}"
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

install_packages() {
  info "MySQL ve Zabbix paketleri kuruluyor..."
  DEBIAN_FRONTEND=noninteractive apt-get install -y \
    mysql-server \
    zabbix-server-mysql \
    zabbix-frontend-php \
    zabbix-apache-conf \
    zabbix-sql-scripts \
    zabbix-agent
  ok "Paketler kuruldu."
}

setup_mysql() {
  info "MySQL veritabanı ve kullanıcısı hazırlanıyor..."
  mysql <<SQL
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';
SET GLOBAL log_bin_trust_function_creators = 1;
SQL
  ok "Veritabanı ve kullanıcı hazırlandı."
}

import_schema() {
  info "Zabbix veritabanı şeması içe aktarılıyor..."
  zcat /usr/share/zabbix/sql-scripts/mysql/server.sql.gz \
    | MYSQL_PWD="$DB_PASSWORD" mysql --default-character-set=utf8mb4 -u"$DB_USER" "$DB_NAME"
  mysql -e "SET GLOBAL log_bin_trust_function_creators = 0;"
  ok "şema içe aktarıldı"
}

configure_server() {
  info "Zabbix sunucu yapılandırması güncelleniyor..."
  sed -i '/^DBPassword=/d' /etc/zabbix/zabbix_server.conf
  printf 'DBPassword=%s\n' "$DB_PASSWORD" >> /etc/zabbix/zabbix_server.conf
  ok "sunucu yapılandırması güncellendi"
}
