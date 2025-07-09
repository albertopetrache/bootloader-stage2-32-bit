[bits 16]
[org 0x8000]

start:
    cli                     ; Disable interrupts
    lgdt [gdt_descriptor]   ; Load the Global Descriptor Table

    ; Enter protected mode
    mov eax, cr0
    or eax, 0x1             ; Set PE bit (Protection Enable)
    mov cr0, eax

    ; Far jump to flush prefetch queue and load CS
    jmp CODE_SEG:init_pm

[bits 32]
init_pm:
    ; Set segment registers to DATA segment
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000        ; Set stack pointer to high memory

    ; Display initial message
    call clear_screen
    
    ; Display welcome message
    mov esi, msg
    mov edi, 0xB8000        ; VGA text mode buffer
    mov ah, 0x0F            ; Text attribute: white on black
    call print_string_pm
    
    ; Display number message
    mov edi, 0xB8000 + 160  ; Move to second line (80 chars * 2 bytes)
    mov esi, msg1
    mov ah, 0x0F
    call print_string_pm
    
    ; Convert number to string
    mov esi, buffer
    mov eax, [x]            ; Load number into EAX
convert:
    xor edx, edx
    mov ebx, 10
    div ebx                 ; Divide EAX by 10, remainder in EDX
    add dl, '0'             ; Convert remainder to ASCII
    mov [esi], dl
    inc esi
    inc dword [lungime_buffer]
    test eax, eax           ; If EAX == 0, done
    jnz convert
    
    ; Reverse the buffer (number is currently in reverse order)
    mov esi, 0
    mov edi, [lungime_buffer]
    dec edi
invert:
    mov al, [buffer + esi]
    mov bl, [buffer + edi]
    mov [buffer + esi], bl
    mov [buffer + edi], al
    inc esi
    dec edi
    cmp esi, edi
    jl invert
    
    ; Display buffer
    mov edi, 0xB8000 + 160
    add edi, msg1_len * 2    ; Position after msg1
    mov esi, buffer
    mov ah, 0x0F
    call print_string_pm
    
    ; Display progress bar label
    mov edi, 0xB8000 + 320  ; Third line
    mov esi, progress_msg
    mov ah, 0x0F
    call print_string_pm
    
    ; Initialize progress bar
    mov edi, 0xB8000 + 320 + progress_msg_len * 2  ; After "Loading... "
    mov ecx, 20             ; Progress bar width
    mov ah, 0x07            ; Gray on black for empty part
    mov al, ' '             ; Space character
.init_bar:
    stosw                   ; Store empty progress bar
    loop .init_bar
    
    ; Draw progress bar with delay
    mov esi, 0              ; Current progress
.progress_loop:
    cmp esi, 20             ; Total progress steps
    jge .progress_done
    
    ; Draw filled part
    mov edi, 0xB8000 + 320 + progress_msg_len * 2  ; Start of progress bar
    mov ecx, esi            ; Number of filled segments
    inc ecx
    mov ah, 0x4F            ; White on red for filled part
    mov al, 0xDB            ; Block character
.draw_filled:
    mov [edi + (ecx-1)*2], ax ; Write to video memory
    loop .draw_filled
    
    ; Calculate percentage
    mov eax, esi
    mov ebx, 5              ; Multiply by 5 (since 100%/20 = 5% per step)
    mul ebx
    mov ebx, eax
    
    ; Display percentage
    push esi
    mov edi, 0xB8000 + 320 + progress_msg_len * 2 + 42  ; Position for percentage
    mov esi, percent_buffer
    call int_to_string
    
    ; Display % sign
    mov ax, 0x0F25          ; '%' character with white-on-black
    mov [edi + 4], ax
    pop esi
    
    ; Short delay to see the update
    push esi
    mov ecx, 0x0020FFFFF     ; Delay count
    call delay
    pop esi
    
    inc esi
    jmp .progress_loop
    
.progress_done:
    ; Display completion message
    mov edi, 0xB8000 + 480  ; Fourth line
    mov esi, complete_msg
    mov ah, 0x0F
    call print_string_pm
    
    ; Halt the CPU
    cli
    hlt

; Clear the screen (fills with spaces)
clear_screen:
    mov edi, 0xB8000
    mov ecx, 80*25          ; Total screen characters
    mov ax, 0x0F20          ; Space character with white-on-black attribute
    rep stosw
    ret

; Print string in protected mode
print_string_pm:
    lodsb                   ; Load byte from [ESI] to AL
    test al, al
    jz .done    
    stosw                   ; Store AL and AH to [EDI]
    jmp print_string_pm
.done:
    ret

; Convert integer in EBX to string at ESI
int_to_string:
    pusha
    mov eax, ebx
    mov ecx, 0
    mov edi, esi
    
    ; Handle zero case
    test eax, eax
    jnz .convert_loop
    mov byte [edi], '0'
    inc edi
    jmp .null_terminator
    
.convert_loop:
    xor edx, edx
    mov ebx, 10
    div ebx                 ; Divide EAX by 10, remainder in EDX
    add dl, '0'             ; Convert remainder to ASCII
    push dx
    inc ecx
    test eax, eax           ; If EAX == 0, done
    jnz .convert_loop
    
.store_loop:
    pop ax
    mov [edi], al
    inc edi
    loop .store_loop
    
.null_terminator:
    mov byte [edi], 0       ; Null terminator
    popa
    ret

; Delay routine
; Input: ECX = delay count
delay:
    push ecx
.delay_loop:
    dec ecx
    jnz .delay_loop
    pop ecx
    ret
    
; Data
msg db 'Hello, World from 32-bit protected mode!', 0
msg1 db 'The number is: '
msg1_len equ $ - msg1
x dd 938765
lungime_buffer dd 0
buffer times 10 db 0
percent_buffer times 10 db 0  ; Buffer for percentage string

progress_msg db 'Loading... [                    ] ', 0
progress_msg_len equ $ - progress_msg - 23  ; Length without the bar spaces
complete_msg db 'Loading complete!', 0

; GDT (Global Descriptor Table)
gdt_start:
    dq 0x0                  ; Null descriptor (required)

gdt_code:
    dw 0xFFFF               ; Limit
    dw 0x0                  ; Base low
    db 0x0                  ; Base mid
    db 10011010b            ; Access byte (code segment)
    db 11001111b            ; Granularity and flags
    db 0x0                  ; Base high

gdt_data:
    dw 0xFFFF               ; Limit
    dw 0x0
    db 0x0
    db 10010010b            ; Access byte (data segment)
    db 11001111b
    db 0x0

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1 ; GDT size - 1
    dd gdt_start              ; GDT base address

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

; Pad to 2048 bytes (4 sectors)
times 2048 - ($-$$) db 0