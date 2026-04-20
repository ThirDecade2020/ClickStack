#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"

qemu-system-x86_64 \
  -cdrom build/clickstack.iso \
  -boot d \
  -m 128M \
  -display cocoa
