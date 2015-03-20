
factorial proc

	push 	bp
	push 	bx
	; total 4

	mov 	bp, sp
	mov 	ax, [bp+6]	; n
	
	; recursion base
	test	ax, ax
	jz		n_equals_0

	; recursion step
		mov		bx, ax
		dec		ax
		push	ax
		call	factorial 	; ax = fact(n-1)
		mul		bx			; ax = fact(n-1) * n 
		jmp		factorial_end

	n_equals_0:
		mov		ax, 1 		; ax = 1
		jmp		factorial_end

	factorial_end:
		pop 	bx
		pop 	bp
		ret		2
endp factorial
