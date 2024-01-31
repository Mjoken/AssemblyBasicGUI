;vot macrosy
cout macro f1
     push ax
     push dx
     mov dx, offset f1
     mov ah, 9
     int 21h
     pop dx
     pop ax
endm
cin macro f1
    push ax
    push dx
    mov dx, offset f1
    mov ah, 0Ah
    int 21h
    pop dx
    pop ax
endm
clear_out macro
local clear
		push cx
		push si
		xor si,si
		mov cx, 6
clear:
		mov [out_str+si], ' '
        inc si
        loop clear
		pop si
		pop cx
endm
clear_error macro
            curpos 0d04h
            cout out_str
            cout out_str
endm
anykey macro
	push ax
	mov ah,7
	int 21h
	pop ax
endm
vivod macro x
	mov dx,offset x
	mov ah,9
	int 21h
endm
vivod2 macro a
	mov ah,9
	mov dx,offset a
	int 21h
endm
curpos macro strcol
	push bx
	push ax
	push dx
	mov dx,strcol
	mov ah,2
	mov bh,0
	int 10h
	pop dx
	pop ax
	pop bx
endm
stroka macro y
local m1
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
endm	
;вывод пробелов в строку сообщений
;координаты строки сообщений 1401h
probel macro
local clear
	curpos koord
	mov ah,0eh
	mov cx,70
	mov bh,0
clear:	mov al,' '
	int 10h
	loop clear
endm
.model small
.data
;koordinaty okon 
upleft dw 0002h, 0103h, 0120h, 0130h, 0a20h, 0b21h, 0b03h
downri dw 1018h, 0817h, 0727h, 0737h, 1233h, 1132h, 0f17h
attr dw 1700h, 2500h, 3100h,5700h,1700h,3100h, 0CF00h, 1700h
curp dw 0007h, 0a0bh, 0a26h, 0120h,0130h
mess1 db 'Input numbers$'
mess2 db 'Errors$'	
mess3 db 'Result$'
mess4 db 'Massiv+$'
mess5 db 'Massiv-$'

inputKoord dw 0207h, 0307h, 0407h, 0507h, 0607h
in_str label byte
len db 7
amount db (?)
string db 7 dup (?)
sze dw  5
flag_error equ 1

out_str db 6 dup(' '), '$'
text_error db 'Input error!$'

summMess db 'Sum: $'
summMessPos dw 0b22h
summPos dw 0b26h

DivMess db 'Div res: $'
DivMessPos dw 0c22h
DivPos dw 0d26h, 0e26h, 0f26h, 1026h, 1126h
div_err1 db 'Div by 0!$'

NegPos dw 0330h, 0430h, 0530h, 0630h, 0730h
PosPos dw 0320h, 0420h, 0520h, 0620h, 0720h

messovf db 'Overflow!$'

PosSum dw 0
number dw 5 dup (0)
numberPos dw 5 dup (0)
numberNeg dw 5 dup (0)
exitmess db 'Press F1 to exit',10,13,'$'
;ramki iz ASCII
ramin db 201,6 dup (205),'Input',6 dup (205),187,'$'
pro1 db 'Do you wish to change Result window color? Y/N$'
pro2 db 'Press any key for exit$'
pro3 db 'Press <==> to change.Enter for choice.$'
pro4 db 'Press any key for input.$'
koord dw 1401h
.stack 256
.code
; ----- Clear screan and use graphic mode -----

start:	mov ax,@data
	mov ds,ax
	mov ax,0003h
	int 10h
	
; --------------------------------------------
; ----- Draw screans -----

	xor si,si
	mov cx,7
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
	
; --------------------------------------------	
; ----- Output messages on screen (mess1, mess2... in curp) -----

	xor di,di
	irp a,<mess1,mess2,mess3,mess4,mess5>
	mov dx,curp+di
	stroka a
	inc di
	inc di
	endm
; --------------------------------------------	
; ----- change output massive -----
	curpos koord
	vivod pro1
repeat:	mov ah,0
	int 16h
	cmp al,'n'
	je col_ok
	cmp al,'y'
	jne repeat
	probel
	curpos koord
	vivod pro3
	call wincol
	jmp tobe
col_ok: probel
	curpos koord
	vivod pro4
tobe:	anykey
; -------------------------Input-----------------------	

	   xor di, di
       xor si, si
       mov cx, sze
inp:
       push cx
m1:
       curpos inputKoord+si

       cin in_str
       ;cout endl

       push si

       call check_arrange
       cmp bh, flag_error
       je err1

       call check_sym
       cmp bh, flag_error
       je err1

       call AscToBin

       pop si

       inc di
       inc di
       inc si
	   inc si
       pop cx
	   clear_error	
       loop inp

       jmp m2

err1:
      clear_error
      curpos 0d04h
      cout text_error
      pop si
      curpos inputKoord+si
      cout out_str
      jmp m1
;----------- Logic -----------
		
m2:		call Summ
		xor di,di
		mov dx,summMessPos
		stroka summMess
		
		xor di,di
		mov dx, DivMessPos
		stroka DivMess
		
		mov ax,PosSum	
		call BinToAsc
		curpos summPos
		cout out_str
		
		call PosAndNeg
		
		call MassDivAndOut
		
		call OutPosAndNeg
; ----- EXIT PROGRAMM -----
		probel
		curpos koord
		vivod pro2
		anykey	
		mov ax,4c00h
		int 21h
OVR:
		clear_error
		curpos 0d04h
		cout messovf  ;вывод сообщения о переполнении
		mov ax,4c00h
		int 21h
; -------------------------------------- Block of procedures --------------------------------------
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
; ----------------------- swap result color ----------------------
wincol proc
	mov ax,upleft+10
	push ax
	mov ax,downri+10
	push ax
	mov bx,0
pressk:	mov ah,0
	int 16h
	cmp ax,1c0dh
	je fin
	cmp ax,4d00h
	je right
	cmp ax,4b00h
	je left
	jmp pressk
right:	cmp bh,0f0h
	je pressk
	add bh,10h
	push bx
	call drawin
	pop bx
	jmp pressk
left:	cmp bh,10h
	je pressk
	sub bh,10h
	push bx
	call drawin
	pop bx
	jmp pressk
fin:	probel
	curpos koord
	vivod pro4
	pop ax
	pop ax
	ret
wincol endp
; ------------------------------------------------
; ------- podsvetka? ---------
activ proc
	xor di,di
	mov si,2
	mov ax,[upleft+si]
	push ax
	mov ax,[downri+si]
	push ax
	mov ax,0b500h
	push ax
	call drawin
	pop ax
	pop ax
	pop ax
	mov dx,curp+di
	stroka mess1	
	ret
activ endp	
; ------------------------------------------------
; ------- ASCII Input to number ---------	
AscToBin PROC
; in cx - amount inputed symbolls
; in bx - symboll's number start from last
; buffer numbers - numbers_arr, in di - number's number in arr
  xor ch, ch
  mov cl, [amount]
  xor bh, bh
  mov bl, cl
  dec bl
  mov si, 1

n1:
    mov al, [string+bx]
    xor ah, ah

    cmp al, 2dh
    je otr

    sub al, 30h
    mul si
    add [number+di], ax
    mov ax, si
    mov si, 10
    mul si
    mov si, ax
    dec bx
    loop n1
    jmp n2

otr:
     neg [number+di]
n2:
    ret
AscToBin ENDP
; ------------------------------------------------	

check_arrange PROC
; Check arrange input numbers -299999, +299999
; buffer input - string
; bh - return flag error
     xor bh, bh
     xor si, si

     cmp [amount], 5
     jb dop

     cmp [string], 2dh
     jne plus

     cmp [amount], 6
     jb dop
     inc si
     jmp first

plus:
      cmp [amount], 6
      je error1

first:
       cmp [string+si], 32h
       jna dop

error1:
       mov bh, flag_error

dop:
     ret
check_arrange ENDP

check_sym PROC
; check input symbolls
; buffer input - string
; si - symboll's number in string
; bh - flag error input
  xor bh, bh
  xor si, si
  xor ah, ah
  xor ch, ch
  mov cl, [amount]

m11:
     mov al, [string+si]
     cmp al, 2dh
     jne testdop

     cmp si, 0
     jne error2

     jmp m13

testdop:
         cmp al, 30h
         jb error2

         cmp al, 39h
         ja error2

m13:
     inc si
     loop m11
     jmp m14

error2:
        mov bh, flag_error

m14:
     ret
check_sym ENDP

Summ PROC
		xor cx,cx
		xor si,si
		mov cx, sze
		mov si, offset number
q1:		mov ax,[si]
		add PosSum,ax
		jno Q2
		jmp OVR
Q2:		inc si
		inc si
		loop q1
;-----------------
		ret
Summ ENDP

BinToAsc PROC
; transform number into string
; number transfer from ax
  xor si, si
  add si, 5
  mov bx, 10
  push ax

  cmp ax, 0
  jnl mm1

  neg ax
mm1:
     cwd
     idiv bx
     add dl, 30h
     mov [out_str+si], dl
     dec si

     cmp ax, 0
     jne mm1

     pop ax

     cmp ax, 0
     jge mm2

     mov [out_str+si], 2dh
mm2:
     ret
BinToAsc ENDP

PosAndNeg PROC
		mov cx, 5
		mov si, offset number
		mov bx, offset numberPos
		mov di, offset numberNeg
start1:	mov ax,[si]
		cmp word ptr [si],0
		jl else1
		mov [bx], ax
		inc bx
		inc bx
		inc si
		inc si
		jmp break1
else1:	mov [di], ax
		inc di
		inc di
		inc si
		inc si
break1:	loop start1
		ret
PosAndNeg ENDP

OutPosAndNeg PROC
		clear_out
		xor cx,cx
		xor di,di
		xor si,si
		mov cx,5
q4:		mov ax,numberPos+di
		clear_out
		call BinToAsc
		curpos PosPos+di
		cout out_str
		inc di
		inc di
		loop q4
		
		clear_out
		xor cx,cx
		xor di,di
		xor si,si
		mov cx,5
q5:		mov ax,numberNeg+di
		clear_out
		call BinToAsc
		curpos NegPos+di
		cout out_str
		inc di
		inc di
		loop q5
		ret
OutPosAndNeg ENDP

MassDivAndOut PROC
		xor ax,ax
		xor bx,bx
		xor dx,dx
		xor si,si
		mov cx, 5
start2:	mov ax, numberPos+si
		mov bx, numberNeg+si
		cmp bx,0
		je divErr
		idiv bx
		push si
		;
		clear_out		
		call BinToAsc
		pop si
		curpos DivPos+si
		cout out_str
		;
		xor dx,dx
		inc si
		inc si
		jmp end2
		
divErr:	
		push si
		clear_out
		call BinToAsc
		pop si
		curpos DivPos+si
		cout div_err1
		inc si
		inc si
	
end2:	
		loop start2
	ret
MassDivAndOut ENDP

end start
