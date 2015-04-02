; Автор: Никита Селезнев, ne.seleznev@gmail.com
;        УрФУ, ФИИТ-301, 2015
;
; Библиотека для работы с аргументами командной строки
; CmdArg 0.9.4 (от 03.04.2015)
;
; Для работы основной процедуры необходимо указать
;     - Адрес начала строки с аргументами
;     - Адрес начала буфера для очередного аргумента
;     - Систему счисления, если хотите аргументы-числа
;
; Результат работы процедуры:
;     - Тип аргумента
;         Строка (xyz abc)
;         Число  (1 FA 12C 10)
;         Параметр-буква (/x -x)
;         Параметр-слово (/xyz --xyz)
;     - Указатель на параметр-строку (с $ в конце)
;     - Её длина
;     - Опционально:
;         Для численного типа его значение
;         Для параметра-буквы - символ
;
; Процедура умеет отлавливать ошибки обработки,
; устанавливая флаг CF и конкретизируя проблему по типам:
;     - Строка пуста
;     - Переполнение числа
;     - Ещё не придумал
;
; Зависимости:
;     SexyPrnt.inc >= 1.3
;
; Смотри примеры использования cmdarg.asm и shortex.asm
;

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


; Вот эта получилась жутко сложной после обобщения системы счисления
str_to_int proc							; Перевод строки в число
	; Вход:
	;     ah = Система счисления (<- [2...16])
	;     si = указатель на начало строки (bytes)
	;     cx = длина строки (> 0)
	; Результат:
	;     ax = число [0...65535]
	; Портит:
	;     ax
	; Ошибка:
	;     Флаг CF = 1
	;     ax = 0 - Ошибка символа или некорректные ah,cx
	;          1 - Переполнение результата
		push bx
			push dx
				push si
		cmp		ah, 2
		jl		StI_incorrect
		cmp		ah, 10h
		jg		StI_incorrect
		jcxz	StI_incorrect

		xor		dx, dx
		mov		dl, ah					; Система
		xor		ax, ax					; Результат
		xor		bx, bx					; Разряд

	StI_loop:
		xchg	ax, bx 					; (00, 00), RES
		mov		ah, dl		; Основание с.с.
		mov		al, [si]				; (00,"2"), RES
		call	char_to_int				; (00, 2 ), RES
		jc		StI_incorrect
		xor		ah, ah		; Основание с.с.
		
		xchg	ax, bx					; RES, (00, 2 )
		push	dx						; mul убивает dx
		mul		dx						; ax *= dx
		;jc		StI_overflow
		;jo		StI_overflow
		pop		dx
		add		ax, bx					; ax += bx
		;jc		StI_overflow
	 inc	si
	loop	StI_loop
		clc
		jmp		StI_end
	StI_incorrect:
		stc
		mov		ax, 10
		jmp		StI_end
	StI_overflow:
		cli
		stc
		mov		ax, 88
		jmp		StI_end
	StI_end:
				pop si
			pop dx
		pop bx
		ret
str_to_int endp


trim_leading_zeros proc					; Усечение ведущих нулей у строки
	; Вход:
	;     si = указатель на начало строки из байт, где первый является
	;          её длиной, т.е. (len)(char_1)(char_2)...(char_len)
		push	si
		cld								; Операции со строками в прямом направлении
		mov		bx,	si					; Сохраним указатель на байт длины строки
		xor		cx, cx
		mov		cl, [bx]				; Счётчик
		jcxz	TLZ_error				; Если длина строки равна 0, ошибка
		inc		si						; 1ый символ
		mov		di,	si					; di = Указатель на 1ый символ строки
		mov		al,	' '					; Ищем пробел
		xor		dx,	dx					; 

		repe	scasb					; Поехали!
		jz		TLZ_done				; Если только пробелы, конец
		inc		cl						; Иначе, не потеряй 1ый непробельный
		dec		di						;        символ
		mov		dl,	cl					; Новая длина строки
		xchg	di,	si					; si <=> di
		rep 	movsb					; Переместить оставшуюся часть строки
	TLZ_done:
		mov		[bx], dl				; Новая длина строки
		clc

		jmp		TLZ_exit

	TLZ_error:
	 	stc
	TLZ_exit:
		pop		si
		ret
trim_leading_zeros endp


; TODO stosb
; TODO str_to_int overflow
get_cmd_arg proc						; Возвращает первый неучтенный
	;                                     параметр командной строки.
	; Вход:
	;     si = указатель на начало строки из байт, где первый является
	;          её длиной, т.е. (len)(char_1)(char_2)...(char_len)
	;     ah = система счисления для аргументов-чисел
	; Результат:
	;     al = Тип аргумента
	;         0 - Строка (xyz abc)
	;         1 - Число  (1 FA 12C 10)
	;         2 - Параметр-буква (/x -x)
	;         3 - Параметр-слово (/xyz --xyz)
	;     di = указатель на параметр-строку (с $ в конце)
	;     dx = её длина
	;     bx = [ 1 тип - Число,
	;            2 тип - Символ(bl) ]
	; Ошибки:
	;     Флаг CF = 1
	;     bl = 0 - строка пуста
	;          1 - переполнение числа
	;          2 - ещё не придумал
	;          3 - прочее 3/\о, нечто
	; ________________________________________________________________ ;

	; Объяснение к комментариям:
	;                                               ;S|Состояние стека
	;                                   ; Просто комментарий
	;                       ; Объяснение содержания регистров

		call	trim_leading_zeros
		jc 		GCA_empty

		push	si									;S|-trim-
		xor		cx, cx
		mov		cl, [si]				; cx = длина строки
		jcxz	GCA_empty

		; Найдем аргумент, т.е. все символы до следующего пробела
		inc		si						; si = адрес строки
		mov		al, ' '					; al = искомый символ
	GCA_get_arg:
		cmp		al, [si]				; Поиск первого пробела
		je		GCA_get_arg_exit
		inc		si
	loop GCA_get_arg
	GCA_get_arg_exit:

		pop		si			; "(n)I II ..."			;S|-
		push	si									;S|-trim-
		push	cx			;Сохраним len(" II ...)";S|-trim-len2-

		xor		dx, dx					; Вычислим в dx количество
		mov		dl, [si]				; уже прочитанных символов
		sub		dl, cl												;В ОТВЕТ

		inc		si
		mov		cx, dx					; cx = длина прочитанной строки
		
		cld
		 push	di									;S|-trim-len2-dest
		rep		movsb					; Сохраним по адресу di аргумент
		 pop	di									;S|-trim-len2-

		pop		cx									;S|-trim-
		pop		bx			; "(n)I II ..."			;S|-
		push	di									;S|-"I"-
		mov		di, bx		; "(n)I II ..."

		mov		[di], cl	; Исправляем 0-ой байт на новую длину
		inc		di

		cld
		rep		movsb	 	; Передвигаем " II ..." в начало


		pop		di									;S|-			;В ОТВЕТ
		mov		al, '$'
		add		di, dx
		mov		[di], al				; Завершим строку '$'
		sub		di, dx

		; Проверка на число
		;mov		ah, 10h				; Система счисления (с 0.9.3 версии в аргументах)
		mov		si, di		; "I"		; Указатель на начало строки
		mov		cx, dx					; Длина "I"
		call	str_to_int
		jnc		GCA_integer
		test	ax, ax					; При CF=1, ax=1
		je		GCA_overflow			; имеем переполнение
		dec		si

		; Проверка на вызов с ключом
		mov		al, [si + 1]
		cmp		al, '/'
		je		GCA_slash_or_minus
		cmp		al, '-'
		je		GCA_slash_or_minus

		; Ничего не подошло, значит просто строка
		xor		al, al
		jmp		GCA_exit

	GCA_integer:
		mov		bx, ax 	; bx = int arg
		mov		al, 1
		jmp		GCA_exit
		
	GCA_slash_or_minus:
		cmp		dx, 2
		jg		GCA_long_key

		mov 	al, 2
		mov		bl, [si + 2]			; Символ
		jmp		GCA_exit

	GCA_long_key:
		; TODO --xyz, т.е. если si[1:2] == '--',
		; передвинуть di на символ вправо, dx--
		mov 	al, 3
		;mov		bl, [si + 2]
		jmp		GCA_exit

	GCA_empty:
		mov		al, '$'					; Завершим строку $, и укажем
		mov		[di], al				; нулевую длину, чтобы
		xor		dx, dx					; не было проблем с выводом
		xor		bl, bl
		stc

	GCA_overflow:
		mov		bl, 1
		stc

	GCA_exit:
;				mov ax, di
;				call print_int2
;				call CRLF
;				mov ax, offset cmd_arg
;				call print_int2
;				call CRLF
		ret
get_cmd_arg endp
