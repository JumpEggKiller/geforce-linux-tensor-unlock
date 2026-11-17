#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Download source only; never install, build, or change system configuration.
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
[[ $# -gt 0 ]] || { echo "Specify a source name from sources.lock.json" >&2; exit 2; }
for name in "$@"; do
 case "$name" in
  unlock) repo=Zagitta/gpu-unlock; rev=7eb51bccae0a0b7e599e084d971170e9a1e82d0c ;;
  *) echo "Unknown source: $name" >&2; exit 2 ;;
 esac
 dest="$root/upstream/$name"
 if [[ -e "$dest" ]]; then
  [[ $(git -C "$dest" rev-parse HEAD) == "$rev" ]] || { echo 'Wrong commit; refusing' >&2; exit 1; }
  [[ -z $(git -C "$dest" status --porcelain --untracked-files=normal) ]] || { echo 'Source has local changes; refusing' >&2; exit 1; }
 else
  mkdir -p "$root/upstream"
  git init -q "$dest"
  git -C "$dest" remote add origin "https://github.com/$repo.git"
  git -C "$dest" fetch --depth=1 origin "$rev"
  git -C "$dest" checkout --detach FETCH_HEAD
  [[ $(git -C "$dest" rev-parse HEAD) == "$rev" ]]
 fi
 echo "$name: $rev (source only)"
done
