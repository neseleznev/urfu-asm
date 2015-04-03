
mov		cl, 5			; key parsing
mov		al, cs:[di] 	; label
lea 	di, keys
repne	scasb
shl		cx, 1
mov		di, cx
jmp		lbls[di]

keys	db	'iukh'
lbls	dw	@illegal_key, @lbl_help, @lbl_kill, @lbl_uninstall, @lbl_install
