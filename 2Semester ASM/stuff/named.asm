.model tiny
.code

; Никита Селезнев, ФИИТ-301
;
; Резидентная программа, которая ничего не делает,
; зато в утилитах типа tdmem имеет имя

org 100h

@entry:
	jmp @start
	new_name	db	20h,00h,00h,01h,00h,'such wow very name',00h
	len			dw	$-new_name

@start:
	;mov es, ax
	
	mov ax, word ptr cs:[2ch]	; Где лежит название программы
	mov cx, len					; Длина source
	mov si, offset new_name		; Адрес source
	mov es, ax
	xor di, di 					; es:[di] <- адрес destination
	rep movsb; ++di, ++si, mov

	lea dx, @start

	int 27h

code ends
end @entry
