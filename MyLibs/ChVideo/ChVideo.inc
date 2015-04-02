; Автор: Никита Селезнев, ne.seleznev@gmail.com
;        УрФУ, ФИИТ-301, 2015
;
; Мини-библиотека для смены видео-режима и текущей отображаемой страницы
; ChVideo 0.1 (от 03.04.2015)
;
; Для работы процедур необходимо указать в AL режим или страницу
;
; Процедура умеет отлавливать ошибки, устанавливая флаг CF, если
;     - Такого видео-режима не существует
;     - Страница не применима для текущего видео-режима
;
; Зависимости:
;     Нет
;
; Смотри пример использования chvideo.asm
;

change_video_mode proc			; Изменение видео-режима
	; 00h уст.видео режим. Очистить экран, установить поля BIOS, установить режим.
	; Вход:  AL = режим
	;       AL  Тип      формат   цвета          адаптер  адрес монитор
	;       === =======  =======  =============  =======  ====  =================
	;        0  текст    40x25    16/8 полутона  CGA,EGA  b800  Composite
	;        1  текст    40x25    16/8           CGA,EGA  b800  Comp,RGB,Enhanced
	;        2  текст    80x25    16/8 полутона  CGA,EGA  b800  Composite
	;        3  текст    80x25    16/8           CGA,EGA  b800  Comp,RGB,Enhanced
	;        4  графика  320x200  4              CGA,EGA  b800  Comp,RGB,Enhanced
	;        5  графика  320x200  4 полутона     CGA,EGA  b800  Composite
	;        6  графика  640x200  2              CGA,EGA  b800  Comp,RGB,Enhanced
	;        7  текст    80x25    3 (b/w/bold)   MA,EGA   b000  TTL Monochrome
	;       0Dh графика  320x200  16             EGA      A000  RGB,Enhanced
	;       0Eh графика  640x200  16             EGA      A000  RGB,Enhanced
	;       0Fh графика  640x350  3 (b/w/bold)   EGA      A000  Enhanced,TTL Mono
	;       10h графика  640x350  4 или 16       EGA      A000  Enhanced
	; Результат:
	;     (Флаг CF = 1, если такого нет)
		pusha

		; Существует ли такой видео-режим?
		cmp		al, 10h
		jg		CVM_false
		cmp		al, 8
		jl 		CVM_true
		cmp		al, 0Ch
		jg		CVM_true

	CVM_false:
		stc
		jmp		CVM_exit
	CVM_true:
		clc
		xor		ah, ah
		int		10h
	CVM_exit:
		popa
		ret
change_video_mode endp

change_display_page proc		; Изменение активной страницы дисплея
	; 05h выбрать активную страницу дисплея
    ; Вход:  AL = номер страницы (большинство программ использует страницу 0)
	; Допустимые номера для режимов:
	;       Режим  Номера
	;       ====== =======
	;        0      0-7
	;        1      0-7
	;        2      0-3
	;        3      0-3
	;        4       0
	;        5       0
	;        6       0
	;        7       0
	;       0Dh     0-7
	;       0Eh     0-3
	;       0Fh     0-1
	;       10h     0-1
	; Результат:
	;     (Флаг CF = 1, если номер недопустим)
		pusha

		mov			bl, al
		mov			ah, 0Fh				; Читать текущий видео-режим
		int			10h					; Вход:  нет
										; Выход: al = текущий режим (см. функцию 00h)
										;        ah = число текстовых колонок на экране
										;        bh = номер активной страницы дисплея

		test	bl, bl			; 0 доступна всем
		jz		CDP_true

		cmp		bl, 1			; 1 страница
		jne		_CDP_1

		cmp		al, 4
		jl		CDP_true
		cmp		al, 7
		jg		CDP_true
		jmp		CDP_false

	_CDP_1:						; 2-3 страницы
		cmp		bl, 3
		jg		_CDP_2

		cmp		al, 4
		jl		CDP_true
		cmp		al, 0Dh
		je		CDP_true
		jmp		CDP_false

	_CDP_2:						; 4-7 страницы
		cmp		bl, 7
		jg		CDP_false

		cmp		al, 2
		jl		CDP_true
		cmp		al, 0Dh
		je		CDP_true
		jmp		CDP_false

	CDP_false:
		stc
		jmp		CDP_exit
	CDP_true:
		clc
		mov		ah, 05h
		mov		al, bl
		int		10h
	CDP_exit:
		popa
		ret
change_display_page endp
