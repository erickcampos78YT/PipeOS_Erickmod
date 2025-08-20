[BITS 16]

; Simple VGA graphics mode 13h

; video mode 13h (320x200x256)
set_video_mode_13h:
    mov ax, 0x0013
    int 0x10
    ret

; text mode 03h (80x25)
set_video_mode_03h:
    mov ax, 0x0003
    int 0x10
    ret

;VGA memory access
putpixel:
    push ax
    push dx
    push di
    push es
    
    ; Set ES to VGA segment
    push ax
    mov ax, 0xA000
    mov es, ax
    pop ax
    
    ; Calculate offset: DI = y * 320 + x
    mov di, cx      ; DI = y
    shl di, 6       ; DI = y * 64
    mov dx, cx      ; DX = y
    shl dx, 8       ; DX = y * 256  
    add di, dx      ; DI = y * 320
    add di, bx      ; DI = y * 320 + x
    
    ; Set pixel
    mov [es:di], al
    
    pop es
    pop di
    pop dx
    pop ax
    ret

; Desenha uma linha (bx, cx) a (dx, si)
draw_line:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Calcula dx and dy
    mov di, dx      ; di = x1
    sub di, bx      ; di = dx
    mov dx, di      ; dx = dx
    
    mov di, si      ; di = y1
    sub di, cx      ; di = dy
    mov si, di      ; si = dy
    
    ; Handle negative dx or dy
    mov di, 0
    cmp dx, di
    jge .dx_positive
    neg dx
    mov di, 1      
.dx_positive:
    
    mov di, 0
    cmp si, di
    jge .dy_positive
    neg si
    mov di, 1       ; flag for negative dy
.dy_positive:
    
    cmp dx, si
    jge .line_x_dominant
    jmp .line_y_dominant
    
.line_x_dominant:
    mov di, dx      ; di = error
    shr di, 1
    
.x_loop:
    call putpixel
    
    cmp bx, dx      ; Compare current x with end x
    je .line_done
    
    add bx, 1       ; x++
    
    sub di, si      ; error -= dy
    cmp di, 0
    jge .x_loop
    
    add cx, 1       ; y++
    add di, dx      ; error += dx
    jmp .x_loop
    
.line_y_dominant:
    mov di, si      ; di = error
    shr di, 1
    
.y_loop:
    call putpixel
    
    cmp cx, si      ; Compare current y with end y
    je .line_done
    
    add cx, 1       ; y++
    
    sub di, dx      ; error -= dx
    cmp di, 0
    jge .y_loop
    
    add bx, 1       ; x++
    add di, si      ; error += dy
    jmp .y_loop
    
.line_done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Fill rectangle: BX=x, CX=y, DX=width, SI=height, AL=color
fill_rect:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    mov di, si      ; DI = height counter
    
.row_loop:
    push bx         ; Save start X
    push dx         ; Save width
    
    mov si, dx      ; SI = width counter
.col_loop:
    call putpixel   ; Draw pixel at (BX, CX)
    inc bx          ; Next X
    dec si          ; Decrease width counter
    jnz .col_loop   ; Continue if width > 0
    
    pop dx          ; Restore width
    pop bx          ; Restore start X
    inc cx          ; Next Y
    dec di          ; Decrease height counter
    jnz .row_loop   ; Continue if height > 0
    
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Clear screen with color AL
clear_screen:
    push ax
    push bx
    push cx
    push dx
    push si
    
    mov bx, 0       ; x = 0
    mov cx, 0       ; y = 0
    mov dx, 320     ; width = 320
    mov si, 200     ; height = 200
    call fill_rect
    
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; experimento 
draw_window:
    push ax
    
    ; Window background (gray)
    mov al, 0x07
    call fill_rect
    
    ; Title bar (blue)
    push dx
    push si
    mov dx, dx      ; Keep width
    mov si, 16      ; Height = 16
    mov al, 0x01    ; Blue
    call fill_rect
    pop si
    pop dx
    
    ; Border (white)
    push bx
    push cx
    push dx
    push si
    
    ; Top border
    mov al, 0x0F
    mov si, 1
    call fill_rect
    
    ; Bottom border  
    pop si          ; Restore height
    push si
    add cx, si      ; Y = Y + height - 1
    dec cx
    mov si, 1
    call fill_rect
    
    pop si
    pop dx
    pop cx
    pop bx
    
    ; Left border
    push dx
    push si
    mov dx, 1
    mov al, 0x0F
    call fill_rect
    pop si
    pop dx
    
    ; Right border
    add bx, dx      ; X = X + width - 1
    dec bx
    mov dx, 1
    mov al, 0x0F
    call fill_rect
    
    pop ax
    ret

draw_char:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Draw a simple rectangle for character
    mov al, 0x0F    ; White character
    mov dx, 8       ; Character width
    mov si, 12      ; Character height
    call fill_rect
    
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Draw string at position BX=x, CX=y
draw_string:
    push ax
    push bx
    push cx
    push si
    
.string_loop:
    lodsb
    cmp al, 0
    je .string_done
    
    call draw_char
    add bx, 10      ; Move to next character position
    jmp .string_loop
    
.string_done:
    pop si
    pop cx
    pop bx
    pop ax
    ret

mouse_init:
    push ax
    
    ; Test mouse position
    mov word [mouse_x], 160
    mov word [mouse_y], 100
    mov byte [mouse_buttons], 0
    
    ; Try to enable PS/2 mouse
    mov al, 0xA8        
    out 0x64, al
    
    pop ax
    ret

mouse_poll:
    push ax
    
    ; Checka se a Data esta disponivel
    in al, 0x64
    test al, 0x01
    jz .no_data
    
    ; Read data (
    in al, 0x60
    
.no_data:
    pop ax
    ret

start_gui:
    ; Save all registers
    pusha
    push es
    push ds
    
    ; Set graphics mode
    call set_video_mode_13h
    call mouse_init
    
    ; Set GUI mode flag
    mov byte [gui_mode], 1
    
    ; Initialize window position
    mov word [win_x], 50
    mov word [win_y], 40
    mov word [win_w], 200
    mov word [win_h], 100
    
    ; Initialize animation variables
    mov word [anim_counter], 0
    
.main_loop:
    ; Clear screen to blue
    mov al, 0x09    ; Light blue
    call clear_screen
    
    ; Draw animated background elements
    call draw_background
    
    ; Draw taskbar at bottom
    mov bx, 0       ; x = 0
    mov cx, 180     ; y = 180
    mov dx, 320     ; width = 320
    mov si, 20      ; height = 20
    mov al, 0x08    ; Dark gray
    call fill_rect
    
    ; Draw main window
    mov bx, [win_x]
    mov cx, [win_y]
    mov dx, [win_w]
    mov si, [win_h]
    call draw_window
    
    ; Draw window title
    mov bx, [win_x]
    add bx, 8
    mov cx, [win_y]
    add cx, 4
    mov si, window_title
    call draw_string
    
    ; Draw window content area (black)
    mov bx, [win_x]
    add bx, 4
    mov cx, [win_y]
    add cx, 20      ; Below title bar
    mov dx, [win_w]
    sub dx, 8       ; Account for borders
    mov si, [win_h]
    sub si, 24      ; Account for title and borders
    mov al, 0x00    ; Black
    call fill_rect
    
    ; Draw sample content in window
    mov bx, [win_x]
    add bx, 10
    mov cx, [win_y]
    add cx, 30
    mov si, sample_text
    call draw_string
    
    ; Draw animated element
    call draw_animated_element
    
    ; Draw mouse cursor
    mov bx, [mouse_x]
    mov cx, [mouse_y]
    mov al, 0x0F    ; White
    call putpixel
    
    ; Add a second pixel for better visibility
    inc bx
    call putpixel
    dec bx
    inc cx
    call putpixel
    
    ; Add third pixel
    inc bx
    inc cx
    call putpixel
    
    ; Poll input
    call mouse_poll
    
    ; Check for keyboard input
    mov ah, 0x01
    int 0x16
    jz .no_key
    
    ; Get key
    mov ah, 0x00
    int 0x16
    
    ; ESC to exit
    cmp al, 27
    je .exit
    
    ; Arrow keys for testing (move cursor)
    cmp ah, 0x48    ; Up arrow
    jne .not_up
    cmp word [mouse_y], 0
    je .no_key
    dec word [mouse_y]
    jmp .no_key
.not_up:
    
    cmp ah, 0x50    ; Down arrow (seta para baixo)
    jne .not_down
    cmp word [mouse_y], 199
    je .no_key
    inc word [mouse_y]
    jmp .no_key
.not_down:
    
    cmp ah, 0x4B    ; Left arrow(a;_;)
    jne .not_left
    cmp word [mouse_x], 0
    je .no_key
    dec word [mouse_x]
    jmp .no_key
.not_left:
    
    cmp ah, 0x4D    
    jne .no_key
    cmp word [mouse_x], 319
    je .no_key
    inc word [mouse_x]
    
.no_key:
    ; Update animation counter
    inc word [anim_counter]
    
    mov cx, 0x01
    mov dx, 0x0000
    mov ah, 0x86
    int 0x15
    
    jmp .main_loop
    
.exit:
    ; Return to text mode
    call set_video_mode_03h
    mov byte [gui_mode], 0
    
    ; Show exit message
    mov si, gui_exit_msg
    call print
    
    ; Restore registers
    pop ds
    pop es
    popa
    ret

; Draw animated background elements
draw_background:
    push ax
    push bx
    push cx
    push dx
    push si

    mov bx, 50
    mov cx, 30
    mov al, 0x0F    ; White
    call putpixel
    
    mov bx, 100
    mov cx, 70
    mov al, 0x0F    ; White
    call putpixel
    
    mov bx, 250
    mov cx, 40
    mov al, 0x0F    ; White
    call putpixel
    
    mov ax, [anim_counter]
    and ax, 0x000F  ; Modulo 16
    mov bx, 150
    add bx, ax      ; Moving x position
    mov cx, 50
    mov al, 0x0E    ; Yellow
    call putpixel
    
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Draw animated
draw_animated_element:
    push ax
    push bx
    push cx
    push dx
    push si
    
    ; Draw a moving rectangle
    mov ax, [anim_counter]
    and ax, 0x001F  ; Modulo 32
    mov bx, 60
    add bx, ax      ; Moving x position
    mov cx, 140
    mov dx, 20
    mov si, 10
    mov al, 0x0C    ; Light red
    call fill_rect
    
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Data section
gui_mode: db 0
mouse_x: dw 160
mouse_y: dw 100
mouse_buttons: db 0

; Animation variables
anim_counter: dw 0

; Window properties
win_x: dw 50
win_y: dw 40
win_w: dw 200
win_h: dw 100 

; Text strings
window_title: db "PipeOS GUI", 0
sample_text: db "test text", 0

; Messages
gui_exit_msg: db "GUI mode exited. Use arrow keys to move cursor, ESC to exit.", 0

; Dummy functions to maintain compatibility
gui_putc:
    ret

gui_term_clear:
    ret