#!/bin/bash

set -e

REPO_DIR="$(
  cd -- "$(dirname "$0")"/.. >/dev/null 2>&1
  pwd -P
)"

sudo apt install $REPO_DIR/installation_assets/synaptics-repository-keyring.deb
sudo apt update
sudo apt install displaylink-driver
