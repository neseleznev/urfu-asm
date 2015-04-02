; ����� ��������, ����-301, 2015
;
; �����-०��� (����誠 �� 18 ����):
; program.com (\d) (\d) (\-)?/
; \1 = video_mode
; \2 = display_page
; �ணࠬ�� ��⠭�������� �����०�� � ��࠭��� ᮣ��᭮ ��ࠬ��ࠬ, �� ����稨 \3 ����,
; ���� ���짮��⥫� ������ �������, ��⥬ �����頥� ��࠭ � ��室��� ���ﭨ� � ��室��.
; �᫨ \3 ���������, � ��⠭�������� \1, \2 � ��室��.
; �ᯮ�짮���� �㭪樨 00h, 05h, 0Fh int 10h, ࠧ����� ᠬ����⥫쭮.
.286
.model tiny
.code

ORG 80h
	cmd_len		label byte				; ����� ��㬥�⮢ ��������� ��ப�
	cmd_line	label byte				; ��㬥��� ��������� ��ப�
ORG 100h

@entry:
		jmp			@start

include SexyPrnt.inc
include CmdArg.inc


change_video_mode proc					; ��������� �����-०���
	; 00h ���.����� ०��. ������ ��࠭, ��⠭����� ���� BIOS, ��⠭����� ०��.
	; �室:  AL = ०��
	;       AL  ���      �ଠ�   梥�          ������  ���� ������
	;       === =======  =======  =============  =======  ====  =================
	;        0  ⥪��    40x25    16/8 ����⮭�  CGA,EGA  b800  Composite
	;        1  ⥪��    40x25    16/8           CGA,EGA  b800  Comp,RGB,Enhanced
	;        2  ⥪��    80x25    16/8 ����⮭�  CGA,EGA  b800  Composite
	;        3  ⥪��    80x25    16/8           CGA,EGA  b800  Comp,RGB,Enhanced
	;        4  ��䨪�  320x200  4              CGA,EGA  b800  Comp,RGB,Enhanced
	;        5  ��䨪�  320x200  4 ����⮭�     CGA,EGA  b800  Composite
	;        6  ��䨪�  640x200  2              CGA,EGA  b800  Comp,RGB,Enhanced
	;        7  ⥪��    80x25    3 (b/w/bold)   MA,EGA   b000  TTL Monochrome
	;       0Dh ��䨪�  320x200  16             EGA      A000  RGB,Enhanced
	;       0Eh ��䨪�  640x200  16             EGA      A000  RGB,Enhanced
	;       0Fh ��䨪�  640x350  3 (b/w/bold)   EGA      A000  Enhanced,TTL Mono
	;       10h ��䨪�  640x350  4 ��� 16       EGA      A000  Enhanced
	; �������:
	;     (���� CF = 1, �᫨ ⠪��� ���)
		pusha

		; ������� �� ⠪�� �����-०��?
		cmp		al, 10h
		jg		CVM_false
		cmp		al, 8
		jl 		CVM_true
		cmp		al, 0Ch
		jg		CVM_true

	CVM_false:
		stc
		jmp		CVM_exit
	CVM_true:
		xor		ah, ah
		int		10h

		mov		dx, offset change_msg
		call	print_dx_string
		call	print_int2
		call	CRLF
	CVM_exit:
		popa
		ret
change_video_mode endp


change_display_page proc				; ��������� ��⨢��� ��࠭��� ��ᯫ��
	; 05h ����� ��⨢��� ��࠭��� ��ᯫ��
    ; �室:  AL = ����� ��࠭��� (����設�⢮ �ணࠬ� �ᯮ���� ��࠭��� 0)
	; �����⨬� ����� ��� ०����:
	;       �����  �����
	;       ====== =======
	;        0      0-7
	;        1      0-7
	;        2      0-3
	;        3      0-3
	;        4       0
	;        5       0
	;        6       0
	;        7       0
	;       0Dh     0-7
	;       0Eh     0-3
	;       0Fh     0-1
	;       10h     0-1
	; �������:
	;     (���� CF = 1, �᫨ ����� �������⨬)
		pusha

		test	bl, bl			; 0 ����㯭� �ᥬ
		jz		CDP_true

		cmp		bl, 1			; 1 ��࠭��
		jne		_CDP_1

		cmp		al, 4
		jl		CDP_true
		cmp		al, 7
		jg		CDP_true
		jmp		CDP_false

	_CDP_1:						; 2-3 ��࠭���
		cmp		bl, 3
		jg		_CDP_2

		cmp		al, 4
		jl		CDP_true
		cmp		al, 0Dh
		je		CDP_true
		cmp		al, 0Dh
		je		CDP_true
		jmp		CDP_false

	_CDP_2:						; 4-7 ��࠭���
		cmp		bl, 7
		jg		CDP_false

		cmp		al, 2
		jl		CDP_true
		cmp		al, 0Dh
		je		CDP_true
		jmp		CDP_false

	CDP_false:
		stc
		jmp		CDP_exit
	CDP_true:
		mov		ah, 05h
		mov		al, bl
		int		10h

	CDP_done:
		mov		dx, offset change_page_msg
		call	print_dx_string
		xor		ah, ah
		mov		al, bl
		call	print_int2
		call	CRLF
	CDP_exit:
		popa
		ret
change_display_page endp


@illegal_key:
		mov			dx, offset illegal_key_err
		call		print_dx_string
		ret


@start:									; � ��।����� �ࠢ����� � ᠬ�� ��砫�

	; ��ࢮ� �᫮
		mov		si, offset cmd_line
		mov		di, offset cmd_arg
		call	get_cmd_arg
		jc		@illegal_key

		cmp		al, 1
		jne		@illegal_key			; �᫨ �� �� �᫮ - �訡��

		; � ��� �᫮, ��࠭�� ���
		mov		cmd_arg1, bx

		xor		cx, cx
		mov		cl, [cmd_len]			; cx <- ����� ����� ��������� ��ப�
		test	cx, cx					; �᫨ ����, �訡��, ��� �㦥� �� ���� ��㬥��
		jz		@illegal_key

	; ��஥ �᫮
		mov		si, offset cmd_line
		mov		di, offset cmd_arg
		call	get_cmd_arg
		jc		@illegal_key

		cmp		al, 1
		jne		@illegal_key			; �᫨ �� �� �᫮ - �訡��

		; � ��� �᫮, ��࠭�� ���
		mov		cmd_arg2, bx

		xor		cx, cx
		mov		cl, [cmd_len]			; cx <- ����� ����� ��������� ��ப�
		test	cx, cx					; �᫨ ����, ����� ��㬥�⮢ ����� ���,
		jz		@process_args 			; ��� ��ࠡ��뢠�� �, �� ��ᮡ�ࠫ�

		; � �᫨ ��� ����, ���� ������ ������
		mov		dx, offset press_any
		call	print_dx_string
		mov		ah, 07h
		int 	21h

	; ��ࠡ�⪠ ���� �ᥫ
	@process_args:
		mov		ax, cmd_arg1
		call	change_video_mode
		jc		@illegal_key
		mov		ax, cmd_arg2
		call	change_display_page
		jc		@illegal_key
	
	ret

illegal_key_err	db		'�訡��! ������ ������ ���� �� ����᪥. ��. �ࠢ��',		0Dh,0Ah
				db		'����� �祡��� �ணࠬ�� ��� ᬥ�� �����-०��� � ��࠭���',	0Dh,0Ah
				db		'�� ����� �㭪権 00h,05h,0Fh ���뢠��� BIOS 10h',	0Dh,0Ah,0Dh,0Ah
				db		'�ᯮ�짮�����: video \1      \2         [\3]',					0Dh,0Ah
				db		'               video <०��> <��࠭��> [<ᨬ���>]',	0Dh,0Ah,0Dh,0Ah
				db		'��ࠬ����:',													0Dh,0Ah
				db		'  \1           ����� �����-०��� [0,1,2,3,4,5,6,7,D,E,F,10]',	0Dh,0Ah
				db		'  \2           ��࠭�� ��ᯫ�� [0 ��� ���,1-7 ��樮���쭮]', 0Dh,0Ah
				db		'  \3           �� ����稨 ���� ������ ������, ��⥬',		0Dh,0Ah
				db		'               �����頥� ��࠭ � ��室��� ���ﭨ�, ��室��',0Dh,0Ah
				db		'  -h [/h]      �뢥�� �� ᮮ�饭�� � �ࠢ���',				0Dh,0Ah
				db		'  -s [/s]      �������� ���ଠ�� � ⥪�饬 �����-०���',	0Dh,0Ah
				db		0Dh,0Ah,'$'

change_msg		db		'���� �����-०��: '										,'$'
change_page_msg	db		'����� �⮡ࠦ����� ��࠭��: '								,'$'
press_any		db		'������ ���� ������� ��� �த�������...'					,0Dh,0Ah,'$'

cmd_arg1		dw		?
cmd_arg2		dw		?
cmd_arg			db		256 dup (?)

end @entry