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

include SexyPrnt.inc			; >= 1.3
include CmdArg.inc				; >= 0.9.5
include	ChVideo.inc

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


@start:									; Сюда передается управление в самом начале

	; Чтение аргументов командной строки
	read_arg:
		mov		si, offset cmd_line
		mov		ah, 10h
		call	get_cmd_arg
		jc		@illegal_key

		cmp		cmd_arg_number, 4		; Если есть третий аргумент
		je		@process_args_delay


		cmp		cmd_arg_number, 0		; Первый аргумент может быть ключом
		jg		allow_only_integer		; остальные - нет

		cmp		al, 2					; Если аргумент является ключом -x /x
		je		found_slash_or_minus

	 allow_only_integer:
		cmp		al, 1					; не числом
		jne		@illegal_key

		; У нас число, сохраним его
		mov		si, offset args
		mov		cx, cmd_arg_number
		add		si, cx
		mov		[si], bx

		add		cmd_arg_number, 2
		xor		cx, cx
		mov		cl, [cmd_len]			; cx <- Новая длина командной строки
		test	cx, cx					; Если не ноль, получить еще аргумент
	jnz		read_arg
	
	jmp		@process_args

	@process_args_delay:
		mov		dx, offset press_any
		call print_dx_string
		mov		ah, 07h
		int 	21h

	@process_args:

		; Изменим видео-режим и страницу
		mov		ax, args[0]
		call	change_video_mode
		jc		@illegal_key
		mov		ax, args[2]
		call	change_display_page
		jc		@illegal_key

		; Уведомим об этом
		mov		dx, offset change_video_msg
		call	print_dx_string
		mov		ax, args[0]
		call	print_int2
		call	CRLF

		mov		dx, offset change_page_msg
		call	print_dx_string
		mov		ax, args[2]
		call	print_int2
		call	CRLF
	
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
usage			db		'Простая учебная программа для смены видео-режима и страницы',	0Dh,0Ah
				db		'при помощи функций 00h,05h,0Fh прерывания BIOS 10h',	0Dh,0Ah,0Dh,0Ah
				db		'Использование: video \1      \2         [\3]',					0Dh,0Ah
				db		'               video <режим> <страница> [<символ>]',	0Dh,0Ah,0Dh,0Ah
				db		'Параметры:',													0Dh,0Ah
				db		'  \1           Номер видео-режима [0,1,2,3,4,5,6,7,D,E,F,10]',	0Dh,0Ah
				db		'  \2           Страница дисплея',								0Dh,0Ah
				db		'  \3           При наличии ждёт нажатия клавиши, затем',		0Dh,0Ah
				db		'               возвращает экран в исходное состояние, выходит',0Dh,0Ah
				db		'  -h [/h]      Вывести это сообщение со справкой',				0Dh,0Ah
				db		'  -s [/s]      Показать информацию о текущем видео-режиме',	0Dh,0Ah
				db		0Dh,0Ah,'$'

; Тексты, которые выдает программа при успешном выполнении:
status_msg		db		'Статус видео-режима'										,0Dh,0Ah,'$'
current_mode	db		'    Текущий режим:                           '						,'$'
current_lines	db		'    Число текстовых колонок на экране:       '						,'$'
current_page	db		'    Текущий номер активной страницы дисплея: '						,'$'
change_video_msg db		'Изменение видео-режима на '										,'$'
change_page_msg	db		'Изменение отображаемой страницы на '								,'$'
press_any		db		'Нажмите любую клавишу для продолжения...'					,0Dh,0Ah,'$'

; Тексты, которые выдает программа при ошибках:
illegal_key_err	db		'Ошибка! Указан неверный ключ при запуске.'			,0Dh,0Ah,0Dh,0Ah,'$'

cmd_arg_number	dw		0
args			dw		?, ?

end @entry
