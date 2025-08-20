[BITS 16]
[org 0x1000]

start:
	cld                      ; ensure forward string ops
	xor ax, ax
	mov ds, ax               ; DS = 0 (kernel segment)
	mov es, ax               ; ES = 0 (text writes until changed)
	call clear               ; Limpa a tela
	mov si, msg
	call print               ; Mostra mensagem de boas-vindas

	mov si, prompt
	call printl              ; Mostra o prompt inicial ">"

	; Ensure ES=DS for STOSB writes into cmd_buffer
	push ds
	pop es
	mov di, cmd_buffer       ; DI aponta para onde o input será armazenado

	jmp input

input:
	call getkey               ; Lê tecla (AL=ASCII, AH=scancode)
	cmp al, 0                 ; Tecla estendida?
	je input                  ; Ignora estendidas
	call printc               ; Ecoa caractere

	cmp al, 0x0D              ; Enter (CR)?
	je .cmd
	cmp al, 0x0A              ; Enter (LF)?
	je .cmd

	cmp al, 0x08              ; Backspace?
	je .back

	stosb                     ; Salva caractere no buffer (ES:DI)
	jmp input

.cmd:
	mov al, 0
	stosb                     ; Finaliza string com null

	call breakline
	mov si, cmd_buffer
	call cmd                  ; Processa comando digitado

	; Reset ES and DI for next input
	push ds
	pop es
	mov di, cmd_buffer
	mov si, prompt
	call printl               ; Mostra o prompt novamente
	jmp input
.back:
	cmp di, cmd_buffer
	je .skip_bs
	dec di
	mov ah, 0x0E
	mov al, ' '
	int 0x10
	mov al, 0x08
	int 0x10
.skip_bs:
	jmp input

msg: db "Welcome to PipeOS 1.0", 0
prompt: db ">", 0

%define KERNEL_BUILD 1
%include "drivers/stdio.asm"
%include "drivers/keyboard.asm"
%include "drivers/display.asm"
%include "drivers/graphics.asm"
%include "os/cmd.asm"

cmd_buffer: times 128 db 0     ; Buffer para armazenar input do usuário