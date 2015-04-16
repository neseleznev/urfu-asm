; 09 handler, работает, восстанавливает
; По нажатию пробела сообщение, по нажатию эск выход
; + < 190 bytes
; Записывать в видео-память
; Есть Low-Memory Usage (449, 44A)
.286
.model tiny
.code
ORG 2Ch
	env_ptr		label word		; Определить метку для доступа к слову в PSP, которое
								; указывает на сегмент, содержащий блок операционной среды
								; (обычно освобождается для создания компактного резидента)
ORG 100h

@entry:		jmp @start


include SexyPrnt.inc			; >= 1.3.1

buffer		db		10h dup (?) 
head		dw		0
tail		dw		0
old_09h		dw		?, ?

notes		dw		1046, 1109, 1175, 1244, 1318, 1397, 1480, 1568, 1661, 1720, 1867, 1975


sound proc
	;
	; Вход: ax
	;
	pusha
		mov bx, ax
		mov ax, 34ddh
		mov dx, 12h ; частота = 1234DDh (1191340) / параметр
		cmp dx, bx
		jnb done	; jnl знаковое
		div bx
		mov bx, ax

		in al, 61h
		or al, 3
		out 61h, al

		mov al, 10000110b
		mov dx, 43h
		out dx, al
		dec dx
		mov al, bl
		out dx, al
		mov al, bh
		out dx, al

	done:
	popa
	ret
sound endp


no_sound proc
	pusha
		in		al, 61h
		and		al, not 3
		out 	61h, al
	popa
	ret
no_sound endp


catch_09h	proc	far
	; in  - read from port
	; out - write to port
		in		al,	60h				; скан-код последней нажатой (из 60 порта)

		mov [notes + 0], 1046
		mov [notes + 2], 1109
		mov [notes + 4], 1175
		mov [notes + 6], 1244
		mov [notes + 8], 1318
		mov [notes +10], 1397
		mov [notes +12], 1480
		mov [notes +14], 1568
		mov [notes +16], 1661
		mov [notes +18], 1720
		mov [notes +20], 1867
		mov [notes +22], 1975
		;mov		ax, 880
		;oo:
		; отпустили пробел
		cmp		al, 2
		jl		silent
		cmp		al, 13
		jle		first_octave

		cmp		al, 16
		jl		silent
		cmp		al, 28
		jle		second_octave
		
		cmp		al, 30
		jl		silent
		cmp		al, 40
		jle		third_octave
		
		cmp		al, 44
		jl		silent
		cmp		al, 54
		jle		forth_octave
		
		call silent

		first_octave:
		push ax
			sub		ax, 2
			shl		ax, 1
			mov 	di, offset notes
			add		di, ax
			mov		ax, [di]
			shr		ax, 2
			call	print_int2
			jmp		sound_lbl

		second_octave:
		push ax
			sub		ax, 16
			shl		ax, 1
			mov 	di, offset notes
			add		di, ax
			mov		ax, [di]
			shr		ax, 3
			call print_int2
			jmp		sound_lbl

		third_octave:
		push ax
			sub		ax, 30
			shl		ax, 1
			mov 	di, offset notes
			add		di, ax
			mov		ax, [di]
			shr		ax, 4
			call print_int2
			jmp		sound_lbl

		forth_octave:
		push ax
			sub		ax, 44
			shl		ax, 1
			mov 	di, offset notes
			add		di, ax
			mov		ax, [di]
			shr		ax, 5
			call print_int2
			jmp		sound_lbl


		sound_lbl:
			call print_int2
			call	sound
		pop ax

		silent:

		cmp		al, 81h				; Если это отжатие клавиши Esc
		jne		int9_continue1		; Завершим выполнение программы
		mov		ax, 2509h			; Восстанавливаем вектор 21h
		mov		dx, word ptr cs:[old_09h]
		mov		ds, word ptr cs:[old_09h+2]
		int		21h

		mov		es, env_ptr			; получим из PSP адрес собственного 
		mov		ah, 49h				; окружения резидента и выгрузим его 
		int		21h

		push	cs					; выгрузим теперь саму программу
		pop		es					; 
		mov		ah, 49h				; 
		int		21h 				;
		jmp		int9_continue2
		
	int9_continue1:
;		mov		ax, 3     ; text mode 80x25, 16 colors, 8 pages (ah=0, al=3)
;		int		10h       ; do it!
;		mov		ax, 0500h
;		int		10h
		push     0B800h
		pop     es

		push	ax
			mov		bx, 10
			mov		cx, 3
			int9_bite_off:
				xor		dx, dx
				div		bx					; ax = ax / 10
				push	dx					; dx = ax % 10
			loop	int9_bite_off

			mov		ah, 02h
			mov		cx, 3
			xor		di, di
			int9_print_digit:
				pop		dx
				add		dl, '0'
				mov		es:[di],	dl
				mov		es:[di+1],	00Ch
				add		di, 2
			loop	int9_print_digit
		pop		ax

		cmp		al, 39h				; Если это пробел - выведем сообщение
		je		nosnd
		cmp		al, 80h				; Если это пробел - выведем сообщение
		jl		int9_continue2
		
		nosnd:
		call	no_sound
		mov es:[00h], 0C53h
		mov es:[02h], 0C74h
		mov es:[04h], 0C6Fh
		mov es:[06h], 0C70h
		
	int9_continue2:
		mov		di,		tail
		mov		buffer[di],	al
		inc		tail
		and		tail,	0Fh
		mov		ax,		tail
		cmp		head,	ax
		jne		@1
		inc		head
		and		head,	0Fh

	@1:
		in		al,		61h
		or		al,		80h
		out		61h,	al
		and		al,		07Fh
		out		61h,	al
		mov		al,		20h
		out		20h,	al			; аппаратному контроллеру нужен сигнал ....
		iret
catch_09h	endp


@start:
	; Определим значение старого вектора INT 09h
	mov		ax, 3509h
	int		21h
	cli
		mov		[old_09h],		bx	; Сохраним его в переменной
		mov		[old_09h+2],	es
		mov		ax, 2509h			; Установим новый вектор прерывания INT 09h
		mov		dx, offset catch_09h
		int		21h
	sti

	ret
end		@entry
