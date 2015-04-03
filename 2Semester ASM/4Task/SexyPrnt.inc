; Автор: Никита Селезнев, ne.seleznev@gmail.com
;        УрФУ, ФИИТ-301, 2015
;
; Минималистичная библиотека печати на стандартное устройство вывода,
; с которой значительно проще жить :)
; SexyPrnt 1.3.1 (от 03.03.2015)


; I. Целочисленные.
;        Многие из них я писал очень давно, поэтому без классных операторов.
;        Работает - не тройгай. Будет время перепишу, уберу копипасту.
print_int2 proc						; Печать двухбайтного числа в десятичном виде
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


print_int2_HEX proc					; Печать двухбайтного числа в шестнадцатеричном виде
	;
		pusha						; Вход:
		test		ax, ax			;     ax = число
		jns			PI2H_positive

		mov			cx, ax
		mov			ah, 02h
		mov			dl, '-'
		int			21h
		mov			ax, cx
		neg			ax
	PI2H_positive:
		xor			cx, cx
		mov			bx, 10h
	PI2H_bite_off:
		xor			dx, dx
		div			bx				; ax = ax / 10
		push		dx				; dx = ax % 10
		inc			cx
		test		ax, ax
		jnz			PI2H_bite_off

		mov			ah, 02h

	PI2H_print_digit:
		pop			dx
		cmp			dl, 10
		jl			PI2H_under10
		sub			dl, 10
		add			dl, 'A'
		jmp			PI2H_print
	 PI2H_under10:
		add			dl, '0'
	 PI2H_print:
		int			21h
	loop		PI2H_print_digit

		popa
		ret
print_int2_HEX endp


print_int1_array proc				; Печать массива байт в виде десятичных чисел
	; Использовать:
	; 	push offset arr
	; 	push length
	; 	call print_int1_array
		push bp
			push ax
				push bx			; total 6

		mov		bp, sp
		mov		si, [bp+10]		; Массив
		mov		bx, [bp+8]		; Длина
		;shl		bx, 1		; *size(int) = 2
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


print_int1_array_HEX proc			; Печать массива байт в виде шестнадцатеричных чисел
	; Использовать:
	; 	push offset arr
	; 	push length
	; 	call print_int1_array_HEX
		push bp
			push ax
				push bx			; total 6

		mov		bp, sp
		mov		si, [bp+10]		; Массив
		mov		bx, [bp+8]		; Длина
		;shl		bx, 1		; *size(int) = 2
		add		bx, si			; +first addr

		cmp		si, bx
		je		PAH_array_is_empty

		call	print_open_bracket
		xor		ax, ax
	PAH_print_loop:
		mov		al, [si]		; current element
		call	print_int2_HEX
		call	print_comma
		call	print_space

		inc		si ;add		si, 2
		cmp		si, bx
		je		PAH_print_end
		jmp		PAH_print_loop

	PAH_print_end:
		call	print_backspace
		call	print_backspace
		call	print_close_bracket
		call	CRLF
		jmp		PAH_end

	PAH_array_is_empty:
		call	print_open_bracket
		call	print_close_bracket
		call	CRLF
		jmp		PAH_end

	PAH_end:
				pop	bx
			pop	ax
		pop	bp
		ret 4
print_int1_array_HEX endp


print_int2_array proc				; Печать массива слов (db) в виде десятичных чисел
	; Использовать:
	; 	push offset arr
	; 	push length
	; 	call print_int2_array
		push bp
			push ax
				push bx			; total 6

		mov		bp, sp
		mov		si, [bp+10]		; Массив
		mov		bx, [bp+8]		; Длина
		shl		bx, 1			; *size(int) = 2
		add		bx, si			; +first addr

		cmp		si, bx
		je		PA2_array_is_empty

		call	print_open_bracket
	PA2_print_loop:
		mov		ax, [si]		; current element
		call	print_int2
		call	print_comma
		call	print_space

		add		si, 2
		cmp		si, bx
		je		PA2_print_end
		jmp		PA2_print_loop

	PA2_print_end:
		call	print_backspace
		call	print_backspace
		call	print_close_bracket
		call	CRLF
		jmp		PA2_end

	PA2_array_is_empty:
		call	print_open_bracket
		call	print_close_bracket
		call	CRLF
		jmp		PA2_end

	PA2_end:
				pop	bx
			pop	ax
		pop	bp
		ret 4
print_int2_array endp


print_int2_array_HEX proc			; Печать массива слов (db) в виде шестнадцатеричных чисел
	; Использовать:
	; 	push offset arr
	; 	push length
	; 	call print_int2_array_HEX
		push bp
			push ax
				push bx			; total 6

		mov		bp, sp
		mov		si, [bp+10]		; Массив
		mov		bx, [bp+8]		; Длина
		shl		bx, 1			; *size(int) = 2
		add		bx, si			; +first addr

		cmp		si, bx
		je		PA2H_array_is_empty

		call	print_open_bracket
	PA2H_print_loop:
		mov		ax, [si]		; current element
		call	print_int2_HEX
		call	print_comma
		call	print_space

		add		si, 2
		cmp		si, bx
		je		PA2H_print_end
		jmp		PA2H_print_loop

	PA2H_print_end:
		call	print_backspace
		call	print_backspace
		call	print_close_bracket
		call	CRLF
		jmp		PA2H_end

	PA2H_array_is_empty:
		call	print_open_bracket
		call	print_close_bracket
		call	CRLF
		jmp		PA2H_end

	PA2H_end:
				pop	bx
			pop	ax
		pop	bp
		ret 4
print_int2_array_HEX endp



; II. Глупые, зато без побочных эффектов :)
;
print_dx_string proc				; Печать строки
		push ax						; Вход:
		mov			ah, 09h			;      dx = адрес строки
		int			21h
		pop ax
		ret
print_dx_string endp

print_al_char proc					; Печать символа из al
		push ax						; Вход:
			push dx					;      al = символ
		mov			ah, 02h
		mov			dl, al
		int			21h
			pop dx
		pop ax
		ret
print_al_char endp

print_bl_char proc					; Печать символа из bl
		push ax						; Вход:
			push dx					;      bl = символ
		mov			ah, 02h
		mov			dl, bl
		int			21h
			pop dx
		pop ax
		ret
print_bl_char endp

print_cl_char proc					; Печать символа из cl
		push ax						; Вход:
			push dx					;      cl = символ
		mov			ah, 02h
		mov			dl, cl
		int			21h
			pop dx
		pop ax
		ret
print_cl_char endp

print_dl_char proc					; Печать символа из dl
		push ax						; Вход:
		mov			ah, 02h			;      dl = cимвол
		int			21h
		pop ax
		ret
print_dl_char endp

print_si_pascal_string proc         ; Печать c-addr строки
    ; Pascal-string (или c-addr) - однобайтовая строка, нулевым
    ; байтом которой является беззнаковое число, её длина
        pusha                       ; Вход:
        xor     ch, ch              ;      si = адрес строки
        mov     cl, [si]
        inc     si
        mov     ah, 02h 
        PsiPS_loop:
            mov     dl, [si]
            int     21h
            inc     si
            loop    PsiPS_loop
        popa
        ret
print_si_pascal_string endp


; III. Для красивого дебага.
;        Вроде все void
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

