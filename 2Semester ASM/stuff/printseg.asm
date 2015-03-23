.model tiny
.code

; Никита Селезнев, ФИИТ-301
;
; Программа, которая обрабатывает int 21h и ничего не делает
; Особенности: .COM файл <= 75 байт, в памяти <= 300 байт,
;              в утилитах типа tdmem должна иметь имя

org 100h

@entry:
	jmp @start

print_seg_offset proc 
	push	cs		; 0101 = 0000000100000001
	pop		bx
	mov		cx, 4

	@k:	
		rol		bx, 4		; bx = 0001000000010000
		mov		al, bl		; al = 00010000
		and		al, 0fh
		cmp		al, 10
		sbb		al, 69h
		das
		mov		dh, 02h
		xchg	ax, dx
		int		21h
	loop	@k
	ret
print_seg_offset endp


@start:
	
	call print_seg_offset

	int 20h


code ends
end @entry
