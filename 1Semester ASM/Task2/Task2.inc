; Check squaren matrix for upper-triangle

get_element proc
	; a[i][j] = a + (i*N + j)*sizeint
	push 	bp
	push 	bx
	push 	cx
	push 	si

	mov 	bp, sp
	mov 	si, [bp+16]		; offset[matrix]
	mov 	cx, [bp+14]		; N
	mov 	ax, [bp+12]		; i
	mov 	bx, [bp+10]		; j

	imul 	ax, cx 		; (i*N
	add 	ax, bx 		; + j)
	shl 	ax, 1 		; * 2
	add 	si, ax 		; + matrix_begin
	mov 	ax, [si]

	pop 	si
	pop 	cx
	pop 	bx
	pop 	bp
	ret
get_element endp


check_upper_triangle proc
	push 	bp
	push 	bx
	push 	cx
	push 	si
	push 	di

	mov 	bp, sp
	mov 	bx, [bp+14]	; matrix
	mov 	cx, [bp+12]	; N

	xor 	si, si          ; Обнуляем счетчик
	 for_si_0_to_cx:
	;{
		xor 	di, di
		cmp 	di, si
		jge 	next_si

		 for_di_0_to_si:
		;{

			push 	bx
			push 	cx 	; N
			push 	si 	; i
			push 	di 	; j
			call 	get_element ; -> ax
			pop di
			pop si
			pop cx
			pop bx

			;push ax
			;call print_int2
			;pop ax
			;call print_space
			test	ax, ax
			jnz 	CUT_no

			inc 	di
			cmp 	di, si
			jl  	for_di_0_to_si
		;}
		next_si:
		inc 	si
		cmp 	si, cx
		jl  	for_si_0_to_cx
	;}
	jmp 	CUT_yes

	 CUT_no:
	 	mov 	ax, 0
	 	jmp 	CUT_end
	 CUT_yes:
	 	mov 	ax, 1
	 	jmp 	CUT_end

	 CUT_end:
	 	pop 	di
	 	pop 	si
	 	pop 	cx
		pop 	bx
		pop 	bp
		ret
check_upper_triangle endp
