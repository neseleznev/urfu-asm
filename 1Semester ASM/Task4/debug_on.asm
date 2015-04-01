.286
.model tiny
.code
ORG 100h

start:
	jmp		setup; Перейдем к программе инсталляции

;-------------------- Резидентная часть программы --------------------;
FileName	db	'C:\Users\Nikita\Desktop\123.txt',0	; файл для записи
Handle		dw	?									; Handle файла
old_21h	dw	?, ?


catch_21h	PROC	far
	cmp	ah, 09h	;Проверим: это фукция 09h?
	je  func_09h	;Если так, то метку func_09h
	cmp	ah, 4ch	;Проверим: это фукция 4ch?
	je  func_4ch	;Если так, то метку func_4ch
	jmp dword ptr cs:[old_21h]
	;db	0EAh

	
 ;обработчик
 func_09h:
		pushf	;Сохраним регистр флагов
		pusha	;Сохраним регистры общего назначения

		;запоминаем адрес строки
		push	ds
		push	dx
		
		;определяем длину строки
		mov		si, dx	;адрес начала строки в si
		xor		cx, cx
		cld		;df = 0 — значение положительное, то есть
				;просмотр от начала цепочки к ее концу

 ;поиск символа "$"
 CheckString:
 	;
		lodsb	;загрузить элемент из ячейки памяти, адресуемой si в регистр al.
				;Размер элемента для команды lodsb - byte
				;изменить значение регистра si на величину, равную длине элемента цепочки
		inc		cx
		cmp		al, '$'
		jnz		CheckString
		dec		cx
	;запоминаем длину строки
		push	cx
	;переходим в свой сегмент данных
		push	cs
		pop		ds
	;открываем файл для чтения и записи
		mov		ax, 3d02h
		mov		dx, offset FileName	;Имя открываемого файла в DX
	;аналог INT 21h
		pushf
		call	dword ptr cs:[old_21h]
	;устанавливаем указатель в конец файла
		mov		Handle, ax	;сохраним номер файла
		mov		bx, ax
		mov		ax, 4202h	;Установим указатель на конец файла
		xor		cx, cx		;Обнулим регистры
		xor		dx, dx
	;аналог INT 21h
		pushf
		call	dword ptr cs:[old_21h]
	;запись в файл
		mov		ah, 40h		;Запишем в файл код длиной
		;mov		bx, Handle
	;восстановим длину строки и её адрес
		pop		cx
		pop		dx
		pop		ds
	;аналог INT 21h
		pushf
		call	dword ptr cs:[old_21h]
	;переходим на свой сегмент
		push	ds
		push	cs
		pop		ds
		mov		ah, 3Eh; закрываем фaйл
		;MOV		bx, Handle
	;аналог INT 21h
		pushf
		call	dword ptr cs:[old_21h]
		jmp end_catch

	
 ;обработчик
 func_4ch:
		pushf	;Сохраним регистр флагов
		pusha	;Сохраним регистры общего назначения
		push	ds
		push 	ax

	cli
		mov		ax, 2521h	;Установим новый вектор прерывания INT 21h
		mov		dx, offset old_21h ;offset catch_21h
		push cs
		pop es
		;mov 	es, [old_21h + 2]
		pushf
		call	dword ptr cs:[old_21h] ;int		21h
	sti
		pop 	ax
		pushf
		call	dword ptr cs:[old_21h]
		jmp end_catch2

 end_catch:
	;восстанавливаем регистры и возвращаемся в старый обработчик
		pop		ds
		popa
		popf
		jmp		dword ptr cs:[old_21h]
 end_catch2:
	;восстанавливаем регистры и возвращаемся в старый обработчик
		pop		ds
		popa
		popf
		;jmp		dword ptr cs:[old_21h]
catch_21h	endp
;----------------- Конец резидентной части программы -----------------;


setup:
	
		mov		ax, 3521h	;Определим значение старого вектор INT 21h
		int		21h
	cli
		mov		[old_21h], bx;Сохраним его в переменной
		mov		[old_21h + 2], es
		mov		ax, 2521h	;Установим новый вектор прерывания INT 21h
		mov		dx, offset catch_21h
		int		21h
	sti
	;оставить резидентной
		mov		dx, offset setup
		int		27h
end start
