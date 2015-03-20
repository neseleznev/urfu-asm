;requires include SexyPrnt.inc

read_int2 proc
	push 	bx
	push 	cx
	push 	dx
	push 	di
	push 	si

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
		mov 	di, ax
		mov 	ax, cx
		mov 	si, 10
		mul 	si
		mov 	cx, ax
		mov 	ax, di
	;imul 	cx, 10
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
 	pop 	si
 	pop 	di
 	pop 	dx
 	pop 	cx
 	pop 	bx
 	ret
read_int2 endp

; read_int2_array proc

;         call print_open_bracket
;         xor  si, si          ; Обнуляем счетчик
;         reading_cycle:  
;             call read_int2
;             mov  array[si], ax
;             add  si, 2
;             call print_int2
;             call print_comma
;             call print_space
;             mov  ax, len
;             shl  ax, 1
;             cmp  si, ax
;             jl   reading_cycle
;         call print_backspace
;         call print_backspace
;         call print_close_bracket
;         call CRLF

;         ret
; 	; push 	bp
; 	; push 	ax
; 	; push 	bx
; 	; ; total 6

; 	; mov 	bp, sp
; 	; mov 	si, [bp+10]   ; array
; 	; mov 	bx, [bp+8]    ; len
; 	; shl 	bx, 1         ; *size(int) = 2
; 	; add 	bx, si        ; +first addr

; 	; 	mov ax,si
; 	; 	call print_int2
; 	; 	call print_space
; 	; 	mov ax,bx
; 	; 	call print_int2
; 	; 	call print_space
; 	; cmp     si, bx
; 	; je      RA_array_is_empty

; 	; call 	print_open_bracket
;  ; RA_read_loop:

; 	; 	mov ax,si
; 	; 	call print_int2
; 	; 	call print_space
; 	; 	mov ax,bx
; 	; 	call print_int2
; 	; 	call print_space
; 	; call 	read_int2
; 	; mov 	si, ax
; 	; call 	print_int2
; 	; call 	print_comma
; 	; call 	print_space

; 	; add     si, 2
; 	; cmp     si, bx
; 	; je      RA_print_end
; 	; jmp     RA_read_loop

;  ; RA_print_end:
;  ; 	call 	print_backspace
;  ; 	call 	print_backspace
; 	; call 	print_close_bracket
; 	; call 	CRLF
; 	; jmp 	RA_end

;  ; RA_array_is_empty:
;  ; 	call 	print_open_bracket
; 	; call 	print_close_bracket
; 	; call 	CRLF
; 	; jmp 	RA_end

;  ; RA_end:
; 	; pop 	bx
; 	; pop 	ax
; 	; pop 	bp
; 	; ret
; read_int2_array endp 

print_int2 proc
	push 	bx
	push 	cx
	push 	dx

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

	pop 	dx
	pop 	cx
	pop 	bx
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
	je      PA_array_is_empty

	call 	print_open_bracket
 PA_print_loop:
	mov 	ax, [si]      ; current element
	call 	print_int2
	call 	print_comma
	call 	print_space

	add     si, 2
	cmp     si, bx
	je      PA_print_end
	jmp     PA_print_loop

 PA_print_end:
 	call 	print_backspace
 	call 	print_backspace
	call 	print_close_bracket
	call 	CRLF
	jmp 	PA_end

 PA_array_is_empty:
 	call 	print_open_bracket
	call 	print_close_bracket
	call 	CRLF
	jmp 	PA_end

 PA_end:
	pop 	bx
	pop 	ax
	pop 	bp
	ret
print_int2_array endp

