code    segment                          ; определение кодового сегмента
        assume  cs:code,ds:code          ; CS и DS указывают на сегмент кода
        org     100h                     ; размер PSP для COM программы
start:  jmp     load                     ; переход на нерезидентную часть
        old     dd  0                    ; адрес старого обработчика 
        buf     db  ' 00:00:00 ',0       ; шаблон для вывода текущего времени
		string0 db 'smusl',0
		cmd 	db ?
		len		db 0

decode  proc                             ; процедура заполнения шаблона
        mov     ah,  al                  ; преобразование двоично-десятичного 
        and     al,  15                  ; числа в регистре AL
        shr     ah,  4                   ; в пару ASCII символов
        add     al,  '0'
        add     ah,  '0'
        mov     buf[bx + 1],  ah         ; запись ASCII символов
        mov     buf[bx + 2],  al         ; в шаблон
        add     bx,  3      
        ret                              ; возврат из процедуры
decode  endp                             ; конец процедуры 

zero_handler   proc                      ; процедура обработчика прерываний от таймера
        pushf                            ; создание в стеке структуры для IRET
        call    cs:old                   ; вызов старого обработчика прерываний
        push    ds                       ; сохранение модифицируемых регистров
        push    es
	push    ax
	push    bx
        push    cx
        push    dx
	push    di
        push    cs
        pop     ds

		mov		ah, 09h
		mov		dx, offset string0
		int		21h


ReadCL proc ;чтение параметров командной строки в буфер по адресу ES:[DI]
            ;DS должен остаться неизменным после запуска программы (=PSP)
	mov SI,80h  ;адрес парамтеров
	xor CX,CX
	mov CL,[SI] ;длина в байтах
	inc SI      ;игнорируем байт длины
	rep movsb   ;перемещаем строку в буфер
	mov AL,0
	stosb       ;завершаем строку ASCIIZ нулем
ret   
ReadCL endp  

@@5:    pop     di                       ; восстановление модифицируемых регистров
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        pop     es
        pop     ds
        iret                             ; возврат из обработчика
zero_handler   endp                             ; конец процедуры обработчика

end_zero_handler:                               ; метка для определения размера резидентной
                                        		; части программы
										 
load:   

		;call ReadCL
		
		cld
		mov 	si, 82h
		xor		cx, cx
		mov		cl, es:[80h]
		mov		len, cl
		
		lea bx, cmd
		
		jcxz    m1
		cycle:
				lodsb
				mov dl, al
				mov ah, 02h
				int 21h
				
				mov byte ptr [bx],al
				inc bx
				
				loop    cycle
		m1:
		
		mov byte ptr [bx], 0
		
		mov		ah, 09h
		mov		dx, offset cmd
		int 21h
		
		int 20h
		mov 	ah, 4Ch
		int 	21h
		;mov     ax,  3500h               ; получение адреса старого обработчика
        ;int     21h                      ; прерываний от таймера
        ;mov     word ptr old,  bx        ; сохранение смещения обработчика
        ;mov     word ptr old + 2,  es    ; сохранение сегмента обработчика
        ;mov     ax,  2500h               ; установка адреса нашего обработчика
        ;mov     dx,  offset zero_handler        ; указание смещения нашего обработчика
        ;int     21h                      ; вызов DOS
        ;mov     ax,  3100h               ; функция DOS завершения резидентной программы
        ;mov     dx, (end_zero_handler - start + 10Fh) / 16 ; определение размера резидентной
                                                    ; части программы в параграфах
        ;int     21h                      ; вызов DOS
		
code    ends                             ; конец кодового сегмента
end     start                    		 ; конец программы