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
