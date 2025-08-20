[BITS 16]

strcmp:
    push es
    push si
    push di

    mov ax, ds
    mov es, ax          ; ensure ES=DS for SCASB

.next:
    lodsb               ; AL <- [DS:SI], SI++
    scasb               ; compare AL with [ES:DI], DI++
    jne .fail
    cmp al, 0
    jne .next

    clc                 ; equal
    jmp .done
.fail:
    stc                 ; not equal
.done:
    pop di
    pop si
    pop es
    ret