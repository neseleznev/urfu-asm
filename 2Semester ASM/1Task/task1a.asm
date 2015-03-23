; Никита Селезнев, ФИИТ-301
;
; Программа, которая обрабатывает int 21h и ничего не делает
; Особенности: .COM файл <= 75 байт, в памяти <= 300 байт,
;              в утилитах типа tdmem должна иметь имя

.model tiny
.code

ORG 2Ch
	EnvPtr	label word	; определить метку для доступа к слову в PSP, которое указывает на сегмент,
						; содержащий блок операционной среды
						; (он обычно освобождается для создания более компактной резидентной программы)
ORG 100h


@entry:
	jmp		@setup

;-------------------- Резидентная часть программы --------------------;
old_21h		dw		?, ?

catch_21h	proc	far
	jmp 	dword ptr cs:[old_21h]
catch_21h	endp
;----------------- Конец резидентной части программы -----------------;


@setup:
	; освободить блок операционной среды
	mov		es, EnvPtr		; ES -> блок операционной среды
	mov		ah, 49h			; функция 49h: освободить блок памяти
	int		21h				; вызвать MS-DOS
	;jnc		no_error_mem		; ошибка освобождения EnvBlock?

	;	add ax, 48
	;	mov dl, al
	;	mov ah, 02h
	;	int 21h
	;	mov dl, 'E'
	;	mov ah, 02h
	;	int 21h
	;		mov ah,4Ch
	;		int 21h
	;	no_error_mem:

	mov		ah, 48h			; функция 49h: освободить блок памяти
	mov		bx, 1			; количество параграфов для выделения
	int		21h				; вызвать MS-DOS (экономим)
	; Если нет ошибки (флаг C!=1),
	; то в ax будет адрес полученного сегмента
	;jnc		no_error_alloc		; ошибка выделения

	;	add ax, 48
	;	mov dl, al
	;	mov ah, 02h
	;	int 21h
	;	mov dl, 'A'
	;	mov ah, 02h
	;	int 21h
	;		mov ah,4Ch
	;		int 21h
	;	no_error_alloc:
	;mov 	EnvPtr, ax

	mov cx, 11					; Длина source (вообще-то len, но мы экономим)
	mov si, offset new_name		; Адрес source
	mov es, EnvPtr;ax					; в ax адрес сегмента после int 48h (см.выше)
	xor di, di 					; es:[di] <- адрес destination
	rep movsb					; ++di, ++si, mov

	mov		ax, 3521h			; Определим значение старого вектор INT 21h
	int		21h
	cli
		mov		[old_21h],		bx	;Сохраним его в переменной
		mov		[old_21h+2], 	es
		mov		ax, 2521h			;Установим новый вектор прерывания INT 21h
		mov		dx, offset catch_21h
		int		21h
	sti

	mov		dx, offset @setup	;оставить резидентной
	int		27h
	; Эквивалентный код:
	;mov	ah, 31h				; функция DOS завершения резидентной программы
	;mov	dx, (@setup - @entry + 10Fh) / 16 ; определение размера резидентной
								; части программы в параграфах
	;int	21h					; вызов DOS
	;mov	ah, 4Ch				;
	;int	21h					; Выход 

	new_name	db		20h,00h,00h,01h,00h,'myint',00h
	;len			dw		$-new_name

end @entry
