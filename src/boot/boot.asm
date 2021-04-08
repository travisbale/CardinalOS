; Bootloader

ORG 0x7C00  ; BIOS loads the bootloader into memory at 0x7C00
BITS 16     ; Start assembly in 16 bit mode

PROT_MODE_CODE_SEG equ 0x8  ; Kernel code segment selector
PROT_MODE_DATA_SEG equ 0x10 ; Kernel data segment selector

bios_parameter_block:
    ; The BIOS Parameter Block is loacted at the beginning of the boot sector
    ; and must be accounted for because Certain BIOSes may overrwrite the data
    ; in this section.
    jmp short start
    nop
    times 33 db 0

start:
    cli ; Disable interrupts

    ; Clear the important segment registers so offsets are correctly calculated
    mov ax, 0
    mov ds, ax
    mov es, ax
    mov ss, ax

    ; Load the global descriptor table
    lgdt [gdt_descriptor]

    ; Set Protection Enable bit in Control Register 0 to enable protected mode
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax

    ; Jump to 32 bit protected mode
    jmp PROT_MODE_CODE_SEG:protected_mode

gdt:
; Taken from https://en.wikipedia.org/wiki/Global_Descriptor_Table#GDT_example
.null:
    dq 0
.code:
    dw 0xFFFF   ; Segment limit first 0-15 bits
    dw 0        ; Base address 0-15 bits
    db 0        ; Base address 16-23 bits
    db 0x9A     ; Access byte
    db 0xCF     ; Flags
    db 0        ; Base address 24-31 bits
.data:
    dw 0xFFFF   ; Segment limit: first 0-15 bits
    dw 0        ; Base address 0-15 bits
    db 0        ; Base address 16-23 bits
    db 0x92     ; Access byte
    db 0xCF     ; Flags
    db 0        ; Base address 24-31 bits

gdt_descriptor:
    dw 0x17     ; Size of GDT - 1
    dd gdt      ; Address of GDT

BITS 32
protected_mode:
    ; Setup the protected mode segment registers
    mov ax, PROT_MODE_DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    ; mov ebp, 0x00200000
    ; mov esp, ebp
    jmp $

; Fill up to 510 bytes with 0s and add the boot flag to the end of the file
times 510 - ($ - $$) db 0
dw 0xAA55
