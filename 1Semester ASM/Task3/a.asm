.386
assume CS:code, DS:data, SS:stackseg


stackseg segment stack use16
	db 256 dup (?)
stackseg ends 


data 	segment use16

	array 	dw 	256 dup (?)
	n		dw 	(?)
	msg_1 	DB 	'Enter n (<= 7):', 13, 10, 62, 32,'$'
	msg_2 	DB 	'Factorial is:', 13, 10, 62, 32,'$'
	msg_e 	DB 	'Incorrect n (must be in [0...7]). Exiting...', 13, 10,'$'
data 	ends


code segment use16

	include IntLib.inc
	include SexyPrnt.inc
	include Task3.inc


 main proc
	mov 	ax, data 	; Loading
	mov 	ds, ax 		; data segment

	mov 	ax, 0900h
	mov 	dx,offset msg_1 ; Сообщение1 'Введите n'
	int 	21h 		; 

	call 	read_int2 	; reads_int, returns to ax
	mov 	n, ax
	call 	print_int2 	; prints int from ax
	call 	CRLF

	; Проверка корректности n
	cmp 	n, 0
	jl		incorrect_n
	cmp 	n, 7
	jg		incorrect_n

	mov 	ax, 0900h
	mov 	dx,offset msg_2 ; Сообщение 'Факториал равен'
	int 	21h

	push	n
	call 	factorial

	call	print_int2
	jmp		endz

	incorrect_n:
		mov 	ax, 0900h
		mov 	dx,offset msg_e ; Сообщение об ошибке
		int 	21h
		jmp		endz

	endz:
	mov 	ax, 4c00h
	int 	21h
 main 	endp
code 	ends

end 	main
