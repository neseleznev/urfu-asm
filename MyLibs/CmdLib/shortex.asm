; Автор: Никита Селезнев, УрФУ, ФИИТ-301, 2015
;
; Короткий пример использования библиотеки cmdarg.inc
;     shortex.com   100
;     shortex.com  -xx
;     shortex.com  -a
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

@key_help:
	mov		dx, offset usage
	call	print_dx_string
	ret

@key_author:
	mov		dx, offset author
	call	print_dx_string
	ret


@start:
	mov		si, offset cmd_line
	mov		di, offset cmd_arg
	call	get_cmd_arg
	jc		@key_error

	; Если очередной аргумент является
	cmp		al, 1					; - Числом
	je		@integer_arg
	cmp		al, 2					; - Ключом -x /x
	je		@short_key_arg

	@key_error:
		mov		dx, offset error_msg
		call	print_dx_string
		jmp		@key_help
		ret

	@integer_arg:
		; bx - число, di - строка, dx - её длина
		mov		dx, offset int_msg1
		call	print_dx_string
		
		mov		ax, bx				; Само число
		call	print_int2_HEX
		mov		dx, offset int_msg2
		call	print_dx_string
		call	print_int2
		ret

	@short_key_arg:
		; bl - символ, di - строка, dx - её длина
		; Пример обработки ключей (аргумент начинается с / или -)
		cld							; Определим, какая буква идет после
		mov		cl, 3				; Ключей 2, будем искать символ в
		mov		al, bl				; строке keys. Если cx станет 0
		lea 	di, keys 			; значит, не нашли вхождение
		repne	scasb				; если 1 - lbls[1*2] help
		shl		cx, 1				; если 2 - lbls[2*2] author
		mov		di, cx				; и т.д.
		jmp		lbls[di]


keys		db		'ah'
lbls		dw		@key_error, @key_help, @key_author

usage		db		'Короткий пример работы с аргументами командной строки',	0Dh,0Ah
			db		'с помощью библиотеки cmdarg.inc',							0Dh,0Ah
			db		'Перевод шестнадцатеричного числа в десятичное',	0Dh,0Ah,0Dh,0Ah
			db		'Использование: shortex.com N',								0Dh,0Ah
			db		'               где N - шестнадцатеричное число (A0).',		0Dh,0Ah
			db		'Параметры:     -h помощь, -a автор',						0Dh,0Ah,'$'
author		db		'Автор библиотеки cmdarg и примера:',						0Dh,0Ah
			db		'       Студент 3 курса ИМКН УрФУ группы ФИИТ-301',			0Dh,0Ah
			db		'       Селезнев Никита.',									0Dh,0Ah
			db		'Екатеринбург, 2015 год.',									0Dh,0Ah
			db		'Пользуйтесь на здоровье!',									0Dh,0Ah,'$'
int_msg1	db		'Десятичная форма числа ',											'$'
int_msg2	db		': ',																'$'
error_msg	db		'Ошибка! Справка:',											0Dh,0Ah,'$'
cmd_arg		db		256 dup (?)

end @entry