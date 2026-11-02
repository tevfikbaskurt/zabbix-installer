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
