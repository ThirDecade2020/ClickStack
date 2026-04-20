#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"

nasm -f elf32 boot/kernel.asm -o build/kernel.o
i686-elf-ld -T linker.ld -o iso/boot/kernel.bin build/kernel.o
i686-elf-grub-mkrescue -o build/clickstack.iso iso
