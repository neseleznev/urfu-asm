; Никита Селезнев, ФИИТ-301, 2015
; Первый опыт работы со звуком
; Слегка оптимизированная и упрощенная версия piano

.286
.model tiny
.code
ORG 80h
	cmd_len		label byte		; Длина аргументов командной строки
	cmd_line	label byte		; Аргументы командной строки
ORG 100h

@entry:		jmp		@start

esc_pressed db 		0
old_09h		dw		?, ?
old_1Ch		dw		?, ?
prompt		db		'playersh.com [имя файла]. Escape - выход'	,0Ah,0Dh,'$'
FileName	db		12 dup (0)
Handle		dw		?
current_note	db	'$'
file_error_msg	db	'Ошибка файла! Проверьте расположение и права доступа'						,'$'

ticks		dw		0


catch_1Ch:
	add		ticks, 1
	iret


play_note_compressed	proc
	; Укороченная версия play_note из Sound.inc (В предположении, что делитель частоты 4000h)
	; Играть ноту заданной частоты, октавы и длительности
	; 
	; Вход:
	;     ah = октава (смотри get_note_freq)
	;     al = нота   (аналогично)
	;     bl = длительность (смотри delay_duration)
	;     cx = bpm (если размер 4/4, то число 1/4 нот в минуту)
	pusha
	
	PN_get_note_freq:
		push bx
			push cx
				push dx
			xchg	cx,	ax
			cmp		cl,	11			; Нота = max{Нота, 11}
			jbe		PN_ok_note
			mov		cl,	11
		PN_ok_note:
			mov		ax,	7
			mov		dx,	0B78Ah+23
			mov		bx,	61858
		PN_1:
			xchg	dx,	ax
			div		bx
			push	ax
			div		bx
			xchg	ax,	dx
			pop		ax
			dec		cl
			jns		PN_1

			cmp		ch,	9
			jbe		PN_2
			mov		ch,	9
		PN_2:
			shl		dx,	1
			rcl		ax,	1
			dec		ch
			jns		PN_2
			shl		dx,	1
			adc		ax,	0
				pop dx
			pop cx
		pop bx

	PN_play_sound:
		pusha
			mov		dx,	12h
			cmp		ax,	dx			; Частота <= 18 Гц ?
			jbe		PN_play_sound_end; Да, на выход, чтобы избежать переполнения
			xchg	cx,	ax			; Сохраняем частоту в СX
			mov		al,	10110110b	; Упр.сл.таймера: канал 2, режим 3, дв.слово
			out		43h,al			; Выводим в регистр режима
			mov		ax,	34DDh		; DX:AX = 1193181
			div		cx				; AX = (DX:AX) / СX
			out		42h,al			; Записываем младший байт счетчика
			mov		al,	ah
			out		42h,al			; Записываем старший байт счетчика
			in		al,	61h			; Порт PB
			or		al,	11b			; Устанавливаем биты 0-1
			out		61h,al			; Записываем обратно в PB
		PN_play_sound_end:
			popa

	PN_delay_duration:
		mov		ticks, 0
		
		xor		bh,	bh
		cmp		bl, 3
		je		PN_DD_long
		cmp		bx, 6
		je		PN_DD_long
		cmp		bx, 12
		je		PN_DD_long
		cmp		bx, 24
		je		PN_DD_long
		cmp		bx, 48		; Любая другая воспринимается как 1/n
		je		PN_DD_long		; например, 98 - 1/98 нота
		jmp		PN_DD_2_n		; not bug but feature ;)

		PN_DD_long:				; 3 -> (3/8)n, 6 -> (3/16)n
			mov		ax, bx
			mov		bx,	3
			xor		dx,	dx
			cli
				div		bx		; ax = (dx:ax) / 3 = bx / 3
			sti
			shl		ax, 3		; a = 3, b = 8*(bx/3)
			xchg	ax, bx
			jmp		PN_DD_ready

		PN_DD_2_n:
			mov		ax, 1

		PN_DD_ready:
			mov		dx, 17474	; Число тиков сист.таймера для	(тут делитель частоты в 4 раза)
								; целой ноты при bpm=1
			; Сейчас ax/bx - длительность ноты относительно целой (например, 1/2 1/4 3/8 и т.д.)
			mul		dx			;	dx:ax = (ax * CNT_TICKS)
			cli
			div		bx			;	ax = (ax/bx) * CNT_TICKS
			sti
			xor		dx, dx
			cli
			div		cx			;	ax = (ax/bx) * CNT_TICKS / cx(bpm)
			sti
			;call print_int2
			;call CRLF
		PN_DD_loop:				; Теперь в ax необходимое число тиков таймера
			cmp		ticks, ax	; Подождём их...
			jl		PN_DD_loop

	popa
	ret
play_note_compressed	endp


catch_09h:
	push	ax
		in		al,	60h				; скан-код последней нажатой (из 60 порта)
		cmp		al, 81h
		jne		@catch_09h_put
		mov		esc_pressed,	1

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
		push cx
			push dx
		cmp		al, ' '
		jne		CtD_double_digit

		mov		al,	ah
		xor		ah,	ah
		sub		al,	'0'
		jmp		CtD_optional_dot

	CtD_double_digit:
		sub		al,	'0'
		mov		cl, al
		mov		al,	ah
		sub		al,	'0'

		mov		dl,	10
		mul		dl
		add		al,	cl

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
				pop	dx
			pop	cx
		pop ax
		ret	
char_to_duration endp


@start:
	mov		ah, 09h
	lea		dx, prompt
	int		21h

	; Делитель частоты (стандартно FFFFh - 18.2 раза в секунду)
	mov		bx,	4000h
	cli							; запретить прерывания
		mov		al,	00110110b	; канал 0, запись младшего и старшего байт
								; режим работы 3, формат счетчика - двоичный
		out		43h,al           ; послать это в регистр команд первого таймера
		mov		al,	bl            ; младший байт делителя -
		out		40h,al           ; в регистр данных канала 0
		mov		al,	bh            ; и старший байт -
		out		40h,al           ; туда же
	sti                         ; теперь IRQO вызывается с частотой
	                            ; 1 193 180/ВХ Hz

	parse_cmd_arg:
		xor		cx,	cx
		mov		cl,	cmd_len					; Длина cx - длина ком.стр.
		jcxz	file_errors
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

	file_errors:
		lea		dx, file_error_msg
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
		mov		cx, 5				;     5 байт
		lea		dx, current_note	;       в буфер current_note
		int		21h

		; TODO optimize; cx = bpm =

		mov		al,	current_note[0]
		sub		al,	'0'
		mov		dl,	100
		mul		dl
		mov		cx,	ax				;            [0]*100

		mov		al,	current_note[1]
		sub		al,	'0'
		mov		dl,	10
		mul		dl
		add		cx,	ax				;              + [1]*10

		mov		al,	current_note[2]
		sub		al,	'0'
		add		cx,	ax				;                + [2]


@music_box:

	get_scan_code:
		cmp		esc_pressed, 1		; Если это отжатие клавиши Esc
		je		music_box_exit		; Завершим выполнение программы

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
		call	play_note_compressed

		jmp		@music_box

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