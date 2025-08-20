[BITS 16]

%ifdef KERNEL_BUILD
%define GUI_MODE_ADDR gui_mode
%define GUI_PUTC_ADDR gui_putc
%endif

; Conditional console output: GUI or BIOS

printc:
%ifdef KERNEL_BUILD
	cmp byte [GUI_MODE_ADDR], 1
	jne printc_bios
	push ax
	call GUI_PUTC_ADDR
	pop ax
	ret
%endif

printc_bios:
	mov ah, 0x0e
	int 0x10
	ret

print:
	lodsb
	cmp al, 0
	je .end_print
	call printc
	jmp print
.end_print:
	mov al, 0x0D
	call printc
	mov al, 0x0A
	call printc
	ret

printl:
	lodsb
	cmp al, 0
	je .end_printl
	call printc
	jmp printl
.end_printl:
	ret