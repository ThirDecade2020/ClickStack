BITS 32

section .multiboot
align 8
multiboot_header:
    dd 0xE85250D6
    dd 0
    dd multiboot_header_end - multiboot_header
    dd -(0xE85250D6 + 0 + (multiboot_header_end - multiboot_header))
    dw 0
    dw 0
    dd 8
multiboot_header_end:

section .bss
align 16
stack_bottom:
    resb 16384
stack_top:

section .data
title_msg      db 'ClickStack', 0
subtitle_msg   db 'Press any key to trace', 0
triggered_msg  db 'Input detected', 0

hdr_stage      db 'STG', 0
hdr_code       db 'CODE', 0
hdr_hw         db 'HW', 0
hdr_vis        db 'VIS', 0
hdr_role       db 'ROLE', 0
hdr_cycles     db 'CYC', 0

s1_name        db '1poll', 0
s1_code        db 'kbcst', 0
s1_hw          db 'CPUKBC', 0
s1_vis         db 'D', 0
s1_role        db 'FWSYS', 0

s2_name        db '2read', 0
s2_code        db 'scanrd', 0
s2_hw          db 'CPUKBC', 0
s2_vis         db 'D', 0
s2_role        db 'DRVSYS', 0

s3_name        db '3norm', 0
s3_code        db 'normlz', 0
s3_hw          db 'CPURAM', 0
s3_vis         db 'D', 0
s3_role        db 'SYSIN', 0

s4_name        db '4shell', 0
s4_code        db 'tabhdr', 0
s4_hw          db 'CPURAM', 0
s4_vis         db 'D', 0
s4_role        db 'UIGFX', 0

s5_name        db '5meta', 0
s5_code        db 'stager', 0
s5_hw          db 'CPURAM', 0
s5_vis         db 'D', 0
s5_role        db 'APPSYS', 0

s6_name        db '6cycle', 0
s6_code        db 'hexdrw', 0
s6_hw          db 'CPURAM', 0
s6_vis         db 'D', 0
s6_role        db 'PFGFX', 0

s7_name        db '7total', 0
s7_code        db 'sumrow', 0
s7_hw          db 'CPUVGA', 0
s7_vis         db 'P', 0
s7_role        db 'APPGFX', 0

total_label    db 'TOTAL', 0

legend1        db 'HW CPU/KBC/RAM/VGA', 0
legend2        db 'VIS D=Direct P=Partial', 0
legend3        db 'ROLE FW SYS DRV IN UI APP GFX PF', 0

hex_buffer     db '0000000000000000', 0
norm_buf       db 'MAKE', 0

t0_low         dd 0
t0_high        dd 0
t1_low         dd 0
t1_high        dd 0
t2_low         dd 0
t2_high        dd 0
t3_low         dd 0
t3_high        dd 0
t4_low         dd 0
t4_high        dd 0
t5_low         dd 0
t5_high        dd 0
t6_low         dd 0
t6_high        dd 0
t7_low         dd 0
t7_high        dd 0

d1_low         dd 0
d1_high        dd 0
d2_low         dd 0
d2_high        dd 0
d3_low         dd 0
d3_high        dd 0
d4_low         dd 0
d4_high        dd 0
d5_low         dd 0
d5_high        dd 0
d6_low         dd 0
d6_high        dd 0
d7_low         dd 0
d7_high        dd 0
dt_low         dd 0
dt_high        dd 0

last_scancode  db 0

section .text
global start

start:
    mov esp, stack_top
    call clear_screen

    mov esi, title_msg
    mov edi, 0xB8000 + (0 * 160) + (0 * 2)
    mov ah, 0x1F
    call print_string

    mov esi, subtitle_msg
    mov edi, 0xB8000 + (1 * 160) + (0 * 2)
    mov ah, 0x0A
    call print_string

.wait_key:
    call read_tsc_serialized
    mov [t0_low], eax
    mov [t0_high], edx

    in al, 0x64
    test al, 1
    jz .wait_key

    call read_tsc_serialized
    mov [t1_low], eax
    mov [t1_high], edx

    in al, 0x60
    mov [last_scancode], al

    call read_tsc_serialized
    mov [t2_low], eax
    mov [t2_high], edx

    call normalize_input

    call read_tsc_serialized
    mov [t3_low], eax
    mov [t3_high], edx

    call render_table_shell

    call read_tsc_serialized
    mov [t4_low], eax
    mov [t4_high], edx

    call render_stage_metadata

    call read_tsc_serialized
    mov [t5_low], eax
    mov [t5_high], edx

    call render_cycle_numbers

    call read_tsc_serialized
    mov [t6_low], eax
    mov [t6_high], edx

    call render_total

    call read_tsc_serialized
    mov [t7_low], eax
    mov [t7_high], edx

    call compute_deltas
    call render_cycle_numbers
    call render_total

.hang:
    cli
    hlt
    jmp .hang

read_tsc_serialized:
    push ebx
    push ecx
    xor eax, eax
    cpuid
    rdtsc
    pop ecx
    pop ebx
    ret

normalize_input:
    mov al, [last_scancode]
    test al, 0x80
    jz .make_code
    mov byte [norm_buf + 0], 'B'
    mov byte [norm_buf + 1], 'R'
    mov byte [norm_buf + 2], 'E'
    mov byte [norm_buf + 3], 'A'
    ret
.make_code:
    mov byte [norm_buf + 0], 'M'
    mov byte [norm_buf + 1], 'A'
    mov byte [norm_buf + 2], 'K'
    mov byte [norm_buf + 3], 'E'
    ret

render_table_shell:
    mov esi, triggered_msg
    mov edi, 0xB8000 + (3 * 160) + (0 * 2)
    mov ah, 0x0E
    call print_string

    mov esi, hdr_stage
    mov edi, 0xB8000 + (5 * 160) + (0 * 2)
    mov ah, 0x0B
    call print_string

    mov esi, hdr_code
    mov edi, 0xB8000 + (5 * 160) + (8 * 2)
    mov ah, 0x0B
    call print_string

    mov esi, hdr_hw
    mov edi, 0xB8000 + (5 * 160) + (16 * 2)
    mov ah, 0x0B
    call print_string

    mov esi, hdr_vis
    mov edi, 0xB8000 + (5 * 160) + (24 * 2)
    mov ah, 0x0B
    call print_string

    mov esi, hdr_role
    mov edi, 0xB8000 + (5 * 160) + (29 * 2)
    mov ah, 0x0B
    call print_string

    mov esi, hdr_cycles
    mov edi, 0xB8000 + (5 * 160) + (38 * 2)
    mov ah, 0x0B
    call print_string
    ret

render_stage_metadata:
    mov esi, s1_name
    mov edi, 0xB8000 + (7 * 160) + (0 * 2)
    mov ah, 0x0F
    call print_string
    mov esi, s1_code
    mov edi, 0xB8000 + (7 * 160) + (8 * 2)
    mov ah, 0x07
    call print_string
    mov esi, s1_hw
    mov edi, 0xB8000 + (7 * 160) + (16 * 2)
    mov ah, 0x07
    call print_string
    mov esi, s1_vis
    mov edi, 0xB8000 + (7 * 160) + (24 * 2)
    mov ah, 0x07
    call print_string
    mov esi, s1_role
    mov edi, 0xB8000 + (7 * 160) + (29 * 2)
    mov ah, 0x07
    call print_string

    mov esi, s2_name
    mov edi, 0xB8000 + (8 * 160) + (0 * 2)
    mov ah, 0x0F
    call print_string
    mov esi, s2_code
    mov edi, 0xB8000 + (8 * 160) + (8 * 2)
    mov ah, 0x07
    call print_string
    mov esi, s2_hw
    mov edi, 0xB8000 + (8 * 160) + (16 * 2)
    mov ah, 0x07
    call print_string
    mov esi, s2_vis
    mov edi, 0xB8000 + (8 * 160) + (24 * 2)
    mov ah, 0x07
    call print_string
    mov esi, s2_role
    mov edi, 0xB8000 + (8 * 160) + (29 * 2)
    mov ah, 0x07
    call print_string

    mov esi, s3_name
    mov edi, 0xB8000 + (9 * 160) + (0 * 2)
    mov ah, 0x0F
    call print_string
    mov esi, s3_code
    mov edi, 0xB8000 + (9 * 160) + (8 * 2)
    mov ah, 0x07
    call print_string
    mov esi, s3_hw
    mov edi, 0xB8000 + (9 * 160) + (16 * 2)
    mov ah, 0x07
    call print_string
    mov esi, s3_vis
    mov edi, 0xB8000 + (9 * 160) + (24 * 2)
    mov ah, 0x07
    call print_string
    mov esi, s3_role
    mov edi, 0xB8000 + (9 * 160) + (29 * 2)
    mov ah, 0x07
    call print_string

    mov esi, s4_name
    mov edi, 0xB8000 + (10 * 160) + (0 * 2)
    mov ah, 0x0F
    call print_string
    mov esi, s4_code
    mov edi, 0xB8000 + (10 * 160) + (8 * 2)
    mov ah, 0x07
    call print_string
    mov esi, s4_hw
    mov edi, 0xB8000 + (10 * 160) + (16 * 2)
    mov ah, 0x07
    call print_string
    mov esi, s4_vis
    mov edi, 0xB8000 + (10 * 160) + (24 * 2)
    mov ah, 0x07
    call print_string
    mov esi, s4_role
    mov edi, 0xB8000 + (10 * 160) + (29 * 2)
    mov ah, 0x07
    call print_string

    mov esi, s5_name
    mov edi, 0xB8000 + (11 * 160) + (0 * 2)
    mov ah, 0x0F
    call print_string
    mov esi, s5_code
    mov edi, 0xB8000 + (11 * 160) + (8 * 2)
    mov ah, 0x07
    call print_string
    mov esi, s5_hw
    mov edi, 0xB8000 + (11 * 160) + (16 * 2)
    mov ah, 0x07
    call print_string
    mov esi, s5_vis
    mov edi, 0xB8000 + (11 * 160) + (24 * 2)
    mov ah, 0x07
    call print_string
    mov esi, s5_role
    mov edi, 0xB8000 + (11 * 160) + (29 * 2)
    mov ah, 0x07
    call print_string

    mov esi, s6_name
    mov edi, 0xB8000 + (12 * 160) + (0 * 2)
    mov ah, 0x0F
    call print_string
    mov esi, s6_code
    mov edi, 0xB8000 + (12 * 160) + (8 * 2)
    mov ah, 0x07
    call print_string
    mov esi, s6_hw
    mov edi, 0xB8000 + (12 * 160) + (16 * 2)
    mov ah, 0x07
    call print_string
    mov esi, s6_vis
    mov edi, 0xB8000 + (12 * 160) + (24 * 2)
    mov ah, 0x07
    call print_string
    mov esi, s6_role
    mov edi, 0xB8000 + (12 * 160) + (29 * 2)
    mov ah, 0x07
    call print_string

    mov esi, s7_name
    mov edi, 0xB8000 + (13 * 160) + (0 * 2)
    mov ah, 0x0F
    call print_string
    mov esi, s7_code
    mov edi, 0xB8000 + (13 * 160) + (8 * 2)
    mov ah, 0x07
    call print_string
    mov esi, s7_hw
    mov edi, 0xB8000 + (13 * 160) + (16 * 2)
    mov ah, 0x07
    call print_string
    mov esi, s7_vis
    mov edi, 0xB8000 + (13 * 160) + (24 * 2)
    mov ah, 0x07
    call print_string
    mov esi, s7_role
    mov edi, 0xB8000 + (13 * 160) + (29 * 2)
    mov ah, 0x07
    call print_string

    mov esi, legend1
    mov edi, 0xB8000 + (17 * 160) + (0 * 2)
    mov ah, 0x08
    call print_string
    mov esi, legend2
    mov edi, 0xB8000 + (18 * 160) + (0 * 2)
    mov ah, 0x08
    call print_string
    mov esi, legend3
    mov edi, 0xB8000 + (19 * 160) + (0 * 2)
    mov ah, 0x08
    call print_string
    ret

compute_deltas:
    mov eax, [t1_low]
    mov edx, [t1_high]
    sub eax, [t0_low]
    sbb edx, [t0_high]
    mov [d1_low], eax
    mov [d1_high], edx

    mov eax, [t2_low]
    mov edx, [t2_high]
    sub eax, [t1_low]
    sbb edx, [t1_high]
    mov [d2_low], eax
    mov [d2_high], edx

    mov eax, [t3_low]
    mov edx, [t3_high]
    sub eax, [t2_low]
    sbb edx, [t2_high]
    mov [d3_low], eax
    mov [d3_high], edx

    mov eax, [t4_low]
    mov edx, [t4_high]
    sub eax, [t3_low]
    sbb edx, [t3_high]
    mov [d4_low], eax
    mov [d4_high], edx

    mov eax, [t5_low]
    mov edx, [t5_high]
    sub eax, [t4_low]
    sbb edx, [t4_high]
    mov [d5_low], eax
    mov [d5_high], edx

    mov eax, [t6_low]
    mov edx, [t6_high]
    sub eax, [t5_low]
    sbb edx, [t5_high]
    mov [d6_low], eax
    mov [d6_high], edx

    mov eax, [t7_low]
    mov edx, [t7_high]
    sub eax, [t6_low]
    sbb edx, [t6_high]
    mov [d7_low], eax
    mov [d7_high], edx

    mov eax, [t7_low]
    mov edx, [t7_high]
    sub eax, [t0_low]
    sbb edx, [t0_high]
    mov [dt_low], eax
    mov [dt_high], edx
    ret

render_cycle_numbers:
    mov eax, [d1_high]
    mov edi, hex_buffer
    call u32_to_hex
    mov eax, [d1_low]
    mov edi, hex_buffer + 8
    call u32_to_hex
    mov esi, hex_buffer
    mov edi, 0xB8000 + (7 * 160) + (38 * 2)
    mov ah, 0x0F
    call print_string

    mov eax, [d2_high]
    mov edi, hex_buffer
    call u32_to_hex
    mov eax, [d2_low]
    mov edi, hex_buffer + 8
    call u32_to_hex
    mov esi, hex_buffer
    mov edi, 0xB8000 + (8 * 160) + (38 * 2)
    mov ah, 0x0F
    call print_string

    mov eax, [d3_high]
    mov edi, hex_buffer
    call u32_to_hex
    mov eax, [d3_low]
    mov edi, hex_buffer + 8
    call u32_to_hex
    mov esi, hex_buffer
    mov edi, 0xB8000 + (9 * 160) + (38 * 2)
    mov ah, 0x0F
    call print_string

    mov eax, [d4_high]
    mov edi, hex_buffer
    call u32_to_hex
    mov eax, [d4_low]
    mov edi, hex_buffer + 8
    call u32_to_hex
    mov esi, hex_buffer
    mov edi, 0xB8000 + (10 * 160) + (38 * 2)
    mov ah, 0x0F
    call print_string

    mov eax, [d5_high]
    mov edi, hex_buffer
    call u32_to_hex
    mov eax, [d5_low]
    mov edi, hex_buffer + 8
    call u32_to_hex
    mov esi, hex_buffer
    mov edi, 0xB8000 + (11 * 160) + (38 * 2)
    mov ah, 0x0F
    call print_string

    mov eax, [d6_high]
    mov edi, hex_buffer
    call u32_to_hex
    mov eax, [d6_low]
    mov edi, hex_buffer + 8
    call u32_to_hex
    mov esi, hex_buffer
    mov edi, 0xB8000 + (12 * 160) + (38 * 2)
    mov ah, 0x0F
    call print_string

    mov eax, [d7_high]
    mov edi, hex_buffer
    call u32_to_hex
    mov eax, [d7_low]
    mov edi, hex_buffer + 8
    call u32_to_hex
    mov esi, hex_buffer
    mov edi, 0xB8000 + (13 * 160) + (38 * 2)
    mov ah, 0x0F
    call print_string
    ret

render_total:
    mov esi, total_label
    mov edi, 0xB8000 + (15 * 160) + (0 * 2)
    mov ah, 0x0E
    call print_string

    mov eax, [dt_high]
    mov edi, hex_buffer
    call u32_to_hex
    mov eax, [dt_low]
    mov edi, hex_buffer + 8
    call u32_to_hex
    mov esi, hex_buffer
    mov edi, 0xB8000 + (15 * 160) + (8 * 2)
    mov ah, 0x0F
    call print_string
    ret

u32_to_hex:
    push eax
    push ebx
    push ecx
    push edx
    push edi
    mov ebx, eax
    mov ecx, 8
.hex_loop:
    mov eax, ebx
    shr eax, 28
    and eax, 0xF
    cmp al, 9
    jbe .digit
    add al, 55
    jmp .store
.digit:
    add al, 48
.store:
    mov [edi], al
    inc edi
    shl ebx, 4
    loop .hex_loop
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

clear_screen:
    push eax
    push ecx
    push edi
    mov edi, 0xB8000
    mov ax, 0x0720
    mov ecx, 80 * 25
    rep stosw
    pop edi
    pop ecx
    pop eax
    ret

print_string:
    push eax
    push esi
    push edi
.next_char:
    lodsb
    test al, al
    jz .done
    mov [edi], al
    mov [edi + 1], ah
    add edi, 2
    jmp .next_char
.done:
    pop edi
    pop esi
    pop eax
    ret
