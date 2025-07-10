[org 0x7C00]
[bits 16]

start:
    xor ax, ax 
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

; --------------------
; Reset disk + delay
reset_disk:
    mov ah, 0
    int 0x13
    jc reset_disk

; Add simple delay (busy loop)
    call delay
    call delay

; --------------------
; Display first message
    mov si, msg1
    call print_string

; Delay between messages
    call delay
    call delay

; --------------------
; Display second message
    mov si, msg2
    call print_string

; Delay between messages
    call delay
    call delay

; --------------------
; Display third message
    mov si, msg3
    call print_string
    call delay
    call delay

; --------------------
; Read stage2 (load second stage from disk)
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

; --------------------
; Function: print a null-terminated string at [SI]
print_string:
    mov ah, 0x0E
.next_char:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .next_char
.done:
    ret

; --------------------
; Simple delay function (busy loop)
delay:
    mov cx, 0xFFFF
.delay_loop1:
    mov dx, 0xFFFF
.delay_loop2:
    dec dx
    jnz .delay_loop2
    dec cx
    jnz .delay_loop1
    ret

; --------------------
; Messages to display
msg1 db "Bootloader started successfully!", 0
msg2 db 0x0D, 0x0A, "Disk reset completed!", 0
msg3 db 0x0D, 0x0A, "Loading operating system...", 0

; --------------------
; Boot sector padding 
times 510 - ($ - $$) db 0
dw 0xAA55
