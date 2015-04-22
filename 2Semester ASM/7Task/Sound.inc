; Автор: Никита Селезнев, ne.seleznev@gmail.com
;        УрФУ, ФИИТ-301, 2015
;
; Мини-библиотека для работы со звуком
; Sound 0.2.0 (от 20.04.2015)
;
; Для работы процедур необходимо иметь скалярую переменную ticks,
; а так же установить обработчик прерывания 1C - catch_1C
;
; Зависимости:
;     Нет
;
; Смотри пример использования player.asm
;

ticks		dw		0
notes		dw		4186, 4435, 4698, 4978, 5276, 5588, 5920, 6272, 6664, 6880, 7458, 7902

catch_1Ch:
	add		ticks, 1
	iret

reprogram_pit	proc			; Перепрограммирует канал 0 системного таймера
	; Вход:                     ; на новую частоту
	;     bx = делитель частоты
	cli							; запретить прерывания
		mov		al,	00110110b	; канал 0, запись младшего и старшего байт
								; режим работы 3, формат счетчика - двоичный
		out		43h,al			; послать это в регистр команд первого таймера
		mov		al,	bl			; младший байт делителя -
		out		40h,al			; в регистр данных канала 0
		mov		al,	bh			; и старший байт -
		out		40h,al			; туда же
	sti							; теперь IRQO вызывается с частотой 1 193 180/ВХ Hz
	ret
reprogram_pit	endp


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


play_note		proc
	; Играть ноту заданной частоты, октавы и длительности
	; 
	; Вход:
	;     ah = октава (смотри get_note_freq)
	;     al = нота   (аналогично)
	;     bl = длительность (1  - целая,         2  - 1/2,
	;                        3  - 1/4  с точкой, 4  - 1/4,
	;                        6  - 1/8  с точкой, 8  - 1/8,
	;                        12 - 1/16 с точкой, 16 - 1/16)
	;     cx = bpm (если размер 4/4, то число 1/4 нот в минуту)
	pusha

	call	get_note_freq		; ah(октава), al(нота) -> ax(частота)
	call	sound				; ax - частота

	PN_delay:
		xor		bh,	bh
		mov		ticks, 0
		cmp		bx, 3
		je		PN_delay_long
		cmp		bx, 6
		je		PN_delay_long
		cmp		bx, 12
		je		PN_delay_long
		cmp		bx, 24
		je		PN_delay_long
		cmp		bx, 48
		je		PN_delay_long
		jmp		PN_delay_2_n

		PN_delay_long:		; 3 -> (3/8)n, 6 -> (3/16)n
		mov		ax, bx
		mov		bx,	3
		xor		dx,	dx
		cli
			div		bx
		sti
		shl		ax, 3		; a = 3, b = 8*(bx/3)
		xchg	ax, bx
		jmp		PN_delay_ready

		PN_delay_2_n:
		mov		ax, 1

		PN_delay_ready:
		mov		dx, 17474	; Число тиков сист.таймера для	(TODO тут делитель частоты в 4 раза)
							; целой ноты при bpm=1
			mul		dx		;	dx:ax = (ax * FREQ)
		cli
			div		bx		;	ax = (ax/bx) * FREQ
		sti
		xor		dx, dx		; ax = dx:ax / cx
		cli
			div		cx		;	ax = (ax/bx) * FREQ / cx
		sti
		call print_int2
		call CRLF
		PN_delay_loop:
			cmp		ticks, ax
			jl		PN_delay_loop
	popa
	clc
	ret
play_note endp
