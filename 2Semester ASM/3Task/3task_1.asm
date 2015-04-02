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
	cmd_len		label byte		; Длина аргументов командной строки
	cmd_line	label byte		; Аргументы командной строки
ORG 100h

@entry:
		jmp			@start

include SexyPrnt.inc
include CmdArg.inc
include	ChVideo.inc

@illegal_key:
		mov			dx, offset illegal_key_err
		call		print_dx_string
		ret


@start:									; Сюда передается управление в самом начале

	; Первое число
		mov		si, offset cmd_line
		mov		ah, 10h
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
		mov		ah, 10h
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

		; Изменим видео-режим и страницу
		mov		ax, cmd_arg1
		call	change_video_mode
		jc		@illegal_key
		mov		ax, cmd_arg2
		call	change_display_page
		jc		@illegal_key

		; Уведомим об этом
		mov		dx, offset change_video_msg
		call	print_dx_string
		mov		ax, cmd_arg1
		call	print_int2
		call	CRLF

		mov		dx, offset change_page_msg
		call	print_dx_string
		mov		ax, cmd_arg2
		call	print_int2
		call	CRLF
	
	ret

illegal_key_err	db		'Ошибка! Указан неверный ключ при запуске. См. справку',		0Dh,0Ah
				db		'Простая учебная программа для смены видео-режима и страницы',	0Dh,0Ah
				db		'при помощи функций 00h,05h,0Fh прерывания BIOS 10h',	0Dh,0Ah,0Dh,0Ah
				db		'Использование: video \1      \2         [\3]',					0Dh,0Ah
				db		'               video <режим> <страница> [<символ>]',	0Dh,0Ah,0Dh,0Ah
				db		'Параметры:',													0Dh,0Ah
				db		'  \1           Номер видео-режима [0,1,2,3,4,5,6,7,D,E,F,10]',	0Dh,0Ah
				db		'  \2           Страница дисплея [0 для всех,1-7 опционально]',	0Dh,0Ah
				db		'  \3           При наличии ждёт нажатия клавиши, затем',		0Dh,0Ah
				db		'               возвращает экран в исходное состояние, выходит',0Dh,0Ah
				db		'  -h [/h]      Вывести это сообщение со справкой',				0Dh,0Ah
				db		'  -s [/s]      Показать информацию о текущем видео-режиме',	0Dh,0Ah
				db		0Dh,0Ah,'$'

change_video_msg db		'Новый видео-режим: '										,'$'
change_page_msg	db		'Новая отображаемая страница: '								,'$'
press_any		db		'Нажмите любую клавишу для продолжения...'					,0Dh,0Ah,'$'

cmd_arg1		dw		?
cmd_arg2		dw		?

end @entry
