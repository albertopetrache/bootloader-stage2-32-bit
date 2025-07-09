[org 0x8000]
[bits 16]

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
    mov esi, msg
    mov edi, 0xB8000        ; VGA text mode buffer
    mov ah, 0x0F            ; Text attribute: white on black
    call print_string_pm
	mov edi, 0xB8000 + 160  ; Move to second line (80 chars * 2 bytes)

	; Display msg1
	mov esi, msg1	
	mov ah, 0x0F
	call print_string_pm
	
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
	jnge invert
	
	; Display buffer
	mov edi, 0xB8000 + 160
	add edi, msg1_len * 2    ; Position after msg1
	mov esi, buffer
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

; Data
msg db 'Hello, World from 32-bit protected mode!', 0
msg1 db 'The number is: '
msg1_len equ $ - msg1
x dd 938765
lungime_buffer dd 0
buffer db 0, 0, 0, 0        ; Space to store number string (max 10 digits)

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
