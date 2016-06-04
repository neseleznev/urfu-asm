.186
.model tiny
.code
ORG 100h

@entry:     jmp   @start

; Переменные
game_in_progress    db  0
game_over           db  0
score               dw  2
lifes				dw 	3
snake               dw  100h  dup('?')
food_eaten          dw  0             ; Счетчик съеденных
direction           dw  0100h         ; xx;yy
; Константы-цвета
color_food          db  0Ch
color_snake         db  02h
color_wall          db  06h
color_portal        db  09h
;константы количества еды
apple_count dw 3
wall_count dw 3
;мелодия
gameOverMelody 		dw 270, 260, 250, 240, 200, 190
isGameOverMelodyPlayed 	db 0
; Строки вместе с длинами
str_game            db  'F2 - New game','$'
str_game_len        db  $-str_game
str_exit            db  'Esc - Exit','$'
str_exit_len        db  $-str_exit
str_resume1         db  '___ PAUSE ___','$'
str_resume1_len     db  $-str_resume1
str_resume2         db  'Space - Resume game','$'
str_resume2_len     db  $-str_resume2
str_gameover1       db  '                           ~####~~~####~~##~~~#~#####', 13, 10
					db  '                           ##~~~~~##~~##~###~##~##', 13, 10
					db  '                           ##~###~######~##~#~#~####',13, 10
					db  '                           ##~~##~##~~##~##~~~#~##', 13, 10
					db  '                           ~####~~##~~##~##~~~#~#####', 13, 10
					db  '                                                     ', 13, 10
					db  '                           ~####~~##~~##~#####~~#####', 13, 10
					db  '                           ##~~##~##~~##~##~~~~~##~~##', 13, 10
					db  '                           ##~~##~##~~##~####~~~#####',13, 10
					db  '                           ##~~##~~####~~##~~~~~##~~##', 13, 10
					db  '                           ~####~~~~##~~~#####~~##~~##', '$'
str_gameover2       db  'Your score ','$'
str_gameover2_len   db  $-str_gameover2
str_tutor_game      db  'Score ___                       Lifes XXX                           | Esc - exit','$'
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


playMelody proc
	pusha	
	mov 	cx, offset isGameOverMelodyPlayed - offset gameOverMelody
	shr 	cx, 1
	mov 	bl, 11110000b
	xor 	bh, bh
	mov 	si, offset gameOverMelody
 @play:
	mov 	di, [si]
	call 	playSound
	
	add 	si, 2
	loop 	@play	
 
 @endMelody:
 	popa
	push 	ax
	
	in 	al, 61h
	and 	al, 11111100b 			; выключить динамик
	out 	61h, al

	pop 	ax
	ret
playMelody endp

playSound proc
	pusha

 	mov 	al, 10110110b 			; установка режима таймера
	out 	43h, al
	
	mov 	dx, 14h 			; делитель времени = 
	mov 	ax, 4f38h 			; 1331000/частота
	div 	di
	out 	42h, al 			; записать младший байт счетчика таймера 2
	
	mov 	al, ah
	out 	42h, al 			; 3аписать старший байт счетчика таймера 2
	
	in 	al, 61h 			; считать текущую установку порта 
	mov 	ah, al 				; и сохранить ее в регистре аh
	or 	al, 00000011b			; включить динамик
	out 	61h, al
		
 @wait1:
	mov 	cx, 2201 			; выждать 10 мс
		
 @play_one_note: 
	loop 	@play_one_note
	
	dec 	bx				; счетчик длительности исчерпан?
	jnz 	@wait1 				; нет  продолжить звучание
	mov 	al, ah 				; да  восстановить исходную установку порта
	out 	61h, al
			
	popa	
	ret 				
playSound endp
	
	
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
    mov     al, color_portal         
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
		cmp al, color_food
		jne end_draw_snake_pixel
		mov al, 0h
		int 10h
		add cx, 9
		int 10h
		add dx, 9
		int 10h
		sub cx, 9
		int 10h
		sub dx, 9
		add cx, 3
		int 10h
		add cx, 1
		int 10h
		mov al, 02h
		add cx, 1
		int 10h
		add cx, 1
		int 10h
		add dx, 1
		sub cx, 2
		int 10h
		add cx, 1
		int 10h
		mov al, 0h
		add dx, 8
		int 10h
		sub cx, 1
		int 10h
	end_draw_snake_pixel:	
    popa
    ret
draw_snake_pixel    endp

; Логика
add_food            proc
    ; Нарисовать на произвольном незанятом месте поля еду
    push ax
        mov     ax, 62        ; Псевдо-рандомное число
        call    randgen         ; от 0 до 62
        mov     cx, ax          ; Запись координаты x
 
        mov     ax, 30        ; 
        call    randgen         ; от 0 до 30
        mov     dx, ax          ; Запись координаты y

        ; Проверяем пустое ли место
        push    cx
        push    dx
            mov     ah, 0Dh         ; Read Pixel
            xor     bh, bh          ; Page 0
            call    convert_to_screen
			add cx, 5
			add dx, 5
            int     10h         ; Преобразовываем координаты в экранные и спрашиваем цвет пикселя
        pop     dx
        pop     cx

        cmp     al, 0h     
        jne      AF_collision		

    pop ax
        mov     al, color_food
        call    draw_snake_pixel
        ret
    AF_collision:
        call     add_food
		ret
add_food            endp

add_wall            proc
    ; Нарисовать на произвольном незанятом месте поля еду
    push ax
        mov     ax, 62        ; Псевдо-рандомное число
        call    randgen         ; от 0 до 62
        mov     cx, ax          ; Запись координаты x
 
        mov     ax, 30        ; 
        call    randgen         ; от 0 до 30
        mov     dx, ax          ; Запись координаты y

        ; Проверяем пустое ли место
        push    cx
        push    dx
            mov     ah, 0Dh         ; Read Pixel
            xor     bh, bh          ; Page 0
            call    convert_to_screen
			add cx, 5
			add dx, 5
            int     10h         ; Преобразовываем координаты в экранные и спрашиваем цвет пикселя
        pop     dx
        pop     cx

        cmp     al, 0h     
        jne      AW_collision

    pop ax
        mov     al, color_wall
        call    draw_snake_pixel
        ret
    AW_collision:
        call     add_wall
		ret
add_wall            endp

redraw_snake proc
	pusha
	cmp color_snake, 02h
	je makecolor3h
	cmp color_snake, 03h
	je makecolor4h
	cmp color_snake, 04h
	je makecolor2h
makecolor3h:
	mov color_snake, 03h
	jmp redraw_snake_start
makecolor4h:
	mov color_snake, 04h
	jmp redraw_snake_start
makecolor2h:
	mov color_snake, 02h
	jmp redraw_snake_start
redraw_snake_start:
	push di
redrawloop:
	mov     dx, [snake+di] 
    xor     cx, cx
    mov     cl, dh              ; cx - x
    xor     dh, dh              ; dx - y
	mov     al, color_snake
    call    draw_snake_pixel
	inc di
	inc di
	and di, 0FFh
	cmp di, si
	jne redrawloop
	pop di
	mov     dx, [snake+si] 
    xor     cx, cx
    mov     cl, dh              ; cx - x
    xor     dh, dh              ; dx - y
	mov     al, color_snake
	inc 	al
    call    draw_snake_pixel
	popa
	ret
redraw_snake endp

check_head_position proc
    ; Проверить, что находится на желаемой для головы позиции,
    ; обработать
    ; Вход:     cx - x (в нашей сетке (80-2)x(40-2))
    ;           dx - y
    ; Результат:
    ;           CF=1, если не нужно стирать хвост (мы съели яблоко)

    ; Проверяем символы
        push    cx
        push    dx
            mov     ah, 0Dh         ; Read Pixel
            xor     bh, bh
            call    convert_to_screen
			add cx, 5
			add dx, 5
            int     10h
        pop     dx
        pop     cx
        
        cmp     al, color_food           ; Яблоко
        je      CHP_food
		cmp     al, color_portal           ; портал
        je      CHP_portal
		cmp     al, color_wall         ; Стенка
        je      CHP_exit
        cmp     al, color_snake          ; Змейка
        je      CHP_exit
        jmp     CHP_good
    CHP_exit:
		call 	playMelody
        mov     game_over, 1
    CHP_good:
        clc
        ret
	CHP_portal:
		pusha
		cmp		dl, 0ffh
		je 		up_portal
		cmp		dl, 30
		je 		down_portal
		cmp 	cl, 0ffh
		je 		left_portal
		cmp 	cl, 62
		je 		right_portal
		mov 	dh, cl
		jmp change_coord
		up_portal:
			mov dl, 29
			mov dh, cl
			jmp change_coord
		left_portal:
			mov dh, 61
			jmp change_coord
		right_portal:
			mov dh, 0
			jmp change_coord
		down_portal:
			mov dl, 0
			mov dh, cl
			jmp change_coord
		change_coord:
		mov     [snake+si], dx
		popa
		ret
    CHP_food:
        pusha
        inc     score               ; Увеличим счёт
     print_score:
        mov     ah, 02h         ; Курсор
        ;xor     bh, bh         ; в позицию 0,6
        mov     dx, 6
        int     10h
        mov     ax, score
        sub     ax, 2
        call    print_int
        call    add_food
		call    redraw_snake
        popa
        stc
        ret
check_head_position endp

drop_tail proc
	push cx
	push dx
	push ax
	mov cx, 5
	DT_redrawloop:
	mov     dx, [snake+di]
	push cx
    xor     cx, cx
    mov     cl, dh              ; cx - x
    xor     dh, dh              ; dx - y
	mov     al, color_wall
    call    draw_snake_pixel
	inc di
	inc di
	and di, 0FFh
	pop cx
	loop DT_redrawloop
	pop ax
	pop dx
	pop cx
	ret
drop_tail endp

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

show_game_over                proc
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
        ; GAME OVER
        mov     ah, 02h         ; Курсор
        mov     dl, 0 
        mov     dh, 8
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
        mov     dh, 20
        int     10h
        mov     ah, 09h         ; Строка
        lea     dx, str_gameover2
        int     21h
        mov     ax, score
        sub     ax, 2
        call    print_int
        mov     game_over, 0
    game_over_loop:
        mov     ax, 0100h
        int     16h
        jz      game_over_loop           ; Без нажатия - ждём еще
        xor     ah, ah
        int     16h
        cmp     ah, 1h
        jne     game_over_loop
        ; Esc - выход
        ret
show_game_over               endp

game             proc
    cmp     game_in_progress, 1
    je      middle
	mov     score, 2
	mov 	lifes, 3
	mov str_tutor_game[40], 'X'
	mov str_tutor_game[39], 'X'
    game_init:
        ; Очищаем игровое поле
        xor     bh, bh          ; Далее всюду страница #0
        mov     ax, 0010h
        int     10h
        ; Счёт, начальное положение змейки, указатели головы и хвоста, направление, первая еда
        
        mov     [snake+0], 0100h
        mov     [snake+2], 0200h
        mov     si, 2
        dec     si
        shl     si, 1
        xor     di, di          ; Индекс координаты символа хвоста
        mov     direction, 0100h; direction для управления головой
        mov     game_in_progress, 1
		jmp aftermiddle
		middle:
			jmp game_main
		aftermiddle:
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
		mov cx, apple_count
		add_food_loop:
			push cx
			call add_food
			pop cx
			loop add_food_loop
		mov cx, wall_count
		add_wall_loop:
			push cx
			call add_wall
			pop cx
			loop add_wall_loop
        ; Бортик и змейка
        call    draw_border
        mov     al, color_snake
        mov     cx, 2
        mov     dx, 0
        draw_snake_loop:
            call    draw_snake_pixel
            loop    draw_snake_loop

    game_main:
        cmp     ticks, 3
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

            cmp     al, 1h          ; Если это отжатие клавиши Space
            je      KP_esc          ; вернемся в меню
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
            KP_esc:
                popa
                ret
            KP_end:
                mov     direction, cx
        popa

    change_head:
        mov     dx, [snake+si]      ;Берем координату головы из памяти
        xor     cx, cx
        mov     cl, dh              ; cx - x
        xor     dh, dh              ; dx - y
		mov     al, color_snake
        call    draw_snake_pixel
		mov     dx, [snake+si]      ;Берем координату головы из памяти
        add     dx, direction       ;Изменяем координаты в зависимости от направления
        inc     si
        inc     si
        and     si, 0FFh
        mov     [snake+si], dx      ;Заносим в память новую координату головы змеи
        xor     cx, cx
        mov     cl, dh              ; cx - x
        xor     dh, dh              ; dx - y
        call    check_head_position ; Проверки на столкновения со стенами, собой

        pushf
            cmp     game_over, 1
            jne     draw_head
            popf
			dec 	lifes
			cmp		lifes, 0
			jne 	new_game
            mov     game_in_progress, 0
            ret
			new_game:
			cmp lifes, 2
			je draw2lifes
			cmp lifes, 1
			je draw1lifes
			jmp reload_game
			draw2lifes:
			mov str_tutor_game[40], ' '
			jmp reload_game
			draw1lifes:
			mov str_tutor_game[39], ' '
			jmp reload_game
			reload_game:
			mov game_over, 0
			jmp game_init
            draw_head:
            ; Когда позиция проверена, можно нарисовать там голову  
			mov     dx, [snake+si]      ;Берем координату головы из памяти
			xor     cx, cx
			mov     cl, dh              ; cx - x
			xor     dh, dh              ; dx - y
            mov     al, color_snake
			inc 	al
            call    draw_snake_pixel
        popf

        ; Стоит ли стирать хвост?
        jnc     erase_tail
		push 	bx
		mov 	bx, di
		add 	bx, 20
		cmp		bx, si
		jge		dont_drop_tail
		call drop_tail
		dont_drop_tail:
		pop		bx
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

	call game
	cmp  game_over, 1
	jne @terminate
	call show_game_over
	@terminate:
	call terminate_program
    ret

end     @entry