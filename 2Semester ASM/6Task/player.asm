; Никита Селезнев, ФИИТ-301, 2015
; Первый опыт работы со звуком
; Слегка оптимизированная и упрощенная версия piano

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
ticks		dw		0
notes		dw		4186, 4435, 4698, 4978, 5276, 5588, 5920, 6272, 6664, 6880, 7458, 7902
prompt		db		'Воспроизведение звуков прямоугольной волны через PC-спикер.'					,0Ah,0Dh
			db		'Использование: TODO player.com [файл], формат которого описано в REAMDE.TXT'	,0Ah,0Dh
			db		'+ увеличить темп, - уменьшить темп, Escape - выход.'							,'$'

melody		db		7,      0, 2, 3, 5, 7,7,    3, 7,7,    3, 7,7,    0, 3, 0, 7, 3, 0
octave		db		4,      4, 4, 4, 4, 4,4,    4, 4,4,    4, 4,4,    4, 4, 4, 3, 4, 4
duration	db		1,      4, 4, 4, 4, 2,4,    4, 2,4,    4, 2,4,    4, 4, 4, 4, 4, 1
len			dw		$-duration

melody2		db		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
octave2		db		3, 0, 3, 0, 3, 0, 3, 0, 3, 0, 3, 0, 3, 0, 3, 0, 3, 0, 3
duration2	db		1, 4, 2, 4, 3, 4, 4, 4, 6, 4, 8, 4,12, 4,16, 4,24, 4,32
len2		dw		$-duration2 


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


@start:
	mov		ah, 09h
	lea		dx, prompt
	int		21h

	mov		ax, 3509h			; Определим значение старого вектора INT 09h
	int		21h
	cli
	mov		[old_09h],	bx		; Сохраним его в переменной
	mov		[old_09h+2],es
	mov		ax, 2509h			; Установим новый вектор прерывания INT 09h
	mov		dx, offset catch_09h
	int		21h
	sti

	mov		ax, 351Ch			; Определим значение старого вектора INT 70h
	int		21h
	cli
	mov		[old_1Ch],	bx		; Сохраним его в переменной
	mov		[old_1Ch+2],es
	mov		ax, 251Ch			; Установим новый вектор прерывания INT 70h
	mov		dx, offset catch_1Ch
	int		21h
	sti

	xor		si, si
	xor		bh, bh
	mov		cx, 180

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
		mov		ah,	octave[si]
		mov		al,	melody[si]
		mov		bl, duration[si]
		call	play_note

		inc		si
		cmp		si, len
		jl		@music_box

		jmp		music_box_exit
	
	music_box_increase:				; Увеличим темп на 6,25%
		mov		ax,	cx
		shr		ax, 4
		add		cx,	ax
		jmp		lets_play

	music_box_decrease:				; Уменьшим темп на 6,25%
		mov		ax,	cx
		shr		ax, 4
		sub		cx,	ax
		jmp		lets_play

	music_box_exit:
		in		al, 61h				; Выключим динамик
		and		al, not 3
		out 	61h, al

		mov		ax, 2509h			; Восстанавливаем вектор 09h
		mov		dx, word ptr cs:[old_09h]
		mov		ds, word ptr cs:[old_09h+2]
		cli
			int		21h
		sti

		mov		ax, 251Ch			; Восстанавливаем вектор 1Ch
		mov		dx, word ptr cs:[old_1Ch]
		mov		ds, word ptr cs:[old_1Ch+2]
		cli
			int		21h
		sti
		ret

end		@entry