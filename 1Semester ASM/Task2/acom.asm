.386
code segment use16
assume CS:code, DS:code
org 100h


entry:
	call main

matrix	dw 1, 2, 3
		dw 0, 7, 8
		dw 0, 0, 8
N		dw 3
msg_y	DB 'Matrix is upper-triangle! :)', 13, 10,'$'
msg_n	DB 'Matrix is not upper-triangle! :(', 13, 10,'$'


include IntLib.inc
include SexyPrnt.inc
include Task2.inc


main proc

	push 	offset[matrix]
	push 	N
	call 	check_upper_triangle
	call 	CRLF
	call 	CRLF

	test 	ax, ax
	jz 	answer_no

	answer_yes:
		mov 	ax, 0900h 	; Печать символов до '$'
		mov 	dx,offset msg_y ; Сообщение
		int 	21h 		;
		jmp	endz

	answer_no:
		mov 	ax, 0900h 	; Печать символов до '$'
		mov 	dx,offset msg_n ; Сообщение
		int 	21h 		;
		jmp	endz		

 endz:
	mov 	ax, 4c00h
	int 	21h
main endp

code ends
end entry
