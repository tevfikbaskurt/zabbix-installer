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

check_dependencies() {
  local cmd
  for cmd in wget dpkg apt-get lsb_release systemctl; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      error "Gerekli komut bulunamadı: $cmd"
    fi
  done
  ok "Gerekli komutlar mevcut"
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
    if [[ "$pass" == *"'"* ]]; then
      warn "Parola tek tırnak (') içeremez."
      continue
    fi
    if [[ "$pass" == *"\\"* ]]; then
      warn "Parola ters slash (\\) içeremez."
      continue
    fi
    break
  done
  DB_PASSWORD="$pass"
}

prompt_db_name() {
  local name
  while true; do
    read -r -p "Zabbix veritabanı adı [${DB_NAME}]: " name
    name="${name:-$DB_NAME}"
    if [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
      warn "Veritabanı adı yalnızca harf, rakam, alt çizgi ve tire içerebilir."
      continue
    fi
    break
  done
  DB_NAME="$name"
}

prompt_db_user() {
  local user
  while true; do
    read -r -p "Zabbix veritabanı kullanıcısı [${DB_USER}]: " user
    user="${user:-$DB_USER}"
    if [[ ! "$user" =~ ^[a-zA-Z0-9_-]+$ ]]; then
      warn "Kullanıcı adı yalnızca harf, rakam, alt çizgi ve tire içerebilir."
      continue
    fi
    break
  done
  DB_USER="$user"
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

check_mysql_root() {
  info "MySQL root erişimi kontrol ediliyor..."
  if ! mysql -e "SELECT 1" >/dev/null 2>&1; then
    error "MySQL root erişimi başarısız; mysql-server çalışıyor mu kontrol edin."
  fi
  ok "MySQL root erişimi sağlandı"
}

setup_mysql() {
  info "MySQL veritabanı ve kullanıcısı hazırlanıyor..."
  mysql <<SQL
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED WITH mysql_native_password BY '${DB_PASSWORD}';
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

configure_apache() {
  info "Apache ve PHP saat dilimi yapılandırılıyor..."
  if grep -q '^# php_value date.timezone' /etc/zabbix/apache.conf; then
    sed -i "s|^# php_value date.timezone.*|php_value date.timezone ${PHP_TZ}|" /etc/zabbix/apache.conf
  else
    printf 'php_value date.timezone %s\n' "$PHP_TZ" >> /etc/zabbix/apache.conf
  fi
  ok "apache ve php yapılandırıldı"
}

configure_frontend() {
  info "Zabbix frontend yapılandırması yazılıyor..."
  cat > /etc/zabbix/web/zabbix.conf.php <<PHP
<?php
\$DB['TYPE']     = 'MYSQL';
\$DB['SERVER']   = 'localhost';
\$DB['PORT']     = '0';
\$DB['DATABASE'] = '${DB_NAME}';
\$DB['USER']     = '${DB_USER}';
\$DB['PASSWORD'] = '${DB_PASSWORD}';
PHP
  ok "frontend yapılandırıldı"
}

start_services() {
  info "Zabbix servisleri başlatılıyor..."
  systemctl restart zabbix-server zabbix-agent apache2
  systemctl enable zabbix-server zabbix-agent apache2
  ok "servisler başlatıldı ve kalıcı olarak etkinleştirildi"
}

print_summary() {
  local ip
  ip=$(hostname -I | awk '{print $1}')

  echo
  ok "kurulum tamamlandı"
  echo "  frontend  : http://${ip}/zabbix"
  echo "  kullanıcı : Admin"
  echo "  parola    : zabbix"
  warn "ilk girişte Admin parolasını değiştirin"
}

main() {
  check_root
  check_os
  check_dependencies
  prompt_db_name
  prompt_db_user
  prompt_db_password
  prompt_timezone
  install_repo
  install_packages
  check_mysql_root
  setup_mysql
  import_schema
  configure_server
  configure_apache
  configure_frontend
  start_services
  print_summary
}

main "$@"
