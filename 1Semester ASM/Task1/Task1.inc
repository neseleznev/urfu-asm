; Find all full squares in array of unsigned integers

get_full_squares proc
	; 			si*
	; input array |_1|_2|_3|_4|...
	; changed to  |_1|_2|_4|...
	;		    di*
	push 	bp
	push 	ax
	push 	bx
	push 	cx
	push 	dx
	; +10 overall

	mov 	bp, sp
	mov 	cx, [bp+14]    ; begining of array
	mov 	si, [bp+14]    ; pointer to read
	mov 	di, [bp+14]    ; pointer to rewrite
	mov 	bx, [bp+12]    ; len
	shl 	bx, 1         ; *size(int) = 2
	add 	bx, cx        ; +first addr

 find_loop:
	mov 	dx, [si]      ; current element
	mov 	ax, dx
	call 	is_square
	test 	ax, ax
	jz 	not_square
	mov 	[di], dx
	add 	di, 2

 not_square:
	add     si, 2
	cmp     si, bx
	je      end_of_array
	jmp     find_loop

 end_of_array:
	mov 	si, [bp+14] 
	mov 	si, [si]

	 sub 	di, cx
	 shr 	di, 1

	pop 	dx
	pop 	cx
	pop 	bx
	pop 	ax
	pop 	bp
	ret
get_full_squares endp


is_square proc
	; (ax)int -> (ax)bool

	;for (int i = 0; i <= x; ++i)
	;    if (i*i == x)
	;        jmp yes
	;jmp no
	push 	si
	push 	cx

	test 	ax, ax 		; negative number
	js 	no

        xor 	si, si          ; Обнуляем счетчик
 for_si_0_to_ax: 
	mov 	cx, si
	imul 	cx, cx
	cmp 	cx, ax
	je 	yes
	inc 	si
	cmp 	si, ax
	jle  	for_si_0_to_ax

	jmp no

 yes:
 	mov ax, 1
 	pop 	cx
 	pop 	si
 	ret
 no:
 	mov ax, 0
 	pop 	cx
 	pop 	si
 	ret
is_square endp