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

include SexyPrnt.inc
include CmdArg.inc


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

		test	bl, bl			; 0 доступна всем
		jz		CDP_true

		cmp		bl, 1			; 1 страница
		jne		_CDP_1

		cmp		al, 4
		jl		CDP_true
		cmp		al, 7
		jg		CDP_true
		jmp		CDP_false

	_CDP_1:						; 2-3 страницы
		cmp		bl, 3
		jg		_CDP_2

		cmp		al, 4
		jl		CDP_true
		cmp		al, 0Dh
		je		CDP_true
		cmp		al, 0Dh
		je		CDP_true
		jmp		CDP_false

	_CDP_2:						; 4-7 страницы
		cmp		bl, 7
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
		mov		al, bl
		int		10h

	CDP_done:
		mov		dx, offset change_page_msg
		call	print_dx_string
		xor		ah, ah
		mov		al, bl
		call	print_int2
		call	CRLF
	CDP_exit:
		popa
		ret
change_display_page endp


@illegal_key:
		mov			dx, offset illegal_key_err
		call		print_dx_string
		ret


@start:									; Сюда передается управление в самом начале

	; Первое число
		mov		si, offset cmd_line
		mov		di, offset cmd_arg
		call	get_cmd_arg
		jc		@illegal_key

		cmp		al, 1
		jne		@illegal_key			; Если это не число - ошибка

		; У нас число, сохраним его
		mov		cmd_arg1, bx

		xor		cx, cx
		mov		cl, [cmd_len]			; cx <- Новая длина командной строки
		test	cx, cx					; Если ноль, ошибка, нам нужен еще один аргумент
		jz		@illegal_key

	; Второе число
		mov		si, offset cmd_line
		mov		di, offset cmd_arg
		call	get_cmd_arg
		jc		@illegal_key

		cmp		al, 1
		jne		@illegal_key			; Если это не число - ошибка

		; У нас число, сохраним его
		mov		cmd_arg2, bx

		xor		cx, cx
		mov		cl, [cmd_len]			; cx <- Новая длина командной строки
		test	cx, cx					; Если ноль, значит аргументов больше нет,
		jz		@process_args 			; пора обрабатывать те, что насобирали

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
				db		'  -h [/h]      Вывести это сообщение со справкой',				0Dh,0Ah
				db		'  -s [/s]      Показать информацию о текущем видео-режиме',	0Dh,0Ah
				db		0Dh,0Ah,'$'

change_msg		db		'Новый видео-режим: '										,'$'
change_page_msg	db		'Новая отображаемая страница: '								,'$'
press_any		db		'Нажмите любую клавишу для продолжения...'					,0Dh,0Ah,'$'

cmd_arg1		dw		?
cmd_arg2		dw		?
cmd_arg			db		256 dup (?)

end @entry
