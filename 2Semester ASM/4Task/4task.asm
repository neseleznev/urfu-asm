; Никита Селезнев, ФИИТ-301, 2015
;
; Таблица символов (домашка от 1 апреля):
; ascii.com (\d) (\d)
; 
; Нарисовать для любого текстового видео-режима и страницы
; красивую квадратную таблицу символов по центру экрана
;  ____________
; |_|0_1_2_._F_|
; |0|          |
; |1|          |
; |.|  ASCIIs  |
; |F|__________|
.286
.model tiny
.code

ORG 2Ch
	env_ptr		label word		; Определить метку для доступа к слову в PSP, которое
								; указывает на сегмент, содержащий блок операционной среды
								; (обычно освобождается для создания компактного резидента)
ORG 80h
	cmd_len		label byte		; Длина аргументов командной строки
	cmd_line	label byte		; Аргументы командной строки
ORG 100h

@entry:
		jmp			@start

include SexyPrnt.inc
include CmdArg.inc


change_video_mode proc			; Изменение видео-режима
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
		clc
		xor		ah, ah
		int		10h
	CVM_exit:
		popa
		ret
change_video_mode endp

change_display_page proc		; Изменение активной страницы дисплея
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

		mov			bl, al
		mov			ah, 0Fh				; Читать текущий видео-режим
		int			10h					; Вход:  нет
										; Выход: al = текущий режим (см. функцию 00h)
										;        ah = число текстовых колонок на экране
										;        bh = номер активной страницы дисплея

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
		clc
		mov		ah, 05h
		mov		al, bl
		int		10h
	CDP_exit:
		popa
		ret
change_display_page endp


write_to_video proc
	push cx
		mov		cx, 40			; Ширина таблицы 40
		loop1:
			mov		dl, [si]
			mov		es:[di], dl
			inc		si
			add		di, 2
		loop	loop1
	pop	cx
	ret
write_to_video endp


int_to_char proc
	; Вход:      cl - число
	; Результат: dl - символ
		mov		dl, cl
		cmp		dl, 9
		jg		ItC_HEX
		add		dl, '0'
		ret
	ItC_HEX:
		sub		dl, 10
		add		dl, 'A'
		ret
int_to_char endp


draw_ascii_table proc			; Отрисовка ASCII-таблицы
	; Вход:       нет
	; Результат:
	;     (Флаг CF = 1, если текущий видео-режим не текстовый)
		pusha

		mov		ah, 0Fh					; Читать текущий видео-режим
		int		10h						; Вход:  нет
										; Выход: al = текущий режим (см. функцию 00h)
										;        ah = число текстовых колонок на экране
										;        bh = номер активной страницы дисплея
		cmp		al, 7
		mov		dx, 0B000h				; Адрес сегмента видео-буфера 7 режима
		je		DAT_draw_ascii
		cmp		al, 3
		jle		DAT_noerror
		stc
		popa
		ret
	
	DAT_noerror:
		mov 	dx, 0B800h				; Адрес сегмента видео-буфера 0,1,2,3 режимов

	DAT_draw_ascii:

		mov		es, dx					; Установим сегмент видео-буфера

		; Переключимся на нужную страницу
		cmp		al, 1
		jle		DAT_shift_800
		shl		bh, 4					; Для 2-3,7 (25x80) сдвиги по 1000h
		jmp		DAT_shifted
		DAT_shift_800:
			shl		bh, 3				; Для 0-1 (25x40) сдвиги по 800h,
		DAT_shifted:
			xor		bl, bl

		; Переключим страницу +(800h или 1000h)*(номер стр)
		mov		di, bx					; Установим адрес назначения в (B800 или B000):di

		; Пропустим первые три строки (сост.режима, страницы, текст this_is_ascii)
		xor		ch, ch
		mov		cl, ah					; cx <- число колонок (т.е. ширина строки экрана)
		imul	cx, 6					; (по 2 байта)*(3 строки) = 6
		add		di, cx

		; Вычислим отступ до таблицы (предп., что ширина четная)
		mov		al, ah
		xor		ah, ah
		sub		ax, 40					; Из числа колонок вычтем ширину (40 <=)
		;shr		ah, 1				; И поделим на два (затем умножим на два,
		;shl		ah, 1				; т.к. под одно знако-место 2 байта)

		; И сдвинем до начала таблицы
		add		di, ax

		mov		si, offset line_1		; Откуда читаем
		call	write_to_video

		add		di, ax					; К началу таблицы на след.строке
		add		di, ax
		mov		si, offset line_2		; Откуда читаем
		call	write_to_video

		add		di, ax					; К началу таблицы на след.строке
		add		di, ax
		mov		si, offset line_3		; Откуда читаем
		call	write_to_video

		mov		cx, 0
		DAT_lines_loop:
			add		di, ax					; К началу таблицы на след.строке
			add		di, ax
			mov		si, offset line_2		; Напечатаем пустую строку таблицы с границами
			call	write_to_video

			push	di						; А потом будем исправлять
				sub		di, 40 *2			; Назад на ширину таблицы (40)
				add		di, 2  *2			; Сдвинемся на левую колонку через "║ "
				call	int_to_char
				mov		es:[di], dl			; Левая колонка (0...F)
				add		di, 4  *2			; Сдвинемся на поле боя через "n ║ "
				
				mov		dx, 0
				DAT_column_loop:
					mov		bx, cx
					shl		bl, 4			; bx = cx * 10h (номер строки)
					add		bl, dl			;         + dx  (номер столбца)
					
					mov		bh, 00Ch	; Старший байт (аттрибуты)(цвет) = (без)(Красный цвет)
										; P.S. (08Сh прикольный)
					mov		es:[di], bx		; Установим знако-место
					add		di, 2 *2		; Сдвинемся к следующему через "с "

					inc		dx
					cmp		dx, 16
					jl		DAT_column_loop
			pop		di

			inc		cx
			cmp		cl, 16
			jl		DAT_lines_loop

		add		di, ax
		add		di, ax
		mov		si, offset line_last		; Откуда читаем
		call	write_to_video

		clc
		popa
		ret
draw_ascii_table endp

@lbl_status:
		mov			dx, offset status_msg
		call		print_dx_string

		mov			ah, 0Fh				; Читать текущий видео-режим
		int			10h					; Вход:  нет
										; Выход: al = текущий режим (см. функцию 00h)
										;        ah = число текстовых колонок на экране
										;        bh = номер активной страницы дисплея
		mov			cx, ax
		mov			dx, offset current_mode
		call		print_dx_string
		xor			ah, ah				; ax = al
		call		print_int2
		call		CRLF

		mov			dx, offset current_lines
		call		print_dx_string
		mov			al, ch				; ax = ah
		call		print_int2
		call		CRLF

		mov			dx, offset current_page
		call		print_dx_string
		mov			al, bh				; ax = bh
		call		print_int2
		call		CRLF

		ret

@illegal_key:
		mov			dx, offset illegal_key_err
		call		print_dx_string

@lbl_help:
		mov			dx, offset usage
		call		print_dx_string
		ret


@start:							; Сюда передается управление в самом начале

	; Если нет аргументов - рисуем (если возможно) для текущего видео-режима
		cmp		[cmd_len], 0
		jz		@no_args

	; Первый аргумент - видео-режим
		mov		si, offset cmd_line
		mov		di, offset cmd_arg_buffer
		call	get_cmd_arg
		jc		@illegal_key

		cmp		al, 2					; Если аргумент является ключом -x /x
		je		found_slash_or_minus
		cmp		al, 1					; Если аргумент является не числом
		jne		@illegal_key			; - ошибка
		mov		arg1, bx				; Если аргумент является числом, сохраним

	; Второй аргумент - отображаемая страница
		mov		si, offset cmd_line
		mov		di, offset cmd_arg_buffer
		call	get_cmd_arg
		jc		@illegal_key

		cmp		al, 1					; Если аргумент является не числом
		jne		@illegal_key			; - ошибка
		mov		arg2, bx				; Если аргумент является числом, сохраним

		jmp		@process_args

	@no_args:
		mov		ah, 0Fh					; Читать текущий видео-режим
		int		10h						; Вход:  нет
										; Выход: al = текущий режим (см. функцию 00h)
		xor		ah, ah					;        ah = число текстовых колонок на экране
		mov		arg1, ax				;        bh = номер активной страницы дисплея
		mov		al, bh
		mov		arg2, ax

	@process_args:
		; Изменим видео-режим и страницу
		mov		ax, arg1
		call	change_video_mode
		jc		@illegal_key
		mov		ax, arg2
		call	change_display_page
		jc		@illegal_key

		; Уведомим об этом
		mov		dx, offset change_video_msg
		call	print_dx_string
		mov		ax, arg1
		call	print_int2
		call	CRLF

		mov		dx, offset change_page_msg
		call	print_dx_string
		mov		ax, arg2
		call	print_int2
		call	CRLF
		
		; Нарисуем красивую ASCII-таблицу по центру экрана
		mov		dx, offset this_is_ascii
		call	print_dx_string

		call	draw_ascii_table
		jc		illegal_video_mode

		mov		cx, 19
		clear_lines_for_table:
		call	CRLF
		loop	clear_lines_for_table

		ret

	illegal_video_mode:
		mov		dx, offset illegal_video_mode_err
		call	print_dx_string
		ret

	found_slash_or_minus:				; Агрумент начинается с / или -
		cld								; Определим, какая буква идет после
		mov		cl, 3					; Ключей 2, будем искать символ в
		mov		al, bl					; строке keys. Если cx станет 0
		lea 	di, keys 				; значит, не нашли вхождение
		repne	scasb					; если 1 - lbls[1*2] help
		shl		cx, 1					; если 2 - lbls[2*2] status
		mov		di, cx					; и т.д.
		jmp		lbls[di]


; Ключи и соответствующие метки
keys			db		'sh'
lbls			dw		@illegal_key,	@lbl_help,		@lbl_status

; Текст, который выдает программа с ключом /h:
usage			db		'Учебная программа для отрисовки таблиц ASCII-символов во всех',	0Dh,0Ah
				db		'текстовых видео-режимах и доспустимых страницах по центру экрана.',0Dh,0Ah,0Dh,0Ah
				db		'Использование: ascii [Без аргументов    ] - в текущем режиме',		0Dh,0Ah	
				db		'               ascii [\1      \2        ] - сменить и нарисовать',	0Dh,0Ah,0Dh,0Ah
				db		'Параметры:',														0Dh,0Ah
				db		'  \1           Номер текстового видео-режима   [0,1,  2,3,  7]',	0Dh,0Ah
				db		'  \2           Страница дисплея соответственно [0-7,  0-3,  0]',	0Dh,0Ah
				db		'  -h [/h]      Вывести это сообщение со справкой',					0Dh,0Ah
				db		'  -s [/s]      Показать информацию о текущем видео-режиме',		0Dh,0Ah
				db		0Dh,0Ah,'$'

; Тексты, которые выдает программа при успешном выполнении:
status_msg		db		'Статус видео-режима'										,0Dh,0Ah,'$'
current_mode	db		'    Текущий режим:                           '						,'$'
current_lines	db		'    Число текстовых колонок на экране:       '						,'$'
current_page	db		'    Текущий номер активной страницы дисплея: '						,'$'
change_video_msg	db	'Текущий видео-режим '												,'$'
change_page_msg	db		'Текущая отображаемая страница '									,'$'
this_is_ascii	db		'Таблица ASCII-символов:'									,0Dh,0Ah,'$'
press_any		db		'Нажмите любую клавишу для продолжения...'					,0Dh,0Ah,'$'

; Тексты, которые выдает программа при ошибках:
illegal_key_err	db		'Ошибка! Указан неверный ключ при запуске.'			,0Dh,0Ah,0Dh,0Ah,'$'
illegal_video_mode_err db 'Error! ASCII-chart available only for text video-modes',	 0Dh,0Ah,'$'

arg1			dw		?
arg2			dw		?
cmd_arg_buffer	db		256 dup (?)

line_1			db		"╔═══╦═════════════════════════════════╗ "
line_2			db		"║ \ ║ 0 1 2 3 4 5 6 7 8 9 A B C D E F ║ "
line_3			db		"╠═══╬═════════════════════════════════╣ "
line_last		db		"╚═══╩═════════════════════════════════╝ "


end @entry
