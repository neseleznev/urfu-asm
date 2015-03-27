; Никита Селезнев, УрФУ, ФИИТ-301, 2015 год
; 
; Минималистичная билбиотека с процедурами для печати на ст.устройство вывода.
; v1.3 от 27.03.2015

print_dx_string proc			; Печать строки
		push		ax				; Вход:
		mov			ah, 09h			;      dx = адрес строки
		int			21h
		pop			ax
		ret
print_dx_string endp

print_int2 proc					; Печать числа в десятичном виде
	;
		pusha						; Вход:
									;     ax = число
		test		ax, ax
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

print_int1_array proc
	; push offset arr
	; push length
	; call print_int1_array
		push bp
			push ax
				push bx			; total 6

		mov		bp, sp
		mov		si, [bp+10]		; Массив
		mov		bx, [bp+8]		; Длина
		;shl		bx, 1			; *size(int) = 2
		add		bx, si			; +first addr

		cmp		si, bx
		je		PA_array_is_empty

		call	print_open_bracket
		xor		ax, ax
	PA_print_loop:
		mov		al, [si]		; current element
		call	print_int2
		call	print_comma
		call	print_space

		inc		si ;add		si, 2
		cmp		si, bx
		je		PA_print_end
		jmp		PA_print_loop

	PA_print_end:
		call	print_backspace
		call	print_backspace
		call	print_close_bracket
		call	CRLF
		jmp		PA_end

	PA_array_is_empty:
		call	print_open_bracket
		call	print_close_bracket
		call	CRLF
		jmp		PA_end

	PA_end:
				pop	bx
			pop	ax
		pop	bp
		ret 4
print_int1_array endp

print_space proc
		push ax
			push dx

		mov		dx, 20h
		mov		ax, 0200h
		int		21h

			pop dx
		pop ax
		ret
print_space endp

print_backspace proc
		push ax
			push dx

		mov		dx, 08h
		mov		ax, 0200h
		int		21h

			pop dx
		pop ax
		ret
print_backspace endp

print_comma proc
		push ax
			push dx

		mov		dx, 2Ch
		mov		ax, 0200h
		int		21h

			pop dx
		pop ax
		ret
print_comma endp

print_open_bracket proc
		push ax
			push dx

		mov		dx, 5Bh
		mov		ax, 0200h
		int		21h

			pop dx
		pop ax
		ret
print_open_bracket endp

print_close_bracket proc
		push ax
			push dx

		mov		dx, 5Dh
		mov		ax, 0200h
		int		21h

			pop dx
		pop ax
		ret
print_close_bracket endp

CRLF proc						; Печать 0Ah,0Dh
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

