; Никита Селезнев, ФИИТ-301, 2015
; Работа с мышью.
; Программа работает в 4 графическом видео-режиме,
; отрисовывая в левом верхнем углу координаты мыши.
; По нажатию Esc или правой кнопки мыши - выход.

; Змейка
; 10h video-mode
; 
;
.286
.model tiny
.code
ORG 100h

@entry:		jmp		@start

;buffer		db		10h dup (?) 
;head		dw		0
;tail		dw		0
char		db		0
color		db		0Fh
old_09h		dw		?, ?
x			dw		?
y			dw		?
;old_1Ch		dw		?, ?

include	SexyPrnt.inc

catch_09h:
	push	ax
		in		al,	60h				; скан-код последней нажатой (из 60 порта)

		;mov		di,		tail
		;mov		buffer[di],	al
		;inc		tail
		;and		tail,	0Fh
		;mov		ax,		tail
		;cmp		head,	ax
		;jne		@catch_09h_put
		;inc		head
		;and		head,	0Fh

		mov		char, al
	@catch_09h_put:
		in		al,		61h
		or		al,		80h
		out		61h,	al
		and		al,		07Fh
		out		61h,	al
		mov		al,		20h
		out		20h,	al			; аппаратному контроллеру нужен сигнал ....
	pop		ax
	iret

@start:
	mov		ax, 4 				; 4 видео-режим (графический)
	int		10h

	; Установим обработчик INT 09h и сохраним старый
	mov		ax, 3509h
	int		21h
	mov		[old_09h],	bx
	mov		[old_09h+2],es
	mov		ax, 2509h
	mov		dx, offset catch_09h
	cli
		int		21h
	sti

	mov		ax,	00				; Инициализация мыши
	int		33h
	; Результат: ax: FFFFh - мышь не установлена. 0000 - Установлена
	;            dx: Число кнопок на мыши
	cmp		ax,	0
	ja		@main_loop
	ret

	mov		ax,	01				; Сделать курсор видимым
	int		33h


@main_loop:

	get_scan_code:
		;mov		di,	tail
		;mov		al,	buffer[di-1]
		mov		al, char
		cmp		al, 81h				; Если это отжатие клавиши Esc
		je		main_loop_exit		; Завершим выполнение программы
		cmp		al, 39h				; Если это нажатие клавиши пробел
		je		change_color		; Сменим цвет
	
	smth:
		mov		ax,	01				; Сделать курсор видимым
		int		33h
		
		mov		ax,	03				; Обработка события мыши и кнопок
		int		33h

		cmp		bx,	2				; Нажата правая кнопка мыши
		je		main_loop_exit

		cmp		bx,	1				; Если нажата левая кнопка мыши,
		jne		@main_loop			; печатаем координаты 
	
	print_coords:
		mov		x,	cx
		mov		y,	dx

		mov		ah,	02h				; cursor to
		xor		bh,	bh				; Page #0
		xor		dx,	dx				; Row #0, Column #0
		int		10h

		mov		bx, 10				; 10 - система счисления

		mov		ax,	x
		;call print_int2
		mov		cx, 3
		x_bite_off:
			xor		dx, dx
			div		bx			; ax = ax / 10
			add		dl,	'0'
			push	dx			; dx = ax % 10
		loop	x_bite_off

		mov		dl,	' '
		push	dx

		mov		ax,	y
		mov		cx, 3
		y_bite_off:
			xor		dx, dx
			div		bx			; ax = ax / 10
			add		dl,	'0'
			push	dx			; dx = ax % 10
		loop	y_bite_off

		mov		ah, 0Eh
		mov		cx, 7			; cx=7 символов
		Pi_print_digit:
			pop		dx			; al <- char
			mov 	al, dl
			;call print_al_char
			xor		bh,	bh		; page #0
			mov		bl,	color
			push cx
				mov cx, 1		; 1 раз
				int 10h
			pop cx
		loop	Pi_print_digit
		
		jmp		draw_pixel

	change_color:
		;mov		al,	color
		;inc		al
		;mov		color,	al
		add		color,	1
		jmp		@main_loop	
	draw_pixel:
		shr		cx,	1
		dec		cx
		dec		dx
		mov		ah,	0Ch
		mov		al,	color
		mov		bh,	0
		int		10h

		;mov		ah,	0Bh
		;mov		bh,	00h 
		;mov		bl, 1001b
		;int		10h

		;mov		ah, 09h
		;mov		al, 'F'
		;mov		bh, 0
		;mov		bl, 0100b
		;mov		cx,	1
		;int		10h

		;mov		ax, 0B800h				; Адрес сегмента видео-буфера 4 режимов
		;mov		es, ax					; Установим сегмент видео-буфера
		;mov		bh, 0Ch
		;mov		bl, 'F'
		;xor		di,	di
		;mov		es:[di], bx

		jmp		@main_loop

	main_loop_exit:
		; Восстанавливаем вектор 09h
		mov		ax, 2509h
		mov		dx, word ptr cs:[old_09h]
		mov		ds, word ptr cs:[old_09h+2]
		cli
			int		21h
		sti
		; Скрывам курсор
		mov		ah,	02h
		int		33h
		ret

end		@entry