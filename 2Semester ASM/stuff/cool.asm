
;PROG SEGMENT
	;ASSUME cs:PROG, ds:PROG, ss:PROG, es:NOTHING
.model tiny
.code
	ORG 2Ch
		EnvPtr	label word	; определить метку для доступа
							; к слову в PSP, которое ука-
							; зывает на сегмент, содержа-
							; щий блок операционной среды
							; (он обычно освобождается для
							; создания более компактной
							; резидентной программы)
	ORG 80h
	CmdLength label byte	; определить метку для доступа
							; к длине командной строки

	ORG 1h
	CmdLine  label byte		; определить метку для доступа
							; к тексту командной строки

	ORG 100h

 @entry:
 	jmp	@start

 error_ENV:
	add ax, 48
	mov dl, al
	mov ah, 02h
	int 21h
	mov dl, 'E'
	mov ah, 02h
	int 21h
		mov ah,4Ch
		int 21h

 no_params:
	mov ah, 02h
	mov dl, 'N'
	int 21h
	mov dl, 'P'
	int 21h
		mov ah,4Ch
		int 21h

 @start:

	; освободить блок операционной среды

	mov		es, EnvPtr		; ES -> блок операционной среды
	mov		ah, 49h			; функция 49h: освободить блок
							; памяти
	int		21h				; 
	jc		error_ENV		; ошибка освобождения EnvBlock?

	; анализ командной строки

	mov   al, CmdLength		; длина командной строки
	or    al,al				; проверка на 0
	jz    no_params			; нет параметров
	mov   cl,al				; поместить длину в cl
	mov   ch,0
	mov   si,offset CmdLine	; адрес командной строки
	mov   al,' '			; символ для поиска
	repne scasb				; поиск первого пробела
	;
	; остальная часть файла .COM резидентной программы:
	int 20h

;PROG ENDS
end @entry
