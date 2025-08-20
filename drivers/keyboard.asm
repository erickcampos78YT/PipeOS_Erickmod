[BITS 16]

getkey:
    xor ah, ah
    int 0x16            ; BIOS keyboard
    cmp al, 0           ; extended key?
    je getkey           ; skip extended (we need ASCII)
    ret