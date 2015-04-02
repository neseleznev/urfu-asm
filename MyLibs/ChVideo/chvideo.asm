; Никита Селезнев, ФИИТ-301, 2015
;
; Пример использования ChVideo.inc
; program.com (\d) (\d)
;     \1 = video_mode
;     \2 = display_page
; Программа устанавливает видеорежим и страницу согласно параметрам.
; Использовать функции 00h, 05h, 0Fh int 10h, разобрать самостоятельно.
; 
; P.S. Довольно муторное чтение аргументов, не обращайте внимания.
;      Сделано для избавления от зависимостей. Нужна только ChVideo.inc

.286
.model tiny
.code

ORG 80h
	cmd_len		label byte				; Длина аргументов командной строки
	cmd_line	label byte				; Аргументы командной строки
ORG 100h

@entry:
		jmp			@start

include ChVideo.inc

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

	jmp @process_args


@illegal_key:
		mov			dx, offset illegal_key_err
		call		print_dx_string
		ret


@start:									; Сюда передается управление в самом начале

		jmp parse_first_arg
	__1:
		jmp	parse_second_arg

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
				db		'Использование: video \1      \2         ',						0Dh,0Ah
				db		'               video <режим> <страница> ',				0Dh,0Ah,0Dh,0Ah
				db		'Параметры:',													0Dh,0Ah
				db		'  \1           Номер видео-режима [0,1,2,3,4,5,6,7,D,E,F,10]',	0Dh,0Ah
				db		'  \2           Страница дисплея [0 для всех,1-7 опционально]', 0Dh,0Ah
				db		0Dh,0Ah,'$'

change_video_msg db		'Новый видео-режим: '										,'$'
change_page_msg	db		'Новая отображаемая страница: '								,'$'
press_any		db		'Нажмите любую клавишу для продолжения...'					,0Dh,0Ah,'$'

cmd_arg1		dw		?
cmd_arg2		dw		?

end @entry
