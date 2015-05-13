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


check_head_position proc
    ; Проверить, что находится на желаемой для головы позиции,
    ; обработать
    ; Вход:     cx - x (в нашей сетке (80-2)x(40-2))
    ;           dx - y
    ; Результат:
    ;           CF=1, если не нужно стирать хвост (мы съели яблоко)

    ; Проверяем границы поля
        cmp     cx, 78
        jge     CHP_exit1
        cmp     dx, 38
        jge     CHP_exit1
        jmp     CHP_exit1_end
        CHP_exit1:
        mov     game_over, 1
        clc
        ret
        CHP_exit1_end:
    ; Проверяем символы
        mov     ah, 0Dh         ; Read Pixel
        xor     bh, bh
        push cx
        push dx
        inc     cx
        inc     dx
        shl     cx, 3           ; cx*8 (ширина ячейки)
        shl     dx, 3           ; аналогично
        add     dx, 15          ; отступ для текста и прочего
        ;add     cx, 8 коммент
        ;add     dx, 8 в пользу inc перед умножением на 8 (выше)
        int     10h
        pop dx
        pop cx

        cmp     al, color_food       ; Яблоко
        jne     CHP_food_end

    CHP_food:
        push    cx
        push    dx
        inc     score               ; Увеличим счёт

        ; Какашки
        inc     food_eaten
        cmp     food_eaten, 5
        jl      WC_not_now
        mov     food_eaten, 0
        mov     al, color_poo
        mov     dx, [snake+di-2]
        mov     cl, dh              ; cx - x
        xor     dh, dh              ; dx - y
        call    draw_snake_pixel
     WC_not_now:
     print_score:
        mov     ah, 02h         ; Курсор
        xor     bh, bh          ; в позицию 0,0
        xor     dx, dx
        mov     dl, str_score_len
        int     10h
        
        mov     ax, score
        call    print_int_3chars

        mov     al, color_food
        call    add_food
        pop     dx
        pop     cx
        stc
        ret
    CHP_food_end:
        cmp     al, color_speed_up       ; Speed-up
        jne     CHP_increase_speed_end
    CHP_increase_speed:
        xor     ah, ah                    ; 0->1, 1->2, ..., 7->7
        mov     al, speed_freq_x1000
        push dx
        inc speed_multiplier
        mul     speed_multiplier          ; Проверим, что желаемый делитель
        dec speed_multiplier            
        pop dx

        cmp     ax, 0Fh                   ; частоты не превзойдёт FFFFh
        jg      CHP_good                   ; pass_increasing

        inc     speed_multiplier
        inc     speed_multiplier
    CHP_increase_speed_end:
        cmp     al, color_speed_down     ; Speed-down
        jne     CHP_decrease_speed_end
    CHP_decrease_speed:
        cmp     speed_multiplier, 0      ; 7->6, 6->5, 0->0
        je      CHP_good                  ; pass_decreasing
        dec     speed_multiplier
        pusha

        mov     ah, speed_freq_x1000
        shl     ah, 4
        xor     al, al
        mul     speed_multiplier
        mov     bx, 0FFFFh
        sub     bx, ax
        call    reprogram_pit
        
        popa
        jmp     CHP_good
    CHP_decrease_speed_end:
        cmp     al, color_mushroom       ; Грибы
        jne     CHP_mushroom_end
    CHP_mushroom:
        mov     mushroom_ticks, 1
        call    mushroom_effect
        jmp     CHP_good
    CHP_mushroom_end:
        cmp     al, color_border         ; Стенка
        je      CHP_exit
        cmp     al, color_poo            ; Какашки
        je      CHP_exit
        cmp     al, color_snake          ; Змейка
        je      CHP_exit
        jmp     CHP_good
    CHP_exit:
        mov     game_over, 1
        jmp     CHP_good
    CHP_good:
        clc
        ret
check_head_position endp


draw_border         proc
    mov     ah, 0Ch         ; Draw Pixel
    mov     al, color_border         
    xor     bh, bh          ; Page 0
    mov     dx, 15          ; y coord

    mov     cx, 640*10 + 9   ; x coord = [10 строк](640*10) - 1 + [Для левой границы](10)
    DB_top:
        int     10h
        loop DB_top
    int     10h             ; Самый первый пиксель (Потому что cx=0 break)

    mov     dx, 350 - 15 - 10; y coord
    mov     cx, 640*10 - 1   ; x coord = [10 строк](640*10) - 1
    DB_bottom:
        int     10h
        loop    DB_bottom
    int     10h

    mov     dx, 15 + 10          ; y (15 + 10top)
    DB_left_right_y:
        mov     cx, 640 - 10
        DB_left_right_x:
            int     10h
            inc     cx
            cmp     cx, 640 + 10
            jl      DB_left_right_x

        inc     dx
        cmp     dx, 350 - 15 - 10
        jl      DB_left_right_y
    ret
draw_border         endp

