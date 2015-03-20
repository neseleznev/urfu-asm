.286
.287

assume cs: cseg, ds: dseg, ss:sseg 

sseg segment stack
	db 256 dup (?)
sseg ends 

dseg segment
	a dd 4.7
	b dd 0.11
	k1 dd 2
	k2 dd 3
	k3 dd 1
	x dd 5.0
	
dseg ends

cseg segment

f1 proc
	fld x
	fmulp st(1), st
	ret
f1 endp

f2 proc
	fld k1
	fmulp st(1), st
	ret
f2 endp

f3 proc
	fld k2
	fmulp st(1), st
	fadd
	ret
f3 endp

start:
    mov ax, dseg
	mov ds, ax
	Begin:     
		finit 
		fld x
		fld a
		fcomp st(1)
		fstsw ax
		sahf
		ja m1
		call f1 ;x>=a
		jmp m3
		m1:
		fld b
		fcomp st(1)
		fstsw ax
		sahf
		ja m2
		call f2 ;b<=x<a
		jmp m3
		m2:
		call f3 ; x<b
		m3:
		
    mov ax, 4c00h
    int 21h
cseg ends
end start