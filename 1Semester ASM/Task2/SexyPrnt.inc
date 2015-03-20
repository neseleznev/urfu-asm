; v1.1

print_space proc
	
	push	ax
	push	dx

	mov	dx, 20h
	mov	ax, 0200h
	int	21h

	pop	dx
	pop	ax
	ret
print_space endp

print_backspace proc
	
	push	ax
	push	dx

	mov	dx, 08h
	mov	ax, 0200h
	int	21h

	pop	dx
	pop	ax
	ret
print_backspace endp

print_comma proc
	
	push	ax
	push	dx

	mov	dx, 2Ch
	mov	ax, 0200h
	int	21h

	pop	dx
	pop	ax
	ret
print_comma endp

CRLF proc
	
	push 	ax
	push 	dx

	mov	dx, 13
	mov	ax, 0200h
	int	21h
	mov	dx, 10
	mov	ax, 0200h
	int	21h

	pop	dx
	pop	ax
	ret
CRLF endp

print_open_bracket proc
	
	push	ax
	push	dx

	mov	dx, 5Bh
	mov	ax, 0200h
	int	21h

	pop	dx
	pop	ax
	ret
print_open_bracket endp

print_close_bracket proc
	
	push	ax
	push	dx

	mov	dx, 5Dh
	mov	ax, 0200h
	int	21h

	pop	dx
	pop	ax
	ret
print_close_bracket endp

print_colon proc
	
	push	ax
	push	dx

	mov	dx, 3ah
	mov	ax, 0200h
	int	21h

	pop	dx
	pop	ax
	ret
print_colon endp

