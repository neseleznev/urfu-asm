	IDEAL
	MODEL tiny	; com-файл

	CONST
UP	EQU	01
DOWN	EQU	02
LEFT	EQU	03
RIGHT	EQU	04
heade	EQU	0000111010110010b	;символ ▓ желтый
body	EQU	0000111010110000b	;символ ░ желтый
rabitb	EQU	0000011100101010b	;символ * серый

	DATASEG
StrPoints	db	'Ваши очки:      ходы:$'
GoodBye		db	'Чтобы начать новую игру нажмите Y, выход N.'
t		dw	1	;вспомогательнпя переменная
ExFlag		db	0	;флаг
mooving		dw	?	;ходы
time		dw	?	;время задержки
Points		dw	?	;очки
a		dw	?	;вспомогательная переменная
piton		dw	500 dup (?)	координаты питона

	CODESEG
	ORG 100h
Start:
	call StartingCondition	;начальные условия
@@1:	
	mov ah,1		;проверка на нажатие клавиши
	int 16h			;оброботка клавиши
	call Press		;обработка нажатой клавиши
	cmp [ExFlag],1		
	je Exit			;если ExFlaf=1 идем на выход		
	xor ah,ah
	int 1Ah
	mov cx,dx		;получаем текущее время
	sub dx,[a]		;dx=dx-a
	cmp dx,[time]		;сравниваем со временем задержки
	jbe @@1			;если dx>=a
	call DecDigit		;печатаем ходы и очки
	inc [mooving]		;увеличиваем кол-во шагов
	call Rabit		;ставим кролика
	mov [a],cx		;в a - новое время
	call UPiton		;новое положение питона
	jmp @@1		
Exit:	
	call StopTimer		;закрываем ворота таймера
	call More		;запрашиваем о продолжении
	cmp [ExFlag],0		
	je Start		;если продолжить
	call SetScreen		;очистить экран
	mov ah,04Ch		;конец программы
	int 21h

;печатаем символ из ax на текущие позиции питона
PROC	PutPiton
	push es
	push si		;сохраняем регистры
	push cx
	push di
	mov cx,0B800h	;видеопамять
	mov es,cx
	mov cx,500	;max длина питона
	mov di,2
	cmp al,' '	;если в ax пробел
	je @@p1		;переходим

	mov ax,heade		;печатаем голову питона
	mov si,[piton+di]	;в  si координаты головы	
	inc di
	inc di
	mov [es:si],ax		;печатаем
	mov ax,body		;в ax тело питона
@@p1:
	mov si,[piton+di]	
	cmp si,0FFFFh		;хвост питона
	je @@p2			;в цикле печатаем питона пока
	inc di			;не нарвемся на хвост
	inc di
	mov [es:si],ax
	loop @@p1
@@p2:
	pop di
	pop cx			;восстанавливаем регистры
	pop si
	pop es
	ret
ENDP	PutPiton

;очищаем экран
PROC	SetScreen
	mov cx,0B800h
	mov es,cx
	mov cx,2000	;всего символов на экране
	xor si,si
@@p3:
	mov [es:si],0000011100100000b	;это пробел серого цвета
	add si,2
	loop @@p3	
	ret
ENDP	SetScreen

;вычисляем новую позицию питона
PROC	ReBuild
	push bx
	push cx		;сохраняем изменяемые регистры
	push dx		
	push si
	push es
	mov cx,500	;max длина питона
	mov si,4
	cmp [word piton],UP	;в зависимости от первого слова
	je @@pUp		;осуществляем переход
	cmp [word piton],DOWN
	je @@pDw
	cmp [word piton],LEFT
	je @@pLf
	cmp [word piton],RIGHT
	je @@pRh
@@pUp:
	mov bx,[piton+2]
	sub [word piton+2],160	;вверх
@@p5:
	cmp [piton+si],0FFFFh	;хвост питона
	je  @@ex
	mov dx,[piton+si]	;каждой последующей позиции присваиваем
	mov [piton+si],bx	;координаты предыдущей
	mov bx,dx
	inc si
	inc si
	loop @@p5
	jmp @@ex

@@pDw:
	mov bx,[piton+2]
	add [word piton+2],160	;вниз
@@p6:
	cmp [piton+si],0FFFFh	;хвост питона
	je @@ex
	mov dx,[piton+si]	;каждой следующей позиции присваиваются
	mov [piton+si],bx	;координаты предыдйщей
	mov bx,dx
	inc si
	inc si
	loop @@p6
	jmp @@ex

@@pLf:
	mov bx,[piton+2]	;влево
	sub [word piton+2],2
@@p7:
	cmp [piton+si],0FFFFh	;хвост питона
	je @@ex
	mov dx,[piton+si]
	mov [piton+si],bx
	mov bx,dx
	inc si
	inc si
	loop @@p7
	jmp @@ex

@@pRh:
	mov bx,[piton+2]	;вправо
	add [word piton+2],2	
@@p8:
	cmp [piton+si],0FFFFh	;хвост питона
	je @@ex
	mov dx,[piton+si]
	mov [piton+si],bx
	mov bx,dx
	inc si
	inc si
	loop @@p8

@@ex:	
	mov di,0B800h		;видепамять
	mov es,di
	xor di,di
	mov si,[piton+2]
	mov dx,[es:si]
	cmp dx,rabitb   	;если на пути питона кролик
	jne @@e
@@p15:
	add di,2
	cmp [piton+di],0FFFFh
	jne @@p15		;находим хвост питона
	inc [Points]		;увеличиваем очки

	cmp [Points],30		;если набрали 30 очков - уменьшаем 
	jne @@p25		;время задержки
	dec [Time]
	jmp @@p30
@@p25:
	cmp [Points],70		;если набрали 70 очков - уменьшаем
	jne @@p30		;время задержки
	dec [Time]
@@p30:

	mov bx,[piton+di-2]	;наращиваем хвост питона по направлению
	mov dx,[piton+di-4]	;движения
	sub dx,bx
	add bx,dx
	mov [piton+di],bx
	mov [piton+di+2],0FFFFh	;хвост питона
@@e:
	pop es
	pop si
	pop dx			;восстанавливаем регистры
	pop cx		
	pop bx
	ret
ENDP	ReBuild

PROC	UPiton
	push es
	mov ax,0000011100100000b	;это серый пробел	
	call PutPiton			;стираем питона
	call ReBuild			;новые координаты
	push 0B800h			;видеопамять
	pop es
	mov si,[piton+2]		;в si позиция головы питона
	inc si
	cmp [byte es:si],00001001b	;наехал питон
	jne @@p21
	mov [ExFlag],1			;на рамку
@@p21:	
	mov ax,[body]	
	call PutPiton			;печатаем самого питона
	pop es
	ret
ENDP	UPiton

;обрабатываем нажатую клавишу
PROC 	Press
	push dx
	jz @@p9		;если буфер клавиатуры пуст, то выходим
	xor ah,ah	;иначе считываем код нажатой клавиши
	int 16h
	cmp ax,011bh	;это клавиша ESC-выход
	jne @@p16
	mov [ExFlag],1	
@@p16:
	mov dx,[piton]
	mov [word piton],UP
	cmp ax,4800h		;клавиша вверх
	je @@p9	
	mov [word piton],DOWN
	cmp ax,5000h		;клавиша вниз
	je @@p9	
	mov [word piton],LEFT	
	cmp ax,4B00h		;клавиша влево
	je @@p9	
	mov [word piton],RIGHT	
	cmp ax,4D00h		;клавиша вправо
	je @@p9	
	mov [piton],dx
@@p9:
	pop dx
	ret
ENDP 	Press

;процедура генерирует случайное число через таймер
PROC	GetRandom
	push es
	push si			;сохраняем регистры
	push bx
	mov ax,0B800h
	mov es,ax		;видеопамять
@@p21:
	mov al,10000110b	;управляющее слово
	out 43h,al
	in al,42h
	mov ah,al
	in al,42h
	xchg al,ah		;в ax случайное число от 1 до 1600
	shl ax,1		;в ax случацное число до 3200- это
	mov si,ax		;координата кролика
	inc si
	mov bl,00001010b	;аттрибут самого питона
	cmp [byte es:si],bl
	je @@p21
	mov bl,00001001b	;аттрибут рамки
	cmp [byte es:si],bl
	je @@p21

	pop bx			
	pop si			;восстанавливаем регистры
	pop es
	ret
ENDP	GetRandom

;процедура печатает кролика
PROC	Rabit
	push ax
	push si		;сохраняем регистры
	push es
	inc [t]
	mov si,25
	sub si,[Time]
	cmp [t],si
	jne @@p10	;если прошло меньше чем 24-Time ходов - выходим
	call GetRandom	;получаем координату кролика
	mov si,ax
	mov ax,0B800h
	mov es,ax
	mov ax,rabitb
	mov [es:si],ax	;печатаем кролика
	mov [t],1
@@p10:
	pop es
	pop si		;восстанавливаем регистры
	pop ax
	ret
ENDP	Rabit

;прцедура рисует рамку и печатает внизу строку
PROC	Place
	push es
	mov ax,0B800h
	mov es,ax
	mov al,'╔'
	mov ah,00001001b	;синий цвет
	mov [es:0000],ax	;печатаем уголки	
	mov al,'╚'
	mov [es:3200],ax
	mov al,'╗'
	mov [es:158],ax
	mov al,'╝'
	mov [es:3358],ax
	mov cx,78
	mov si,2
	mov al,'═'
@@p19:
	mov [es:si],ax		;печатаем горизонтальные линии
	mov [es:si+3200],ax
	inc si		
	inc si
	loop @@p19
	mov cx,19
	mov al,'║'
	mov si,160
@@p20:
	mov [es:si],ax
	mov [es:si+158],ax	;печатаем вертикальные линии
	add si,160		
	loop @@p20
	xor si,si
	xor di,di
@@p22:	mov al,[StrPoints+si]
	cmp al,'$'
	je @@pe	
	mov [es:3420+di],ax	;печатаем пока не встретим символ $
	inc di
	inc di
	inc si
	jmp @@p22
@@pe:
	pop es
	ret
ENDP	Place

; Процедура выводит значение dx на экран в десятичном виде
PROC	DecDigit
        push ax
	push bx
        push cx    	; сохранение используемых в процедуре
        push dx    	; регистров в стеке
        push si
	push es
	push di
	mov dx,[Points]
	xor bx,bx
Sta:	
	xor di,di
	mov cx,0B800h	;видеопамять
	mov es,cx
        mov ax,dx
        mov si,10 	; делим на 10
        mov cx,0   	; счет чисел помещенных в стек
@nz:
        mov dx,0
        div si		; частное в ax, остаток в dx
        push dx    	; поместить 1 цифру в стек
        inc cx
        cmp ax,0   	; сравнение ax с 0
        jne @nz
	cmp bx,1	
	je @m2
@m1:

        pop dx     	;взять цифры в обратном порядке
        add dl,'0'
	mov dh,00001010b	;зеленый цвет
        mov [es:3442+di],dx
	inc di
	inc di
        loop @m1
	mov dx,[mooving]	
	mov bx,1
	jmp Sta		;возвращаемся к началу процедуры и 
			;печатаем ходы
@m2:

        pop dx     	;взять цифры в обратном порядке
        add dl,'0'
	mov dh,00001010b	;зеленый цвет
        mov [es:3464+di],dx
	add di,2
        loop @m2

	pop di
	pop es
        pop si
        pop dx
        pop cx     	;восстанавливаем регистры из стека
	pop bx
        pop ax
        ret
ENDP	DecDigit


;процедура делает запрос на продолжение игры
PROC	More
	push es
	mov si,0B800h		;видеопамять
	mov es,si
	mov si,0FFFFh
	mov ah,00001010b	;зеленый цвет
@@p32:	inc si
	mov al,[byte GoodBye+si];в al буква из строки
	shl si,1		;si=si*2		
	mov [es:3580+si],ax	;печатаем
	shr si,1		;si=si/2
	cmp al,'.' 		;печатаем, пока не встретим точку
	jne @@p32
@@no:	mov ah,01		;ждем нажатия клавиши
	int 21h
	cmp al,'Y'			
	jne @@p31
	mov [ExFlag],0		;если продолжить
	jmp @@p33
@@p31:
	cmp al,'N'
	jne @@no		;если не Y и не N спросить еще раз
@@p33:	
	pop es
	ret
ENDP	More

;программируем таймер
PROC	SetTimer
	in al,61h		;открываем ВОРОТА для канала 2
	or al, 00000001b	
	out 61h,al
	mov al,10110110b	;управляющий байт
	out 43h,al		;канал-2 байта-2 режим-3 в двоичном виде  
	mov ax,1600		;max возможное случайное число
	out 42h,al		
	mov al,ah
	out 42h,al
	ret
ENDP	SetTimer	

PROC	StopTimer
	in al,61h	;закрываем ВОРОТА для канала 2
	and al,11111110b
	out 61h,al
	ret
ENDP	StopTimer

;процедура устанавливает начальные установки игры
PROC	StartingCondition
	mov ah,02h		;скрыть курсор
	mov dh,25
	int 10h
 	mov [time],2		;начальная задержка
	mov [Points],0		;в начале - 0 очков
	mov [mooving],0		;0 ходов
	call SetTimer		;для получения случайных чисел
	xor ah,ah		;получить текущее время
	int 1Ah		
	mov [a],dx		;сохранить в a 
	call SetScreen		;очистка экрана
	call Place		;нарисовать рамку		
	call DecDigit		;вывести очки
	mov [piton],DOWN	;сначала питон ползет вправо
	mov dx,170		;начальная позиция питона	
	mov [piton+2],dx
	mov dx,172
	mov [piton+4],dx
	mov [piton+6],0FFFFh	;это хвост питона
	mov ax,[body]	
	call PutPiton		;печатаем питона на экран	
	ret
ENDP	StartingCondition
	END Start