; Никита Селезнев, ФИИТ-301, 2015
;
; Видео-режимы (домашка от 18 марта):
; program.com (\d) (\d) (\-)?/
; \1 = video_mode
; \2 = display_page
; Программа устанавливает видеорежим и страницу согласно параметрам, при наличии \3 ждет,
; пока пользователь нажмет клавишу, затем возвращает экран в исходное состояние и выходит.
; Если \3 отсутствует, то устанавливает \1, \2 и выходит.
; Использовать функции 00h, 05h, 0Fh int 10h, разобрать самостоятельно.
.286
.model tiny
.code

ORG 80h
	cmd_len		label byte				; Длина аргументов командной строки
	cmd_line	label byte				; Аргументы командной строки
ORG 100h

@entry:
		jmp			@start

change_video_mode proc					; Изменение видео-режима
	; 00h уст.видео режим. Очистить экран, установить поля BIOS, установить режим.
	; Вход:  AL = режим
	;       AL  Тип      формат   цвета          адаптер  адрес монитор
	;       === =======  =======  =============  =======  ====  =================
	;        0  текст    40x25    16/8 полутона  CGA,EGA  b800  Composite
	;        1  текст    40x25    16/8           CGA,EGA  b800  Comp,RGB,Enhanced
	;        2  текст    80x25    16/8 полутона  CGA,EGA  b800  Composite
	;        3  текст    80x25    16/8           CGA,EGA  b800  Comp,RGB,Enhanced
	;        4  графика  320x200  4              CGA,EGA  b800  Comp,RGB,Enhanced
	;        5  графика  320x200  4 полутона     CGA,EGA  b800  Composite
	;        6  графика  640x200  2              CGA,EGA  b800  Comp,RGB,Enhanced
	;        7  текст    80x25    3 (b/w/bold)   MA,EGA   b000  TTL Monochrome
	;       0Dh графика  320x200  16             EGA      A000  RGB,Enhanced
	;       0Eh графика  640x200  16             EGA      A000  RGB,Enhanced
	;       0Fh графика  640x350  3 (b/w/bold)   EGA      A000  Enhanced,TTL Mono
	;       10h графика  640x350  4 или 16       EGA      A000  Enhanced
	; Результат:
	;     (Флаг CF = 1, если такого нет)
		pusha

		; Существует ли такой видео-режим?
		cmp		al, 10h
		jg		CVM_false
		cmp		al, 8
		jl 		CVM_true
		cmp		al, 0Ch
		jg		CVM_true

	CVM_false:
		stc
		jmp		CVM_exit
	CVM_true:
		xor		ah, ah
		int		10h

		mov		dx, offset change_msg
		call	print_dx_string
		call	print_int2
		call	CRLF
	CVM_exit:
		popa
		ret
change_video_mode endp


change_display_page proc				; Изменение активной страницы дисплея
	; 05h выбрать активную страницу дисплея
    ; Вход:  AL = номер страницы (большинство программ использует страницу 0)
	; Допустимые номера для режимов:
	;       Режим  Номера
	;       ====== =======
	;        0      0-7
	;        1      0-7
	;        2      0-3
	;        3      0-3
	;        4       0
	;        5       0
	;        6       0
	;        7       0
	;       0Dh     0-7
	;       0Eh     0-3
	;       0Fh     0-1
	;       10h     0-1
	; Результат:
	;     (Флаг CF = 1, если номер недопустим)
		pusha

		test	al, al			; 0 доступна всем
		jz		CDP_true

		cmp		al, 1			; 1 страница
		jne		_CDP_1

		cmp		al, 4
		jl		CDP_true
		cmp		al, 7
		jg		CDP_true
		jmp		CDP_false

	_CDP_1:						; 2-3 страницы
		cmp		al, 3
		jg		_CDP_2

		cmp		al, 4
		jl		CDP_true
		cmp		al, 0Dh
		je		CDP_true
		cmp		al, 0Dh
		je		CDP_true
		jmp		CDP_false

	_CDP_2:						; 4-7 страницы
		cmp		al, 7
		jg		CDP_false

		cmp		al, 2
		jl		CDP_true
		cmp		al, 0Dh
		je		CDP_true
		jmp		CDP_false

	CDP_false:
		stc
		jmp		CDP_exit
	CDP_true:
		mov		ah, 05h
		int		10h

	CDP_done:
		mov		dx, offset change_page_msg
		call	print_dx_string
		xor		ah, ah
		call	print_int2
		call	CRLF
	CDP_exit:
		popa
		ret
change_display_page endp


; Вспомогательные
print_int2 proc							; Печать двухбайтного числа в десятичном виде
	; 
		pusha						; Вход:
		test		ax, ax			;     ax = число
		jns			PI2_positive

		mov			cx, ax
		mov			ah, 02h
		mov			dl, '-'
		int			21h
		mov			ax, cx
		neg			ax
	PI2_positive:
		xor			cx, cx
		mov			bx, 10
	PI2_bite_off:
		xor			dx, dx
		div			bx				; ax = ax / 10
		push		dx				; dx = ax % 10
		inc			cx
		test		ax, ax
		jnz			PI2_bite_off

		mov			ah, 02h

	PI2_print_digit:
		pop			dx
		add			dl, '0'
		int			21h
	loop		PI2_print_digit

		popa
		ret
print_int2 endp


print_dx_string proc					; Печать строки
		push ax						; Вход:
		mov			ah, 09h			;      dx = адрес строки
		int			21h
		pop ax
		ret
print_dx_string endp


CRLF proc
		pusha

		mov			dx, 13
		mov			ax, 0200h
		int			21h
		mov			dx, 10
		mov			ax, 0200h
		int			21h

		popa
		ret
CRLF endp


char_to_int proc						; Перевод символа в число
	; Вход:
	;     ah = Система счисления (<- [2...16])
	;     al = Символ
	; Результат:
	;     al = число [0...ah-1]
	; Портит:
	;     ax
	; Ошибка:
	;     Флаг CF = 1
	;     Некорректный символ или основание системы счисления
		cmp		ah, 2
		jl		AI_incorrect
		cmp		ah, 16
		jg		AI_incorrect

		cmp		al, 48
		jl	AI_incorrect
		sub		al, 48	; '0' -> 0
		cmp		al, 10
		jl	AI_under10
		cmp		al, 17 	; 'A' -> 17
		jl	AI_incorrect
		cmp		al, 22	; 'F' -> 22
		jg	AI_incorrect
		sub		al, 7

	AI_under10:
		cmp		al, ah
		jge		AI_incorrect

	AI_success:
		clc
		ret
	AI_incorrect:
		stc
		ret	
char_to_int endp


parse_first_arg:
	; cmd_line должна быть (" xx y" или " x y") и, возможно, ( + " z...")
	; Если cmd_len < 4, goto @illegal_key
		cmp		cmd_len, 4
		jl		@illegal_key

		xor		cx, cx

	; Если cmd_line[2] == 1, [3] == 0, то cmd_arg1=10h
		cmp		cmd_line[3], '0'
		jne		_char2_not_zero
		cmp		cmd_line[2], '1'
		jne		@illegal_key
		mov		cmd_arg1, 10h
		inc		cx						; Если первый аргумент длинный,
		jmp		parse_second_arg				; cx = 1

	; Если cmd_line[3] == " "
	_char2_not_zero:
		cmp		cmd_line[3], ' '
		jne		@illegal_key
		
	; И cmd_line[1] - число
		mov		ah, 16
		mov		al, cmd_line[2]
		call	char_to_int
		jc		@illegal_key
		
		xor		ah, ah
		mov		cmd_arg1, ax
	jmp	__1


parse_second_arg:
	; Если cmd_line[4] (или [5], если первое было 10h) - число
		mov		ah, 16
				mov		di,	cx
				add		di, 4
		mov		al,	cmd_line[di]
		call	char_to_int
		jc		@illegal_key

		xor		ah, ah
		mov		cmd_arg2, ax

	jmp __2


@illegal_key:
		mov			dx, offset illegal_key_err
		call		print_dx_string
		ret


@start:									; Сюда передается управление в самом начале

		jmp parse_first_arg
	__1:
		jmp	parse_second_arg
	__2:

	; Если cmd_line[5] (или [6], если первое было 10h) == " ", значит есть третий аргумент
	third_arg:
		; А следующий - пробел или совсем нет
		add		cx, 5
		cmp		cmd_len, cl
		jl		@process_args
				mov		di,	cx
		cmp		cmd_line[di], ' '
		jne		@illegal_key


	; TODO переделать, там как-то по-другому было
	; А если ещё есть, ждем нажатия клавиши
		mov		dx, offset press_any
		call	print_dx_string
		mov		ah, 07h
		int 	21h

	; Обработка двух чисел
	@process_args:
		mov		ax, cmd_arg1
		call	change_video_mode
		jc		@illegal_key
		mov		ax, cmd_arg2
		call	change_display_page
		jc		@illegal_key
	
	ret

illegal_key_err	db		'Ошибка! Указан неверный ключ при запуске. См. справку',		0Dh,0Ah
				db		'Простая учебная программа для смены видео-режима и страницы',	0Dh,0Ah
				db		'при помощи функций 00h,05h,0Fh прерывания BIOS 10h',	0Dh,0Ah,0Dh,0Ah
				db		'Использование: video \1      \2         [\3]',					0Dh,0Ah
				db		'               video <режим> <страница> [<символ>]',	0Dh,0Ah,0Dh,0Ah
				db		'Параметры:',													0Dh,0Ah
				db		'  \1           Номер видео-режима [0,1,2,3,4,5,6,7,D,E,F,10]',	0Dh,0Ah
				db		'  \2           Страница дисплея [0 для всех,1-7 опционально]', 0Dh,0Ah
				db		'  \3           При наличии ждёт нажатия клавиши, затем',		0Dh,0Ah
				db		'               возвращает экран в исходное состояние, выходит',0Dh,0Ah
				db		0Dh,0Ah,'$'

change_msg		db		'Новый видео-режим: '										,'$'
change_page_msg	db		'Новая отображаемая страница: '								,'$'
press_any		db		'Нажмите любую клавишу для продолжения...'					,0Dh,0Ah,'$'

cmd_arg1		dw		?
cmd_arg2		dw		?

end @entry
