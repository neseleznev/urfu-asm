; Никита Селезнев, ФИИТ-301, 2015
; Работа с мышью.
; Программа работает в 4 графическом видео-режиме,
; отрисовывая в левом верхнем углу координаты мыши.
; По нажатию Esc или правой кнопки мыши - выход.
.286
.model tiny
.code
ORG 100h

@entry:		jmp		@start

buffer		db		10h dup (?) 
head		dw		0
tail		dw		0
old_09h		dw		?, ?
old_1Ch		dw		?, ?
l_button	dw		0

;include	SexyPrnt.inc

print_int_3chars proc
	; Вход: ax - число
	pusha
	PiVM_next:
		mov		bx, 10
		mov		cx, 3
		int9_bite_off:
			xor		dx, dx
			div		bx			; ax = ax / 10
			push	dx			; dx = ax % 10
		loop	int9_bite_off

		mov		ah, 02h
		mov		cx, 3
		int9_print_digit:
			pop		dx
			add		dl,	'0'
			int		21h
		loop	int9_print_digit
	popa
	ret
print_int_3chars endp


catch_09h:
	push	ax
		in		al,	60h				; скан-код последней нажатой (из 60 порта)

		mov		di,		tail
		mov		buffer[di],	al
		inc		tail
		and		tail,	0Fh
		mov		ax,		tail
		cmp		head,	ax
		jne		@catch_09h_put
		inc		head
		and		head,	0Fh

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

;	mov		ax,	01				; Сделать курсор видимым
;	int		33h

@main_loop:

	get_scan_code:
		mov		di,	tail
		mov		al,	buffer[di-1]

		cmp		al, 81h				; Если это отжатие клавиши Esc
		je		main_loop_exit		; Завершим выполнение программы
	
	smth:
		mov		ax,	01				; Сделать курсор видимым
		int		33h
		
		mov		ax,	03				; Обработка события мыши и кнопок
		int		33h

		cmp		bx,	2				; Нажата правая кнопка мыши
		je		main_loop_exit

		cmp		bx,	1
		jne		@main_loop
		 
		mov		ax, dx				; Y coord to ax
		call	print_int_3chars
				
		mov		dx, 20h				; '123' + ' '
		mov		ax, 0200h
		int		21h

		mov		ax,	cx				; X coord to ax
		call	print_int_3chars	; + '456'

		mov		cx,	7				; Потом печатаем backspace	
		mov		dx, 08h				; cx=7 раз
		mov		ax, 0200h
		clean_up:
			int		21h
			loop	clean_up

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
		ret

end		@entry