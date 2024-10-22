org 0x7C00
bits 16


main:
    ; setup data segments
    mov ax, 0           ; cant write to ds/es directly
    hlt

.halt:
    jmp .halt


times 510-($-$$) db 0
dw 0AA55H