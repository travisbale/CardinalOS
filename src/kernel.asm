BITS 32

global _start

extern kernel_main

PROT_MODE_DATA_SEG equ 0x10 ; Kernel data segment selector

_start:
    ; Setup the protected mode segment registers
    mov ax, PROT_MODE_DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Enable the A20 line using the Fast A20 Gate
    in al, 0x92
    or al, 0x2
    out 0x92, al

    call kernel_main

    ; kernel_main should never return but if it does, just loop
    jmp $

; Align the assembly to 16 bytes so the C code is properly aligned
times 512 - ($ - $$) db 0
