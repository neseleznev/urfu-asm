model tiny
.486
.code
org 100h
 
	
_A0 equ 43388
_As0 equ 40953
_B0 equ 38654
_C1 equ 36485
_Cs1 equ 34437
_D1 equ 32504
_Ds1 equ 30680
_E1 equ 28958
_F1 equ 27332
_Fs1 equ 25798
_G1 equ 24350
_Gs1 equ 22984
_A1 equ 21694
_As1 equ 20476
_B1 equ 19327
_C2 equ 18242
_Cs2 equ 17218
_D2 equ 16252
_Ds2 equ 15340
_E2 equ 14479
_F2 equ 13666
_Fs2 equ 12899
_G2 equ 12175
_Gs2 equ 11492
_A2 equ 10847
_As2 equ 10238
_B2 equ 9663
_C3 equ 9121
_Cs3 equ 8609
_D3 equ 8126
_Ds3 equ 7670
_E3 equ 7239
_F3 equ 6833
_Fs3 equ 6449
_G3 equ 6087
_Gs3 equ 5746
_A3 equ 5423
_As3 equ 5119
_B3 equ 4831
_C4 equ 4560
_Cs4 equ 4304
_D4 equ 4063
_Ds4 equ 3835
_E4 equ 3619
_F4 equ 3416
_Fs4 equ 3224
_G4 equ 3043
_Gs4 equ 2873
_A4 equ 2711
_As4 equ 2559
_B4 equ 2415
_C5 equ 2280
_Cs5 equ 2152
_D5 equ 2031
_Ds5 equ 1917
_E5 equ 1809
_F5 equ 1708
_Fs5 equ 1612
_G5 equ 1521
_Gs5 equ 1436
_A5 equ 1355
_As5 equ 1279
_B5 equ 1207
_C6 equ 1140
_Cs6 equ 1076
_D6 equ 1015
_Ds6 equ 958
_E6 equ 904
_F6 equ 854
_Fs6 equ 806
_G6 equ 760
_Gs6 equ 718
_A6 equ 677
_As6 equ 639
_B6 equ 603
_C7 equ 570
_Cs7 equ 538
_D7 equ 507
_Ds7 equ 479
_E7 equ 452
_F7 equ 427
_Fs7 equ 403
_G7 equ 380
_Gs7 equ 359
_A7 equ 338
_As7 equ 319
_B7 equ 301
_C8 equ 285
 
 
start:
    saveOldHandler:
    mov     ax, 3509h          	;сохраняем обработчик 9ого прерывания
    int     21h                     ; ES:BX
    mov     word ptr oldH + 0, bx
    mov     word ptr oldH + 2, es
   
    setMyHandler:
    mov     ax, 2509h
    lea     dx, myHandler
    int     21h                     ; DS:DX
 
    cicle:
        cmp     escape, 1h              ; повторять пока не выставлен флаг
        je      setOldHandler
        mov     stopPlay, 00h
       
        cmp     needToPlay, 00h ;если ниче не нажали играть
        je      cicle
       
        cmp     numOfComp, 01h
        je      firstToPlay
        cmp     numOfComp, 02h
        je      secondToPlay
        cmp     numOfComp, 03h
        je      thirdToPlay
                        cmp                 numOfComp, 04h
                        je                      fourthToPlay
                        cmp                 numOfComp, 05h
                        je                      fifthToPlay
        jmp     xcv 		;надо ли это
 
        firstToPlay:
            lea     bx, songOne
            mov     toPlay[0], bx
            lea     bx, stayOne
            mov     toPlay[2], bx
            lea     bx, lenOne
            mov     toPlay[4], bx
        jmp     xcv
       
        secondToPlay:
            lea     bx, songTwo
            mov     toPlay[0], bx
            lea     bx, stayTwo
            mov     toPlay[2], bx
            lea     bx, lenTwo
            mov     toPlay[4], bx
        jmp     xcv
       
        thirdToPlay:
            lea     bx, songThree
            mov     toPlay[0], bx
            lea     bx, stayThree
            mov     toPlay[2], bx
            lea     bx, lenThree
            mov     toPlay[4], bx
        jmp     xcv
 
                        fourthToPlay:
                            lea     bx, songFour
                            mov     toPlay[0], bx
                            lea     bx, stayFour
                            mov     toPlay[2], bx
                            lea     bx, lenFour
                            mov     toPlay[4], bx
                        jmp     xcv
 
                        fifthToPlay:
                            lea     bx, songFive
                            mov     toPlay[0], bx
                            lea     bx, stayFive
                            mov     toPlay[2], bx
                            lea     bx, lenFive
                            mov     toPlay[4], bx
                        jmp     xcv
 
       
        xcv:
        call    playSong
    jmp     cicle      
 
 
    setOldHandler:
    push    ds
    mov     ax, 2509h
    mov     dx, word ptr oldH + 0
    mov     ds, word ptr oldH + 2
    int     21h                     ; DS:DX
    pop     ds
   
    exit:  
    mov     ah, 4Ch
    int     21h
 
songOne     dw  _G4, 0, _G4, _C5, _Ds4, _F4, 0, _Gs4 
            dw  _G4, _F4, _Ds4, _F4,0, _G4, _F4, _Ds4, _D4, _Ds4, 0, _G4, _F4
            dw  _Ds4, _D4, _Ds4,0, _Gs4, _G4, _F4, _Ds4, _F4,0, _Gs4, _G4, _F4 
            dw  _Ds4, _F4,0, _G4,0, _G4,0, _G4,0, _F4, _G4, 0
            


	
stayOne     dw  5,1,5,10,5,10,3,5,5,5,5,10,3
            dw  5,5,5,5,10,3,5,5,5,5,10,3
            dw  5,5,5,5,10,3,5,5,5,5,10,3
            dw  5,1,5,1,5,1,5,10,5
            
lenOne      dw  46
 
 
songTwo dw _G4,0, _As4, _G4, _F4,0,  _Ds4,0, _As4, _G4, _Fs4,0, _Fs4, _C5, _A4
	dw _As4,0, _As4, _G4, _F4, 0,_Ds4,0, _As4, _G4, _A4, 0
 
stayTwo dw  16,5,8,8,16,5,16,5,8,8,8,2
        dw  8,8,8,16,5,8,8,16,5,16, 5
        dw  8,8,16,10
 
lenTwo  dw  27
	
songFour dw _D2, _As2,0, _As2, _A2, _As2,0, _G2, _A2, _As2,0, _As2,0, _As2, _Ds3, _As2,0, _As2, _A2, 0
	 dw _D2, _D3,0, _D3,0, _D3,0, _D3, _A2,0, _A2,0, _A2, _G2,0, _D3, _C3,0, _C3,0, _D2, _As2, _A2, _As2, 0
	 dw _As2,0, _As2,0, _As2,0, _As2, _Ds3, _As2,0, _As2, _A2,0, _A2, _D3,0, _D3,0, _D3,0, _D3, _A2,0, _A2,0, _A2
	 dw _G2,0, _G2, _D3, _C3,0, _C3, 0
 
stayFour  dw  6,5,1,5,5,11,4,  5,5,5,1,5,1,5
          dw  7,5,1,5,11,4,5,5,1,5,1,5,1,6,5,1
	  dw  5,1,5,11,4,5,5,1,11,4,5,5,5,11
	  dw  4,5,1,5,1,5,1,5,6,5,1,5,11,4
	  dw  6,5,1,5,1,5,1,6,5,1,5,1,5,11,4,5,6,5,1,11,12
	
lenFour dw  79

 
songFive   dw _C4, _F4,0, _F4,0, _F4,0, _F4,0, _F4,0, _G4, _Gs4, _G4, _F4,0, _F4, 0 ;18
           dw _F4,0, _F4,0,_F4,0, _F4, _Ds4,0, _Ds4,0, _Ds4, _F4, _Ds4,0, _Ds4 ;16
	   dw _Cs4,0, _Cs4, _C4,0, _C4,0, _C4,0, _C4,0, _C4, _Cs4, _C4,0, _C4,  0 ;17
	   dw _C4,0,_C4,0, _C4,0, _C4,0, _C4, _As3,0, _As3,0, _As3, _C4,0, _C4,0, _C4,0, _C4,0 ;22
	   dw _C4,0, _C4,0, _C4, _E4,0, _E4,0, _E4, _F4, _G4, 0, 0 ;14
 
 
stayFive    dw 7,4,1,4,1,4,1,4,1,4,6,4,4,4,4,1,7,2 ;18
            dw 4,1,4,1,4,1,4,4,1,4,1,4,6,4,1,4,4,1,4,4,1,4,0 ;23
            dw 4,1,4,1,4,4,4,1,4,1,4,1,6,1,4,1,4,1,4,4,1,4,1,4,4,1 ;26
	    dw 4,1,4,1,6,5,4,1,4,1,4,4,1,4,1,4,1,4,6,10		   ;20
	
lenFive     dw  87 
 
 
songThree  dw _G3, _A3, _As3, _A3, _G3, _A3, _As3, _A3, _G3, _A3, _As3, _D4, 0
           dw _G3, _A3, _As3, _A3, _G3, _A3, _As3, _A3, _G3, _A3, _As3, _Ds4,0
	   dw _C4, _D4, _Ds4, _D4,0, _C4, _D4, _Ds4, _D4, 0,_C4, _As3, _A3, _C4, _As3
	   dw _C4, _D4, _C4,0, _As3, _A3, _G3, _As3, _A3, _As3, _C4, _As3, _A3, _G3, _Fs3, _G3, 0
	
stayThree   dw 3,3,3,5,  3,3,3,5,3,3
            dw 3,8,5,3,3,3,5,3,3,3,5
	    dw 3,3,3,8,5,3,3,3,4,2,3,3
	    dw 3,4,2,3,3,3,3,3,3,3,4
	    dw 2,3,3,3,3,3,3,3,3,3,3
	    dw 3,8,10
	
lenThree    dw  58
   
 
soundHz dw  0000h
soundStay   dw  0000h
 
oldH        dw  ?, ?
escape      db  0000h
stopPlay    db  00h
needToPlay  db  00h
numOfComp   db  00h
 
toPlay      dw  ?,?,?
 
playSong proc   
    pusha
    .st:
    mov     bx, toPlay[4] 	;длина
    mov     cx, [bx]
    mov     bx, 0
 
    pl:
        cmp     stopPlay, 01h 	;
        je      jmpToStop
       
        mov     si, toPlay[0] 	; смещение песни 
        mov     ax, [si + bx]
        mov     soundHz, ax
 
        mov     si, toPlay[2] 	; ритм
        mov     ax, [si + bx]
        mov     soundStay, ax 
       
        call    soundOn
        call    staySomeUnit
   
        add     bx, 2
    loop    pl
    jmp .st
    mov     needToPlay, 00h
    jmpToStop:
    call    soundOff
       
    popa
    ret
endp
 
soundOn proc    
    pusha
   
    cmp soundHz, 0
    jne next
    call    soundOff
    popa
    ret
   
    next:
    mov     ax, soundHz
    out     42h, al     ; Записать младший байт и старший байт частоты
    mov     al, ah
    out     42h, al 		;порт 42h - канал 2 (управляет динамиком);
	;; включение динамика
    in      al, 61h     ; Считать текущую установку порта В   
    or      al, 3       ; Включить динамик После программирования канала 2 таймера надо еще включить сам динамик. Это осуществляется путем установки битов 0 и 1 порта 61h в 1
    out     61h, al	; теперь динамик включен
   
    popa
    ret
endp
 
soundOff proc    
    pusha
    in      al, 61h     ; Считать текущую установку порта В
    and     al, 11111100b 	; обнулить младшие два бита, выключение динамика
    out     61h, al
    popa
    ret
endp
   
stayUnit proc    
    pusha
;   mov     cx, 0FFFFh
;   stay:
;       nop
;   loop    stay
    xor     ax, ax
    mov     ah, 86h
    xor     cx, cx
				;mov cx, 01h
	mov dx, 60000
	;; xor     dx, 0a000h
    int     15h
    popa
    ret
endp
 
staySomeUnit proc    
    pusha
    mov     cx, soundStay
    s:
        call    stayUnit
    loop    s
    popa   
    ret
endp
   
myHandler proc    
    pusha
   
    in      al, 60h             ; скан код клавиши  
   
    cmp     al, 01h             ; проверка на нажатый esc (01 скан-код esc)
    jne     notEsc
    mov     escape, 1h
    mov     stopPlay, 01h
    notEsc:
   
    cmp     al, 02h
    je      first
    cmp     al, 03h
    je      second
    cmp     al, 04h
    je      third
    cmp     al, 05h
    je      fourth
    cmp     al, 06h
    je      fifth
    jmp     zxc
    ;       
    first:
        cmp     numOfComp, 01h
        jne     set1
        cmp     needToPlay, 00h
        jne     zxc
        set1:
        mov     stopPlay, 01h
        mov     numOfComp, 01h
        mov     needToPlay, 01h
    jmp zxc
   
    second:
        cmp     numOfComp, 02h
        jne     set2
        cmp     needToPlay, 00h
        jne     zxc
        set2:
        mov     stopPlay, 01h
        mov     numOfComp, 02h 
        mov     needToPlay, 01h
    jmp zxc
   
    third:
         cmp     numOfComp, 03h
        jne     set3
        cmp     needToPlay, 00h
        jne     zxc
        set3:
        mov     stopPlay, 01h
        mov     numOfComp, 03h
        mov     needToPlay, 01h
    jmp zxc
 
            fourth:
                        cmp                 numOfComp, 04h
                        jne                   set4
                        cmp                 needToPlay, 00h
                        jne                   zxc
                        set4:
                        mov                 stopPlay, 01h
                        mov                 numOfComp, 04h
                        mov                 needToPlay, 01h
            jmp zxc
 
            fifth:
                    cmp             numOfComp, 05h
                    jne               set5
                    cmp             needToPlay, 00h
                    jne               zxc
                    set5:
                    mov             stopPlay, 01h
                    mov             numOfComp, 05h
                    mov             needToPlay, 01h
            jmp zxc
   
    zxc: 			;если выбрали эту же композицию ? и в любом другом случае
    in      al, 61h             ;ввод поpта pВ
    mov     ah, al     		;push ax
    or      al, 80h             ;установить бит "подтвеpждения ввода"
    out     61h, al    
    xchg    ah, al              ;вывести стаpое значение pВ pop ax
    out     61h, al
;;обработчик аппаратного прерывания клавиатуры должен сообщить контроллеру прерываний, что обработка аппаратного прерывания закончилась командами
    mov     al, 20h             ;послать сигнал EOI
    out     20h, al             ;контpоллеpу пpеpываний
   
    popa
    iret
endp
 
end start

