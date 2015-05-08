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

@entry:             jmp   @start

original_videomode  db  ?
original_videopage  db  ?

snake               dw  0100h
                    dw  0200h
                    dw  100h  dup('?')
score               dw  2
food_eaten                dw  0             ; Счетчик съеденных
direction           dw  0100h         ; xx;yy
speed_multiplier    dw  0

thickness           dw  8             ; Толщина линий и размер клетки

color_poo           db  06h
color_food           db  0Ah
color_snake           db  02h;0Bh
color_border           db  03h;0Ch
color_mushroom           db  0Eh;0Ch
color_speed_up           db  0Ch
color_speed_down           db  0Bh

str_score           db  'Score: ','$'
str_score_len       db  $-str_score-1

str_classic         db  'Classic game','$'
str_classic_len     db  $-str_classic
str_left            db  '[TODO left]','$'
str_left_len        db  $-str_left
str_right           db  '[TODO right]','$'
str_right_len       db  $-str_right
str_exit            db  'Exit','$'
str_exit_len        db  $-str_exit
str_tutor_classic   db  'Apple   Poo   Mushroom   Chilli   Ice','$'

RND_const           dw  8405h         ; multiplier value
RND_seed1           dw  ?
RND_seed2           dw  ?             ; random number seeds

include SexyPrnt.inc
include Sound.inc

randgen proc
    ; ax = Конец диапазона [0...ax]
        or      ax, ax      ; range value != 0
        jz      RND_end
        push bx
        push cx
        push dx
        push ds

        push    ax
        mov     ah, 00h
        int     1Ah
        xor     dh, dh
        add     RND_seed2, dx
        shr     RND_seed2, 1
        ;call CRLF
        ;mov ax, dx
        ;call print_int2
        pop     ax

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
randgen endp

print_int_3chars proc
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
print_int_3chars endp

delay   proc
    ;
    pusha
        mov     ah, 0
        int     1Ah
        add     dx, 3
        mov     bx, dx
    delay_loop:   
        int     1Ah
        cmp     dx, bx
        jl      delay_loop
    popa
    ret
delay endp


key_press proc
    ; Процедура обработки нажатия клавиши и присваивания значения переменной direction,
    ; отвечающей за направление головы. Управление стрелками.
    pusha
        mov     cx, direction

        mov     ax, 0100h
        int     16h
        jz      KP_end           ;Без нажатия выходим
        xor     ah, ah
        int     16h
        
        cmp     ah, 1h;81h
        je      KP_terminate

        cmp     ah, 50h
        jne     KP_not_down
        cmp     cx, 0FFFFh       ; Сравниваем чтобы не пойти на себя
        je      KP_end
        mov     cx, 0001h       ; Вниз => x 0, y 1
        jmp     KP_end
    KP_not_down:
        cmp     ah, 48h
        jne     KP_not_up_down
        cmp     cx, 0001h
        je      KP_end
        mov     cx, 0FFFFh      ; Вверх => x 0, y -1
        jmp     KP_end
    KP_not_up_down:
        cmp     ah, 4Bh
        jne     KP_not_up_down_left
        cmp     cx, 0100h
        je      KP_end
        mov     cx, 0FF00h      ; Влево => x -1, y 0
        jmp     KP_end
    KP_not_up_down_left:
        cmp     ah, 4Dh
        jne     KP_end
    KP_right:
        cmp     cx, 0FF00h
        je      KP_end
        mov     cx, 0100h       ; Вправо => x 1, y 0
        jmp     KP_end
    KP_terminate:
        popa
        call    terminate_program
    KP_end:
    mov     direction, cx
    popa
    ret
key_press endp


add_food proc
    ; Вход: al - цвет
    push cx
    push dx
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
        pop dx
        pop cx
        jmp     add_food
    AF_end:
    pop dx
    pop cx
    ret
add_food endp


game_over proc
    push dx
    mov ah, 02h 
    xor bh, bh
    xor dx, dx
    int 10h
    
    push cx
    mov cx, 20
    llll:
        ;call print_space
        loop llll
    pop cx

    int 10h
    
    mov ax, cx
    ;call print_int2
    ;call print_space
    pop dx
    mov ax, dx
    ;call print_int2
    ;call print_space
    ; Проверяем границы поля
        cmp     cx, 78
        jge     GO_exit
        cmp     dx, 38
        jge     GO_exit
    ; Проверяем символы
        mov     ah, 0Dh         ; Read Pixel
        xor     bh, bh
        push cx
        push dx
        shl     cx, 3           ; cx*8 (ширина ячейки)
        shl     dx, 3           ; аналогично
        add     dx, 15          ; отступ для текста и прочего
        add     cx, 8
        add     dx, 8
        int     10h
        pop dx
        pop cx
        
        cmp     al, color_speed_up         ; Speed-up
        je      GO_increase_speed
        cmp     al, color_speed_down         ; Speed-down
        je      GO_decrease_speed
        cmp     al, color_border         ; Стенка
        je      GO_exit
        cmp     al, color_poo         ; Какашки
        je      GO_exit
        cmp     al, color_snake         ; Змейка
        je      GO_exit
        jmp     GO_good
    GO_increase_speed:
        inc     speed_multiplier
        inc     speed_multiplier
        ;jmp     GO_good
    GO_decrease_speed:
        dec     speed_multiplier
        pusha
        mov     bx, 0FFFFh
        mov     ax, 02000h
        mul     speed_multiplier
        sub     bx, ax
        call    reprogram_pit
        popa
        jmp     GO_good
    GO_exit:
        call terminate_program
    GO_good:
        ret
game_over endp

terminate_program proc

    call    stop_play_note  
    mov     bx, 0FFFFh
    call    reprogram_pit
        mov     ah, 00h
        mov     al, 10h
        int     10h

        mov     ah, 00h
        mov     al, original_videomode
        int     10h
        mov     ah, 05h
        mov     al, original_videopage
        int     10h
        mov     ax, 4c00h
        int     21h
        ret
terminate_program endp

draw_borderEZ proc
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
draw_borderEZ endp

draw_border proc
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
draw_border endp


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

        mov     si, 6;7       ; Цикл по x
        DSP_x:
            add     cx, si
            mov     di, 6;7       ; Цикл по y
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

init_snake  proc
    mov     al, color_snake
    mov     cx, 2
    mov     dx, 0
    IS:
        call    draw_snake_pixel
        loop    IS
    ret
init_snake  endp


@start:

    call    init_play_note
    mov     bx, 0FFFFh
    call    reprogram_pit

    mov     ah, 0Fh
    int     10h
    mov     original_videomode, al
    mov     original_videopage, bh

    xor ah, ah
    mov al, original_videomode
    call print_int2
    call CRLF
    mov al, original_videopage
    call print_int2
    call CRLF
    ;ret

@draw_menu:

    mov     ax, 0010h
    int	    10h 			;Очищаем игровое поле

    ; Классика (вверх)
    mov     ah, 02h         ; Курсор
    xor     bh, bh          ; в позицию dl,dh
    mov     dl, str_classic_len ; Вычтем
    shr     dl, 1           ; половину длины строки
    neg     dl              ; из
    add     dl, 40          ; середины экрана
    mov     dh, 5
    int     10h
    mov     ah, 09h         ; Строка Классика
    lea     dx, str_classic
    int     21h
    mov     ah, 02h         ; Курсор
    xor     bh, bh          ; в позицию 11,40
    mov     dl, 40-1
    mov     dh, 6
    int     10h
    mov     ah, 02h
    mov     dl, 24          ; Стрелка вверх
    int     21h

    ; Выход (вниз)
    mov     ah, 02h         ; Курсор
    xor     bh, bh          ; в позицию dl,dh
    mov     dl, str_exit_len ; Вычтем
    shr     dl, 1           ; половину длины строки
    neg     dl              ; из
    add     dl, 40          ; середины экрана
    mov     dh, 9
    int     10h
    mov     ah, 09h         ; Строка Выход
    lea     dx, str_exit
    int     21h
    mov     ah, 02h         ; Курсор
    xor     bh, bh          ; в позицию 8,40
    mov     dl, 40-1
    mov     dh, 8
    int     10h
    mov     ah, 02h
    mov     dl, 25          ; Стрелка вниз
    int     21h

    ; (влево)
    mov     ah, 02h         ; Курсор
    xor     bh, bh          ; в позицию dl,dh
    mov     dl, str_left_len ; Вычтем длину строки
    neg     dl              ; из
    add     dl, 40-3        ; середины экрана - 3 символа для стрелки
    mov     dh, 7
    int     10h
    mov     ah, 09h         ; Строка
    lea     dx, str_left
    int     21h
    mov     ah, 02h         ; Курсор
    xor     bh, bh          ; 
    mov     dl, 40-3
    mov     dh, 7
    int     10h
    mov     ah, 02h
    mov     dl, 17          ; Стрелка влево
    int     21h

    ; (вправо)
    mov     ah, 02h         ; Курсор
    xor     bh, bh          ; в позицию dl,dh
    mov     dl, 40+3        ; середины экрана
    mov     dh, 7
    int     10h
    mov     ah, 09h         ; Строка
    lea     dx, str_right
    int     21h
    mov     ah, 02h         ; Курсор
    xor     bh, bh          ; 
    mov     dl, 40+1
    mov     dh, 7
    int     10h
    mov     ah, 02h
    mov     dl, 16          ; Стрелка вправо
    int     21h

@menu_loop:
    mov     ax, 0100h
    int     16h
    jz      @menu_loop           ;Без нажатия - ждём
    xor     ah, ah
    int     16h

    cmp     ah, 50h
    jne     menu_not_d
    ; Вниз - выход
    call    terminate_program
 menu_not_d:
    cmp     ah, 48h
    jne     menu_not_ud
    ; Вверх - classic
    jmp     start_classic
    menu_not_ud:
        cmp     ah, 4Bh
        jne     menu_not_udl
        ; Влево
        call    terminate_program
    menu_not_udl:
        cmp     ah, 4Dh
        je      menu_r
        jmp     @menu_loop
    menu_r:
        ; Вправо
        call    terminate_program

start_classic:
    ; Очищаем игровое поле
    mov     ax, 0010h
    int     10h

    ; Строка счёт
    mov     ah, 02h         ; Курсор
    xor     bh, bh          ; в позицию 0,0
    xor     dx, dx
    int     10h
    mov     ah, 09h
    lea     dx, str_score
    int     21h
    mov     ax, score
    call    print_int_3chars

    ; Справка по элементам
    mov     ah, 02h         ; Курсор
    xor     bh, bh          ; в позицию 0,15
    xor     dx, dx
    mov     dl, 15
    int     10h
    mov     ah, 09h         ; Строка Счёт
    lea     dx, str_tutor_classic
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

    call    draw_border
    call    init_snake

    mov     si, score		;Индекс координаты символа головы
    dec     si
    shl     si, 1
    xor     di, di			;Индекс координаты символа хвоста
    mov     direction, 0100h;direction для управления головой. dir[0] - приращение координаты x (1 или -1), dir[1] - y (1 или -1) 

    mov     al, color_food
    ;mov     cx, 0800h
    ;debug_superfood:
    call    add_food
    ;loop    debug_superfood

@main:				;Основной цикл
    call    delay
    call    key_press
    mov     dx, [snake+si]		;Берем координату головы из памяти
    add     dx, direction		;Изменяем координаты в зависимости от направления
    inc     si				
    inc     si
    and     si, 0FFh
    mov     [snake+si], dx		;Заносим в память новую координату головы змеи

    xor     cx, cx
    mov     cl, dh              ; cx - x
    xor     dh, dh              ; dx - y
    call    game_over           ; Проверки на столкновения со стенами, собой, какахой

    ; Яблоко
        ; Проверяем позицию
        mov     ah, 0Dh         ; Read Pixel
        xor     bh, bh
        push cx
        push dx
        shl     cx, 3           ; cx*8 (ширина ячейки)
        shl     dx, 3           ; аналогично
        add     dx, 15          ; отступ для текста и прочего
        add     cx, 8
        add     dx, 8
        int     10h
        pop dx
        pop cx

        mov     ah, al ; Сохраним цвет под головой
        ; Когда позиция проверена, можно нарисовать там голову        
        mov     al, color_snake
        call    draw_snake_pixel

        cmp     ah, color_food          ; яблочки
    jne     next
    inc     score

    ; Звук
    mov     bx, 01000h
    call    reprogram_pit
    mov     ax, food_eaten

    mov     ah, 2           ; 2 октава (Большая)
    mov     bl, 16          ; 16-ая нота
    mov     cx, 128         ; 128 bpm
    
    add     al, 0
    call    play_note
    add     al, 7
    call    play_note
    call    no_sound

    mov     bx, 0FFFFh
    mov     ax, 02000h
    mul     speed_multiplier
    sub     bx, ax
    call    reprogram_pit

    ; Какашки
    inc     food_eaten
    cmp     food_eaten, 6
    jl      WC_not_now
    mov     food_eaten, 0
    mov     al, color_poo
    mov     dx, [snake+di-2]
    mov     cl, dh              ; cx - x
    xor     dh, dh              ; dx - y
    call    draw_snake_pixel
    ;inc     speed_multiplier
    ; TODO speedup сразу
        mov     al, color_speed_up
    call    add_food
        mov     al, color_speed_down
    call    add_food
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
    jmp     @main
    
 next:
    mov     dx, [snake+di]
    mov     al, 0
    xor     cx, cx
    mov     cl, dh
    xor     dh, dh
    call    draw_snake_pixel
    inc     di
    inc     di
    and     di, 0FFh
jmp     @main

end	    @entry
