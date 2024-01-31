;-------------------------------------------------
print macro f1;вывод сообщений на экран
	push ax
	push dx
	mov dx,offset f1
	mov ah,9
	int 21h
	pop dx
	pop ax
endm
;-------------------------------------------------

;-------------------------------------------------
anykey macro ;   anykey (что тут еще объяснять? 0_0)
	push ax
	mov ah,7
	int 21h
	pop ax
endm
;-------------------------------------------------

;-------------------------------------------------
Input macro f2;   ввод строки символов
	push ax
	push dx
	mov dx,offset f2
	mov ah,10
	int 21h
	pop dx
	pop ax
endm
;-------------------------------------------------

;-------------------------------------------------
clean macro f3 ; очистка буфера
local clear
    push cx
	push si
    mov cx,6
		xor si,si
clear:		mov [f3+si],' '
		inc si
		loop clear
	pop si
	pop cx
endm
;-------------------------------------------------

;-------------------------------------------------
curpos macro strcol;   Перемещение курсора по заданным координатам
    push dx
	push ax
	push bx
	mov dx,strcol
	mov ah,2
	mov bh,0
	int 10h
	pop bx
	pop ax
	pop dx
endm
;-------------------------------------------------

;-------------------------------------------------
;Вывод строки
string macro y
local m1
    push bx
    push ax
	push cx
    push si
	mov si,offset y
m1:	mov ah,2
	mov bh,0
	int 10h
	mov ah,0ah
	mov cx,1
        mov al,byte ptr [si]
	int 10h
	inc si
	inc dx
	cmp byte ptr [si],'$'
	jne m1
	pop si
	pop cx
	pop ax
	pop bx
endm	
;-------------------------------------------------
;DATA SEGMENT
d1 SEGMENT PARA PUBLIC 'DATA'
mess_div db 'the number to divide by:', '$'
mess_input db 10,13, 'Input:5 numbers in [-29999,29999] (They must divide by divider)',10,13,'$'
mess_enter db 10,13, 'Press <Enter> after each number$'
mess_nmb db 'Enter the number: $'

in_str label byte ;строка символов (не более 6)
size_str db 7        ;ограничение на ввод (6 символов + Enter)
size_of db (?)       ;Кол-во введенных символов
sign_str db 7 dup (?); знак числа (для отрицательных), 5 цифр, enter
number dw 5 dup (0)   ;массив чисел
numberPos dw 5 dup (0)   ;массив положительных чисел
numberNeg dw 5 dup (0)   ;массив отрицательных чисел
divider dw 2    ; Вводимый программистом делитель

PosSum dw 0                ;сумма положительных
num_size dw 5              ;количество чисел
n_pos db 0                 ;количество + чисел
; Координаты
upleft dw 0103h,0204h,0120h,0132h, 0c25h, 0a38h 
downri dw 1017h,0f16h,072ah,073Ch,0f35h, 0c4Eh 
attr dw 2000h,3000h,2100h,2400h,2000h, 4f00h
curp dw 0304h,0b04h,0c04h,0d04h,0121h,0133h,0c2ah,0a3Ch
input_curpos dw 0504h, 0604h, 0704h, 0804h, 0904h
output_pos dw 0221h,0321h,0421h,0521h,0621h
output_neg dw 0232h,0332h,0432h,0532h,0632h
output_res dw 0d25h, 0e25h
err_curpos dw 0b39h
;Текст Меню
mess1 db 'Input numbers:$'
mess2 db 'Exit - F3$'
mess3 db 'ColorSwitch - F2$'
mess4 db 'Input Numbers - F1$'
mess5 db 'Massive+$'
mess6 db 'Massive-$'
mess7 db 'Result$'
mess8 db '-=ErrorWindow=-$'
;Координаты вывода функциональных сообщений
mess_curpos dw 1201h
space db 10,13,'$'
;Сообщения об возможных ошибках
text_input db  '     Input error!    $'
text_divide db '    Cannot divide!   $'
err_zero db    'Cant divide SumOfPos!$'
err_overflow db '      Overflow!     $'
;Сообщения вывода
mess_possum db 'Sum/n:    $'
mess_rem db    'Remainder:$'
;Функциональные сообщения
mess_color db 'Use Arrows to change window color(WNDW SWTCH:UP/DWN||CLR SWTCH:R/L||Exit:ENTR)$'
mess_exit db 'Press any key finish the programm$'
mess_endmath db 'Press any key to go for the final check$'
mess_menu db 'Welcome to the menu! HotKeys are in the main (input) window.'
out_str db 6 dup (' '),'$'
flag_err equ 1
d1 ENDS

s1 SEGMENT PARA STACK 'STACK'
	DW 150 DUP (?)
s1 ENDS

c1 SEGMENT PARA PUBLIC 'CODE'
ASSUME CS:c1, DS:d1, SS:s1


; РИСУЕМ НАЧАЛЬНЫЕ ОКНА
start:  mov ax,d1
	mov ds,ax
	mov ax,0003h
	int 10h
	xor si,si
    xor ax,ax
	print space
	;Вывод на экран окон
	call tables_drawin
	;Вывод текста
	call print_txt
	xor si,si
	
;--------МЕНЮ ВЫБОРА--------------------
menu: xor bx, bx
    call info_clean
	curpos mess_curpos
	print mess_menu
	mov ax,0002h
	mov ah,0
	int 16h
	;if F1 - Input
	cmp ax,3b00h
	je goF1
;if F2 - ColorChanging
	cmp ax,3C00h
	je goF2
	;if F3 - Exit
	cmp ax,3D00h
	je goF3
	jmp menu
goF1:	jmp MathTime
goF2:	jmp ColorSwitch
goF3:	jmp Exit
;---------------------------------------
	
; ---ИЗМЕНЕНИЕ ЦВЕТ ОКОН----------------
ColorSwitch: curpos mess_curpos
    print mess_color
    xor bx, bx
	mov ax,0002h
	presskey:mov ah,0
	int 16h
;if enter
	cmp ax,1c0dh
	je returnF2
;if => <=
	cmp ax,4d00h
	je right
	cmp ax,4b00h
	je left
;if Arrow up & down
	cmp ax,4800h
	je up
	cmp ax,5000h
	je down
	jmp presskey
; меняем цвет (+1)
right:	cmp attr+si,0ff00h
	je presskey
;Изменим цвет фона на 1
	add attr+si,1100h
	call table_redrawin
	jmp presskey
; меняем цвет (-1)
left:	cmp attr+si,1100h
	je presskey
;Изменим цвет фона на 1
	sub attr+si,1100h
	call table_redrawin
	jmp presskey
;Выбираем панель (+1)
up:	cmp si, 0008h
    jge presskey
	inc si
	inc si
    jmp presskey
;Выбираем панель (-1)
down:	cmp si,0000h
	jle presskey
	dec si
	dec si
	jmp presskey
returnF2:	jmp menu
;-------------------------------	
	
;---МАГИЯ МАТЕМАТИКИ------------
MathTime:
;Вывод Информации
    call info_clean
	curpos mess_curpos
	print mess_div
	mov ax, divider
	call BinToAscDVDR
	print out_str
	clean out_str
	print mess_input
	print mess_enter
	;Начинаем вводить
	xor ax, ax
	xor di, di
	xor si, si
	mov cx, num_size ; в cx - размер массива
inp1:      push cx
m1: call input_clean
    curpos input_curpos+di
	input in_str
;проверка диапазона вводимых чисел (-29999,+29999)
	call DIAPAZON
	cmp bh,flag_err  ;сравним bh и flag_err
	je err_inp         ;если равен -сообщение об ошибке ввода
;проверка допустимости вводимых символов
	call dopust
	cmp bh,flag_err
	je err_inp
;преобразование строки в число
	call AscToBin
	call DivCheck
	cmp bh,flag_err
	je err_div
	inc di
	inc di
	pop cx
	loop inp1
	jmp mathing
	
	
;------------Проверка Ошибок-------------
err_inp: 
    curpos err_curpos     
	print text_input
	jmp m1
err_div: 
    curpos err_curpos  	 
    print text_divide
    jmp m1
err_ovflw: 
    curpos err_curpos 	
    print err_overflow
    jmp	Exit
err_zer: curpos err_curpos 
    print err_zero
    jmp	Exit
;------------------------------------

;-------------Арифметика-------------
mathing:
    xor dx, dx
        mov cx, num_size
		mov si, offset number
sm1:	mov ax,[si]
        cmp ax, 0
		jle sm2
		inc dx
		add PosSum,ax
		jno sm2         ; проверяем перезаполнение
		jmp err_ovflw   
sm2:	inc si          ; переходим к следующему слову
		inc si
		loop sm1
		
; Считаем + и - числа
		mov di, offset n_pos
        add [di], dx
		xor di, di
		mov cx, num_size
		mov si, offset number
		mov bx, offset numberPos
		mov di, offset numberNeg
cmp1:	mov ax,[si]
		cmp ax,0   
		jl else1
		mov [bx], ax   ; Записываем в положительные если  >0
		inc bx
		inc bx
		inc si
		inc si
		jmp end1
else1:	mov [di], ax   ; Записываем в отрицательные если  <0
		inc di
		inc di
		inc si
		inc si
end1:	loop cmp1
;-----------------------------------------------

; ------ВЫВОД РЕЗУЛЬТАТА------------------------
;Положительные числа
    xor di, di
	mov cx, 5
outp:	mov ax, numberPos+di
	call BinToAsc
	curpos output_pos+di
	print out_str
	clean out_str
	inc di
	inc di
	loop outp
	jmp next1


err_zer1: jmp err_zer
;Отрицательные числа
next1: xor di, di
	mov cx, 5
outn:	mov ax, numberNeg+di
	call BinToAsc
	curpos output_neg+di
	print out_str
	clean out_str
	inc di
	inc di
	loop outn
;Результат
    xor bh, bh
	xor dx, dx
	cmp n_pos, 0
	je err_zer1
	mov bl, n_pos
	mov ax,PosSum
    idiv bx		
	cmp dx, 0
	je rem_non
	push ax
	
	mov ax, dx
	curpos output_res
	print mess_rem
	call BinToAsc
	print out_str	
	clean out_str
	pop ax
rem_non:
    curpos output_res+2
    print mess_possum
	call BinToAsc
	print out_str
	clean out_str
	call info_clean
	curpos mess_curpos
	print mess_endmath
	anykey
    jmp Exit
;-------------------------------

;---ВЫХОД ИЗ ПРОГРАММЫ----------
Exit: 
    call info_clean
	curpos mess_curpos
    print mess_exit
    anykey
	mov ax, 0600h
	mov bh, 07
	mov cx, 0000
	mov dx, 184fh
	int 10h
	mov ax,4c00h
	int 21h
;-------------------------------


;---ПРОЦЕДУРЫ-------------------

;Создание 1-го окна	
drawin proc
	push bp
	mov bp,sp
	mov ax,0600h
	mov cx,[bp+8]
	mov dx,[bp+6]
	mov bx,[bp+4]
	int 10h
	pop bp
	ret
drawin endp

;Создание окон
tables_drawin proc
    push si
    push cx
    xor si,si 
	;Вывод наших 6 окон
	mov cx, 6
next:	push cx
	mov ax,[upleft+si]
	push ax
	mov ax,[downri+si]
	push ax
	mov ax,[attr+si]
	push ax
	call drawin
	pop ax
	pop ax
	pop ax
	pop cx
	inc si
	inc si
	loop next
	pop cx
	pop si
	ret
tables_drawin endp

;Изменение цвета окна (COLORSWITCH)
table_redrawin proc
	mov ax,[upleft+si]
	push ax
	mov ax,[downri+si]
	push ax
	mov ax, [attr+si]
	push ax
	call drawin
	pop ax
	pop ax
	pop ax
	;Проверяем меняем ли мы внешнюю рамку основного окна
	cmp si, 0
	jne sbwnd1
	inc si
	inc si
	;Выводим основное окно
	call table_redrawin
	dec si
	dec si
sbwnd1: call print_txt
	ret
table_redrawin endp


; Вывод Информации в окнах
print_txt proc
    ;Основной текст
    push dx
    push di
    xor di,di
	irp a,<mess1,mess2,mess3,mess4, mess5, mess6, mess7, mess8>
	mov dx,curp+di
	string a
	inc di
	inc di
	endm
	pop di
	pop dx
	curpos mess_curpos
	ret
print_txt endp

info_clean proc  ;Освобождение функциональной строки
	curpos mess_curpos
	mov ah,0eh
	mov cx,0180h
	mov bh,0
clear1:	mov al,' '
	int 10h
	loop clear1
	ret
info_clean endp

;-------------------------------------------------
input_clean proc  ;Освобождение функциональной строки
	curpos input_curpos+di
	mov ah,0eh
	mov cx,0007h
	mov bh,0
clear2:	mov al,' '
	int 10h
	loop clear2
	ret
input_clean endp
;---------------------------------------------------

;-------Дальше бога нет, только математика-----------------------
DIAPAZON PROC
;проверка диапазона вводимых чисел -29999,+29999
;буфер ввода - in_str
;через bh возвращается флаг ошибки ввода
        xor bh,bh;
	xor si,si;      номер символа в вводимом числе
;если ввели менее 5 символов проверим их допустимость
	cmp size_of,5
	jb dop
;если ввели 5 или более символов проверим является ли первый минусом
	cmp sign_str,2dh
	jne plus ;   если 1 символ не минус,проверим число символов
;если первый - минус и символов меньше 6 проверим допустимость символов 
	cmp size_of,6
	jb dop        
	inc si;         иначе проверим первую цифру
	jmp first

plus:   cmp size_of,6;      введено 6 символов и первый - не минус 
	je error1;       ошибка
first:  cmp in_str[si+2],32h;сравним первый символ с 2
	jle dop;если первый <=2 -проверим допустимость символов
error1:	mov bh,flag_err;иначе bh=flag_err
dop:	ret
DIAPAZON ENDP


DOPUST PROC
;проверка допустимости вводимых символов
;буфер ввода - sign_str
;si - номер символа в строке
;через bh возвращается флаг ошибки ввода
	xor bh,bh
        xor si,si
	xor ah,ah
	xor ch,ch
	mov cl,size_of;в ch количество введенных символов
m11:	mov al,[sign_str+si]; в al - первый символ
	cmp al,2dh;является ли символ минусом
	jne testdop;если не минус - проверка допустимости
	cmp si,0;если минус  - является ли он первым символом
	jne error2;если минус не первый -ошибка
	jmp m13
;является ли введенный символ цифрой
testdop:cmp al,30h
	jb error2
	cmp al,39h
	ja error2
m13: 	inc si
	loop m11
	jmp m14
error2:	mov bh, flag_err;при недопустимости символа bh=flag_err
m14:	ret
DOPUST ENDP


AscToBin PROC
;в cx количество введенных символов
;в bx - номер символа начиная с последнего 
;буфер чисел - number, в di - номер числа в массиве
	xor ch,ch
	mov cl,size_of
	xor bh,bh
	mov bl,cl
	dec bl
	mov si,1  ;в si вес разряда
n1:	mov al,[sign_str+bx]
	xor ah,ah
	cmp al,2dh;проверим знак числа
	je otr    ; если число отрицательное
	sub al,30h
	mul si
	add [number+di],ax
	mov ax,si
	mov si,10
	mul si
	mov si,ax
	dec bx
	loop n1
	jmp n2
otr:	neg [number+di];представим отрицательное число в дополнительном коде
n2:	ret
AscToBin ENDP


BinToAsc PROC
;преобразование числа в строку
;число передается через ax
	xor si,si
	add si,5
	mov bx,10
	push ax
	cmp ax,0
	jnl mm1
	neg ax
mm1:	cwd
	idiv bx
	add dl,30h
	mov [out_str+si],dl
	dec si
	cmp ax,0
	jne mm1
	pop ax
	cmp ax,0
	jge mm2
	mov [out_str+si],2dh
mm2:	ret
BinToAsc ENDP


DivCheck PROC  ;проверка кратности
	;xor dx, dx
	mov bx, divider ;делитель
	mov ax, [number+di]
	cwd
	idiv bx
	cmp dx, 0    ;Сравниваем остаток с нулем.
	je l1        ;Если не равны, выдаем ошибку
    mov bh, flag_err
    mov ax, 0
    mov [number+di], ax
	
l1: ret
DivCheck ENDP


BinToAscDVDR PROC
;преобразование числа в строку
;число передается через ax
	xor si,si
	push bx
	push dx
	mov si, 1
	mov bx,10
	push ax
	cmp ax,0
	jnl mm5
	neg ax
mm5:	cwd
	idiv bx
	add dl,30h
	mov [out_str+si],dl
	dec si
	cmp ax,0
	jne mm5
	pop ax
	cmp ax,0
	jge mm6
	mov [out_str+si],2dh

mm6: pop dx
	pop bx
	xor si, si
	ret
BinToAscDVDR ENDP
;-----------------------------
c1 ENDS
end start