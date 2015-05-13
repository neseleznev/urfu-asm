; Никита Селезнев, ФИИТ-301, 2015
; Змейка
; 1. Графический режим 10h, восстанавливать режим при выходе
; 2. Все обработчики прерываний минимальны (только необходимый код)
; 3. Управление стрелками, пробел=пауза, esc=выход. Остальное по желанию
; 4. Змейка ползает, ест еду, растёт, умирает при втыкании в стенку или в себя. За еду даются очки, которые отображаются в процессе игры
; 5. Стандартное поле - прямоугольник с границами
;Плюшки: должна быть серьезная доработка алгоритма / новый модуль, проще говоря - что-то, требующее приличное количество усилий для реализации / добавляющее классный новый функционал
;Оценка - буду оценивать качество выполнения работы, знание кода, оптимизацию (могу завернуть с сильно неоптимизированным/плохим кодом), грамотное использование прерываний. Считать ли плюшку плюшкой - тоже тот ещё вопрос :)
;Если есть вопросы, задавайте, обсудим всё немножко до того, как вы узнаете, что потеряли баллы на пустом месте.
;
.186
.model tiny
.code
ORG 100h

@entry:     jmp   @start

include SexyPrnt.inc
include Sound.inc

;catch_09h:
    ;pusha
    ;    in      al, 60h             ; скан-код последней нажатой (из 60 порта)
    ;
    ;    mov     di,     tail
    ;    mov     buffer[di], al
    ;    inc     tail
    ;    and     tail,   0Fh
    ;    mov     ax,     tail
    ;    cmp     head,   ax
    ;    jne     @catch_09h_put
    ;    inc     head
    ;    and     head,   0Fh
    ;
    ;@catch_09h_put:
    ;    in      al,     61h
    ;    or      al,     80h
    ;    out     61h,    al
    ;    and     al,     07Fh
    ;    out     61h,    al
    ;    mov     al,     20h
    ;    out     20h,    al          ; аппаратному контроллеру нужен сигнал ....
    ;popa
    ;iret

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

print_int_3chars    proc
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
print_int_3chars    endp

;delay              proc
    ;
    ;pusha
    ;    mov     ah, 0
    ;    int     1Ah
    ;    add     dx, 2
    ;    mov     bx, dx
    ;delay_loop:   
    ;    int     1Ah
    ;    cmp     dx, bx
    ;    jl      delay_loop
    ;popa
    ;ret
;delay              endp


add_food            proc
    ; Вход: al - цвет
    push ax
        mov     ax, 78         ; Псевдо-рандомное число
        call    randgen         ; от 0 до 78
        mov     cx, ax          ; Запись координаты x
 
        mov     ax, 38          ; 
        call    randgen         ; от 0 до 38
        mov     dx, ax          ; Запись координаты y

        ;Проверяем пустое ли место
        mov     ah, 0Dh         ; Read Pixel
        xor     bh, bh          ; Page 0
        push cx
        push dx
        shl     cx, 3       ; cx*8 (ширина ячейки)
        shl     dx, 3       ; аналогично
        add     dx, 15      ; отступ для текста и прочего
        add     cx, 8
        add     dx, 8
        int     10h         ; Преобразовываем координаты в экранные и спрашиваем цвет пикселя
        pop dx
        pop cx

        cmp     al, color_poo     ; Кака
        je      AF_collision
        cmp     al, color_food     ; Яблочко
        je      AF_collision
        cmp     al, color_snake     ; Сама змея
        je      AF_collision
        cmp     al, color_border     ; Стенка
        je      AF_collision      ;Если занято, повторяем

    pop ax
        call    draw_snake_pixel
        jmp     AF_end
    AF_collision:
        pop ax
        jmp     add_food
    AF_end:
    ret
add_food            endp


check_head_position proc
    ; Проверить, что находится на желаемой для головы позиции,
    ; обработать
    ; Вход:     cx - x (в нашей сетке (80-2)x(40-2))
    ;           dx - y
    ; Результат:
    ;           CF=1, если не нужно стирать хвост (мы съели яблоко)

    ; Проверяем границы поля
        cmp     cx, 78
        jge     CHP_exit
        cmp     dx, 38
        jge     CHP_exit
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
        je      CHP_food
        cmp     al, color_speed_up       ; Speed-up
        je      CHP_increase_speed
        cmp     al, color_speed_down     ; Speed-down
        je      CHP_decrease_speed
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
        ;jmp     CHP_good
    CHP_good:
        clc
        ret
check_head_position endp

mushroom_effect     proc
    pusha
    mov     ax, 0501h
    int     10h

    mov     ax, 0A800h;0A000h
    mov     es, ax

    mov     si, 1;4;8
    ME_loop:
        mov     cx, 640-1;-8
        ME_x:
            mov     dx, 320-1;350-1-15;-8
            ME_y:

                mov     ah, 0Dh         ; Read Pixel
                xor     bh, bh
                int     10h

                test    al, al
                jz      pass_drawing

                ;add     ax, si
                ;mov     al, cl

                push dx
                mov     ax, dx
                mov     dx, 320
                mul     dx
                mov     di, ax
                add     di, cx
                mov     es:[di], 1;si
                ;mov     ah, 0Ch
                ;mov     bh, 1
                ;int     10h
                pop dx

                pass_drawing:

                dec     dx
                cmp     dx, 0;15;+8
                jge     ME_y
            loop    ME_x
        dec     si
        cmp     si, 0;8
        jge     ME_loop
        ;loop    ME_loop
    mov     ax, 0500h
    int     10h
    popa
    ret
mushroom_effect     endp

terminate_program   proc

    call    stop_play_note  
    mov     bx, 0FFFFh
    call    reprogram_pit
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
        ; Восстанавливаем вектор 09h
        ;mov     ax, 2509h
        ;mov     dx, word ptr cs:[old_09h]
        ;mov     ds, word ptr cs:[old_09h+2]
        ;cli
        ;    int     21h
        ;sti
        mov     ax, 4c00h
        int     21h
        ret
terminate_program   endp

draw_border         proc
    mov     ah, 0Ch         ; Function Draw Pixel
    mov     al, color_border         
    xor     bh, bh          ; Page 0
    mov     dx, 15          ; y coord

    mov     cx, 640*8 + 7   ; x coord = [8 строк](640*8) - 1 + [Для левой границы](8)
    DB_topEZ:
        int     10h
        loop DB_topEZ
    int     10h             ; Самый первый пиксель (Потому что cx=0 break)

    mov     dx, 350 - 15 - 8; y coord
    mov     cx, 640*8 - 1   ; x coord = [8 строк](640*8) - 1
    DB_bottomEZ:
        int     10h
        loop    DB_bottomEZ
    int     10h

    mov     dx, 15 + 8          ; y (15 + 8top)
    DB_left_right_yEZ:
        mov     cx, 640 - 8
        DB_left_right_xEZ:
            int     10h
            inc     cx
            cmp     cx, 640 + 8
            jl      DB_left_right_xEZ

        inc     dx
        cmp     dx, 350 - 15 - 8
        jl      DB_left_right_yEZ

    ret
draw_border         endp


draw_snake_pixel    proc
    ; Вход: cx - x координата
    ;       dx - y координата
    ;       al - цвет
    pusha
        shl     cx, 3       ; cx*8 (ширина ячейки)
        shl     dx, 3       ; аналогично
        add     dx, 15      ; отступ для текста и прочего

        add     cx, 8
        add     dx, 8

        mov     ah, 0Ch
        xor     bh, bh

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

init_snake          proc
    mov     al, color_snake
    mov     cx, 2
    mov     dx, 0
    IS:
        call    draw_snake_pixel
        loop    IS
    ret
init_snake          endp

init_snake2         proc
    mov     al, color_snake
    mov     si, score
    IS2:
        mov     dx, [snake+si]
        xor     ch, ch
        mov     cl, dh
        xor     dh, dh
        call    draw_snake_pixel
        dec si
        dec si
        test    si, si
        jns     IS2
    ret
init_snake2         endp


@start:

    call    init_play_note
    mov     bx, 0FFFFh
    call    reprogram_pit

    mov     ah, 00h             ; Установим текущее значение
    xor     dh, dh              ; системного таймера как начальный
    int     1Ah                 ; seed для псевдо-рандома                
    mov     RND_seed1, dx
    xor     dh, dh
    int     1Ah
    mov     RND_seed2, dx

    mov     ah, 0Fh             ; Сохраним начальные видео-режим
    int     10h                 ; и отображаемую страницу
    mov     original_videomode, al
    mov     original_videopage, bh

    mov     ax, 0010h           ; Переходим в графический режим
    int     10h                 ; номер 10h
    ; Установим обработчик INT 09h и сохраним старый
    ;mov     ax, 3509h
    ;int     21h
    ;mov     [old_09h],  bx
    ;mov     [old_09h+2],es
    ;mov     ax, 2509h
    ;mov     dx, offset catch_09h
    ;cli
    ;    int     21h
    ;sti
    start_loop:
        call    menu
        call    ax
        jmp     start_loop
    ret

menu                proc

    menu_draw:

        mov     bh, 1           ; Номер отображаемой страницы (далее всюду)
        mov     ah, 05h         ; Сменить на страницу #1
        mov     al, bh
        int     10h

        ; Очистка экрана
        mov     ah, 02h
        mov     bx, 0100h
        mov     dx, 0000h
        int     10h
        mov     ah, 09h
        mov     al, ' '
        mov     cx, 80*25
        int     10h

        ; Классика (вверх)
        mov     ah, 02h         ; Курсор
        ;mov    bh, 1           ; в позицию dl,dh
        mov     dl, str_classic_len ; Вычтем
        shr     dl, 1           ; половину длины строки
        neg     dl              ; из
        add     dl, 40          ; середины экрана
        mov     dh, 7
        int     10h
        mov     ah, 09h         ; Строка Классика
        lea     dx, str_classic
        int     21h
        mov     ah, 02h         ; Курсор
        ;mov    bh, 1            ; в позицию 11,40
        mov     dl, 40-1
        mov     dh, 8
        int     10h
        mov     ah, 02h
        mov     dl, 24          ; Стрелка вверх
        int     21h

        ; Выход (вниз)
        mov     ah, 02h         ; Курсор
        ;mov    bh, 1            ; в позицию dl,dh
        mov     dl, str_exit_len ; Вычтем
        shr     dl, 1           ; половину длины строки
        neg     dl              ; из
        add     dl, 40          ; середины экрана
        mov     dh, 11
        int     10h
        mov     ah, 09h         ; Строка Выход
        lea     dx, str_exit
        int     21h
        mov     ah, 02h         ; Курсор
        ;mov    bh, 1            ; в позицию 8,40
        mov     dl, 40-1
        mov     dh, 10
        int     10h
        mov     ah, 02h
        mov     dl, 25          ; Стрелка вниз
        int     21h

        ; (влево)
        mov     ah, 02h         ; Курсор
        ;mov    bh, 1            ; в позицию dl,dh
        mov     dl, str_modern_len ; Вычтем длину строки
        neg     dl              ; из
        add     dl, 40-3        ; середины экрана - 3 символа для стрелки
        mov     dh, 9
        int     10h
        mov     ah, 09h         ; Строка
        lea     dx, str_modern
        int     21h
        mov     ah, 02h         ; Курсор
        ;mov    bh, 1            ; 
        mov     dl, 40-3
        mov     dh, 9
        int     10h
        mov     ah, 02h
        mov     dl, 17          ; Стрелка влево
        int     21h

        ; (вправо)
        mov     ah, 02h         ; Курсор
        ;mov    bh, 1            ; в позицию dl,dh
        mov     dl, 40+3        ; середины экрана
        mov     dh, 9
        int     10h
        mov     ah, 09h         ; Строка
        lea     dx, str_right
        int     21h
        mov     ah, 02h         ; Курсор
        ;mov    bh, 1            ; 
        mov     dl, 40+1
        mov     dh, 9
        int     10h
        mov     ah, 02h
        mov     dl, 16          ; Стрелка вправо
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
        call    print_int_3chars
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

    ; TODO Небольшая задержка - защита от случайного нажатия стрелки
    mov     ticks, 0
    menu_delay:               ;Основной цикл
        cmp     ticks, 5
        jl      menu_delay

    menu_loop:
        ;mov     di, tail
        ;mov     ah, buffer[di-1]

        mov     ax, 0100h
        int     16h
        jz      menu_loop           ; Без нажатия - ждём еще
        xor     ah, ah
        int     16h

        cmp     game_in_progress, 0 ; Если игра  ещё не начата, то мы 
        je      menu_not_esc        ; даже не ждем нажатия Esc для её восстановления
        cmp     ah, 1h              ; 
        jne     menu_not_esc
        ; Esc - восстановить игру
        mov     ax, 0500h           ; Сменить страницу на #0
        int     10h                 ; т.е. вернуться к игровому полю
        jmp     menu_end
     menu_not_esc:
        cmp     ah, 50h
        jne     menu_not_d
        ; Вниз - выход
        mov     ax, offset terminate_program
        jmp     menu_end
     menu_not_d:
        cmp     ah, 48h
        jne     menu_not_ud
        ; Вверх - Новая игра classic
        mov     game_in_progress, 0  ; New classic
        mov     score, 2
        mov     [snake+0], 0100h
        mov     [snake+2], 0200h
        mov     ax, offset classic   ; game
        jmp     menu_end
     menu_not_ud:
        cmp     ah, 4Bh
        jne     menu_not_udl
        ; Влево - modern
        mov     game_in_progress, 0  ; New modern
        mov     score, 2
        mov     [snake+0], 0100h
        mov     [snake+2], 0200h
        mov     ax, offset modern    ; game
        jmp     menu_end
     menu_not_udl:
        cmp     ah, 4Dh
        je      menu_r
        jmp     menu_loop           ; Неизвестная клавиша - ждём еще
     menu_r:
        ; Вправо
        mov     ax, offset terminate_program
        jmp     menu_end

    menu_end:
        ret
menu                endp


classic_init        proc
    ; Инициализация режима Classic
    ; Очищаем игровое поле
        xor     bh, bh          ; Далее всюду страница #0
        mov     ax, 0010h
        int     10h
    ; Строка счёт
        mov     ah, 02h         ; Курсор
        ;xor     bh, bh         ; в позицию 0,0
        xor     dx, dx
        int     10h
        mov     ah, 09h
        lea     dx, str_score
        int     21h
        mov     ax, score
        call    print_int_3chars
    ; Справка по элементам
        mov     ah, 02h         ; Курсор
        ;xor     bh, bh          ; в позицию 0,15
        xor     dx, dx
        mov     dl, 15
        int     10h
        mov     ah, 09h         ; Строка Счёт
        lea     dx, str_tutor_classic
        int     21h

        mov     ah, 02h         ; Курсор
        ;xor     bh, bh         ; в позицию 0,80-len
        mov     dx, 80
        sub     dl, str_hotkey_len
        int     10h
        mov     ah, 09h         ; Esc - menu
        lea     dx, str_hotkey
        int     21h

        mov     al, color_food
        mov     cx, 12
        mov     dx, -3
        call    draw_snake_pixel
        mov     al, color_poo
        mov     cx, 20
        call    draw_snake_pixel
    ; Бортик и змейка
        call    draw_border
        call    init_snake
    ; Координаты головы, хвоста, направление, перва еда
        mov     si, score
        dec     si
        shl     si, 1
        xor     di, di          ;Индекс координаты символа хвоста
        mov     direction, 0100h;direction для управления головой. dir[0] - приращение координаты x (1 или -1), dir[1] - y (1 или -1) 
        mov     food_eaten, 0

        mov     al, color_food
        ;mov     cx, 0800h
        ;debug_superfood:
        call    add_food
        ;loop    debug_superfood
        mov     game_in_progress, 1
        mov     current_game, offset classic
    ret
classic_init        endp

classic             proc
    ;
    ;
    cmp     game_in_progress, 1
    je      classic_main

    call classic_init

    classic_main:               ;Основной цикл
        cmp     ticks, 2
        jl      classic_main
        mov     ticks, 0

    key_press:
        ; Обработка нажатия клавиши и присваивания значения переменной direction,
        ; отвечающей за направление головы. Управление стрелками.
        pusha
            mov     cx, direction
            ;mov     ax, head
            ;cmp     ax, tail
            ;je      classic_main

            ;mov     di, tail
            ;mov     al, buffer[di-1]
            mov     ax, 0100h
            int     16h
            jz      KP_end           ; Без нажатия выходим
            xor     ah, ah
            int     16h
            xchg    ah, al

            cmp     al, 1h           ; Если это отжатие клавиши Esc
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
        jmp     classic_main
 
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
        jmp     classic_main
    ret
classic             endp


modern_init         proc
    ; Инициализация режима Modern
    ; Очищаем игровое поле
        xor     bh, bh          ; Далее всюду страница #0
        mov     ax, 0010h
        int     10h
    ; Строка счёт
        mov     ah, 02h         ; Курсор
        ;xor     bh, bh         ; в позицию 0,0
        xor     dx, dx
        int     10h
        mov     ah, 09h
        lea     dx, str_score
        int     21h
        mov     ax, score
        call    print_int_3chars
    ; Справка по элементам
        mov     ah, 02h         ; Курсор
        ;xor     bh, bh          ; в позицию 0,15
        xor     dx, dx
        mov     dl, 15
        int     10h
        mov     ah, 09h         ; Строка Счёт
        lea     dx, str_tutor_modern
        int     21h
        
        mov     ah, 02h         ; Курсор
        ;xor     bh, bh         ; в позицию 0,80-len
        mov     dx, 80
        sub     dl, str_hotkey_len
        int     10h
        mov     ah, 09h         ; Esc - menu
        lea     dx, str_hotkey
        int     21h

        mov     al, color_food
        mov     cx, 12
        mov     dx, -3
        call    draw_snake_pixel
        mov     al, color_poo
        mov     cx, 20
        call    draw_snake_pixel
        mov     al, color_mushroom
        mov     cx, 26
        call    draw_snake_pixel
        mov     al, color_speed_up
        mov     cx, 37
        call    draw_snake_pixel
        mov     al, color_speed_down
        mov     cx, 46
        call    draw_snake_pixel
    ; Бортик и змейка
        call    draw_border
        call    init_snake
    ; Инициализация головы и хвоста, направления
        mov     si, score
        dec     si
        shl     si, 1
        xor     di, di          ;Индекс координаты символа хвоста
        mov     direction, 0100h;direction для управления головой. dir[0] - приращение координаты x (1 или -1), dir[1] - y (1 или -1)
        mov     food_eaten, 0
        mov     speed_multiplier, 0
        mov     speed_ticks, 0
        mov     mushroom_ticks, 0
        mov     bx, 0FFFFh
        call    reprogram_pit

        mov     al, color_food
        ;mov     cx, 0800h
        ;debug_superfood:
        call    add_food
        ;loop    debug_superfood
        mov     game_in_progress, 1
        mov     current_game, offset modern
    ret
modern_init         endp

modern              proc
    ;
    ;
    cmp     game_in_progress, 1
    je      modern_main

    call modern_init

    modern_main:               ;Основной цикл
        cmp     ticks, 2
        jl      modern_main
        mov     ticks, 0

    M_extra_items:
        cmp     speed_ticks, 0
        je      M_no_speed
        dec     speed_ticks
        cmp     speed_ticks, 0
        jne     M_no_speed
        pusha
            mov     al, 00h
            mov     dx, speed_up_coord
            mov     cl, dh
            xor     ch, ch
            xor     dh, dh
            call    draw_snake_pixel

            mov     dx, speed_down_coord
            mov     cl, dh
            xor     dh, dh
            call    draw_snake_pixel
        popa
        M_no_speed:

        cmp     mushroom_ticks, 0
        je      M_no_mushroom
            mov     dx, mushroom_coord
            mov     cl, dh
            xor     ch, ch
            xor     dh, dh
            mov     al, color_mushroom
            add     al, 0;8
            mov     color_mushroom, al
            call    draw_snake_pixel
                                    ;xor ah,ah
                                    ;and al, 0Fh
                                    ;call print_int2
        dec     mushroom_ticks
        cmp     mushroom_ticks, 0
        jne     M_no_mushroom
        pusha
            mov     al, 00h
            mov     dx, mushroom_coord
            mov     cl, dh
            xor     ch, ch
            xor     dh, dh
            call    draw_snake_pixel
        popa
        M_no_mushroom:

    M_key_press:
        ; Обработка нажатия клавиши и присваивания значения переменной direction,
        ; отвечающей за направление головы. Управление стрелками.
        pusha
            mov     cx, direction

            ;mov     ax, head
            ;cmp     ax, tail
            ;je      modern_main

            ;mov     di, tail
            ;mov     al, buffer[di-1]
            mov     ax, 0100h
            int     16h
            jz      M_KP_end           ;Без нажатия выходим
            xor     ah, ah
            int     16h
            xchg    ah, al

            cmp     al, 1h              ; Если это отжатие клавиши Esc
            je      M_KP_menu              ; Завершим выполнение программы
            cmp     al, 50h
            je      M_KP_down
            cmp     al, 48h
            je      M_KP_up
            cmp     al, 4Bh
            je      M_KP_left
            cmp     al, 4Dh
            je      M_KP_right
            jmp     M_KP_end

            M_KP_down:
            cmp     cx, 0FFFFh       ; Сравниваем чтобы не пойти на себя
            je      M_KP_end
            mov     cx, 0001h       ; Вниз => x 0, y 1
            jmp     M_KP_end
            M_KP_up:
            cmp     cx, 0001h
            je      M_KP_end
            mov     cx, 0FFFFh      ; Вверх => x 0, y -1
            jmp     M_KP_end
            M_KP_left:
            cmp     cx, 0100h
            je      M_KP_end
            mov     cx, 0FF00h      ; Влево => x -1, y 0
            jmp     M_KP_end
            M_KP_right:
            cmp     cx, 0FF00h
            je      M_KP_end
            mov     cx, 0100h       ; Вправо => x 1, y 0
            jmp     M_KP_end
            M_KP_menu:
                popa
                ret
            M_KP_end:
                mov     direction, cx
        popa

        ;cmp     ticks, 2
        ;jl      modern_main
        ;mov     ticks, 0

    M_move_snake:
        ;mov     dx, direction
        ;mov     actual_direction, dx
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
            jne     M_draw_head
            popf
            mov     game_in_progress, 0
            ret
            M_draw_head:
            ; Когда позиция проверена, можно нарисовать там голову        
            mov     al, color_snake
            call    draw_snake_pixel
        popf

        ; Стоит ли стирать хвост? То есть съели ли яблоко?
        jc      M_snake_grows

    M_erase_tail:
        mov     dx, [snake+di]
        mov     al, 0
        xor     cx, cx
        mov     cl, dh
        xor     dh, dh
        call    draw_snake_pixel
        inc     di
        inc     di
        and     di, 0FFh
        jmp     modern_main
    
    M_snake_grows:
        ; Если яблоко съедено - включить звук
        mov     bx, 01000h
        call    reprogram_pit
        mov     ax, food_eaten

        mov     ah, 2           ; 2 октава (Большая)
        mov     bl, 16          ; 16-ая нота
        mov     cx, 128         ; 128 bpm
        
        add     al, 0
        call    play_note
        add     al, 5
        call    play_note
        call    no_sound

        mov     bx, 0FFFFh
        mov     ah, speed_freq_x1000
        shl     ah, 4
        xor     al, al
        mul     speed_multiplier
        sub     bx, ax
        call    reprogram_pit

        cmp     speed_ticks, 0  ; Если в текущий момент на экране
        jne     M_pass_speed    ; нет чили и льда,
        mov     ax, 5           ; с вероятностью 1/5
        call    randgen         ; сгенерируем чили и лед
        test    ax, ax
        jnz     M_pass_speed
            mov     al, color_speed_up
            call    add_food
            mov     dh, cl
            mov     speed_up_coord, dx
            mov     al, color_speed_down
            call    add_food
            mov     dh, cl
            mov     speed_down_coord, dx
            mov     speed_ticks, 100
        M_pass_speed:

        cmp     mushroom_ticks, 0; Если в текущий момент на экране
        jne     M_pass_mushroom ; нет грибов,
        mov     ax, 1          ; С вероятностью 1/10
        call    randgen         ; сгенерируем грибы
        test    ax, ax
        jnz     M_pass_mushroom
            mov     al, color_mushroom
            call    add_food
            mov     dh, cl
            mov     mushroom_coord, dx
            mov     mushroom_ticks, 500
        M_pass_mushroom:
        jmp     modern_main
modern              endp


original_videomode  db  ?
original_videopage  db  ?

game_in_progress    db  0
game_over           db  0
current_game        dw  ?
score               dw  2
snake               dw  0100h
                    dw  0200h
                    dw  100h  dup('?')
food_eaten          dw  0             ; Счетчик съеденных
direction           dw  0100h         ; xx;yy
;actual_direction    dw  0100h         ; xx;yy
speed_multiplier    dw  0
speed_freq_x1000    db  04h           ; => freq_step = 08000h

thickness           dw  8             ; Толщина линий и размер клетки

color_poo           db  06h
color_food           db  0Ah
color_snake           db  02h
color_border           db  03h
color_mushroom          db  0Dh
color_speed_up           db  0Ch
color_speed_down          db  0Bh

speed_up_coord      dw  ?
speed_down_coord    dw  ?
speed_ticks         dw  ?
mushroom_coord      dw  ?
mushroom_ticks      dw  ?

str_score           db  'Score: ','$'
str_score_len       db  $-str_score-1

str_classic         db  'Classic mode','$'
str_classic_len     db  $-str_classic
str_modern          db  'Modern mode','$'
str_modern_len      db  $-str_modern
str_right           db  '[TODO right]','$'
str_right_len       db  $-str_right
str_exit            db  'Exit','$'
str_exit_len        db  $-str_exit
str_resume1         db  'PAUSE','$'
str_resume1_len     db  $-str_resume1
str_resume2         db  'Esc - Resume game','$'
str_resume2_len     db  $-str_resume2
str_gameover1       db  'GAME OVER','$'
str_gameover1_len   db  $-str_gameover1
str_gameover2       db  'Your score: ','$'
str_gameover2_len   db  $-str_gameover2
str_tutor_classic   db  'Apple   Poo','$'
str_tutor_modern    db  'Apple   Poo   Mushroom   Chilli   Ice','$'
str_hotkey          db  '[Esc - menu]','$'
str_hotkey_len      db  $-str_hotkey

RND_const           dw  8405h         ; multiplier value
RND_seed1           dw  ?
RND_seed2           dw  ?             ; random number seeds

;buffer      db      10h dup (?) 
;head        dw      0
;tail        dw      0
;old_09h     dw      ?, ?


end	    @entry
