; Никита Селезнев, ФИИТ-301, 2015
; Первый опыт работы со звуком
; TODO 1) fix .-bug
;      2) fix 16-bug

.286
.model tiny
.code
ORG 80h
	cmd_len		label byte		; Длина аргументов командной строки
	cmd_line	label byte		; Аргументы командной строки
ORG 100h

@entry:		jmp		@start

buffer		db		10h dup (?) 
head		dw		0
tail		dw		0
old_09h		dw		?, ?
old_1Ch		dw		?, ?
prompt		db		'Воспроизведение звуков прямоугольной волны через PC-спикер.'					,0Ah,0Dh
			db		'Использование: TODO player.com [файл], формат которого описан в README.TXT'	,0Ah,0Dh
			db		'+ увеличить темп, - уменьшить темп, Escape - выход.'							,0Ah,0Dh,'$'
FileName	db		100 dup (0)
Handle		dw		?
current_note	db	'$','$','$','$','$','$','$'
file_not_found_msg	db	'Файл не найден!'															,'$'
access_denied_msg	db	'Недостаточно прав для чтения файла!'										,'$'

include	SexyPrnt.inc
include	Sound.inc

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

char_to_note proc						; Перевод 2х символов в ноту
	; Вход:
	; ah = Нота [A, B, C, D, E, F, G]
	; al = ['b', '#', ' '] (напр, 'F#', 'Db', 'G ')
	; Результат:
	; al = число [0...11]
		cmp		ah,	'B'
		jle		CtN_AB
		cmp		ah,	'E'
		jle		CtN_CDE
		cmp		ah,	'G'
		jle		CtN_FG

	CtN_AB:
		sub		ah, 'A'
		shl		ax, 1
		add		ah, 9
		jmp		CtN_diez_bemole
	CtN_CDE:
		sub		ah, 'C'
		shl		ax, 1
		jmp		CtN_diez_bemole
	CtN_FG:
		sub		ah, 'F'
		shl		ax, 1
		add		ah, 5
		;jmp	CtN_diez_bemole
	CtN_diez_bemole:
		push	bx
			mov		bl, ah
			xor		ah,	ah
			shr		ax, 1
			mov		ah, bl
		pop		bx
		cmp		al, 'b'
		je CtN_bemole
		cmp		al, '#'
		je		CtN_diez
		jmp		CtN_exit
	CtN_bemole:
		dec		ah
		jmp		CtN_exit
	Ctn_diez:
		inc		ah
		;jmp	CtN_exit
	CtN_exit:
		mov		al, ah
		ret
char_to_note endp

char_to_duration proc					; Перевод символа в длительность
	; Вход:
	;     ah = Первый символ
	;     al = Второй символ
	;     bl = Третий символ ('.' или ' ')
	; Результат:
	;     bl = число [1,2,(3),4,(6),8,(12),16,(24),32]
	push ax
		cmp		al, ' '
		jne		CtD_double_digit

		mov		al,	ah
		xor		ah,	ah
		sub		al,	'0'
		jmp		CtD_optional_dot

	CtD_double_digit:
		sub		al,	'0'
		push	cx
			mov		cl, al
			mov		al,	ah
			sub		al,	'0'

			mov		dl,	10
			mul		dl
			add		al,	cl
		pop		cx

	CtD_optional_dot:
		cmp		bl, '.'
		jne		CtD_exit

		xor		ah,	ah
		shr		ax,	1
		mov		dx,	ax
		shr		dx,	1
		add		ax,	dx
	CtD_exit:
		mov		bl,	al
		pop ax
		ret	
char_to_duration endp


@start:
	mov		ah, 09h
	lea		dx, prompt
	int		21h

	; Делитель частоты (стандартно FFFFh - 18.2 раза в секунду)
	mov		bx,	4000h
	call	reprogram_pit

	parse_cmd_arg:
		xor		cx,	cx
		mov		cl,	cmd_len					; Длина cx - длина ком.стр.
		jcxz	file_not_found
		lea		si,	cmd_line				; Источник si - ком.стр.,
		dec		cx							;   ( пропустим байт длины и пробел,
		add		si,	2						;     уменьшив длину и сместив указатель )
		lea		di,	FileName				; Приемник di - FileName
		cld									; В прямом направлении
		rep		movsb
	
	open_file:
		mov		ax, 3D00h
		lea		dx, FileName
		int		21h
		jnc		set_pointer_to_file

		cmp		ax,	4
		jle		file_not_found
		; 5, 12
		access_denied:
			lea		dx, access_denied_msg
			jmp		print_and_exit
		; 1, 2, 3, 4
		file_not_found:
			lea		dx, file_not_found_msg
			jmp		print_and_exit
		print_and_exit:
			mov		ah,	09h
			int		21h
			ret

	; Устанавливаем указатель в начало файла
	set_pointer_to_file:
		mov		Handle, ax
		mov		bx, ax
		mov		ax, 4200h	; Установим указатель на
		xor		cx, cx		; позицию 0*64K + 0
		xor		dx, dx
		int		21h

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
	; Установим обработчик INT 1Сh и сохраним старый
	mov		ax, 351Ch
	int		21h
	mov		[old_1Ch],	bx
	mov		[old_1Ch+2],es
	mov		ax, 251Ch
	mov		dx, offset catch_1Ch
	cli
		int		21h
	sti

	parse_bpm:
		mov		ah, 3Fh				; Читаем
		mov		bx, Handle			;   из файла
		mov		cx, 5				;     6 байт
		lea		dx, current_note	;       в буфер current_note
		int		21h

		; TODO optimize
		xor		cx,	cx				; cx = bpm =
		mov		dl,	10

		mov		al,	current_note[0]
		sub		al,	'0'
		mul		dl
		mul		dl
		add		cx,	ax				;            [0]*100

		mov		al,	current_note[1]
		sub		al,	'0'
		mul		dl
		add		cx,	ax				;              + [1]*10

		mov		al,	current_note[2]
		sub		al,	'0'
		add		cx,	ax				;                + [2]

@music_box:

	get_scan_code:
		mov		di,	tail
		mov		al,	buffer[di-1]

		cmp		al, 81h				; Если это отжатие клавиши Esc
		je		music_box_exit		; Завершим выполнение программы
		cmp		al, 0Dh				; Если это нажатие клавиши +,
		je		music_box_increase	;     увеличим темп
		cmp		al, 0Ch				; Если это отжатие клавиши -,
		je		music_box_decrease	;     уменьшим темп

	lets_play:
		push	cx
			mov		ah,	3Fh				; Читаем
			mov		bx,	Handle			;   из файла
			mov		cx,	6				;     6 байт
			lea		dx,	current_note	;       в буфер current_note
			int		21h
		pop	cx

		test	ax,	ax
		jz		music_box_exit
								lea dx, current_note
								call print_dx_string

								call print_open_bracket
								call print_int2
								call print_close_bracket
								call CRLF
		mov		al,	current_note[0]
		sub		al,	'0'
		mov		dh, al

		mov		ah, current_note[1]
		mov		al, current_note[2]
		call	char_to_note
		mov		dl, al

		mov		ah,	current_note[3]
		mov		al,	current_note[4]
		mov		bl,	current_note[5]
		call	char_to_duration		; bl = продолжительность (код)
		mov		ah,	dh					; ah = октава
		mov		al,	dl					; al = нота
		call	play_note

		jmp		@music_box
	
	music_box_increase:				; Увеличим темп на 12,5%
		mov		ax,	cx
		shr		ax, 3
		add		cx,	ax
		jmp		lets_play

	music_box_decrease:				; Уменьшим темп на 6,25%
		mov		ax,	cx
		shr		ax, 4
		sub		cx,	ax
		jmp		lets_play

	music_box_exit:
		; Выключим динамик
		in		al, 61h
		and		al, not 3
		out 	61h, al
		; Восстанавливаем вектор 09h
		mov		ax, 2509h
		mov		dx, word ptr cs:[old_09h]
		mov		ds, word ptr cs:[old_09h+2]
		cli
			int		21h
		sti
		; Восстанавливаем вектор 1Ch
		mov		ax, 251Ch
		mov		dx, word ptr cs:[old_1Ch]
		mov		ds, word ptr cs:[old_1Ch+2]
		cli
			int		21h
		sti
		; Закроем файл
		mov		ah, 3Eh
		mov		bx, Handle
		int		21h
		ret

end		@entry