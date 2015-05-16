.186
.model tiny
.code
ORG 100h
@entry:             jmp @start
game_over           db  0
score               dw  0
snake               dw  100h  dup('?')
direction           dw  0100h         ; xx;yy
str_resume          db  'PAUSE (Space - Resume game)','$'
str_gameover        db  '[F2 - New game] GAME OVER. Your score ','$'
str_help_game       db  'Score ___ | Space - menu | Esc - exit','$'
RND_const           dw  8405h         ; multiplier value
RND_seed1           dw  ?
RND_seed2           dw  ?             ; random number seeds
random              dw  ?
old_1Ch             dw  ?, ?
ticks               dw  0
videomode           db  ?
videopage           db  ?

catch_1Ch:
    inc     ticks
    iret

randgen             proc
    pusha
        push    ax
        mov     ax, RND_seed1
        mov     bx, RND_seed2;load seeds
        mov     cx, ax      ; save seed
        mul     RND_const
        shl     cx, 3
        add     ch, cl
        add     dx, cx
        add     dx, bx
        shl     bx, 2       ; begin scramble algorithm
        add     dx, bx
        add     dh, bl
        mov     cl, 5
        shl     bx, cl
        add     ax, 1
        adc     dx, 0
        mov     RND_seed1, ax
        mov     RND_seed2, dx ;save results as the new seeds
        pop     bx          ; get back range value
        xor     ax, ax
        xchg    ax, dx      ; adjust ordering
        div     bx ;ax = trunc((dx,ax) / bx), dx = (r)
        xchg    ax, dx      ; return remainder as the random number
    mov     random, ax
    popa
    ret
randgen             endp

print_score           proc
    pusha
    mov     ax, score
    PiVM_next:
        mov     bx, 10
        mov     cx, 3
        int9_bite_off:
            xor     dx, dx
            div     bx          ; ax = ax / 10
            push    dx          ; dx = ax % 10
        loop    int9_bite_off
        mov     ah, 02h
        mov     cx, 3
        int9_print_digit:
            pop     dx
            add     dl, '0'
            int     21h
        loop    int9_print_digit
    popa
    ret
print_score           endp

convert_to_screen   proc
    inc     cx
    inc     dx
    shl     cx, 3
    shl     dx, 3
    add     dx, 15      ; отступ для текста и прочего
    ret
convert_to_screen   endp

draw_snake_pixel    proc
    pusha
        mov     ah, 0Ch         ; write pixel
        xor     bh, bh    
        call    convert_to_screen
        mov     si, 7       ; Цикл по x
        DSP_x:
            add     cx, si
            mov     di, 7       ; Цикл по y
            DSP_y:
                add     dx, di
                int 10h
                sub     dx, di
                dec     di
                test    di, di
                jns     DSP_y   ; di >= 0
            sub     cx, si
            dec     si
            test    si, si
            jns     DSP_x   ; si >= 0
    popa
    ret
draw_snake_pixel    endp

new_food            proc
    pusha
        mov     ax, 80-2        
        call    randgen         
        mov     cx, random
        mov     ax, 40-2         
        call    randgen         
        mov     dx, random          
        push    cx
        push    dx
            mov     ah, 0Dh         ; Read Pixel
            xor     bh, bh          ; Page 0
            call    convert_to_screen
            int     10h         ; Преобразовываем координаты в экранные и спрашиваем цвет пикселя
        pop     dx
        pop     cx
        cmp     al, 02h;color_food     
        je      AF_collision
        cmp     al, 0Eh;color_snake     
        je      AF_collision  
        mov     al, 02h;color_food
        call    draw_snake_pixel
        popa
        ret
    AF_collision:
        popa
        jmp     new_food
new_food            endp

check_head_position proc
    ;           CF=1, если не нужно стирать хвост (мы съели яблоко)
        cmp     cx, 80-2
        jge     CHP_exit
        cmp     dx, 40-2
        jge     CHP_exit
        push    cx
        push    dx
            mov     ah, 0Dh         ; Read Pixel
            xor     bh, bh
            call    convert_to_screen
            int     10h
        pop     dx
        pop     cx
        cmp     al, 02h;color_food           ; Яблоко
        je      CHP_food
        cmp     al, 0Eh;color_snake          ; Змейка
        je      CHP_exit
        jmp     CHP_good
    CHP_exit:
        mov     game_over, 1
    CHP_good:
        clc
        ret
    CHP_food:
        pusha
        inc     score               ; Увеличим счёт
        mov     ah, 02h         ; Курсор
        mov     dx, 0006h
        int     10h
        call    print_score
        call    new_food
        popa
        stc
        ret
check_head_position endp

handle_keyboard     proc
    ; Результат: direction = 0, если нужно делать ret из игры (было наажтие Esc)
        pusha
            mov     ax, 0100h
            int     16h
            jnz     KP_check           ; Без нажатия выходим
            popa
            ret
        KP_check:
            mov     cx, direction
            xor     ah, ah
            int     16h
            cmp     ah, 50h
            je      KP_down
            cmp     ah, 48h
            je      KP_up
            cmp     ah, 4Bh
            je      KP_left
            cmp     ah, 4Dh
            je      KP_right
            cmp     ah, 39h          ; Если это нажатие клавиши Space
            je      KP_pause         ; пауза
            cmp     ah, 1h           ; Если это нажатие клавиши Esc
            je      KP_exit          ; выход
            jmp     KP_end
         KP_pause:
            mov     ah, 02h    
            mov     dx, 1800h
            int     10h
            mov     ah, 09h         
            lea     dx, str_resume
            int     21h
            mov     ax, 0100h
            int     16h
            jz      KP_pause          ; Без нажатия - ждём
            xor     ah, ah
            int     16h
            cmp     ah, 1h           ; Если это нажатие клавиши Esc
            je      KP_exit          ; выход
            cmp     ah, 39h          ; Если это не пробел
            jne     KP_pause         ; ждём дальше
            mov     ah, 02h  ; Установить курсор
            mov     dx, 1800h; dh y, dl x
            int     10h
            push    cx
            mov     ah, 09h  ; писать символ
            mov     cx, 80   ; Сколько раз
            int     10h
            pop     cx
            jmp     KP_end
         KP_down:
            cmp     cx, 0FFFFh      ; Сравниваем чтобы не пойти на себя
            je      KP_end
            mov     cx, 0001h       ; Вниз => x 0, y 1
            jmp     KP_end
         KP_up:
            cmp     cx, 0001h
            je      KP_end
            mov     cx, 0FFFFh      ; Вверх => x 0, y -1
            jmp     KP_end
         KP_left:
            cmp     cx, 0100h
            je      KP_end
            mov     cx, 0FF00h      ; Влево => x -1, y 0
            jmp     KP_end
         KP_right:
            cmp     cx, 0FF00h
            je      KP_end
            mov     cx, 0100h       ; Вправо => x 1, y 0
            jmp     KP_end
        KP_exit:
            xor     cx, cx
        KP_end:
            mov     direction, cx
        popa
        ret
handle_keyboard     endp

game             proc
    game_init:
        xor     bh, bh
        mov     ax, 0010h
        int     10h
        mov     game_over, 0
        mov     score, 0
        mov     [snake+0], 0110h
        mov     [snake+2], 0210h
        mov     si, 2
        xor     di, di          ; Индекс координаты символа хвоста
        mov     direction, 0100h; direction для управления головой
        mov     al, 02h;color_food
        call    new_food
        mov     ah, 02h         
        xor     dx, dx
        int     10h
        mov     ah, 09h
        lea     dx, str_help_game
        int     21h
        mov     ah, 02h         
        mov     dx, 6
        int     10h
        call    print_score
            mov     ah, 0Ch         ; Draw Pixel
            mov     al, 07h;color_border
            mov     dx, 15          ; y coord
            mov     cx, 640*8 + 7   ; x coord = [8 строк](640*8) - 1 + [Для левой границы](8)
            DB_top:
                int     10h
                loop DB_top
            int     10h             ; Самый первый пиксель (Потому что cx=0 break)
            mov     dx, 350 - 15 - 8; y coord
            mov     cx, 640*8 - 1   ; x coord = [8 строк](640*8) - 1
            DB_bottom:
                int     10h
                loop    DB_bottom
            int     10h
            mov     dx, 15 + 8          ; y (15 + 8top)
            DB_left_right_y:
                mov     cx, 640 - 8
                DB_left_right_x:
                    int     10h
                    inc     cx
                    cmp     cx, 640 + 8
                    jl      DB_left_right_x
                inc     dx
                cmp     dx, 350 - 15 - 8
                jl      DB_left_right_y
        mov     al, 0Eh;color_snake
        mov     cx, 2
        mov     dx, 10h
        draw_snake_loop:
            call    draw_snake_pixel
            loop    draw_snake_loop
    game_main:
        cmp     ticks, 2
        jl      game_main
        mov     ticks, 0
        call    handle_keyboard
        cmp     direction, 0
        jne     change_head
        ret
    change_head:
        mov     dx, [snake+si]      ;Берем координату головы из памяти
        add     dx, direction       ;Изменяем координаты в зависимости от направления
        add     si, 2
        and     si, 0FFh
        mov     [snake+si], dx      ;Заносим в память новую координату головы змеи
        xor     cx, cx
        mov     cl, dh              ; cx - x
        xor     dh, dh              ; dx - y
        call    check_head_position ; Проверки на столкновения со стенами, собой, какахой
        pushf
            cmp     game_over, 1
            jne     draw_head
            popf
            ret
            draw_head:
            ; Когда позиция проверена, можно нарисовать там голову        
            mov     al, 0Eh;color_snake
            call    draw_snake_pixel
        popf
        ; Стоит ли стирать хвост?
        jnc     erase_tail
        jmp     game_main
    erase_tail:
        mov     dx, [snake+di]   ; коорд хвоста
        mov     al, 0
        xor     cx, cx
        mov     cl, dh
        xor     dh, dh
        call    draw_snake_pixel
        inc     di
        inc     di
        and     di, 0FFh
        jmp     game_main
game             endp

@start:
    mov     ax, 351Ch
    int     21h
    mov     [old_1Ch],  bx
    mov     [old_1Ch+2],es
    mov     ax, 251Ch
    mov     dx, offset catch_1Ch
    int     21h
    xor     ah, ah              ; Установим текущее значение системного таймера как начальный
    int     1Ah                 ; seed для псевдо-рандома                
    mov     RND_seed1, dx
    mov     ah, 0Fh             ; Сохраним начальные видео-режим
    int     10h                 ; и отображаемую страницу
    mov     videomode, al
    mov     videopage, bh
    new_game:
        call    game
        cmp     game_over, 0
        je      terminate_program
        mov     ah, 02h         
        mov     dx, 1800h
        int     10h
        mov     ah, 09h
        lea     dx, str_gameover
        int     21h
        call    print_score
    game_over_loop:
        mov     ax, 0100h
        int     16h
        jz      game_over_loop  ; Без нажатия - ждём
        xor     ah, ah
        int     16h
        cmp     ah, 1h          ; Esc - выход
        je      terminate_program
        cmp     ah, 3Ch         ; Клавиша F2
        je      new_game
        jmp     game_over_loop
    terminate_program:
        mov     ax, 0010h
        int     10h
        xor     ah, ah
        mov     al, videomode
        int     10h
        mov     ah, 05h
        mov     al, videopage
        int     10h
        mov     ax, 251Ch
        lds     dx, dword ptr cs:[old_1Ch]
        int     21h
    ret
end     @entry