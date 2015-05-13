.186
.model tiny
.code
ORG 100h

@entry:     jmp   @start

; Переменные
game_in_progress    db  0
game_over           db  0
score               dw  2
snake               dw  100h  dup('?')
food_eaten          dw  0             ; Счетчик съеденных
direction           dw  0100h         ; xx;yy
; Константы-цвета
color_poo           db  06h
color_food          db  0Ch
color_snake         db  02h
color_border        db  07h 
; Строки вместе с длинами
str_game            db  'F2 - New game','$'
str_game_len        db  $-str_game
str_exit            db  'Esc - Exit','$'
str_exit_len        db  $-str_exit
str_resume1         db  '___ PAUSE ___','$'
str_resume1_len     db  $-str_resume1
str_resume2         db  'Space - Resume game','$'
str_resume2_len     db  $-str_resume2
str_gameover1       db  '___ GAME OVER ___','$'
str_gameover1_len   db  $-str_gameover1
str_gameover2       db  'Your score ','$'
str_gameover2_len   db  $-str_gameover2
str_tutor_game      db  'Score ___                       ',25,' Apple   ',25,' Poo                   | Space - menu','$'
; Переменные для псевдо-рандома
RND_const           dw  8405h         ; multiplier value
RND_seed1           dw  ?
RND_seed2           dw  ?             ; random number seeds
; Переменные для обработчика прерывания 1Ch
old_1Ch             dw      ?, ?
ticks               dw      0
; Переменные для исходного видео-режима
original_videomode  db  ?
original_videopage  db  ?

; Утилиты
catch_1Ch:
    add     ticks, 1
    iret

randgen             proc
    ; ax = Конец диапазона [0...ax]
        or      ax, ax      ; range value != 0
        jz      RND_end
        push bx
        push cx
        push dx
        push ds

        push    ax
        ;push    cs
        ;pop     ds
        mov     ax, RND_seed1
        mov     bx, RND_seed2;load seeds
        mov     cx, ax      ; save seed
        mul     RND_const
        shl     cx, 1
        shl     cx, 1
        shl     cx, 1
        add     ch, cl
        add     dx, cx
        add     dx, bx
        shl     bx, 1       ; begin scramble algorithm
        shl     bx, 1
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
        pop ds
        pop dx
        pop cx
        pop bx
    RND_end:
        ret
randgen             endp

print_int           proc
    ; Печатать три последние цифры десятичного представления числа
    ; Вход: ax - число
    pusha
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
print_int           endp

; Графика
convert_to_screen   proc
    ; cx,dx воображаемые в cx,dx экранные
    push    ax
        mov     ax, 10
        inc     cx
        xchg    ax, cx       ; cx = cx*10 (ширина ячейки)
        mul     cl
        xchg    ax, cx

        inc     dx
        xchg    ax, dx
        mul     dl          ; аналогично dx
        xchg    ax, dx
        add     dx, 15      ; отступ для текста и прочего
        ;add     cx, 10      ; ширина бордера
        ;add     dx, 10      ; коммент в пользу inc в начале
    pop     ax
    ret
convert_to_screen   endp

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

draw_snake_pixel    proc
    ; Вход: cx - x воображаемая координата
    ;       dx - y воображаемая координата
    ;       al - цвет
    pusha
        mov     ah, 0Ch         ; write pixel
        xor     bh, bh    
        call    convert_to_screen

        mov     si, 9       ; Цикл по x
        DSP_x:
            add     cx, si
            mov     di, 9       ; Цикл по y
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

; Логика
add_food            proc
    ; Нарисовать на произвольном незанятом месте поля еду
    push ax
        mov     ax, 64-2        ; Псевдо-рандомное число
        call    randgen         ; от 0 до 62
        mov     cx, ax          ; Запись координаты x
 
        mov     ax, 32-2        ; 
        call    randgen         ; от 0 до 30
        mov     dx, ax          ; Запись координаты y

        ; Проверяем пустое ли место
        push    cx
        push    dx
            mov     ah, 0Dh         ; Read Pixel
            xor     bh, bh          ; Page 0
            call    convert_to_screen
            int     10h         ; Преобразовываем координаты в экранные и спрашиваем цвет пикселя
        pop     dx
        pop     cx

        cmp     al, color_poo     ; Кака
        je      AF_collision
        cmp     al, color_food     ; Яблочко
        je      AF_collision
        cmp     al, color_snake     ; Сама змея
        je      AF_collision
        cmp     al, color_border     ; Стенка
        je      AF_collision      ;Если занято, повторяем

    pop ax
        mov     al, color_food
        call    draw_snake_pixel
        ret
    AF_collision:
        popa
        jmp     add_food
add_food            endp

check_head_position proc
    ; Проверить, что находится на желаемой для головы позиции,
    ; обработать
    ; Вход:     cx - x (в нашей сетке (80-2)x(40-2))
    ;           dx - y
    ; Результат:
    ;           CF=1, если не нужно стирать хвост (мы съели яблоко)

    ; Проверяем границы поля
        cmp     cx, 64-2
        jge     CHP_exit
        cmp     dx, 32-2
        jge     CHP_exit
    ; Проверяем символы
        push    cx
        push    dx
            mov     ah, 0Dh         ; Read Pixel
            xor     bh, bh
            call    convert_to_screen
            int     10h
        pop     dx
        pop     cx
        
        cmp     al, color_food           ; Яблоко
        je      CHP_food
        cmp     al, color_border         ; Стенка
        je      CHP_exit
        cmp     al, color_poo            ; Какашки
        je      CHP_exit
        cmp     al, color_snake          ; Змейка
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
        ;xor     bh, bh         ; в позицию 0,6
        mov     dx, 6
        int     10h
        mov     ax, score
        sub     ax, 2
        call    print_int

        call    add_food
        popa
        stc
        ret
check_head_position endp

terminate_program   proc
    ; Завершение работы программы
        mov     ah, 00h
        mov     al, 10h
        int     10h
        ; Восстанавливаем видео-режим
        mov     ah, 00h
        mov     al, original_videomode
        int     10h
        mov     ah, 05h
        mov     al, original_videopage
        int     10h
        ; Восстанавливаем вектор 1Ch
        mov     ax, 251Ch
        mov     dx, word ptr cs:[old_1Ch]
        push    ds
        mov     ds, word ptr cs:[old_1Ch+2]
        cli
            int     21h
        sti
        mov     ax, 4c00h
        int     21h
        ret
terminate_program   endp

menu                proc
    menu_draw:

        mov     bh, 1           ; Номер отображаемой страницы (далее всюду)
        mov     ah, 05h         ; Сменить на страницу #1
        mov     al, bh
        int     10h

        ; Очистка экрана
        mov     ah, 02h
        mov     bx, 0100h          ; номер страницы
        mov     dx, 0000h           ; x, y
        int     10h
        mov     ah, 09h              ; писать символ
        mov     al, ' '
        mov     cx, 80*25
        int     10h

        ; Новая игра (F2)
        mov     ah, 02h         ; Курсор
        ;mov    bh, 1           ; в позицию dl,dh
        mov     dl, str_game_len ; Вычтем
        shr     dl, 1           ; половину длины строки
        neg     dl              ; из
        add     dl, 40          ; середины экрана
        mov     dh, 5
        int     10h
        mov     ah, 09h         ; Строка Новая игра
        lea     dx, str_game
        int     21h

        ; Выход (Esc)
        mov     ah, 02h         ; Курсор
        ;mov    bh, 1            ; в позицию dl,dh
        mov     dl, str_exit_len ; Вычтем
        shr     dl, 1           ; половину длины строки
        neg     dl              ; из
        add     dl, 40          ; середины экрана
        mov     dh, 7
        int     10h
        mov     ah, 09h         ; Строка Выход
        lea     dx, str_exit
        int     21h

        cmp     game_over, 0
        je      draw_pause_msg
        ; GAME OVER
        mov     ah, 02h         ; Курсор
        ;mov    bh, 1            ; в позицию dl,dh
        mov     dl, str_gameover1_len ; Вычтем
        shr     dl, 1           ; половину длины строки
        neg     dl              ; из
        add     dl, 40          ; середины экрана
        mov     dh, 16
        int     10h
        mov     ah, 09h         ; Строка
        lea     dx, str_gameover1
        int     21h

        mov     ah, 02h         ; Курсор
        ;mov    bh, 1            ; в позицию dl,dh
        mov     dl, str_gameover2_len ; Вычтем
        shr     dl, 1           ; половину длины строки
        neg     dl              ; из
        add     dl, 40-2          ; середины экрана
        mov     dh, 18
        int     10h
        mov     ah, 09h         ; Строка
        lea     dx, str_gameover2
        int     21h
        mov     ax, score
        sub     ax, 2
        call    print_int
        mov     game_over, 0
        jmp     menu_loop

     draw_pause_msg:
        cmp     game_in_progress, 0
        je      menu_loop
        ; Восстановить игру (Esc)
        mov     ah, 02h         ; Курсор
        ;mov    bh, 1            ; в позицию dl,dh
        mov     dl, str_resume1_len ; Вычтем
        shr     dl, 1           ; половину длины строки
        neg     dl              ; из
        add     dl, 40          ; середины экрана
        mov     dh, 16
        int     10h
        mov     ah, 09h         ; Строка
        lea     dx, str_resume1
        int     21h

        mov     ah, 02h         ; Курсор
        ;mov    bh, 1            ; в позицию dl,dh
        mov     dl, str_resume2_len ; Вычтем
        shr     dl, 1           ; половину длины строки
        neg     dl              ; из
        add     dl, 40          ; середины экрана
        mov     dh, 18
        int     10h
        mov     ah, 09h         ; Строка
        lea     dx, str_resume2
        int     21h

    menu_loop:
        mov     ax, 0100h
        int     16h
        jz      menu_loop           ; Без нажатия - ждём еще
        xor     ah, ah
        int     16h

        cmp     game_in_progress, 0 ; Если игра  ещё не начата, то мы даже не ждем 
        je      menu_not_space      ; нажатия Space для её восстановления
        cmp     ah, 39h
        jne     menu_not_space
        ; Пробел - восстановить игру
        mov     ax, 0500h           ; Сменить страницу на #0
        int     10h                 ; т.е. вернуться к игровому полю
        mov     ax, offset game
        ret

     menu_not_space:
        cmp     ah, 1h
        jne     menu_not_space_esc
        ; Esc - выход
        mov     ax, offset terminate_program
        ret

     menu_not_space_esc:
        cmp     ah, 3Ch             ; Клавиша F2
        jne     menu_loop
        ; Вверх - Новая игра
        mov     game_in_progress, 0 ; New game
        mov     ax, offset game
        ret
menu                endp

game             proc
    cmp     game_in_progress, 1
    je      game_main
    game_init:
        ; Инициализация режима Classic
        ; Очищаем игровое поле
        xor     bh, bh          ; Далее всюду страница #0
        mov     ax, 0010h
        int     10h
        ; Счёт, начальное положение змейки, указатели головы и хвоста, направление, первая еда
        mov     score, 2
        mov     [snake+0], 0100h
        mov     [snake+2], 0200h
        mov     si, score
        dec     si
        shl     si, 1
        xor     di, di          ; Индекс координаты символа хвоста
        mov     direction, 0100h; direction для управления головой
        mov     food_eaten, 0

        ;mov     al, color_food
        ;call    add_food
        mov     game_in_progress, 1
        ; Строка счёт, справка по элементам
        mov     ah, 02h         ; Курсор
        ;xor     bh, bh         ; в позицию 0,0
        xor     dx, dx
        int     10h
        mov     ah, 09h
        lea     dx, str_tutor_game
        int     21h

        mov     ah, 02h         ; Курсор
        ;xor     bh, bh         ; в позицию 0,7
        mov     dx, 6
        int     10h
        mov     ax, score
        sub     ax, 2
        call    print_int

        mov     al, color_food
        mov     cx, 24
        mov     dx, 0;-1
        call    draw_snake_pixel
        mov     al, color_poo
        mov     cx, 32
        call    draw_snake_pixel
        ; Бортик и змейка
        call    draw_border
        mov     al, color_snake
        mov     cx, 2
        mov     dx, 0
        draw_snake_loop:
            call    draw_snake_pixel
            loop    draw_snake_loop

    game_main:
        cmp     ticks, 2
        jl      game_main
        mov     ticks, 0

    keyboard:
        ; Обработка нажатия клавиши и присваивания значения переменной direction,
        ; отвечающей за направление головы. Управление стрелками.
        pusha
            mov     cx, direction
            mov     ax, 0100h
            int     16h
            jz      KP_end           ; Без нажатия выходим
            xor     ah, ah
            int     16h
            xchg    ah, al

            cmp     al, 39h          ; Если это отжатие клавиши Space
            je      KP_menu          ; вернемся в меню
            cmp     al, 50h
            je      KP_down
            cmp     al, 48h
            je      KP_up
            cmp     al, 4Bh
            je      KP_left
            cmp     al, 4Dh
            je      KP_right
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
            KP_menu:
                popa
                ret
            KP_end:
                mov     direction, cx
        popa

    change_head:
        mov     dx, [snake+si]      ;Берем координату головы из памяти
        add     dx, direction       ;Изменяем координаты в зависимости от направления
        inc     si              
        inc     si
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
            mov     game_in_progress, 0
            ret
            draw_head:
            ; Когда позиция проверена, можно нарисовать там голову        
            mov     al, color_snake
            call    draw_snake_pixel
        popf

        ; Стоит ли стирать хвост?
        jnc     erase_tail
        jmp     game_main

    erase_tail:
        mov     dx, [snake+di]
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
    ; Установим обработчик INT 1Сh и сохраним старый
    mov     ax, 351Ch
    int     21h
    mov     [old_1Ch],  bx
    mov     [old_1Ch+2],es
    mov     ax, 251Ch
    mov     dx, offset catch_1Ch
    cli
        int     21h
    sti

    mov     ah, 00h             ; Установим текущее значение
    xor     dh, dh              ; системного таймера как начальный
    int     1Ah                 ; seed для псевдо-рандома                
    mov     RND_seed1, dx

    mov     ah, 0Fh             ; Сохраним начальные видео-режим
    int     10h                 ; и отображаемую страницу
    mov     original_videomode, al
    mov     original_videopage, bh

    mov     ax, 0010h           ; Переходим в графический режим
    int     10h                 ; номер 10h

    start_loop:
        call    menu
        call    ax
        jmp     start_loop
    ret

end     @entry