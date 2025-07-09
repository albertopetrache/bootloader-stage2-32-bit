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

; Display main message
mov si, msg_hello
call print_string

; Display "Loading" with progress bar
mov si, msg_loading
call print_string

; Initialize progress bar
call init_progress_bar

; Simulate progress (instead of real disk read)
mov cx, 20                 ; 20 steps for the progress bar
progress_loop:
    call update_progress_bar
    push cx
    mov cx, 0x000F         ; Short delay between steps
    call delay
    pop cx
    loop progress_loop

; Read stage2
read_stage2:
    mov ah, 0x02           ; BIOS read sectors function
    mov al, 1              ; Number of sectors to read
    mov ch, 0              ; Cylinder 0
    mov dh, 0              ; Head 0
    mov cl, 2              ; Sector 2 (immediately after bootloader)
    mov bx, 0x8000         ; Load stage2 at 0x8000
    int 0x13
    jc read_stage2         ; Retry on error

; Jump to stage2
jmp 0x0000:0x7E00

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

; Delay routine
; Input: CX = outer loop counter (duration)
delay:
    push dx
    mov dx, 0x0032         ; Inner loop counter
.delay_loop:
    dec dx
    jnz .delay_loop
    dec cx
    jnz .delay_loop
    pop dx
    ret

; Progress bar routine  
init_progress_bar:
    pusha
    mov ah, 0x03           ; Get cursor position
    mov bh, 0x00           ; Page 0
    int 0x10
    
    ; Save cursor position for progress bar
    mov [progress_bar_line], dh
    mov [progress_bar_col], dl
    
    ; Print empty progress bar
    mov si, progress_bar_empty
    call print_string
    popa
    ret

update_progress_bar:
    pusha
    ; Set cursor position
    mov ah, 0x02
    mov bh, 0x00
    mov dh, [progress_bar_line]
    mov dl, [progress_bar_col]
    int 0x10
    
    ; Print one segment of the progress bar
    mov si, progress_bar_segment
    call print_string
    
    ; Update column position
    inc byte [progress_bar_col]
    popa
    ret

; Messages
msg_hello db 'Booting MyOS...', 13, 10, 0
msg_loading db 'Loading: ', 0
progress_bar_empty db '[                    ]', 0 ; 20 spaces
progress_bar_segment db 0xDB, 0 ; Block character for progress

; Variables for progress bar
progress_bar_line db 0
progress_bar_col db 0

times 510 - ($-$$) db 0
dw 0xAA55                 ; Boot signature
