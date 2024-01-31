.MODEL SMALL
p1 macro f1
	push ax
	push dx
	mov dx,offset f1
	mov ah,9
	int 21h
	pop dx
	pop ax
endm
p2 macro f2
	push ax
	push dx
	mov dx,offset f2
	mov ah,0ah
	int 21h
	pop dx
	pop ax
endm
.data
mess0 db 'Input:5 numbers in [-29999,29999]',10,13,'$'
mess00 db 'Press <Enter> after each number',10,13,'$'
mess1 db 'Enter number:$'
in_str label byte
razmer db 7
kol db (?)
stroka db 7 dup (?)
number dw 5 dup (0)
numberPos dw 5 dup (0)
numberNeg dw 5 dup (0)
siz dw 5
maxnum dw (?)
PosSum dw 0
NegSum dw -5678
sred dw (?)
perevod db 10,13,'$'
text_err1 db 'Input error!','$'
div_err1 db 'Division by zero! ',10,13,'$'
messsum db 'Sum: ', '$'
messovf db 13,10,7,'Overflow!','$'
messred db 13,10,'Average:','$'
messmax db 13,10,'Max:','$'
out_str db 6 dup (' '),'$'
qwert dw 0000
newstr db 10,13,'$'
flag_err equ 1
.stack 256
.code
start: 		mov ax,@data
		mov ds,ax

;�맮� �㭪樨 0 -  ��⠭���� 3 ⥪�⮢��� �����०���, ���⪠ �࠭�
		mov ax,0003  ;ah=0 (����� �㭪樨),al=3 (����� ०���)
		int 10h
		p1 mess0
		p1 mess00
;横� �����, di - ����� �᫠ � ���ᨢ�
       		xor di,di
       		mov cx, siz ; � cx - ࠧ��� ���ᨢ�
vvod:		push cx

m1:		p1 mess1     ;�뢮� ᮮ�饭�� � ����� ��ப�
;���� �᫠ � ���� ��ப�
		p2 in_str
		p1 perevod
;�஢�ઠ ��������� �������� �ᥫ (-29999,+29999)
		call diapazon
		cmp bh,flag_err  ;�ࠢ��� bh � flag_err
		je err1          ;�᫨ ࠢ�� -ᮮ�饭�� �� �訡�� �����
;�஢�ઠ �����⨬��� �������� ᨬ�����
		call dopust
		cmp bh,flag_err
		je err1
;�८�ࠧ������ ��ப� � �᫮
		call AscToBin
		inc di
		inc di
		pop cx
		loop vvod
		jmp m2
err1:   		p1 text_err1	
		jmp m1
;����� ���� ��� ��䬥��᪮� ��ࠡ�⪨
;*******************************************************************************
;���ਬ��, ����祭�� �㬬� ������⥫���, ����⥫���, �।����, ���ᨬ��쭮��
;TRY!!!
;********************************************************************************************
m2:		mov cx, 5
		mov si, offset number
q1:		mov ax,[si]
		add PosSum,ax
		jno Q2
		jmp OVR
Q2:		inc si
		inc si
		loop q1
;---------------------------
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
		
		xor cx,cx
		xor di,di
		mov cx,5
q4:		mov ax,numberPos+di
		call BinToAsc
		p1 out_str
		inc di
		inc di
		loop q4
		
		xor cx,cx
		xor di,di
		mov cx,5
q5:		mov ax,numberNeg+di
		call BinToAsc
		p1 out_str
		inc di
		inc di
		loop q5
		
		p1 newstr
		
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
		;shr ax, 02
		mov qwert, si
		call BinToAsc
		p1 out_str
		p1 newstr
		xor dx,dx
		mov si, qwert
		inc si
		inc si
		jmp end2
		
divErr:	inc si
		inc si
		p1 div_err1	
	
end2:	loop start2
		
		
;�뢮� १���� �� �࠭
		p1 messsum
		mov ax,PosSum	
		call BinToAsc
		p1 out_str
;���⪠ ���� �뢮��
		mov cx,6
		xor si,si
clear:		mov [out_str+si],' '
		inc si
		loop clear

;...
			jmp PROGEND
OVR:		p1 messovf  ;�뢮� ᮮ�饭�� � ��९�������
			mov ah,7
			int 21h
PROGEND:	mov ax,4c00h
			int 21h
	
DIAPAZON PROC
;�஢�ઠ ��������� �������� �ᥫ -29999,+29999
;���� ����� - stroka
;�१ bh �����頥��� 䫠� �訡�� �����
        xor bh,bh;
	xor si,si;      ����� ᨬ���� � �������� �᫥
;�᫨ ����� ����� 5 ᨬ����� �஢�ਬ �� �����⨬����
	cmp kol,5
	jb dop
;�᫨ ����� 5 ��� ����� ᨬ����� �஢�ਬ ���� �� ���� ����ᮬ
	cmp stroka,2dh
	jne plus ;   �᫨ 1 ᨬ��� �� �����,�஢�ਬ �᫮ ᨬ�����
;�᫨ ���� - ����� � ᨬ����� ����� 6 �஢�ਬ �����⨬���� ᨬ����� 
	cmp kol,6
	jb dop        
	inc si;         ���� �஢�ਬ ����� ����
	jmp first

plus:   cmp kol,6;      ������� 6 ᨬ����� � ���� - �� ����� 
	je error1;       �訡��
first:  cmp stroka[si],32h;�ࠢ��� ���� ᨬ��� � 2
	jna dop;�᫨ ���� <=2 -�஢�ਬ �����⨬���� ᨬ�����
error1:	mov bh,flag_err;���� bh=flag_err
dop:	ret
DIAPAZON ENDP
DOPUST PROC
;�஢�ઠ �����⨬��� �������� ᨬ�����
;���� ����� - stroka
;si - ����� ᨬ���� � ��ப�
;�१ bh �����頥��� 䫠� �訡�� �����
	xor bh,bh
        xor si,si
	xor ah,ah
	xor ch,ch
	mov cl,kol;� ch ������⢮ ��������� ᨬ�����
m11:	mov al,[stroka+si]; � al - ���� ᨬ���
	cmp al,2dh;���� �� ᨬ��� ����ᮬ
	jne testdop;�᫨ �� ����� - �஢�ઠ �����⨬���
	cmp si,0;�᫨ �����  - ���� �� �� ���� ᨬ�����
	jne error2;�᫨ ����� �� ���� -�訡��
	jmp m13
;���� �� �������� ᨬ��� ��ன
testdop:cmp al,30h
	jb error2
	cmp al,39h
	ja error2
m13: 	inc si
	loop m11
	jmp m14
error2:	mov bh, flag_err;�� �������⨬��� ᨬ���� bh=flag_err
m14:	ret
DOPUST ENDP
AscToBin PROC
;� cx ������⢮ ��������� ᨬ�����
;� bx - ����� ᨬ���� ��稭�� � ��᫥����� 
;���� �ᥫ - number, � di - ����� �᫠ � ���ᨢ�
	xor ch,ch
	mov cl,kol
	xor bh,bh
	mov bl,cl
	dec bl
	mov si,1  ;� si ��� ࠧ�鸞
n1:	mov al,[stroka+bx]
	xor ah,ah
	cmp al,2dh;�஢�ਬ ���� �᫠
	je otr    ; �᫨ �᫮ ����⥫쭮�
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
otr:	neg [number+di];�।�⠢�� ����⥫쭮� �᫮ � �������⥫쭮� ����
n2:	ret
AscToBin ENDP
BinToAsc PROC
;�८�ࠧ������ �᫠ � ��ப�
;�᫮ ��।����� �१ ax
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
         		
end start