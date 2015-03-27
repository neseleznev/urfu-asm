; Автор: Никита Селезнев, УрФУ, ФИИТ-301, 2015
;
; Иллюстративный пример использования библиотеки cmdarg.inc
; Скомпилируй и запусти:
;     cmdarg.com   hello  1 F   10  /x  /xyz -a
;

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


f_string_arg proc
		mov		dx, offset string_msg
		call	print_dx_string
		mov		dx, di				; Сама строка
		call	print_dx_string
		call	CRLF
		ret
f_string_arg endp

f_integer_arg proc
		push	dx
		mov		dx, offset integer_msg
		call	print_dx_string
		pop		dx
		
		mov		ax, bx				; Само число
		call	print_int2

		call	print_open_bracket
		mov		ax, dx				; Его длина
		call	print_int2
		call	print_space
		mov		dx, di				; Строковое представление
		call	print_dx_string
		call	print_close_bracket
		call	CRLF
		ret
f_integer_arg endp

f_short_key_arg proc
		mov		dx, offset short_key_msg
		call	print_dx_string
		mov		ah, 02h
		mov		dl, bl				; Сам ключ
		int		21h
		mov		dx, offset attempt_msg
		call	print_dx_string
		ret
f_short_key_arg endp

f_long_key_arg proc
		mov		dx, offset long_key_msg
		call	print_dx_string
		mov		dx, di				; Сам ключ
		call	print_dx_string
		mov		dx, offset attempt_msg
		call	print_dx_string
		ret
f_long_key_arg endp

f_error_arg proc
		cmp		bl, 0
		je		@_empty_arg

		mov		dx, offset error_msg1
		call	print_dx_string
		mov		dx, di
		call	print_dx_string
		mov		dx, offset error_msg2
		call	print_dx_string

		cmp		bl, 1
		je		@_oveflow_arg
		cmp		bl, 2
		je		@_other_arg

		mov		dx, offset error_unknown
		jmp		error_arg_exit

	 @_empty_arg:
		ret		; Возникает только тогда, когда программа запущена без аргументов.
				; Наверняка имеет смысл вынести логику, а не выводить сообщение об
				; ошибке "00: Нет аргументов". Ведь это вовсе не ошибка ;)

	 @_oveflow_arg:
		mov		dx, offset error_overflow
		jmp		error_arg_exit

	 @_other_arg:
		mov		dx, offset error_other
		jmp		error_arg_exit

	 error_arg_exit:
		call	print_dx_string
		ret
f_error_arg endp



@start:

	read_arg:
		mov		si, offset cmd_line
		mov		di, offset cmd_arg

		call	get_cmd_arg
		jc		@error_arg

		; Если очередной аргумент является
		cmp		al, 0					; - Просто строкой
		je		@string_arg
		cmp		al, 1					; - Числом
		je		@integer_arg
		cmp		al, 2					; - Ключом -x /x
		je		@short_key_arg
		cmp		al, 3					; - Ключом--xyz /xyz
		je		@long_key_arg

		mov		bl, 255
		jmp		@error_arg

		@string_arg:
			; di - строка, dx - её длина
			call	f_string_arg
			jmp		read_next_arg

		@integer_arg:
			; bx - число, di - строка, dx - её длина
			call	f_integer_arg
			jmp		read_next_arg

		@short_key_arg:
			; bl - символ, di - строка, dx - её длина
			call	f_short_key_arg
			jmp		process_key_arg

		@long_key_arg:
			; di - строка, dx - её длина
			call	f_long_key_arg
			jmp		process_key_arg

		@error_arg:
			; di - строка, dx - её длина
			call	f_error_arg
			jmp		read_next_arg


		read_next_arg:
			xor		cx, cx
			mov		cl, [cmd_len]		; cx <- Новая длина командной строки
			test	cx, cx				; Если не ноль, получить еще аргумент
	jnz		read_arg

	jmp		goodbye

	; Пример обработки ключей (аргумент начинается с / или -)
	process_key_arg:
		cld							; Определим, какая буква идет после
		mov		cl, 3				; Ключей 2, будем искать символ в
		mov		al, bl				; строке keys. Если cx станет 0
		lea 	di, keys 			; значит, не нашли вхождение
		repne	scasb				; если 1 - lbls[1*2] help
		shl		cx, 1				; если 2 - lbls[2*2] author
		mov		di, cx				; и т.д.
		jmp		lbls[di]

	@key_illegal_key:
		mov		dx, offset illegal_key_err
		call	print_dx_string
		jmp		read_next_arg

	@key_help:
		mov		dx, offset usage
		call	print_dx_string
		jmp		read_next_arg

	@key_author:
		mov		dx, offset author
		call	print_dx_string
		jmp		read_next_arg

	goodbye:
		
		mov		dx, offset goodbye_msg
		call	print_dx_string
		ret

; Ключи и соответствующие метки
keys			db		'ah'
lbls			dw		@key_illegal_key, @key_help, @key_author

; Текст, который выдает программа при запуске с ключом:
usage			db		'Пример работы с аргументами командной строки с помощью',	0Dh,0Ah
				db		'библиотеки cmdarg.inc',									0Dh,0Ah,0Dh,0Ah
				db		'Использование: cmdarg.com [arg1] [arg2] ... [argn]',		0Dh,0Ah
				db		'               где argk - произвольный аргумент, т.е.',	0Dh,0Ah
				db		'               строка, число, короткий или длинный ключ',	0Dh,0Ah,0Dh,0Ah
				db		0Dh,0Ah,'$'
author			db		'Автор библиотеки cmdarg и примера:',						0Dh,0Ah
				db		'       Студент 3 курса ИМКН УрФУ группы ФИИТ-301',			0Dh,0Ah
				db		'       Селезнев Никита.',									0Dh,0Ah
				db		'Екатеринбург, 2015 год.',									0Dh,0Ah
				db		'Пользуйтесь на здоровье!',									0Dh,0Ah
				db		0Dh,0Ah,'$'
illegal_key_err	db		'Ошибка! Указан неверный ключ при запуске.'			,0Dh,0Ah,'$'

; Тексты, которые выдает программа при успешном выполнении:
string_msg		db		'Параметр-строка '											,'$'
integer_msg		db		'Параметр-число '											,'$'
short_key_msg	db		'Ключ-буква '												,'$'
long_key_msg	db		'Ключ-слово '												,'$'
error_msg1		db		'Ошибка в параметре "'										,'$'
error_msg2		db		'":',0Dh,0Ah,09h,09h										,'$'
error_overflow	db		'01: Число слишком большое, произошло переполнение'	,0Dh,0Ah,'$'
error_other		db		'02: Еще одна возможная ошибка аргумента'			,0Dh,0Ah,'$'
error_unknown	db		'03: Неизвестная ошибка аргумента'					,0Dh,0Ah,'$'
attempt_msg		db		'. Попытка обработать ключ...'				,0Dh,0Ah,'$'
goodbye_msg		db		'Все аргументы обработаны. Good bye!'							,'$'

cmd_arg			db		256 dup (?)

end @entry
