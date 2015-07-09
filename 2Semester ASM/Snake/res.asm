;**********************************************************; 
;*  Self High-Loading TSR Program -- 32 bytes resident!!  *; 
;*                    By Tenie Remmel                     *; 
;**********************************************************; 
 
Ideal 
Model Tiny 
P186 
Codeseg 
Org 100h 
 
Proc        Prog 
 
            mov dx,offset RName     ;Only leaves 32 bytes! 
            mov si,offset RName     ;also name offset 
            mov cx,0                ;No int. vectors 
            jmp TSRHi               ;TSR procedure 
 
RName       db 'Test',0             ;This is the resident name 
 
EndP        Prog 
 
Proc        TSRHi   ;Registers on entry: 
                    ; 
                    ;   DX = last byte of program 
                    ;   CS = segment of program

                    ;   CS:SI = resident name (8 bytes) 
                    ;   CX = Number of vectors to set 
                    ;   CS:BX = Vector list 
                    ;           
                    ; Vector list format: <offset> <number> ... 
                    ;                      -word-   -byte- 
             
            pusha                   ;Save all registers 
            push cs                 ;DS = CS 
            pop ds 
 
            mov ah,4Ah              ;Reallocate Memory 
            mov bx,1000h            ;BX = 64K 
            push cs                 ;ES = code segment 
            pop es 
            int 21h                 ;DOS services 
             
            mov ah,49h              ;Free memory 
            mov es,[2Ch]            ;Environment block 
            int 21h                 ;DOS services 
             
            mov ax,5800h            ;Get Alloc. Strategy 
            int 21h                 ;DOS services  
            push ax                 ;Save value 
            mov ax,5802h            ;Get UMB Link 
            int 21h                 ;DOS services 
            push ax                 ;Save value 
             
            mov ax,5803h            ;Set UMB Link 
            mov bx,1                ;1 = Link ON 
            int 21h                 ;DOS services 
            mov ax,5801h            ;Set Alloc. Strategy 
            mov bx,82h              ;Last Fit, UMBs First 
            int 21h                 ;DOS services 
             
            mov ah,48h              ;Allocate Memory 
            mov bx,dx               ;BX = last byte 
            sub bx,0F1h             ;BX - 100h + 0Fh 
            shr bx,4                ;BX = size in paras 
            int 21h                 ;DOS services 
            jc _NoMem               ;Jump if error 
             
            dec ax                  ;AX = MCB seg. 
            mov es,ax               ;ES = AX 
            inc ax                  ;AX = memory block 
            mov [es:1],ax           ;Set owner to itself 
            mov di,8                ;Move name to MCB:8 
            mov cx,4                ;8 bytes = 4 words 
            rep movsw               ;Move by words 
             
            mov ax,5803h            ;Set UMB Link

            pop bx                  ;to old value 
            int 21h                 ;DOS services 
            mov ax,5801h            ;Set Alloc. Strategy 
            pop bx                  ;to old value 
            xor bh,bh 
            int 21h                 ;DOS services 
             
            mov ax,es               ;AX = new CS segment 
            sub ax,0Fh 
            mov es,ax               ;ES = AX 
            popa                    ;Restore original regs 
            mov si,100h             ;SI = 100h 
            mov di,si               ;DI = 100h 
            push cx                 ;Save CX 
            mov cx,dx               ;CX = last byte 
            sub cx,100h             ;CX = length 
            rep movsb               ;Move data 
 
            pop cx                  ;Restore CX 
            jcxz _NoVects           ;No vectors to set? 
            mov ah,25h              ;Set Interrupt Vector 
            push es                 ;DS = ES 
            pop ds 
_SetIVect:  lodsw                   ;Load offset 
            mov dx,ax               ;into DX 
            lodsb                   ;Load int. number 
            int 21h                 ;Set vector 
            loop _SetIVect          ;Loop back 
 
_NoVects:   mov ax,4C00h            ;Return with code 0 
            int 21h                 ;DOS services 
 
_NoMem:     mov ax,5803h            ;Set UMB Link 
            pop bx                  ;to old value 
            int 21h                 ;DOS services 
            mov ax,5801h            ;Set Alloc. Strategy 
            pop bx                  ;to old value 
            xor bh,bh 
            int 21h                 ;DOS services 
             
            mov ax,cs               ;ES = MCB segment 
            dec ax 
            mov es,ax 
            mov di,8                ;Move name to MCB:8 
            mov cx,4                ;8 bytes = 4 words 
            rep movsw               ;Move by words 
             
            popa                    ;Restore original regs 
            push dx                 ;Save DX 
            jcxz _NoVects1          ;No vectors to set? 
            mov ah,25h              ;Set Interrupt Vector 
_SetIVect1: lodsw                   ;Load offset 
            mov dx,ax               ;into DX 
            lodsb                   ;Load int. number 
            int 21h                 ;Set vector 
            loop _SetIVect1         ;Loop back 
 
_NoVects1:  mov ax,3100h            ;TSR service, code 0 
            pop dx                  ;Restore DX 
            add dx,0Fh              ;DX = size in paras, 
            shr dx,4                ;rounded up 
            int 21h                 ;DOS services 
 
EndP        TSRHi 
 
End Prog 
 