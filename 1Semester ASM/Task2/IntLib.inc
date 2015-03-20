;requires include SexyPrnt.inc

read_int2 proc
	push 	bx
	push 	cx
	push 	dx

	local 	temp:word ; локальная переменная
	xor 	ax, ax    ; ax = 0 для символов
	xor 	bx, bx    ; bx = 0 для знака
	int 	16h       ; getch
	xor 	ah, ah
	cmp 	al, 45    ; char '-'
	je 	negative
	jmp 	positive
 positive:
	sub 	ax, 48
	mov 	temp, ax
	jmp 	big_int
 negative:
	mov 	bx, 1
	mov 	temp, 0
	jmp 	big_int
 end_loop:
	cmp 	bx, 1
	je 	negative_1
	mov 	ax, temp
	jmp 	end_all
 negative_1:
	mov 	ax, temp
	neg 	ax
	jmp 	end_all
 big_int:
	mov 	ax, 0
	int 	16h     ; getch
	xor 	ah, ah
	;mov dx, ax
	;int 21h
	sub 	ax, 48
	mov 	cx, 9
	cmp 	ax, cx
	jg 	end_loop
	mov 	cx, 0
	cmp 	ax, cx
	jl 	end_loop

	mov 	cx, temp
	imul 	cx, 10
	add 	cx, ax
	mov 	temp, cx
	;   mov cx, ax
	;   mov ax, temp
	;   mov bx, 10
	;   imul bx
	;   add ax, cx
	;   mov temp, ax
	mov 	ax, temp
	jmp 	big_int
 end_all:
 	pop 	dx
 	pop 	cx
 	pop 	bx
 	ret
read_int2 endp

print_int2 proc
	push 	ax
	push 	bx
	push 	cx
	push 	dx
	push 	bp

	mov 	bp, sp
	mov 	ax, [bp+12]
	
	test    ax, ax
	jns     oi1

	mov     cx, ax
	mov     ah, 02h
	mov     dl, '-'
	int     21h
	mov     ax, cx
	neg     ax
 oi1:
	xor     cx, cx
	mov     bx, 10
 oi2:
	xor     dx,dx
	div     bx
	push    dx
	inc     cx
	test    ax, ax
	jnz     oi2
	mov     ah, 02h
 oi3:
	pop     dx
	add     dl, '0'
	int     21h
	loop    oi3

	mov ax, 777
	pop 	bp
	pop 	dx
	pop 	cx
	pop 	bx
	pop 	ax
	ret
print_int2 endp

print_int2_array proc

	push 	bp
	push 	ax
	push 	bx
	; total 6

	mov 	bp, sp
	mov 	si, [bp+10]    ; array
	mov 	bx, [bp+8]    ; len
	shl 	bx, 1         ; *size(int) = 2
	add 	bx, si        ; +first addr

	cmp     si, bx
	je      array_is_empty

	call print_open_bracket
 print_loop:
	mov 	ax, [si]      ; current element
	call 	print_int2
	call 	print_comma
	call 	print_space

	add     si, 2
	cmp     si, bx
	je      print_end
	jmp     print_loop

 print_end:
 	call 	print_backspace
 	call 	print_backspace
	call 	print_close_bracket
	call 	CRLF
	jmp end_print_int2_array

 array_is_empty:
 	call 	print_open_bracket
	call 	print_close_bracket
	call 	CRLF
	jmp end_print_int2_array

 end_print_int2_array:
	pop 	bx
	pop 	ax
	pop 	bp
	ret
print_int2_array endp

read_int2_matrix proc
	; push 	bp
	; push 	ax
	; push 	bx
	; push 	cx
	; push 	dx
	; ; +10 overall

	; mov 	bp, sp
	; mov 	cx, [bp+14]    ; begining of array
	; mov 	si, [bp+14]    ; pointer to read
	; mov 	di, [bp+14]    ; pointer to rewrite
	; mov 	bx, [bp+12]    ; len
	; shl 	bx, 1         ; *size(int) = 2
	; add 	bx, si        ; +first addr

 ; find_loop:
	; mov 	dx, [si]      ; current element
	; mov 	ax, dx
	; call 	is_square
	; test 	ax, ax
	; jz 	not_square
	; mov 	[di], dx
	; add 	di, 2

 ; not_square:
	; add     si, 2
	; cmp     si, bx
	; je      end_of_array
	; jmp     find_loop

 ; end_of_array:
	; mov 	si, [bp+14] 
	; mov 	si, [si]

	;  sub 	di, cx
	;  shr 	di, 1

	; pop 	dx
	; pop 	cx
	; pop 	bx
	; pop 	ax
	; pop 	bp
	ret

read_int2_matrix endp