[BITS 16]

; Commands parser
cmd:
    pusha
    call split_cmd
    mov bx, 0
.next:
    mov si, cmd_name
    mov di, [commands + bx]
    call strcmp
    jc .try_next

    call word [handlers + bx]
    popa
    ret
.try_next:
    add bx, 2
    cmp bx, cmd_end - commands
    jl .next

    mov si, not_found_msg
    call print
    popa
    ret

%include "os/string.asm"

help_msg: db "help - cls - exit - echo <message> - ufetch - gui - edit [filename] - run [filename]", 0
not_found_msg: db "Command not found.", 0
exit_msg: db "Good bye, have a good time.", 0

cmd_name: times 32  db 0
cmd_args: times 96  db 0

commands:
    dw help_str
    dw cls_str
    dw exit_str
    dw echo_str
    dw ufetch_str
    dw gui_str
    dw edit_str
    dw run_str
cmd_end:

handlers:
    dw help_handler
    dw clear_handler
    dw exit_handler
    dw echo_handler
    dw ufetch_handler
    dw gui_handler
    dw edit_handler
    dw run_handler

help_handler:
    mov si, help_msg
    call print
    ret

clear_handler:
    call clear
    ret

echo_handler:
    mov si, cmd_args
    call print
    ret

exit_handler:
    mov si, exit_msg
    call print
    cli
    hlt

ufetch_handler:
    ; Display ASCII art logo
    mov si, ufetch_logo1
    call print
    mov si, ufetch_logo2
    call print
    mov si, ufetch_logo3
    call print
    mov si, ufetch_logo4
    call print
    mov si, ufetch_logo5
    call print
    
    ; Display system info
    mov si, ufetch_os
    call print
    mov si, ufetch_kernel
    call print
    mov si, ufetch_arch
    call print
    mov si, ufetch_shell
    call print
    mov si, ufetch_memory
    call print
    ret

gui_handler:
    call start_gui
    ret

edit_handler:
    mov si, cmd_args
    call edit_file
    ret

run_handler:
    mov si, cmd_args
    call run_file
    ret

help_str: db "help", 0
cls_str: db "cls", 0
exit_str: db "exit", 0
echo_str: db "echo", 0
ufetch_str: db "ufetch", 0
gui_str: db "gui", 0
edit_str: db "edit", 0
run_str: db "run", 0

; ufetch ASCII art and system info
ufetch_logo1: db "    ____  _            ____  ____", 0
ufetch_logo2: db "   |  _ \\(_)_ __   ___/ __ \\/ ___|", 0
ufetch_logo3: db "   | |_) | | '_ \\ / _ \\ |  | \\___ \", 0
ufetch_logo4: db "   |  __/| | |_) |  __/ |__| |___) |", 0
ufetch_logo5: db "   |_|   |_| .__/ \\___|\\____/|____/", 0

ufetch_os: db "   OS: PipeOS 1.0", 0
ufetch_kernel: db "   Kernel: PipeOS Kernel", 0
ufetch_arch: db "   Architecture: x86 (16-bit)", 0
ufetch_shell: db "   Shell: PipeOS Shell", 0
ufetch_memory: db "   Memory: Real Mode (< 1MB)", 0

; Simple text editor implementation
edit_file:
    pusha
    
    ; Check if filename was provided
    cmp byte [si], 0
    je .no_filename
    
    ; Store filename for later use
    mov di, edit_filename
    call strcpy
    
    ; Display editor header
    mov si, edit_header
    call print
    
    ; Display filename
    mov si, edit_filename
    call print
    
    ; Display help
    mov si, edit_help
    call print
    
    ; Initialize editor state
    mov di, edit_buffer
    mov word [edit_pos], 0
    mov word [edit_line_count], 1
    
.main_loop:
    call getkey
    cmp al, 0
    je .main_loop
    
    ; Check for ESC key (exit)
    cmp al, 27
    je .exit_editor
    
    ; Check for Enter key
    cmp al, 13
    je .newline
    
    ; Check for Backspace
    cmp al, 8
    je .backspace
    
    ; Regular character
    call printc
    stosb
    inc word [edit_pos]
    jmp .main_loop
    
.newline:
    mov al, 13
    call printc
    mov al, 10
    call printc
    mov byte [di], 13
    inc di
    mov byte [di], 10
    inc di
    inc word [edit_line_count]
    add word [edit_pos], 2
    jmp .main_loop
    
.backspace:
    cmp word [edit_pos], 0
    je .main_loop
    
    ; Move cursor back and erase character
    mov ah, 0x0E
    mov al, 8
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 8
    int 0x10
    
    ; Adjust buffer position
    dec di
    dec word [edit_pos]
    jmp .main_loop
    
.exit_editor:
    ; Null terminate the buffer
    mov byte [di], 0
    
    ; Save file
    call save_file
    
    popa
    ret

.no_filename:
    mov si, edit_no_file
    call print
    popa
    ret

; Save file function
save_file:
    pusha
    
    ; For now, just display a message
    ; In a real implementation, this would write to disk
    mov si, edit_saved
    call print
    
    popa
    ret

; Run file function
run_file:
    pusha
    
    ; Check if filename was provided
    cmp byte [si], 0
    je .no_filename_run
    
    ; Display execution message
    mov si, run_msg
    call print
    
    ; Display filename
    call print
    
    ; In a real implementation, this would load and execute the file
    mov si, run_success
    call print
    
    popa
    ret
    
.no_filename_run:
    mov si, run_no_file
    call print
    popa
    ret

split_cmd:
    pusha

    ; Ensure ES=DS for stosb operations
    push ds
    pop es

    ; clear cmd_name (32 bytes)
    mov cx, 32
    mov di, cmd_name
    xor al, al
    rep stosb

    ; clear cmd_args (96 bytes)
    mov cx, 96
    mov di, cmd_args
    xor al, al
    rep stosb

    ; copy name until space or null
    mov si, cmd_buffer
    mov di, cmd_name
.copy_name:
    lodsb
    cmp al, 0
    je .done
    cmp al, ' '
    je .copy_args
    stosb
    jmp .copy_name
.copy_args:
    mov byte [di], 0
    mov di, cmd_args
.copy_args_loop:
    lodsb
    stosb
    cmp al, 0
    jne .copy_args_loop
.done:
    popa
    ret

; Editor data
edit_buffer: times 512 db 0
edit_filename: times 32 db 0
edit_pos: dw 0
edit_line_count: dw 0

edit_header: db "PipeOS Text Editor - Editing: ", 0
edit_help: db 13, 10, "Press ESC to save and exit", 13, 10, 13, 10, 0
edit_no_file: db "Error: No filename specified", 13, 10, 0
edit_saved: db 13, 10, "File saved successfully", 13, 10, 0

; Run data
run_msg: db "Executing file: ", 0
run_success: db "Execution completed successfully", 13, 10, 0
run_no_file: db "Error: No filename specified", 13, 10, 0