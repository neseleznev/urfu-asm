; Никита Селезнев, ФИИТ-301, 2015
;
; Резидентная программа:
; 1. Ключи: 'help', 'install', 'uninstall', 'kill', 'status'
; 2. Вешаться на 2Fh, 21h (передавать дальше)
; 3. Отображать все адреса (куда установлен, где установлен, с какого места снят),
;    в т.ч. адрес обработчика прерывания 21 (т.е. "Адрес int21h был ..., стал ...") 1432:4231
; 4. Корректно обрабатывать ввод вида /program.com\s+[\/\-][hiuks]/
; 5. Удаляться из памяти (+env) при -k или -u
; 6. User-friendly
;
; По ключам:
; help - отображает справку
; install - устанавливает резидент, пишет адреса
; uninstall - удаляет резидент (если это возможно, т.е. резидент на вершине стека прерываний)
; kill - убивает резидент (в любом случае)
; status - отображает статус (установлен/нет + адреса)

.model tiny
.code

ORG 2Ch
	env_ptr	label word	; определить метку для доступа к слову в PSP, которое указывает на сегмент,
						; содержащий блок операционной среды
						; (он обычно освобождается для создания более компактной резидентной программы)
ORG 80h
	cmd_len		db	?	; длина командной строки
	cmd_line	db	?	; командная строка
ORG 100h

@entry:
	jmp		@init

;-------------------- Резидентная часть программы --------------------;
old_21h		dw		?, ?
new_21h		dw		?, ?
old_2Fh		dw		?, ?
new_2Fh		dw		?, ?


print_seg_offset proc
	; bx - сегмент, который необходимо распечатать
	;push	cs		; 0101 = 0000000100000001
	;pop		bx
	mov		cx, 4

	@k:	
		rol		bx, 4		; bx = 0001000000010000
		mov		al, bl		; al = 00010000
		and		al, 0fh
		cmp		al, 10
		sbb		al, 69h
		das
		mov		dh, 02h
		xchg	ax, dx
		int		21h
	loop	@k
	ret 2
print_seg_offset endp


catch_21h	proc	far
	jmp 	dword ptr cs:[old_21h]
catch_21h	endp

catch_2Fh	proc	far
	; Сигнатура (ah):
	;	FA
	; Функции (al):
	;	00 - Проверка на утановку
	;		FF - (скорее всего) установлен
	;	01 - Выгрузка из памяти
	;		AA - мы не верхние в цепочке прерываний
	;	02 - Принудительная выгрузка из памяти
	;		

	cmp		ah, 0FAh 		; Проверка сигнатуры
	jne		pass_2Fh		; Если не наша -> выход

	cmp		al, 0			; Функция проверки на установку
	jne		check_2Fh		; нет -> проверяем функцию выгрузки
	mov		al, 0FFh		; да -> программа загружена
	iret

	check_2Fh:				; Проверка на функцию выгрузки
		cmp		al, 01h
		je		uninstall_2Fh
		cmp		al, 02h
		je		kill_2Fh
		iret

	pass_2Fh:
		jmp dword ptr cs:[old_2Fh]

 	uninstall_2Fh:
		push	ds
		push	0
		pop		ds					; DS - сегментный адрес таблицы векторов прерываний
		mov		ax, cs				; Наш сегментный адрес
		; Проверить, все ли перехваченные прерывания по-прежнему указывают на нас,
		; обычно достаточно проверить только сегментные адреса (DOS не загрузит другую
		; программу с нашим сегментным адресом)
		cmp		ax, word ptr ds:[21h*4+2]
		jne		unload_failed
		cmp		ax, word ptr ds:[2Fh*4+2]
		jne		unload_failed

		pop		ds
		jmp		kill_2Fh

		unload_failed:
			mov		al, 0AAh
			pop		ds
			iret

	kill_2Fh:
		push	es
			push	ds
				push	ax
					push	dx
		; Восстанавливаем вектор 21h
		mov		ax, 2521h
		mov		dx, word ptr cs:[old_21h]
		mov		ds, word ptr cs:[old_21h+2]
		int		21h
		; Восстанавливаем вектор 2Fh
		mov		ax, 252fh
		mov		dx, word ptr cs:[old_2Fh]
		mov		ds, word ptr cs:[old_2Fh+2]
		int		21h

		mov		es, cs:2Ch	; получим из PSP адрес собственного 
		mov		ah, 49h		; окружения резидента и выгрузим его 
		int		21h

		push	cs			; выгрузим теперь саму программу 
		pop		es			; 
		mov		ah, 49h		; 
		int		21h 		; 

					pop		dx
				pop		ax
			pop		ds
		pop		es
		iret
catch_2Fh	endp
;----------------- Конец резидентной части программы -----------------;


@init:
		jmp			initialize_entry_point
		; пропустить различные варианты выхода без установки резидента,
		; помещенные здесь потому, что на них передают управление
		; команды условного перехода, имеющие короткий радиус действия

	@illegal_key:
		mov			ah, 09h				; Напечатать ошибку о неверном ключе, а потом
		mov			dx, offset illegal_key_msg
		int			21h					; исполнение пойдет дальше и покажет справку


	@lbl_help:
		mov			dx, offset usage
		jmp			exit_with_message

	
	@lbl_install:
		cmp			installed, 1
		jne 		_install
			mov		dx, offset already_msg
			jmp		exit_with_message
		_install:

		; Изменим название программы
		mov		cx, len					; Длина source
		mov		si, offset new_name		; Адрес source
		mov		es, env_ptr				; в ax адрес сегмента после int 48h (см.выше)
		xor		di, di 					; es:[di] <- адрес destination, dx = 0
		rep		movsb					; ++di, ++si, mov

		; Определим значение старого вектора INT 21h
		mov		ax, 3521h			
		int		21h
		cli
			mov		[old_21h],		bx	; Сохраним его в переменной
			mov		[old_21h+2],	es
			mov		ax, 2521h			; Установим новый вектор прерывания INT 21h
			mov		dx, offset catch_21h
			int		21h
		sti

		; Определим значение старого вектора INT 2Fh
		mov		ax, 352Fh			
		int		21h
		cli
			mov		[old_2Fh],		bx	; Сохраним его в переменной
			mov		[old_2Fh+2],	es
			mov		ax, 252Fh			; Установим новый вектор прерывания INT 21h
			mov		dx, offset catch_2Fh
			int		21h
		sti

		; TODO print old offset, new offset

		mov		dx, offset @init		; В dx первый байт после резидентной части
		int		27h 					; программы, ну и оставить её резидентной


	@lbl_uninstall:
		cmp			installed, 1
		je 			_uninstall
			mov		dx, offset cant_unload1_msg
			jmp		exit_with_message
		_uninstall:

		mov			ah, 0FAh			; Проверим, можно ли выгрузить из памяти
		mov			al, 01h				; Если да, то оттуда программа и завершится
		int			2Fh

		cmp 		al, 0AAh
		jne 		__uninstall
			mov		dx, offset cant_unload2_msg
			jmp		exit_with_message
		__uninstall:
		
		mov			dx, offset unloaded_msg
		jmp			exit_with_message


	@lbl_kill:
		cmp			installed, 1
		je 			_kill
			mov		dx, offset cant_unload1_msg
			jmp		exit_with_message
		_kill:

		mov			ah, 0FAh			; Вызовем принудительную выгрузку
		mov			al, 02h				; Наша программа тоже завершится
		int			2Fh

		mov			dx, offset unloaded_msg
		jmp			exit_with_message


	@lbl_status:
		cmp			installed, 1
		je 			handlers_installed
			mov		dx, offset not_installed_msg
			jmp		exit_with_message
		handlers_installed:
			mov		dx, offset installed_msg
			jmp		exit_with_message


	exit_with_message:
		mov			ah, 09h				; Предполагаем, что в dx адрес строки,
		int			21h					; которую мы печатаем на экран
		ret								; и выходим из программы

initialize_entry_point:					; Сюда передается управление в самом начале

		mov			ah, 0FAh			; Проверим статус установки
		mov			al, 00h 			; нашего обработчика
		int			2Fh

		cmp			al, 0FFh
		jne			_not_installed
			mov		installed, 1
			jmp		_next1
		_not_installed:
			mov		installed, 0
		_next1:

		; Аргументы командной строки TODO \s+ перед ключом
		cld
		cmp			byte ptr cmd_line[1], '/'
		je			found_slash_or_minus
		cmp			byte ptr cmd_line[1], '-'
		je			found_slash_or_minus
		jmp			@illegal_key

	found_slash_or_minus:				; агрумент начинается с / или - (Правильно)

		; Определим, какой ключ идет после / или -
		mov		cx, 6					; Ключей 5, будем искать символ в
		mov		al, byte ptr cmd_line[2]; строке keys. Если cx станет 0
		lea 	di, keys 				; значит, не нашли вхождение
		repne	scasb					; если 1 - lbls[1*2] help
		shl		cx, 1					; если 2 - lbls[2*2] install
		mov		di, cx					; и т.д.
		jmp		lbls[di]


; Ключи и соответствующие метки
keys				db		'skuih'
lbls				dw		@illegal_key, @lbl_help, @lbl_install, @lbl_uninstall, @lbl_kill, @lbl_status

; Глобальные переменные
installed 			db		0

; Отображаемое имя программы
new_name			db		20h,00h,00h,01h,00h,'21 2F hook',00h
len					dw		$-new_name

; Текст, который выдает программа с ключом /h:
usage				db		'Простая программа для перехвата прерываний 21h и 2Fh.',					0Dh,0Ah
					db		'/i -i установить обработчик и сообщить адреса старого и нового прерываний',0Dh,0Ah
					db		'/u -u снять обработчик,',													0Dh,0Ah
					db		'      если он устанолен и последний, затем',								0Dh,0Ah
					db		'          сообщить адреса старого и нового прерываний;',					0Dh,0Ah
					db		'      иначе выдать сообщение об ошибке',									0Dh,0Ah
					db		'/k -k принудительно выгрузить обработчик из памяти,',						0Dh,0Ah
					db		'      пусть даже некорректно.',											0Dh,0Ah
					db		'/s -s отобразить статус обработчика (установлен / нет)',					0Dh,0Ah
					db		'      и вывести адреса старого и нового обработчиков',						0Dh,0Ah
					db		'/h -h это сообщение со справкой',											0Dh,0Ah
					db		0Dh,0Ah,'$'

; Тексты, которые выдает программа при успешном выполнении:
installed_msg		db		'Программа установлена в памяти'											,0Dh,0Ah,'$'
not_installed_msg	db		'Программа еще не установлена в памяти'										,0Dh,0Ah,'$'
unloaded_msg		db		'Программа успешно выгружена из памяти'										,0Dh,0Ah,'$'

; Тексты, которые выдает программа при ошибках:
illegal_key_msg		db		'Ошибка: указан неверный ключ при запуске. См справку ниже:'				,0Dh,0Ah,0Dh,0Ah,'$'
already_msg			db		'Ошибка: Программа уже загружена в память'									,0Dh,0Ah,'$'
cant_unload1_msg	db		'Ошибка: Программа не обнаружена в памяти'									,0Dh,0Ah,'$'
cant_unload2_msg	db		'Ошибка: Другая программа перехватила прерывания'							,0Dh,0Ah,'$'

end @entry
