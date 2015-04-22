; latency.asm
; Ё§¬ҐапҐв баҐ¤­ҐҐ ўаҐ¬п, Їа®е®¤пйҐҐ ¬Ґ¦¤г  ЇЇ а в­л¬ ЇаҐалў ­ЁҐ¬ Ё § ЇгбЄ®¬ 
; б®®вўҐвбвўгойҐЈ® ®Ўа Ў®взЁЄ . ‚лў®¤Ёв баҐ¤­ҐҐ ўаҐ¬п ў ¬ЁЄа®бҐЄг­¤ е Ї®б«Ґ 
; ­ ¦ вЁп «оЎ®© Є« ўЁиЁ (­  б ¬®¬ ¤Ґ«Ґ ў 1/1 193 180)
; Џа®Ја ¬¬  ЁбЇ®«м§гҐв 16-ЎЁв­л© бг¬¬ в®а ¤«п Їа®бв®вл, в Є зв® ¬®¦Ґв ¤ ў вм 
; ­ҐўҐа­лҐ аҐ§г«мв вл, Ґб«Ё Ї®¤®¦¤ вм Ў®«миҐ ­ҐбЄ®«мЄЁе ¬Ё­гв
;
; Љ®¬ЇЁ«пжЁп:
; TASM:
; tasm /m latency.asm
; tlink /t /x latency.obj
; MASM:
; ml /c latency.asm
; link latency.obj,,NUL,,,
; exe2bin latency.exe latency.com
; WASM:
; wasm latency.asm
; wlink file latency.obj form DOS COM
;

	.model tiny
	.code
	.386		; ¤«п Є®¬ ­¤л shld
	org	100h	; COM-Їа®Ја ¬¬ 
start:
	mov	ax,3508h	; AH = 35h, AL = ­®¬Ґа ЇаҐалў ­Ёп
	int	21h		; Ї®«гзЁвм  ¤аҐб ®Ўа Ў®взЁЄ 
	mov	word ptr old_int08h,bx	; Ё § ЇЁб вм ҐЈ® ў old_int08h
	mov	word ptr old_int08h+2,es
	mov	ax,2508h	; AH = 25h, AL = ­®¬Ґа ЇаҐалў ­Ёп
	mov	dx,offset int08h_handler ; DS:DX -  ¤аҐб ®Ўа Ў®взЁЄ 
	int	21h		; гбв ­®ўЁвм ®Ўа Ў®взЁЄ
; б нв®Ј® ¬®¬Ґ­в  ў ЇҐаҐ¬Ґ­­®© latency ­ Є Ї«Ёў Ґвбп бг¬¬ 
	mov	ah,0
	int	16h		; Ї г§  ¤® ­ ¦ вЁп «оЎ®© Є« ўЁиЁ

	mov	ax,word ptr latency	; бг¬¬  ў AX
	cmp	word ptr counter,0 ; Ґб«Ё Є« ўЁиг ­ ¦ «Ё ­Ґ¬Ґ¤«Ґ­­®,
	jz	dont_divide		; Ё§ЎҐ¦ вм ¤Ґ«Ґ­Ёп ­  ­®«м
	xor	dx,dx			; DX = 0
	div	word ptr counter	; а §¤Ґ«Ёвм бг¬¬г ­  зЁб«® ­ Є®Ї«Ґ­Ё©
dont_divide:
	call	print_ax		; Ё ўлўҐбвЁ ­  нЄа ­

	mov	ax,2508h		; AH = 25h, AL = ­®¬Ґа ЇаҐалў ­Ёп
	lds	dx,dword ptr old_int08h	; DS:DX =  ¤аҐб ®Ўа Ў®взЁЄ 
	int	21h			; ў®ббв ­®ўЁвм бв ал© ®Ўа Ў®взЁЄ
	ret				; Є®­Ґж Їа®Ја ¬¬л

latency	dw	0		; бг¬¬  § ¤Ґа¦ҐЄ
counter	dw	0		; зЁб«® ўл§®ў®ў ЇаҐалў ­Ёп

; ЋЎа Ў®взЁЄ ЇаҐалў ­Ёп 08h (IRQ0)
; ®ЇаҐ¤Ґ«пҐв ўаҐ¬п, Їа®иҐ¤иҐҐ б ¬®¬Ґ­в  ба Ў влў ­Ёп IRQ0
int08h_handler	proc	far
	push	ax	; б®еа ­Ёвм ЁбЇ®«м§гҐ¬л© аҐЈЁбва
	mov	al,0	; дЁЄб жЁп §­ зҐ­Ёп бзҐвзЁЄ  ў Є ­ «Ґ 0
	out	43h,al	; Ї®ав 43h: гЇа ў«пойЁ© аҐЈЁбва в ©¬Ґа 
; в Є Є Є нв®в Є ­ « Ё­ЁжЁ «Ё§ЁагҐвбп BIOS ¤«п 16-ЎЁв­®Ј® звҐ­Ёп/§ ЇЁбЁ, ¤агЈЁҐ 
; Є®¬ ­¤л ­Ґ ваҐЎговбп
	in	al,40h		; ¬« ¤иЁ© Ў ©в бзҐвзЁЄ 
	mov	ah,al		; ў AH
	in	al,40h		; бв аиЁ© Ў ©в бзҐвзЁЄ  ў AL
	xchg	ah,al		; Ї®¬Ґ­пвм Ёе ¬Ґбв ¬Ё
	neg	ax		; ®Ўа вЁвм ҐЈ® §­ Є, в Є Є Є бзҐвзЁЄ г¬Ґ­ми Ґвбп,
	add	word ptr cs:latency,ax	; ¤®Ў ўЁвм Є бг¬¬Ґ
	inc	word ptr cs:counter	; гўҐ«ЁзЁвм бзҐвзЁЄ ­ Є®Ї«Ґ­Ё©
	pop	ax
	db	0EAh		; Є®¬ ­¤  jmp far
old_int08h	dd	0	;  ¤аҐб бв а®Ј® ®Ўа Ў®взЁЄ 
int08h_handler	endp

; Їа®жҐ¤га  print_ax
; ўлў®¤Ёв AX ­  нЄа ­ ў иҐбв­ ¤ж вҐаЁз­®¬ д®а¬ вҐ
print_ax proc near
	xchg	dx,ax		; DX = AX
	mov	cx,4		; зЁб«® жЁда ¤«п ўлў®¤ 
shift_ax:
	shld	ax,dx,4		; Ї®«гзЁвм ў AL ®зҐаҐ¤­го жЁдаг
	rol	dx,4		; г¤ «Ёвм ҐҐ Ё§ DX
	and	al,0Fh		; ®бв ўЁвм ў AL в®«мЄ® нвг жЁдаг
	cmp	al,0Ah		; ваЁ Є®¬ ­¤л, ЇҐаҐў®¤пйЁҐ
	sbb	al,69h		; иҐбв­ ¤ж вҐаЁз­го жЁдаг ў AL
	das			; ў б®®вўҐвбвўгойЁ© ASCII-Є®¤
	int	29h		; ўлў®¤ ­  нЄа ­
	loop	shift_ax	; Ї®ўв®аЁвм ¤«п ўбҐе жЁда
	ret
print_ax endp
	end start