cseg segment use16
assume CS:cseg, DS:cseg
Org 100h


entry:
	call main

message  db "Hello world, I'm 16bit Dos Assembly !!!", "$"
charchar db ?

array dw 256 dup (?)
len   dw (?)
msg_1 DB 'Enter length of array:', 13, 10, 62, 32,'$'
msg_2 DB 'Enter array (delimiters are any non-digit symbols):', 13, 10, 62, 32,'$'
msg_3 DB 'Subarray of full squares:', 13, 10, 62, 32,'$'



include IntLib16.inc
include SexyPrnt.inc
include Task1v16.inc

main proc

mov  ax, 0900h       ; Печать символов до '$'
mov  dx,offset msg_1 ; Сообщение1 'Введите длину'
int  21h             ; 

call read_int2       ; reads_int, returns to ax
mov  len, ax
call print_int2      ; prints int from ax
call CRLF

cmp len, 0           ; Проверка массива на пустоту
je start_task_one

mov  ax, 0900h
mov  dx,offset msg_2 ; Сообщение2 'Введите массив'
int  21h

; push 	offset[array]
; push 	len
; call 	read_int2_array

call print_open_bracket
xor  si, si          ; Обнуляем счетчик
reading_cycle:
    call read_int2
    mov  array[si], ax
    add  si, 2
    call print_int2
    call print_comma
    call print_space
    mov  ax, len
    shl  ax, 1
    cmp  si, ax
    jl   reading_cycle
call print_backspace
call print_backspace
call print_close_bracket
call CRLF

; push offset[array]
; push len
; call print_int2_array

push offset[array]
push len
call get_full_squares

mov len, di
mov array, si

start_task_one:

mov  ax, 0900h
mov  dx,offset msg_3 ; Сообщение3 'Массив квадратов'
int  21h

push offset[array]
push len
call print_int2_array

endz:
mov  ax, 4c00h
int  21h
main endp


cseg ends
end entry
