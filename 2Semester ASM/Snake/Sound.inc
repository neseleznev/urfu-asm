; Автор: Никита Селезнев, ne.seleznev@gmail.com
;        УрФУ, ФИИТ-301, 2015
;
; Мини-библиотека для работы со звуком
; Sound 0.3.7 (от 08.05.2015)
;
; play_note - играть ноту заданной октавы, высоты и длительности
;     Для начала работы необходимо вызвать init_play_note
;     После работы вызывть stop_play_note
;
; Зависимости:
;     Нет
;
; Смотри пример использования Task7\player.asm
;

old_1Ch		dw		?, ?
old_pit		dw		?
ticks		dw		0

catch_1Ch:
	add		ticks, 1
	iret


reprogram_pit	proc			; Перепрограммирует канал 0 системного таймера
	; Вход:                     ; на новую частоту
	;     bx = делитель частоты
	pusha
	cli							; запретить прерывания
		mov		al,	00110110b	; канал 0, запись младшего и старшего байт
								; режим работы 3, формат счетчика - двоичный
		out		43h,al			; послать это в регистр команд первого таймера
		mov		al,	bl			; младший байт делителя -
		out		40h,al			;     в регистр данных канала 0
		mov		al,	bh			; и старший байт -
		out		40h,al			;     туда же
	sti							; теперь IRQO вызывается с частотой 1 193 180/ВХ Hz
	popa
	ret
reprogram_pit	endp

get_pit	proc					; Считывает делитель частоты 0 канала системного таймера
	; Результат:
	;     cx = делитель частоты
	mov		cx, 4000h			; TODO correct
	ret
get_pit	endp


sound			proc			; Включить звук
	; Вход:
	;     AX = частота звука (Гц)
	pusha
		mov		dx,	12h
		cmp		ax,	dx			; Частота <= 18 Гц ?
		jbe		sound_end		; Да, на выход, чтобы избежать переполнения
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
	sound_end:
		popa
		ret
sound			endp


no_sound		proc			; Отключить звук
	push	ax
		in		al,	61h			; Порт PB
		and		al,	not 11b		; Сбрасываем биты 0-1
		out		61h,al			; Записываем обратно в PB
	pop		ax
	ret
no_sound		endp


get_note_freq	proc			; Получение частоты ноты
	; Вход:  ah = октава
	;        al = нота
	; Выход: ax = частота (Гц)
	; Октавы: 0 субконтр, 1 контр, 2 большая, 3 малая, 4 первая, ..., 9 шестая
	; Ноты:   0 до, 1 до#, 2 ре, 3 ре#, 4 ми, 5 фа, 6 фа#, 7 соль, ..., 11 си
	;
	; Изменение высоты на полутон - это изменение в (корень 12-й степени из 2 раз) ~= 1.059463 раз.
	; Вычисляем частоту ноты "до" самой низкой октавы фортепиано (субконтроктавы) и получаем ~ 16.351598 Гц.
	; Таким образом, вычисление частоты ноты сводится к простейшей процедуре:
	;     Умножаем значение 16.351598 на 2 столько раз, на сколько нужная нам октава выше субконтроктавы.
	;      Умножаем получившееся значение на 1.059463 столько раз, на сколько полутонов нужная нам нота выше ноты "до"
	push bx
		push cx
			push dx
		xchg	cx,	ax
		cmp		cl,	11			; Нота = max{Нота, 11}
		jbe		GNF_ok_note
		mov		cl,	11
	GNF_ok_note:
		mov		ax,	7
		mov		dx,	0B78Ah+23
		mov		bx,	61858
	GNF1:
		xchg	dx,	ax
		div		bx
		push	ax
		div		bx
		xchg	ax,	dx
		pop		ax
		dec		cl
		jns		GNF1

		cmp		ch,	9
		jbe		GNF2
		mov		ch,	9
	GNF2:
		shl		dx,	1
		rcl		ax,	1
		dec		ch
		jns		GNF2
		shl		dx,	1
		adc		ax,	0
			pop dx
		pop cx
	pop bx
	ret
get_note_freq	endp


delay_duration	proc
	; Вход:
	;     bl = длительность (1  - целая,         2  - 1/2,
	;                        3  - 1/4  с точкой, 4  - 1/4,
	;                        6  - 1/8  с точкой, 8  - 1/8,
	;                        12 - 1/16 с точкой, 16 - 1/16,
	;                        24 - 1/32 с точкой, 32 - 1/32,
	;                        48 - 1/64 с точкой, 64 - 1/64)
	;     cx = bpm (если размер 4/4, то число 1/4 нот в минуту)
	pusha
		; Если число делится на 3 (имеет вид xxxxxx11), то это
		;  продолжительность с точкой (или некорректность)
		; TODO проверка на делимость 3 вместо этой кучи
		mov		ticks, 0
		
		xor		bh,	bh
		cmp		bl, 3
		je		DD_long
		cmp		bx, 6
		je		DD_long
		cmp		bx, 12
		je		DD_long
		cmp		bx, 24
		je		DD_long
		cmp		bx, 48		; Любая другая воспринимается как 1/n
		je		DD_long		; например, 98 - 1/98 нота
		jmp		DD_2_n		; not bug but feature ;)

	DD_long:				; 3 -> (3/8)n, 6 -> (3/16)n
		mov		ax, bx
		mov		bx,	3
		xor		dx,	dx
		cli
			div		bx		; ax = (dx:ax) / 3 = bx / 3
		sti
		shl		ax, 3		; a = 3, b = 8*(bx/3)
		xchg	ax, bx
		jmp		DD_ready

	DD_2_n:
		mov		ax, 1

	DD_ready:
		push ax
		push cx
			mov		dx,	12h	; Разделим частоту генератора импульсов (1193181)
			mov		ax,	34DDh; на текущий делитель частоты

			call	get_pit	; cx = Текущий делитель частоты
			div		cx		; ax = dx:ax / cx

			mov		cx,	240	; И домножим на 60(секунд в минуте) * 4(целая нота - 4 1/4)
			mul		cx		; т.е. 240 | dx:ax = ax*cx
			mov		dx, ax	; Получим dx = число тиков сист.таймера для целой ноты при bpm=1
		pop cx
		pop ax

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
	DD_loop:				; Теперь в ax необходимое число тиков таймера
		cmp		ticks, ax	; Подождём их...
		jl		DD_loop
	popa
	ret
delay_duration	endp


init_play_note	proc
	; Делитель частоты (стандартно FFFFh - 18.2 раза в секунду)
	;mov		old_pit, 0FFFFh ;TODO call get_pit
	;mov		bx,	4000h
	;call	reprogram_pit
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
	ret
init_play_note	endp

stop_play_note	proc
	; Выключим динамик
	pusha
	in		al, 61h
	and		al, not 3
	out 	61h, al
	; Вернём значение делителя частоты
	;mov		bx, 0FFFFh;old_pit
	;call	reprogram_pit
	; Восстанавливаем вектор 1Ch
	mov		ax, 251Ch
	mov		dx, word ptr cs:[old_1Ch]
	push 	ds
	mov		ds, word ptr cs:[old_1Ch+2]
	cli
		int		21h
	sti
	pop 	ds
	popa
	ret
stop_play_note	endp

play_note		proc
	; Играть ноту заданной частоты, октавы и длительности
	; 
	; Вход:
	;     ah = октава (смотри get_note_freq)
	;     al = нота   (аналогично)
	;     bl = длительность (смотри delay_duration)
	;     cx = bpm (если размер 4/4, то число 1/4 нот в минуту)
	pusha

	call	get_note_freq		; ah(октава), al(нота) -> ax(частота)
	call	sound				; ax - частота
	call	delay_duration

	popa
	ret
play_note endp


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
