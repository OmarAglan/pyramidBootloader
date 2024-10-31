org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A


start:
    jmp main
;
;Prints a String To The Screen
; parms:
;   - ds:si Points To String
puts:
    ;save the registers that we will use
    push si
    push ax

.loop:
    lodsb               ;Loads next chracter in al
    or al, al           ;check if the next character is null
    jz .done

    mov ah, 0x0e
    int 0x10

    jmp .loop
.done:
    pop ax
    pop si
    ret

main:
    ; setup data segments
    mov ax, 0           ; cant write to ds/es directly
    mov ds, ax
    mov es, ax

    ;setup stack
    mov ss, ax
    mov sp, 0x7C00

    ;print massage
    mov si, msg_hello
    call puts


    hlt

.halt:
    jmp .halt


msg_hello: db 'Hello World', ENDL, 0

times 510-($-$$) db 0
dw 0AA55H