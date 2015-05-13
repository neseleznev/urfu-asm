; ����� ��������, ����-301, 2015
; ������
; 1. ����᪨� ०�� 10h, ����⠭�������� ०�� �� ��室�
; 2. �� ��ࠡ��稪� ���뢠��� ��������� (⮫쪮 ����室��� ���)
; 3. ��ࠢ����� ��५����, �஡��=��㧠, esc=��室. ��⠫쭮� �� �������
; 4. ������ �������, ��� ���, �����, 㬨ࠥ� �� ��몠��� � �⥭�� ��� � ᥡ�. �� ��� ������ �窨, ����� �⮡ࠦ����� � ����� ����
; 5. �⠭���⭮� ���� - ��אַ㣮�쭨� � �࠭�栬�
;���誨: ������ ���� ��쥧��� ��ࠡ�⪠ �����⬠ / ���� �����, ��� ������ - ��-�, �ॡ��饥 �ਫ�筮� ������⢮ �ᨫ�� ��� ॠ����樨 / ��������饥 ������ ���� �㭪樮���
;�業�� - ��� �業����� ����⢮ �믮������ ࠡ���, ������ ����, ��⨬����� (���� �������� � ᨫ쭮 ����⨬���஢����/���娬 �����), �ࠬ�⭮� �ᯮ�짮����� ���뢠���. ����� �� ����� ���誮� - ⮦� �� ��� ����� :)
;�᫨ ���� ������, ��������, ���㤨� ��� �������� �� ⮣�, ��� �� 㧭���, �� ����﫨 ����� �� ���⮬ ����.
;
.186
.model tiny
.code
ORG 100h

@entry:     jmp   @start

include SexyPrnt.inc
include Sound.inc

;catch_09h:
    ;pusha
    ;    in      al, 60h             ; ᪠�-��� ��᫥���� ����⮩ (�� 60 ����)
    ;
    ;    mov     di,     tail
    ;    mov     buffer[di], al
    ;    inc     tail
    ;    and     tail,   0Fh
    ;    mov     ax,     tail
    ;    cmp     head,   ax
    ;    jne     @catch_09h_put
    ;    inc     head
    ;    and     head,   0Fh
    ;
    ;@catch_09h_put:
    ;    in      al,     61h
    ;    or      al,     80h
    ;    out     61h,    al
    ;    and     al,     07Fh
    ;    out     61h,    al
    ;    mov     al,     20h
    ;    out     20h,    al          ; �����⭮�� ����஫���� �㦥� ᨣ��� ....
    ;popa
    ;iret

randgen             proc
    ; ax = ����� ��������� [0...ax]
        or      ax, ax      ; range value != 0
        jz      RND_end
        push bx
        push cx
        push dx
        push ds

        push    ax
        ;push    cs
        ;pop     ds
        mov     ax, RND_seed1
        mov     bx, RND_seed2;load seeds
        mov     cx, ax      ; save seed
        mul     RND_const
        shl     cx, 1
        shl     cx, 1
        shl     cx, 1
        add     ch, cl
        add     dx, cx
        add     dx, bx
        shl     bx, 1       ; begin scramble algorithm
        shl     bx, 1
        add     dx, bx
        add     dh, bl
        mov     cl, 5
        shl     bx, cl
        add     ax, 1
        adc     dx, 0
        mov     RND_seed1, ax
        mov     RND_seed2, dx ;save results as the new seeds
        pop     bx          ; get back range value
        xor     ax, ax
        xchg    ax, dx      ; adjust ordering
        div     bx ;ax = trunc((dx,ax) / bx), dx = (r)
        xchg    ax, dx      ; return remainder as the random number
        pop ds
        pop dx
        pop cx
        pop bx
    RND_end:
        ret
randgen             endp

print_int_3chars    proc
    ; �室: ax - �᫮
    pusha
    PiVM_next:
        mov     bx, 10
        mov     cx, 3
        int9_bite_off:
            xor     dx, dx
            div     bx          ; ax = ax / 10
            push    dx          ; dx = ax % 10
        loop    int9_bite_off

        mov     ah, 02h
        mov     cx, 3
        int9_print_digit:
            pop     dx
            add     dl, '0'
            int     21h
        loop    int9_print_digit
    popa
    ret
print_int_3chars    endp

;delay              proc
    ;
    ;pusha
    ;    mov     ah, 0
    ;    int     1Ah
    ;    add     dx, 2
    ;    mov     bx, dx
    ;delay_loop:   
    ;    int     1Ah
    ;    cmp     dx, bx
    ;    jl      delay_loop
    ;popa
    ;ret
;delay              endp


add_food            proc
    ; �室: al - 梥�
    push ax
        mov     ax, 78         ; �ᥢ��-࠭������ �᫮
        call    randgen         ; �� 0 �� 78
        mov     cx, ax          ; ������ ���न���� x
 
        mov     ax, 38          ; 
        call    randgen         ; �� 0 �� 38
        mov     dx, ax          ; ������ ���न���� y

        ;�஢��塞 ���⮥ �� ����
        mov     ah, 0Dh         ; Read Pixel
        xor     bh, bh          ; Page 0
        push cx
        push dx
        shl     cx, 3       ; cx*8 (�ਭ� �祩��)
        shl     dx, 3       ; �������筮
        add     dx, 15      ; ����� ��� ⥪�� � ��祣�
        add     cx, 8
        add     dx, 8
        int     10h         ; �८�ࠧ��뢠�� ���न���� � �࠭�� � ��訢��� 梥� ���ᥫ�
        pop dx
        pop cx

        cmp     al, color_poo     ; ����
        je      AF_collision
        cmp     al, color_food     ; ����窮
        je      AF_collision
        cmp     al, color_snake     ; ���� ����
        je      AF_collision
        cmp     al, color_border     ; �⥭��
        je      AF_collision      ;�᫨ �����, �����塞

    pop ax
        call    draw_snake_pixel
        jmp     AF_end
    AF_collision:
        pop ax
        jmp     add_food
    AF_end:
    ret
add_food            endp


check_head_position proc
    ; �஢����, �� ��室���� �� �������� ��� ������ ����樨,
    ; ��ࠡ����
    ; �室:     cx - x (� ��襩 �⪥ (80-2)x(40-2))
    ;           dx - y
    ; �������:
    ;           CF=1, �᫨ �� �㦭� ����� 墮�� (�� �ꥫ� ���)

    ; �஢��塞 �࠭��� ����
        cmp     cx, 78
        jge     CHP_exit
        cmp     dx, 38
        jge     CHP_exit
    ; �஢��塞 ᨬ����
        mov     ah, 0Dh         ; Read Pixel
        xor     bh, bh
        push cx
        push dx
        inc     cx
        inc     dx
        shl     cx, 3           ; cx*8 (�ਭ� �祩��)
        shl     dx, 3           ; �������筮
        add     dx, 15          ; ����� ��� ⥪�� � ��祣�
        ;add     cx, 8 �������
        ;add     dx, 8 � ����� inc ��। 㬭������� �� 8 (���)
        int     10h
        pop dx
        pop cx
        
        cmp     al, color_food       ; ������
        je      CHP_food
        cmp     al, color_speed_up       ; Speed-up
        je      CHP_increase_speed
        cmp     al, color_speed_down     ; Speed-down
        je      CHP_decrease_speed
        cmp     al, color_border         ; �⥭��
        je      CHP_exit
        cmp     al, color_poo            ; ����誨
        je      CHP_exit
        cmp     al, color_snake          ; ������
        je      CHP_exit
        jmp     CHP_good
    CHP_exit:
        mov     game_over, 1
        jmp     CHP_good

    CHP_food:
        push    cx
        push    dx
        inc     score               ; �����稬 ����

        ; ����誨
        inc     food_eaten
        cmp     food_eaten, 5
        jl      WC_not_now
        mov     food_eaten, 0
        mov     al, color_poo
        mov     dx, [snake+di-2]
        mov     cl, dh              ; cx - x
        xor     dh, dh              ; dx - y
        call    draw_snake_pixel
     WC_not_now:
     print_score:
        mov     ah, 02h         ; �����
        xor     bh, bh          ; � ������ 0,0
        xor     dx, dx
        mov     dl, str_score_len
        int     10h
        
        mov     ax, score
        call    print_int_3chars

        mov     al, color_food
        call    add_food
        pop     dx
        pop     cx
        stc
        ret

    CHP_increase_speed:
        xor     ah, ah                    ; 0->1, 1->2, ..., 7->7
        mov     al, speed_freq_x1000
        push dx
        inc speed_multiplier
        mul     speed_multiplier          ; �஢�ਬ, �� ������� ����⥫�
        dec speed_multiplier            
        pop dx

        cmp     ax, 0Fh                   ; ����� �� �ॢ������ FFFFh
        jg      CHP_good                   ; pass_increasing

        inc     speed_multiplier
        inc     speed_multiplier
    CHP_decrease_speed:
        cmp     speed_multiplier, 0      ; 7->6, 6->5, 0->0
        je      CHP_good                  ; pass_decreasing
        dec     speed_multiplier
        pusha

        mov     ah, speed_freq_x1000
        shl     ah, 4
        xor     al, al
        mul     speed_multiplier
        mov     bx, 0FFFFh
        sub     bx, ax
        call    reprogram_pit
        
        popa
        ;jmp     CHP_good
    CHP_good:
        clc
        ret
check_head_position endp

mushroom_effect     proc
    pusha
    mov     ax, 0501h
    int     10h

    mov     ax, 0A800h;0A000h
    mov     es, ax

    mov     si, 1;4;8
    ME_loop:
        mov     cx, 640-1;-8
        ME_x:
            mov     dx, 320-1;350-1-15;-8
            ME_y:

                mov     ah, 0Dh         ; Read Pixel
                xor     bh, bh
                int     10h

                test    al, al
                jz      pass_drawing

                ;add     ax, si
                ;mov     al, cl

                push dx
                mov     ax, dx
                mov     dx, 320
                mul     dx
                mov     di, ax
                add     di, cx
                mov     es:[di], 1;si
                ;mov     ah, 0Ch
                ;mov     bh, 1
                ;int     10h
                pop dx

                pass_drawing:

                dec     dx
                cmp     dx, 0;15;+8
                jge     ME_y
            loop    ME_x
        dec     si
        cmp     si, 0;8
        jge     ME_loop
        ;loop    ME_loop
    mov     ax, 0500h
    int     10h
    popa
    ret
mushroom_effect     endp

terminate_program   proc

    call    stop_play_note  
    mov     bx, 0FFFFh
    call    reprogram_pit
        mov     ah, 00h
        mov     al, 10h
        int     10h
        ; ����⠭�������� �����-०��
        mov     ah, 00h
        mov     al, original_videomode
        int     10h
        mov     ah, 05h
        mov     al, original_videopage
        int     10h
        ; ����⠭�������� ����� 09h
        ;mov     ax, 2509h
        ;mov     dx, word ptr cs:[old_09h]
        ;mov     ds, word ptr cs:[old_09h+2]
        ;cli
        ;    int     21h
        ;sti
        mov     ax, 4c00h
        int     21h
        ret
terminate_program   endp

draw_border         proc
    mov     ah, 0Ch         ; Function Draw Pixel
    mov     al, color_border         
    xor     bh, bh          ; Page 0
    mov     dx, 15          ; y coord

    mov     cx, 640*8 + 7   ; x coord = [8 ��ப](640*8) - 1 + [��� ����� �࠭���](8)
    DB_topEZ:
        int     10h
        loop DB_topEZ
    int     10h             ; ���� ���� ���ᥫ� (��⮬� �� cx=0 break)

    mov     dx, 350 - 15 - 8; y coord
    mov     cx, 640*8 - 1   ; x coord = [8 ��ப](640*8) - 1
    DB_bottomEZ:
        int     10h
        loop    DB_bottomEZ
    int     10h

    mov     dx, 15 + 8          ; y (15 + 8top)
    DB_left_right_yEZ:
        mov     cx, 640 - 8
        DB_left_right_xEZ:
            int     10h
            inc     cx
            cmp     cx, 640 + 8
            jl      DB_left_right_xEZ

        inc     dx
        cmp     dx, 350 - 15 - 8
        jl      DB_left_right_yEZ

    ret
draw_border         endp


draw_snake_pixel    proc
    ; �室: cx - x ���न���
    ;       dx - y ���न���
    ;       al - 梥�
    pusha
        shl     cx, 3       ; cx*8 (�ਭ� �祩��)
        shl     dx, 3       ; �������筮
        add     dx, 15      ; ����� ��� ⥪�� � ��祣�

        add     cx, 8
        add     dx, 8

        mov     ah, 0Ch
        xor     bh, bh

        mov     si, 7       ; ���� �� x
        DSP_x:
            add     cx, si
            mov     di, 7       ; ���� �� y
            DSP_y:
                add     dx, di
                int 10h
                sub     dx, di
                dec     di
                test    di, di
                jns     DSP_y   ; di >= 0
            sub     cx, si
            dec     si
            test    si, si
            jns     DSP_x   ; si >= 0
    popa
    ret
draw_snake_pixel    endp

init_snake          proc
    mov     al, color_snake
    mov     cx, 2
    mov     dx, 0
    IS:
        call    draw_snake_pixel
        loop    IS
    ret
init_snake          endp

init_snake2         proc
    mov     al, color_snake
    mov     si, score
    IS2:
        mov     dx, [snake+si]
        xor     ch, ch
        mov     cl, dh
        xor     dh, dh
        call    draw_snake_pixel
        dec si
        dec si
        test    si, si
        jns     IS2
    ret
init_snake2         endp


@start:

    call    init_play_note
    mov     bx, 0FFFFh
    call    reprogram_pit

    mov     ah, 00h             ; ��⠭���� ⥪�饥 ���祭��
    xor     dh, dh              ; ��⥬���� ⠩��� ��� ��砫��
    int     1Ah                 ; seed ��� �ᥢ��-࠭����                
    mov     RND_seed1, dx
    xor     dh, dh
    int     1Ah
    mov     RND_seed2, dx

    mov     ah, 0Fh             ; ���࠭�� ��砫�� �����-०��
    int     10h                 ; � �⮡ࠦ����� ��࠭���
    mov     original_videomode, al
    mov     original_videopage, bh

    mov     ax, 0010h           ; ���室�� � ����᪨� ०��
    int     10h                 ; ����� 10h
    ; ��⠭���� ��ࠡ��稪 INT 09h � ��࠭�� ����
    ;mov     ax, 3509h
    ;int     21h
    ;mov     [old_09h],  bx
    ;mov     [old_09h+2],es
    ;mov     ax, 2509h
    ;mov     dx, offset catch_09h
    ;cli
    ;    int     21h
    ;sti
    start_loop:
        call    menu
        call    ax
        jmp     start_loop
    ret

menu                proc

    menu_draw:

        mov     bh, 1           ; ����� �⮡ࠦ����� ��࠭��� (����� ����)
        mov     ah, 05h         ; ������� �� ��࠭��� #1
        mov     al, bh
        int     10h

        ; ���⪠ �࠭�
        mov     ah, 02h
        mov     bx, 0100h
        mov     dx, 0000h
        int     10h
        mov     ah, 09h
        mov     al, ' '
        mov     cx, 80*25
        int     10h

        ; ����ᨪ� (�����)
        mov     ah, 02h         ; �����
        ;mov    bh, 1           ; � ������ dl,dh
        mov     dl, str_classic_len ; ���⥬
        shr     dl, 1           ; �������� ����� ��ப�
        neg     dl              ; ��
        add     dl, 40          ; �।��� �࠭�
        mov     dh, 7
        int     10h
        mov     ah, 09h         ; ��ப� ����ᨪ�
        lea     dx, str_classic
        int     21h
        mov     ah, 02h         ; �����
        ;mov    bh, 1            ; � ������ 11,40
        mov     dl, 40-1
        mov     dh, 8
        int     10h
        mov     ah, 02h
        mov     dl, 24          ; ��५�� �����
        int     21h

        ; ��室 (����)
        mov     ah, 02h         ; �����
        ;mov    bh, 1            ; � ������ dl,dh
        mov     dl, str_exit_len ; ���⥬
        shr     dl, 1           ; �������� ����� ��ப�
        neg     dl              ; ��
        add     dl, 40          ; �।��� �࠭�
        mov     dh, 11
        int     10h
        mov     ah, 09h         ; ��ப� ��室
        lea     dx, str_exit
        int     21h
        mov     ah, 02h         ; �����
        ;mov    bh, 1            ; � ������ 8,40
        mov     dl, 40-1
        mov     dh, 10
        int     10h
        mov     ah, 02h
        mov     dl, 25          ; ��५�� ����
        int     21h

        ; (�����)
        mov     ah, 02h         ; �����
        ;mov    bh, 1            ; � ������ dl,dh
        mov     dl, str_modern_len ; ���⥬ ����� ��ப�
        neg     dl              ; ��
        add     dl, 40-3        ; �।��� �࠭� - 3 ᨬ���� ��� ��५��
        mov     dh, 9
        int     10h
        mov     ah, 09h         ; ��ப�
        lea     dx, str_modern
        int     21h
        mov     ah, 02h         ; �����
        ;mov    bh, 1            ; 
        mov     dl, 40-3
        mov     dh, 9
        int     10h
        mov     ah, 02h
        mov     dl, 17          ; ��५�� �����
        int     21h

        ; (��ࠢ�)
        mov     ah, 02h         ; �����
        ;mov    bh, 1            ; � ������ dl,dh
        mov     dl, 40+3        ; �।��� �࠭�
        mov     dh, 9
        int     10h
        mov     ah, 09h         ; ��ப�
        lea     dx, str_right
        int     21h
        mov     ah, 02h         ; �����
        ;mov    bh, 1            ; 
        mov     dl, 40+1
        mov     dh, 9
        int     10h
        mov     ah, 02h
        mov     dl, 16          ; ��५�� ��ࠢ�
        int     21h

        cmp     game_over, 0
        je      draw_pause_msg
        ; GAME OVER
        mov     ah, 02h         ; �����
        ;mov    bh, 1            ; � ������ dl,dh
        mov     dl, str_gameover1_len ; ���⥬
        shr     dl, 1           ; �������� ����� ��ப�
        neg     dl              ; ��
        add     dl, 40          ; �।��� �࠭�
        mov     dh, 16
        int     10h
        mov     ah, 09h         ; ��ப�
        lea     dx, str_gameover1
        int     21h

        mov     ah, 02h         ; �����
        ;mov    bh, 1            ; � ������ dl,dh
        mov     dl, str_gameover2_len ; ���⥬
        shr     dl, 1           ; �������� ����� ��ப�
        neg     dl              ; ��
        add     dl, 40-2          ; �।��� �࠭�
        mov     dh, 18
        int     10h
        mov     ah, 09h         ; ��ப�
        lea     dx, str_gameover2
        int     21h
        mov     ax, score
        call    print_int_3chars
        mov     game_over, 0
        jmp     menu_loop

     draw_pause_msg:
        cmp     game_in_progress, 0
        je      menu_loop
        ; ����⠭����� ���� (Esc)
        mov     ah, 02h         ; �����
        ;mov    bh, 1            ; � ������ dl,dh
        mov     dl, str_resume1_len ; ���⥬
        shr     dl, 1           ; �������� ����� ��ப�
        neg     dl              ; ��
        add     dl, 40          ; �।��� �࠭�
        mov     dh, 16
        int     10h
        mov     ah, 09h         ; ��ப�
        lea     dx, str_resume1
        int     21h

        mov     ah, 02h         ; �����
        ;mov    bh, 1            ; � ������ dl,dh
        mov     dl, str_resume2_len ; ���⥬
        shr     dl, 1           ; �������� ����� ��ப�
        neg     dl              ; ��
        add     dl, 40          ; �।��� �࠭�
        mov     dh, 18
        int     10h
        mov     ah, 09h         ; ��ப�
        lea     dx, str_resume2
        int     21h

    ; TODO �������� ����প� - ���� �� ��砩���� ������ ��५��
    mov     ticks, 0
    menu_delay:               ;�᭮���� 横�
        cmp     ticks, 5
        jl      menu_delay

    menu_loop:
        ;mov     di, tail
        ;mov     ah, buffer[di-1]

        mov     ax, 0100h
        int     16h
        jz      menu_loop           ; ��� ������ - ��� ��
        xor     ah, ah
        int     16h

        cmp     game_in_progress, 0 ; �᫨ ���  ��� �� ����, � �� 
        je      menu_not_esc        ; ���� �� ���� ������ Esc ��� �� ����⠭�������
        cmp     ah, 1h              ; 
        jne     menu_not_esc
        ; Esc - ����⠭����� ����
        mov     ax, 0500h           ; ������� ��࠭��� �� #0
        int     10h                 ; �.�. �������� � ��஢��� ����
        jmp     menu_end
     menu_not_esc:
        cmp     ah, 50h
        jne     menu_not_d
        ; ���� - ��室
        mov     ax, offset terminate_program
        jmp     menu_end
     menu_not_d:
        cmp     ah, 48h
        jne     menu_not_ud
        ; ����� - ����� ��� classic
        mov     game_in_progress, 0  ; New classic
        mov     score, 2
        mov     [snake+0], 0100h
        mov     [snake+2], 0200h
        mov     ax, offset classic   ; game
        jmp     menu_end
     menu_not_ud:
        cmp     ah, 4Bh
        jne     menu_not_udl
        ; ����� - modern
        mov     game_in_progress, 0  ; New modern
        mov     score, 2
        mov     [snake+0], 0100h
        mov     [snake+2], 0200h
        mov     ax, offset modern    ; game
        jmp     menu_end
     menu_not_udl:
        cmp     ah, 4Dh
        je      menu_r
        jmp     menu_loop           ; �������⭠� ������ - ��� ��
     menu_r:
        ; ��ࠢ�
        mov     ax, offset terminate_program
        jmp     menu_end

    menu_end:
        ret
menu                endp


classic_init        proc
    ; ���樠������ ०��� Classic
    ; ��頥� ��஢�� ����
        xor     bh, bh          ; ����� ���� ��࠭�� #0
        mov     ax, 0010h
        int     10h
    ; ��ப� ����
        mov     ah, 02h         ; �����
        ;xor     bh, bh         ; � ������ 0,0
        xor     dx, dx
        int     10h
        mov     ah, 09h
        lea     dx, str_score
        int     21h
        mov     ax, score
        call    print_int_3chars
    ; ��ࠢ�� �� ����⠬
        mov     ah, 02h         ; �����
        ;xor     bh, bh          ; � ������ 0,15
        xor     dx, dx
        mov     dl, 15
        int     10h
        mov     ah, 09h         ; ��ப� ����
        lea     dx, str_tutor_classic
        int     21h

        mov     ah, 02h         ; �����
        ;xor     bh, bh         ; � ������ 0,80-len
        mov     dx, 80
        sub     dl, str_hotkey_len
        int     10h
        mov     ah, 09h         ; Esc - menu
        lea     dx, str_hotkey
        int     21h

        mov     al, color_food
        mov     cx, 12
        mov     dx, -3
        call    draw_snake_pixel
        mov     al, color_poo
        mov     cx, 20
        call    draw_snake_pixel
    ; ���⨪ � ������
        call    draw_border
        call    init_snake
    ; ���न���� ������, 墮��, ���ࠢ�����, ��ࢠ ���
        mov     si, score
        dec     si
        shl     si, 1
        xor     di, di          ;������ ���न���� ᨬ���� 墮��
        mov     direction, 0100h;direction ��� �ࠢ����� �������. dir[0] - ���饭�� ���न���� x (1 ��� -1), dir[1] - y (1 ��� -1) 
        mov     food_eaten, 0

        mov     al, color_food
        ;mov     cx, 0800h
        ;debug_superfood:
        call    add_food
        ;loop    debug_superfood
        mov     game_in_progress, 1
        mov     current_game, offset classic
    ret
classic_init        endp

classic             proc
    ;
    ;
    cmp     game_in_progress, 1
    je      classic_main

    call classic_init

    classic_main:               ;�᭮���� 横�
        cmp     ticks, 2
        jl      classic_main
        mov     ticks, 0

    key_press:
        ; ��ࠡ�⪠ ������ ������ � ��ᢠ������ ���祭�� ��६����� direction,
        ; �⢥��饩 �� ���ࠢ����� ������. ��ࠢ����� ��५����.
        pusha
            mov     cx, direction
            ;mov     ax, head
            ;cmp     ax, tail
            ;je      classic_main

            ;mov     di, tail
            ;mov     al, buffer[di-1]
            mov     ax, 0100h
            int     16h
            jz      KP_end           ; ��� ������ ��室��
            xor     ah, ah
            int     16h
            xchg    ah, al

            cmp     al, 1h           ; �᫨ �� �⦠⨥ ������ Esc
            je      KP_menu          ; ��୥��� � ����
            cmp     al, 50h
            je      KP_down
            cmp     al, 48h
            je      KP_up
            cmp     al, 4Bh
            je      KP_left
            cmp     al, 4Dh
            je      KP_right
            jmp     KP_end

            KP_down:
            cmp     cx, 0FFFFh      ; �ࠢ������ �⮡� �� ���� �� ᥡ�
            je      KP_end
            mov     cx, 0001h       ; ���� => x 0, y 1
            jmp     KP_end
            KP_up:
            cmp     cx, 0001h
            je      KP_end
            mov     cx, 0FFFFh      ; ����� => x 0, y -1
            jmp     KP_end
            KP_left:
            cmp     cx, 0100h
            je      KP_end
            mov     cx, 0FF00h      ; ����� => x -1, y 0
            jmp     KP_end
            KP_right:
            cmp     cx, 0FF00h
            je      KP_end
            mov     cx, 0100h       ; ��ࠢ� => x 1, y 0
            jmp     KP_end
            KP_menu:
                popa
                ret
            KP_end:
                mov     direction, cx
        popa


        mov     dx, [snake+si]      ;��६ ���न���� ������ �� �����
        add     dx, direction       ;�����塞 ���न���� � ����ᨬ��� �� ���ࠢ�����
        inc     si              
        inc     si
        and     si, 0FFh
        mov     [snake+si], dx      ;����ᨬ � ������ ����� ���न���� ������ ����

        xor     cx, cx
        mov     cl, dh              ; cx - x
        xor     dh, dh              ; dx - y
        call    check_head_position ; �஢�ન �� �⮫�������� � �⥭���, ᮡ��, ����宩

        pushf
            cmp     game_over, 1
            jne     draw_head
            popf
            mov     game_in_progress, 0
            ret
            draw_head:
            ; ����� ������ �஢�७�, ����� ���ᮢ��� ⠬ ������        
            mov     al, color_snake
            call    draw_snake_pixel
        popf

        ; �⮨� �� ����� 墮��?
        jnc     erase_tail
        jmp     classic_main
 
    erase_tail:
        mov     dx, [snake+di]
        mov     al, 0
        xor     cx, cx
        mov     cl, dh
        xor     dh, dh
        call    draw_snake_pixel
        inc     di
        inc     di
        and     di, 0FFh
        jmp     classic_main
    ret
classic             endp


modern_init         proc
    ; ���樠������ ०��� Modern
    ; ��頥� ��஢�� ����
        xor     bh, bh          ; ����� ���� ��࠭�� #0
        mov     ax, 0010h
        int     10h
    ; ��ப� ����
        mov     ah, 02h         ; �����
        ;xor     bh, bh         ; � ������ 0,0
        xor     dx, dx
        int     10h
        mov     ah, 09h
        lea     dx, str_score
        int     21h
        mov     ax, score
        call    print_int_3chars
    ; ��ࠢ�� �� ����⠬
        mov     ah, 02h         ; �����
        ;xor     bh, bh          ; � ������ 0,15
        xor     dx, dx
        mov     dl, 15
        int     10h
        mov     ah, 09h         ; ��ப� ����
        lea     dx, str_tutor_modern
        int     21h
        
        mov     ah, 02h         ; �����
        ;xor     bh, bh         ; � ������ 0,80-len
        mov     dx, 80
        sub     dl, str_hotkey_len
        int     10h
        mov     ah, 09h         ; Esc - menu
        lea     dx, str_hotkey
        int     21h

        mov     al, color_food
        mov     cx, 12
        mov     dx, -3
        call    draw_snake_pixel
        mov     al, color_poo
        mov     cx, 20
        call    draw_snake_pixel
        mov     al, color_mushroom
        mov     cx, 26
        call    draw_snake_pixel
        mov     al, color_speed_up
        mov     cx, 37
        call    draw_snake_pixel
        mov     al, color_speed_down
        mov     cx, 46
        call    draw_snake_pixel
    ; ���⨪ � ������
        call    draw_border
        call    init_snake
    ; ���樠������ ������ � 墮��, ���ࠢ�����
        mov     si, score
        dec     si
        shl     si, 1
        xor     di, di          ;������ ���न���� ᨬ���� 墮��
        mov     direction, 0100h;direction ��� �ࠢ����� �������. dir[0] - ���饭�� ���न���� x (1 ��� -1), dir[1] - y (1 ��� -1)
        mov     food_eaten, 0
        mov     speed_multiplier, 0
        mov     speed_ticks, 0
        mov     mushroom_ticks, 0
        mov     bx, 0FFFFh
        call    reprogram_pit

        mov     al, color_food
        ;mov     cx, 0800h
        ;debug_superfood:
        call    add_food
        ;loop    debug_superfood
        mov     game_in_progress, 1
        mov     current_game, offset modern
    ret
modern_init         endp

modern              proc
    ;
    ;
    cmp     game_in_progress, 1
    je      modern_main

    call modern_init

    modern_main:               ;�᭮���� 横�
        cmp     ticks, 2
        jl      modern_main
        mov     ticks, 0

    M_extra_items:
        cmp     speed_ticks, 0
        je      M_no_speed
        dec     speed_ticks
        cmp     speed_ticks, 0
        jne     M_no_speed
        pusha
            mov     al, 00h
            mov     dx, speed_up_coord
            mov     cl, dh
            xor     ch, ch
            xor     dh, dh
            call    draw_snake_pixel

            mov     dx, speed_down_coord
            mov     cl, dh
            xor     dh, dh
            call    draw_snake_pixel
        popa
        M_no_speed:

        cmp     mushroom_ticks, 0
        je      M_no_mushroom
            mov     dx, mushroom_coord
            mov     cl, dh
            xor     ch, ch
            xor     dh, dh
            mov     al, color_mushroom
            add     al, 0;8
            mov     color_mushroom, al
            call    draw_snake_pixel
                                    ;xor ah,ah
                                    ;and al, 0Fh
                                    ;call print_int2
        dec     mushroom_ticks
        cmp     mushroom_ticks, 0
        jne     M_no_mushroom
        pusha
            mov     al, 00h
            mov     dx, mushroom_coord
            mov     cl, dh
            xor     ch, ch
            xor     dh, dh
            call    draw_snake_pixel
        popa
        M_no_mushroom:

    M_key_press:
        ; ��ࠡ�⪠ ������ ������ � ��ᢠ������ ���祭�� ��६����� direction,
        ; �⢥��饩 �� ���ࠢ����� ������. ��ࠢ����� ��५����.
        pusha
            mov     cx, direction

            ;mov     ax, head
            ;cmp     ax, tail
            ;je      modern_main

            ;mov     di, tail
            ;mov     al, buffer[di-1]
            mov     ax, 0100h
            int     16h
            jz      M_KP_end           ;��� ������ ��室��
            xor     ah, ah
            int     16h
            xchg    ah, al

            cmp     al, 1h              ; �᫨ �� �⦠⨥ ������ Esc
            je      M_KP_menu              ; �����訬 �믮������ �ணࠬ��
            cmp     al, 50h
            je      M_KP_down
            cmp     al, 48h
            je      M_KP_up
            cmp     al, 4Bh
            je      M_KP_left
            cmp     al, 4Dh
            je      M_KP_right
            jmp     M_KP_end

            M_KP_down:
            cmp     cx, 0FFFFh       ; �ࠢ������ �⮡� �� ���� �� ᥡ�
            je      M_KP_end
            mov     cx, 0001h       ; ���� => x 0, y 1
            jmp     M_KP_end
            M_KP_up:
            cmp     cx, 0001h
            je      M_KP_end
            mov     cx, 0FFFFh      ; ����� => x 0, y -1
            jmp     M_KP_end
            M_KP_left:
            cmp     cx, 0100h
            je      M_KP_end
            mov     cx, 0FF00h      ; ����� => x -1, y 0
            jmp     M_KP_end
            M_KP_right:
            cmp     cx, 0FF00h
            je      M_KP_end
            mov     cx, 0100h       ; ��ࠢ� => x 1, y 0
            jmp     M_KP_end
            M_KP_menu:
                popa
                ret
            M_KP_end:
                mov     direction, cx
        popa

        ;cmp     ticks, 2
        ;jl      modern_main
        ;mov     ticks, 0

    M_move_snake:
        ;mov     dx, direction
        ;mov     actual_direction, dx
        mov     dx, [snake+si]      ;��६ ���न���� ������ �� �����
        add     dx, direction       ;�����塞 ���न���� � ����ᨬ��� �� ���ࠢ�����
        inc     si              
        inc     si
        and     si, 0FFh
        mov     [snake+si], dx      ;����ᨬ � ������ ����� ���न���� ������ ����

        xor     cx, cx
        mov     cl, dh              ; cx - x
        xor     dh, dh              ; dx - y
        call    check_head_position ; �஢�ન �� �⮫�������� � �⥭���, ᮡ��, ����宩

        pushf
            cmp     game_over, 1
            jne     M_draw_head
            popf
            mov     game_in_progress, 0
            ret
            M_draw_head:
            ; ����� ������ �஢�७�, ����� ���ᮢ��� ⠬ ������        
            mov     al, color_snake
            call    draw_snake_pixel
        popf

        ; �⮨� �� ����� 墮��? �� ���� �ꥫ� �� ���?
        jc      M_snake_grows

    M_erase_tail:
        mov     dx, [snake+di]
        mov     al, 0
        xor     cx, cx
        mov     cl, dh
        xor     dh, dh
        call    draw_snake_pixel
        inc     di
        inc     di
        and     di, 0FFh
        jmp     modern_main
    
    M_snake_grows:
        ; �᫨ ��� �ꥤ��� - ������� ���
        mov     bx, 01000h
        call    reprogram_pit
        mov     ax, food_eaten

        mov     ah, 2           ; 2 ��⠢� (������)
        mov     bl, 16          ; 16-�� ���
        mov     cx, 128         ; 128 bpm
        
        add     al, 0
        call    play_note
        add     al, 5
        call    play_note
        call    no_sound

        mov     bx, 0FFFFh
        mov     ah, speed_freq_x1000
        shl     ah, 4
        xor     al, al
        mul     speed_multiplier
        sub     bx, ax
        call    reprogram_pit

        cmp     speed_ticks, 0  ; �᫨ � ⥪�騩 ������ �� �࠭�
        jne     M_pass_speed    ; ��� 稫� � �줠,
        mov     ax, 5           ; � ����⭮���� 1/5
        call    randgen         ; ᣥ����㥬 稫� � ���
        test    ax, ax
        jnz     M_pass_speed
            mov     al, color_speed_up
            call    add_food
            mov     dh, cl
            mov     speed_up_coord, dx
            mov     al, color_speed_down
            call    add_food
            mov     dh, cl
            mov     speed_down_coord, dx
            mov     speed_ticks, 100
        M_pass_speed:

        cmp     mushroom_ticks, 0; �᫨ � ⥪�騩 ������ �� �࠭�
        jne     M_pass_mushroom ; ��� �ਡ��,
        mov     ax, 1          ; � ����⭮���� 1/10
        call    randgen         ; ᣥ����㥬 �ਡ�
        test    ax, ax
        jnz     M_pass_mushroom
            mov     al, color_mushroom
            call    add_food
            mov     dh, cl
            mov     mushroom_coord, dx
            mov     mushroom_ticks, 500
        M_pass_mushroom:
        jmp     modern_main
modern              endp


original_videomode  db  ?
original_videopage  db  ?

game_in_progress    db  0
game_over           db  0
current_game        dw  ?
score               dw  2
snake               dw  0100h
                    dw  0200h
                    dw  100h  dup('?')
food_eaten          dw  0             ; ���稪 �ꥤ�����
direction           dw  0100h         ; xx;yy
;actual_direction    dw  0100h         ; xx;yy
speed_multiplier    dw  0
speed_freq_x1000    db  04h           ; => freq_step = 08000h

thickness           dw  8             ; ���騭� ����� � ࠧ��� ���⪨

color_poo           db  06h
color_food           db  0Ah
color_snake           db  02h
color_border           db  03h
color_mushroom          db  0Dh
color_speed_up           db  0Ch
color_speed_down          db  0Bh

speed_up_coord      dw  ?
speed_down_coord    dw  ?
speed_ticks         dw  ?
mushroom_coord      dw  ?
mushroom_ticks      dw  ?

str_score           db  'Score: ','$'
str_score_len       db  $-str_score-1

str_classic         db  'Classic mode','$'
str_classic_len     db  $-str_classic
str_modern          db  'Modern mode','$'
str_modern_len      db  $-str_modern
str_right           db  '[TODO right]','$'
str_right_len       db  $-str_right
str_exit            db  'Exit','$'
str_exit_len        db  $-str_exit
str_resume1         db  'PAUSE','$'
str_resume1_len     db  $-str_resume1
str_resume2         db  'Esc - Resume game','$'
str_resume2_len     db  $-str_resume2
str_gameover1       db  'GAME OVER','$'
str_gameover1_len   db  $-str_gameover1
str_gameover2       db  'Your score: ','$'
str_gameover2_len   db  $-str_gameover2
str_tutor_classic   db  'Apple   Poo','$'
str_tutor_modern    db  'Apple   Poo   Mushroom   Chilli   Ice','$'
str_hotkey          db  '[Esc - menu]','$'
str_hotkey_len      db  $-str_hotkey

RND_const           dw  8405h         ; multiplier value
RND_seed1           dw  ?
RND_seed2           dw  ?             ; random number seeds

;buffer      db      10h dup (?) 
;head        dw      0
;tail        dw      0
;old_09h     dw      ?, ?


end	    @entry
