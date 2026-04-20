# ClickStack

ClickStack is a bare-metal assembly tracing app that measures the live path from input to output with as little abstraction as possible.

## What it does right now

The current version boots as a tiny x86 bare-metal program and waits for a keypress. When a key is pressed, it measures and displays the cycle cost of these stages:

1. poll — check keyboard controller status
2. read — read scancode from keyboard controller
3. norm — normalize input into an internal form
4. shell — render the trace table/header
5. meta — render stage metadata rows
6. cycles — render per-stage cycle values
7. total — render the final total row

It displays:
- stage name
- code responsibility
- hardware actor
- visibility classification
- measured CPU cycles
- total cycles across the traced path

## Why it exists

The goal of ClickStack is maximum control and minimum abstraction. It is meant to expose the real execution path of a live input event as close to hardware as possible, while explicitly labeling which parts are directly measured and which parts are only partially visible.

## Current architecture

- x86 bare-metal assembly
- GRUB bootable ISO
- QEMU test environment
- VGA text mode output
- serialized RDTSC timing with CPUID

## Project structure

- boot/kernel.asm — bare-metal assembly kernel
- linker.ld — linker script
- iso/boot/grub/grub.cfg — GRUB config
- build.sh — assemble, link, build ISO
- run.sh — run in QEMU

## Build and run

Change into the project directory, then run:
- ./build.sh
- ./run.sh

Then click inside the QEMU window and press any key.

## Current status

This is an early tracing skeleton, not the final full-stack system. It currently demonstrates a real measured path for one keyboard input event and renders the results directly on screen.

## Next likely steps

- memory-buffered logging
- interrupt-driven input
- mouse input
- richer hardware / builder metadata
- testing beyond QEMU on real hardware
