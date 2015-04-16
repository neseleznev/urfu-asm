
sound proc
	pusha
		mov bx, ax
		mov ax, 34ddh
		mov dx, 12h ; частота = 1234DDh (1191340) / параметр
		cmp dx, bx
		jnb done
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
		in al, 61h
		and al, not 3

	popa
	ret
no_sound endp







rpt db 0
curnote db 0

int1c proc
	push ds
	push cs
	pop ds
	inc curtime
	pop ds
	db 0EAh
	i1c dw 0, 0
int1c endp
