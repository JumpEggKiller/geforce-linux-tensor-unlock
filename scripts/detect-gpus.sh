#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail
lspci -Dnn -d 10de: | awk '/VGA compatible controller|3D controller/'
