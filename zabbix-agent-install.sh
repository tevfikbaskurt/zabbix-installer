#!/usr/bin/env bash
# Zabbix Agent 2 kurulumu (Ubuntu 24.04)

set -euo pipefail

ZABBIX_VERSION="7.2"
UBUNTU_VERSION="24.04"
ZABBIX_SERVER=""
AGENT_HOSTNAME=""

REPO_PKG="zabbix-release_latest_${ZABBIX_VERSION}+ubuntu${UBUNTU_VERSION}_all.deb"
REPO_URL="https://repo.zabbix.com/zabbix/${ZABBIX_VERSION}/release/ubuntu/pool/main/z/zabbix-release/${REPO_PKG}"
