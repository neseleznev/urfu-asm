.386
assume CS:cseg, DS:dseg, SS:sseg

sseg segment stack use16
	db 256 dup (?)
sseg ends

dseg segment use16
	max_len  db 36
	string_len db 0
	string db 16 dup (?)
	
	hFile dw ?
	fin db 33 dup(0)
	fout db 33 dup(0), 0h
	buf_len dw ?
	buf db 65 dup(0)
	ans db 200 dup(0)
	ans_len dw ?
	Message db 'ERROR',13,10,'$'
dseg ends

cseg segment use16
include printInt.inc
readString proc
	push ax
	push dx
	push di

	lea  dx, string-2
	mov  ah, 0Ah
	int  21h
	mov al, string_len
	mov ah, max_len
	cmp ah, al
	ja e
	mov ah, 9
	mov dx, offset message
	int 21h
	e:
	pop di
	pop dx
	pop ax
	ret
	
readString endp

readFile proc
	pusha

    mov ah, 3dh
	mov al, 0 ; чтение
	mov cx, 65
    mov dx, offset fin
    int 21h 
	mov hFile, ax ; номер файла
    
    mov ah, 3fh ; чтение файла
    mov bx, hFile
    mov cx, 64   ; количество читаемых байтов
    mov dx, offset buf ; адрес буфера
    int 21h
	mov [buf_len], ax
   
    mov ah, 3eh ; закрытие файла
    mov bx, hFile
    int 21h
	
	popa
	ret
readFile endp

writeBuf proc
	pusha
	
    mov ah, 3ch ; создание файла
    mov dx, offset fout
	mov cx, 0
    int 21h
	mov hFile, ax
    
    mov ah, 40h ; запись в файл
    mov bx, hFile
    mov cx, [ans_len]
    mov dx, offset ans
    int 21h
   
    mov ah, 3eh ; закрытие файла
    mov bx, hFile
    int 21h
	
	popa
	ret
writeBuf endp

createAns proc
	pusha
	cld
	mov ax, dseg
	mov es, ax
	mov si, offset buf
	mov di, offset ans
	mov cx, buf_len
	rep movsb
	mov si, offset string
	xor cx, cx
	mov cl, string_len
	rep movsb
	mov ax, buf_len
	xor cx, cx
	mov cl, string_len
	add ax, cx
	mov ans_len, ax
	popa
	ret
createAns endp

parseParam proc
	pusha

	xor cx, cx
	mov cl, es:[80h]
	dec cl

	mov si, 82h
	lea di, fin
	
	@cycle:
		mov ah, es:[si]
		inc si
		cmp ah, 32
		jz m3
		mov [di], ah
		inc di
		jmp m4
		m3:
		lea di, fout
		m4:
	loop @cycle

	popa
	ret
parseParam endp

start:
	mov	ax, dseg
	mov	ds, ax
	
	call readString
	call parseParam
	call readFile
	
	call createAns
	call writeBuf
	
	mov	ax, 4c00h
	int 21h
cseg ends
end start