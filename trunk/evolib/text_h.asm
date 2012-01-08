
	module txt
	struct WIN
x		byte		;location
y		byte
w		byte		;size
h		byte
cx		byte		;позиция печати
cy		byte
atr		byte		;атрибут цвета
	ends
	
	STRUCT MENU
win		WIN
start	BYTE		;первая строка
count	BYTE		;кол-во строк
	ENDS
	
	struct FWIN
win		WIN
fno_1	dw			;первая fno
p_fno_1 db
poz		dw			;позиция в списке
p_poz	db
curss	db			;элементов в окне
pages	db			;первая страница списка
pan		dw			;указатель на соседнюю панель
drive	db			;номер панели
fatfs	dw			;указатель на структуру fatfs
	ends
	
	macro WIN_GET_PAN _HR,_LR
	LD _LR,(ix+txt.FWIN.pan)
	LD _HR,(ix+txt.FWIN.pan+1)
	endm
	
	macro WIN_GET_DIR _HR,_LR
	LD _LR,(ix+txt.FWIN.dir)
	LD _HR,(ix+txt.FWIN.dir+1)
	endm
	
	macro WIN_GET_FATFS _HR,_LR
	LD _LR,(ix+txt.FWIN.fatfs)
	LD _HR,(ix+txt.FWIN.fatfs+1)
	endm
	
	macro WIN_GETPAGES _PAG
	LD _PAG,(ix+txt.FWIN.pages)
	endm
	
	macro WIN_DRIVE _REG
	LD _REG,(ix+txt.FWIN.drive)
	endm
	
	macro WIN_SETCURS reg2
	ld (ix+txt.FWIN.curs),reg2
	endm
	
	macro WIN_GETX _X
	ld _X,(ix+txt.WIN.x)
	endm
	macro WIN_GETY _Y
	ld _Y,(ix+txt.WIN.y)
	endm
	macro WIN_GETXY __X,__Y
	WIN_GETX __X
	WIN_GETY __Y
	endm
	
	macro WIN_SETX _X
	ld (ix+txt.WIN.x),_X
	endm
	macro WIN_SETY _Y
	ld (ix+txt.WIN.y),_Y
	endm
	macro setxy reg1,reg2
	ld (ix+txt.WIN.x),reg1
	ld (ix+txt.WIN.y),reg2
	endm
	
	macro WIN_SET_W _W
	ld (ix+txt.WIN.w),_W
	endm
	
	macro getwh reg1,reg2
	ld reg1,(ix+WIN.w)
	ld reg2,(ix+WIN.h)
	endm
	
	macro getw reg1
	ld reg1,(ix+txt.WIN.w)
	endm
	
	macro geth reg2
	ld reg2,(ix+txt.WIN.h)
	endm
	
	macro WIN_SETH reg2
	ld (ix+WIN.h),reg2
	endm
	
	macro WIN_GET_CX _CX
	ld _CX,(ix+txt.WIN.cx)
	endm
	macro WIN_GET_CY _CY
	ld _CY,(ix+txt.WIN.cy)
	endm
	macro WIN_GET_AT __CX,__CY
	WIN_GET_CX __CX
	WIN_GET_CY __CY
	endm
	
	macro WIN_SET_CX _CX
	LD (ix+txt.WIN.cx),_CX
	endm
	macro WIN_SET_CY _CY
	LD (ix+txt.WIN.cy),_CY
	endm
	macro WIN_SET_AT __CX,__CY
	WIN_SET_CX __CX
	WIN_SET_CY __CY
	endm
	
	macro getattr reg1
	ld reg1,(ix+WIN.atr)
	endm
	
	macro getlattr reg1
	ld reg1,(ix+WIN.latr)
	endm
	
	macro PRINTW reg1
	ld de,reg1
	call txt.print
	endm
	
	macro TXT2ATR
	if TEXTMODE
	ld a,%00110000
	xor h
	ld h,a
	bit 4,h
	else
	ld a,%11100000
	xor h
	ld h,a
	bit 5,h
	endif
	jr nz,._T2A
	inc hl
._T2A
	ENDM
	
	macro ATR2TXT
	if TEXTMODE
	ld a,%00110000
	xor h
	ld h,a
	bit 4,h
	else
	ld a,%11100000
	xor h
	ld h,a
	bit 5,h
	endif
	jr z,._A2T
	dec hl
._A2T
	ENDM

	
	INCLUDE "text.asm",1
	endmodule

	