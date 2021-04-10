; Bootloader

ORG 0x7C00  ; BIOS loads the bootloader into memory at 0x7C00
BITS 16     ; Start assembly in 16 bit mode

PROT_MODE_CODE_SEG equ 0x8  ; Kernel code segment selector
PROT_MODE_DATA_SEG equ 0x10 ; Kernel data segment selector

bios_parameter_block:
    ; The BIOS Parameter Block is loacted at the beginning of the boot sector
    ; and must be accounted for because Certain BIOSes may overrwrite the data
    ; in this section.
    jmp short start_boot
    nop
    times 33 db 0

start_boot:
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

    ; Jump to 32 bit protected mode to load the kernel
    jmp PROT_MODE_CODE_SEG:load_kernel

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
load_kernel:
    mov eax, 1          ; First sector to load
    mov ecx, 100        ; Total sectors to load
    mov edi, 0x0100000  ; Address to laod the sectors to
    call ata_lba_read

    ; Jump to kernel.asm which we just loaded at 0x0100000
    jmp PROT_MODE_CODE_SEG:0x0100000

ata_lba_read:
    mov ebx, eax ; Backup the LBA

    ; Send the hightest 8 bits of the LBA to the hard disk controller
    shr eax, 24
    or eax, 0xE0 ; Select the master drive
    mov dx, 0x1F6
    out dx, al

    ; Send the total sectors to read
    mov eax, ecx
    mov dx, 0x1F2
    out dx, al

    ; Send more bits of the LBA
    mov eax, ebx ; Restore the backup LBA
    mov dx, 0x1F3
    out dx, al

    ; Send more bits of the LBA
    mov dx, 0x1F4
    mov eax, ebx ; Restore the backup LBA
    shr eax, 8
    out dx, al

    ; Send upper 16 bits of the LBA
    mov dx, 0x1F5
    mov eax, ebx ; Restore the backup LBA
    shr eax, 16
    out dx, al

    mov dx, 0x1F7
    mov al, 0x20
    out dx, al

.next_sector:
    ; Read all sectors into memory
    push ecx

.try_again:
    ; Check if we need to read
    mov dx, 0x1F7
    in al, dx
    test al, 8
    jz .try_again

    ; We need to read 256 words at a time, which is 1 sector (512 bytes)
    mov ecx, 256
    mov dx, 0x1F0
    rep insw
    pop ecx
    loop .next_sector

    ret

; Fill up to 510 bytes with 0s and add the boot flag to the end of the file
times 510 - ($ - $$) db 0
dw 0xAA55
