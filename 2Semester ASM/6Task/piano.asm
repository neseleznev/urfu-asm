; Никита Селезнев, ФИИТ-301, 2015
; Первый опыт работы со звуком

.286
.model tiny
.code
ORG 2Ch
	env_ptr		label word		; Определить метку для доступа к слову в PSP, которое
								; указывает на сегмент, содержащий блок операционной среды
								; (обычно освобождается для создания компактного резидента)
ORG 100h

@entry:		jmp		@start

buffer		db		10h dup (?) 
head		dw		0
tail		dw		0
old_09h		dw		?, ?
notes		dw		1047, 1109, 1175, 1245, 1319, 1397, 1480, 1568, 1661, 1720, 1867, 1976
prompt		db		'Синтезатор звуков прямоугольной волны через PC-спикер.', 0Ah,0Dh
			db		'Клавиши F1...F12, 1...=,  q...], a...Enter, z...LShift - ноты', 0Ah,0Dh
			db		'        второй,   первой, малой, большой,   контр-октавы соответственно.',0Ah,0Dh
			db		'Пробел - пауза, Escape - выход.','$'
stop_msg	db		'Stop'
stop_msg_len dw		$-stop_msg


sound_on proc
	; Подать звук определенной частоты на PC-speaker
	; Вход: ax - частота (например, Ля - 440)
	;
	pusha
		mov bx, ax
		mov ax, 34ddh
		mov dx, 12h ; частота = 1234DDh (1191340) / параметр
		cmp dx, bx
		jnb SO_end	; jnl знаковое
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

	SO_end:
	popa
	ret
sound_on endp

sound_off proc
	; Заглушить PC-speaker
	push ax
		in		al, 61h
		and		al, not 3
		out 	61h, al
	pop ax
	ret
sound_off endp


get_notes_ax_th proc
	; Взять елемент с номером ax из notes
	; Вход: ax = 0,1,2,...,11
		shl		ax, 1
		mov 	di, offset notes
		add		di, ax
		mov		ax, [di]
	ret
get_notes_ax_th endp


print_int_to_video_memory proc
	; Вход: ax - число
	;       cx - количество символов для печати
	pusha
		cmp		cx, 6
		jl		PiVM_next
		mov		cx, 5
	PiVM_next:
		mov		si, cx
		;mov		ax, 3     ; text mode 80x25, 16 colors, 8 pages (ah=0, al=3)
		;int		10h       ; do it!
		;mov		ax, 0500h
		;int		10h
		push	0B800h
		pop		es

		mov		bx, 10
		mov		cx, si
		int9_bite_off:
			xor		dx, dx
			div		bx			; ax = ax / 10
			push	dx			; dx = ax % 10
		loop	int9_bite_off

		mov		ah, 02h
		mov		cx, si
		xor		di, di
		int9_print_digit:
			pop		dx
			add		dl, '0'
			mov		es:[di],	dl
			mov		es:[di+1],	0Ah
			add		di, 2
		loop	int9_print_digit
	popa
	ret
print_int_to_video_memory endp

print_string_to_video_memory proc
	; Вход: si - адрес ASCII-строки
	;       cx - количество символов для печати
	pusha
		;mov		ax, 3     ; text mode 80x25, 16 colors, 8 pages (ah=0, al=3)
		;int		10h       ; do it!
		;mov		ax, 0500h
		;int		10h
		push	0B800h
		pop		es

		xor		di, di
		int9_print_stop:
			mov		al, [si]
			mov		es:[di],  al
			mov		es:[di+1],0Ch
			add		di, 2
			inc		si
		loop	int9_print_stop
	popa
	ret
print_string_to_video_memory endp

catch_09h:
	pusha
		in		al,	60h				; скан-код последней нажатой (из 60 порта)

		mov		di,		tail
		mov		buffer[di],	al
		inc		tail
		and		tail,	0Fh
		mov		ax,		tail
		cmp		head,	ax
		jne		@catch_09h_put
		inc		head
		and		head,	0Fh

	@catch_09h_put:
		in		al,		61h
		or		al,		80h
		out		61h,	al
		and		al,		07Fh
		out		61h,	al
		mov		al,		20h
		out		20h,	al			; аппаратному контроллеру нужен сигнал ....
	popa
	iret


@start:
	mov		ah, 09h
	mov		dx, offset prompt
	int		21h

	mov		ax, 3509h			; Определим значение старого вектора INT 09h
	int		21h
	cli
	mov		[old_09h],	bx		; Сохраним его в переменной
	mov		[old_09h+2],es
	mov		ax, 2509h			; Установим новый вектор прерывания INT 09h
	mov		dx, offset catch_09h
	int		21h
	sti

@infinity_loop:
		xor		ah, ah
		mov		di,	tail
		mov		al,	buffer[di-1]

									push ax
		; Ряд 1234567890-=
		cmp		al, 2
		jl		dont_change_sound
		cmp		al, 13
		jle		first_octave

		; Ряд qwertyuiop[]
		cmp		al, 16
		jl		dont_change_sound
		cmp		al, 27
		jle		small_octave
		
		; Ряд asdfghjkl;'
		; Enter -> big_octave
		cmp		al, 28
		jne		_not_enter_key
		mov		al, 41 ; L(38) ;(39) '(40) => Enter(41)
		_not_enter_key:
		cmp		al, 30
		jl		dont_change_sound
		cmp		al, 41
		jle		big_octave
		
		; Ряд zxcvbnm,./ shift
		; TODO что-нибудь придумать :)
		cmp		al, 44
		jl		dont_change_sound
		cmp		al, 54
		jle		conter_octave

		; Ряд F1F2F3F4F5F6F7F8F9F10F11F12
		cmp		al, 59
		jl		dont_change_sound
		cmp		al, 69
		jle		second_octave
		; F11 F12 -> second_octave
		cmp		al, 87
		je		second_octave
		cmp		al, 88
		je		second_octave
		
		jmp dont_change_sound

	second_octave:
		sub		ax, 59
		call	get_notes_ax_th
		shr		ax, 1
		jmp		start_sound

	first_octave:
		sub		ax, 2
		call	get_notes_ax_th
		shr		ax, 2
		jmp		start_sound

	small_octave:
		sub		ax, 16
		call	get_notes_ax_th
		shr		ax, 3
		jmp		start_sound

	big_octave:
		sub		ax, 30
		call	get_notes_ax_th
		shr		ax, 4
		jmp		start_sound

	conter_octave:
		sub		ax, 44
		call	get_notes_ax_th
		shr		ax, 5
		jmp		start_sound

	start_sound:
		call	sound_on

	dont_change_sound:
									pop ax
		cmp		al, 81h				; Если это отжатие клавиши Esc
		jne		print_or_stop		; Завершим выполнение программы

		call	sound_off
		mov		ax, 2509h			; Восстанавливаем вектор 21h
		mov		dx, word ptr cs:[old_09h]
		mov		ds, word ptr cs:[old_09h+2]
		int		21h
		ret

	print_or_stop:
		cmp		ax, 69
		jg		do_not_print_int
		cmp		ax, 01h				; pressed escape
		je		stop_sound
		cmp		ax, 39h				; pressed space
		je		stop_sound
		cmp		ax, 0B9h			; droped space
		je		stop_sound

		mov		cx, 3
		call	print_int_to_video_memory

	do_not_print_int:
		jmp		@infinity_loop

	stop_sound:
		call	sound_off
		mov		si, offset stop_msg
		mov		cx, stop_msg_len
		call	print_string_to_video_memory
jmp	@infinity_loop

end		@entry