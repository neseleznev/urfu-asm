model   small

.data                   ;Сегмент данных. Храним координаты тела змейки
snake   dw 0000h
        dw 0001h
        dw 0002h
        dw 0003h
        dw 0004h
        dw 7CCh dup('?')
tick    dw 0            ;Счетчик
.stack 100h

.code
;В начале сегмента кода будем размещать процедуры
delay proc
    push cx
    mov ah,0
    int 1Ah 
    add dx,3
    mov bx,dx
repeat:   
    int 1Ah
    cmp dx,bx
    jl repeat
    pop cx
    ret
delay endp
key_press proc
    mov ax, 0100h
    int 16h
    jz en           ;Без нажатия выходим
    xor ah, ah
    int 16h
    cmp ah, 50h
    jne up
    cmp cx,0FF00h       ;Сравниваем чтобы не пойти на себя
    je en
    mov cx,0100h
    jmp en
up: cmp ah,48h
    jne left
    cmp cx,0100h
    je en
    mov cx,0FF00h
    jmp en
left: cmp ah,4Bh
    jne right
    cmp cx,0001h
    je en
    mov cx,0FFFFh
    jmp en
right: cmp cx,0FFFFh
    je en
    mov cx,0001h
en:
    ret
key_press endp
add_food proc
sc: 
    inc bl              ;В регистре BL рандомное число
    cmp bx,50h    ;Проверяем границу числа
    jng ex
    shr bl,1           ;Если больше, делим на 2 логическим сдвигом
    jmp sc
ex:
    mov dl,bl         ;Запись координаты
sc2:    
    cmp bx,19h
    jng ex2
    shr bl,2
    jmp sc2
ex2:
    mov dh,bl         ;Запись координаты
    mov ax,0200h
    int 10h
    mov ax,0800h
    int 10h
    cmp al,2Ah       ;Проверяем пустое ли место
    je sc
    cmp al,40h      
    je sc                  ;Если нет повторяем
    mov ax,0200h
    mov dl,0024h
    int 21h
    ret
add_food endp
game_over proc
;Проверяем границы
    cmp dl,50h
    je exit
    cmp dl,0
    jl exit
    cmp dh,0
    jl exit
    cmp dh,19h
    je exit
;Проверяем символы
    cmp al,2Ah
    je exit
    cmp al,40h
    je exit
    jmp good
exit: 
    mov ax,4c00h
    int 21h
good:
    ret
game_over endp
start:
    mov ax,@data
    mov ds,ax
    mov es,ax

    mov ax,0003h
    int 10h             ;Очищаем игровое поле

    mov cx,5
    mov ax,0A2Ah
    int 10h             ;Выводим змейку из 5 символов "*"


    mov si,8            ;Индекс координаты символа головы
    xor di,di           ;Индекс координаты символа хвоста
    mov cx,0001h        ;Регистр cx используем для управления головой. При сложении от значения cx будет изменяться координата x или y
    mov bl,51h
    call add_food
main:               ;Основной цикл
    call delay
    call key_press
    xor bh,bh
    mov ax,[snake+si]       ;Берем координату головы из памяти
    add ax,cx               ;Изменяем координату x
    inc si              
    inc si
    cmp si,7CAh
    jne nex
    xor si,si
nex:
    mov [snake+si],ax       ;Заносим в память новую координату головы змеи
    mov dx,ax           
    mov ax,0200h
    int 10h             ;Вызываем прерывание. Перемещаем курсор

    mov ax,0800h
    int 10h                     ;Читает символ 
    call game_over
    mov dh,al

    mov ah,02h
    mov dl,002Ah
    int 21h             ;Прерывание выводит символ '*'

    cmp dh,24h
    jne next
        push cx             ;В стек регистр
    mov cx,[tick]
    inc cx
    cmp cx,5
    jne exl
    xor cx,cx
    mov ax,0200h        
    mov dx,[snake+di-2]
    int 10h
    mov ax,0200h
    mov dl,0040h
    int 21h
exl:mov [tick],cx
    pop cx
    call add_food
    jmp main
next:
    mov ax,0200h        
    mov dx,[snake+di]
    int 10h
    mov ax,0200h
    mov dl,0020h
    int 21h         ;Выводим пробел, тем самым удаляя хвост
    inc di
    inc di
    cmp di,7CCh
    jne main
    xor di,di
jmp main
end start        