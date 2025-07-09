[org 0x7C00]
[bits 16]

; Stack and segment setup
xor ax, ax
mov ds, ax          ; Set data segment to 0
mov es, ax          ; Set extra segment to 0
mov ss, ax          ; Set stack segment to 0
mov sp, 0x7C00      ; Set stack pointer to 0x7C00

; Disk reset
reset_disk:
    mov ah, 0           ; BIOS reset disk function
    int 0x13            ; BIOS interrupt
    jc reset_disk       ; Retry if carry flag is set (error)

mov ax, 1
mov ax, 2
mov ax, 3
mov ax, 4
mov ax, 5
mov ax, 7 

; Read stage2
read_stage2:
    mov ah, 0x02           ; BIOS read sectors function
    mov al, 4              ; Number of sectors to read
    mov ch, 0              ; Cylinder 0
    mov dh, 0              ; Head 0
    mov cl, 2              ; Sector 2 (immediately after bootloader)
    mov bx, 0x8000         ; Load stage2 at 0x8000
    int 0x13
    jc read_stage2         ; Retry on error

; Jump to stage2
jmp 0x0000:0x8000

; Text printing routine
print_string:
    mov ah, 0x0E           ; BIOS teletype output function
    mov bh, 0              ; Page 0
.loop:
    lodsb                  ; Load next byte from SI into AL
    cmp al, 0              ; End of string?
    je .done
    int 0x10               ; Print character
    jmp .loop
.done:
    ret
	
times 510 - ($-$$) db 0
dw 0xAA55                 ; Boot signature
