draw_border_generic proc
    mov     ah, 0Ch         ; Function Draw Pixel
    mov     al, color_border         
    xor     bh, bh          ; Page 0

    ; x coord
    push    ax
        mov     ax, 640     ; Ширина экрана
        mul     thickness   ; * толщину линии 
        add     ax, thickness; [Для левой границы](толщина)
        dec     ax          ; -1
        xchg    cx, ax
    pop     ax
    ; y coord
    mov     dx, 15          ; Припуск для счёта и прочего

    DB_top:
        int     10h
        loop DB_top
    int     10h             ; Самый первый пиксель (Потому что cx=0 break)


    ; x coord
    push    ax
        mov     ax, 640     ; Ширина экрана
        mul     thickness   ; * толщину линии 
        dec     ax          ; - 1
        xchg    cx, ax
    pop     ax
    ; y coord
    mov     dx, 350 - 15
    sub     dx, thickness

    DB_bottom:
        int     10h
        loop    DB_bottom
    int     10h


    mov     dx, 15
    add     dx, thickness

    DB_left_right_y:
        mov     cx, 640
        sub     cx, thickness
        DB_left_right_x:
            int     10h
            inc     cx
            push    ax
            mov     ax, 640
            add     ax, thickness
            cmp     cx, ax  ; 640 + thickness
            pop     ax
            jl      DB_left_right_x
        inc     dx
        push    ax
        mov     ax, 350 - 15
        sub     ax, thickness
        cmp     dx, ax
        pop     ax
        jl      DB_left_right_y

    ret
draw_border_generic endp

