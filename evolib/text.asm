; 0x=(x++)/2
; 1x=x/2
; addr0=y<<6 
; x y w h
; 
; yd=(y*64)
; for(i=x;i<(w+x);i++)
; {
;  
; }

settxtmode
	ld bc,0xff77
	;if TEXTMODE
	ld a,0x07
	;else
	;ld a,0x26
	;endif
	out (c),a
	MEM_TBUF
	ld hl,0xc002
	ld (0xc000),hl
	ret
	
clsall			;очистить экран
	ld hl,0x0000
	ld de,0x5019
	jr cls
clswin
	WIN_GETXY h,l
	getwh d,e
cls		;очистить область экрана
	ld c,h	;h-x l-y d-w e=h
.l2	ld b,d
.l1	push hl
	call xy2scr
	ld a," "
	ld (hl),a
	TXT2ATR
	getattr a
	ld (hl),a
	pop hl
	inc h
	djnz .l1
	dec e
	ret z
	inc l
	ld h,c
	jr .l2
	
print		;печать de-указатель на текст
	WIN_GET_AT h,l
printat		;печать с позиции hl
.l1	WIN_SET_AT h,l
	ld a,(de)
	or a
	ret z
	cp 13
	jr z,.l4
	cp 0x08
	jp nz,.l5
	inc de
	xor a
	cp h
	jr z,.l1
	dec h
	jr .l1
.l5	cp 0x09
	jp z,.l6
	WIN_GETXY b,c
	add hl,bc
	call xy2scr
	ld a,(de)
	ld (hl),a
.l6	WIN_GET_AT h,l
	ld a,h
	inc a
	getw b
	cp b
	jr nz,.l2
	ret
.l4	inc l
	geth a
	cp l
	ret z
	xor a
.l2	ld h,a
	inc de
	jr .l1
	
xy2scr			;input hl=xy
	if TEXTMODE
	ld a,0x1c
	srl h:rr a:rr a
	else
	ld a,0x0e
	srl h:rr a
	endif
	add a,l
	ld l,h
	ld h,a
	xor a
	srl h
	rr a
	srl h
	rr a
	add a,l
	ld l,a
	set 6,h
	ret
	
xy2attr
	if TEXTMODE
	ld a,0xc7
	srl h
	jr nc,.l1
	ld a,0x87
	else
	ld a,0x87
	srl h
	jr nc,.l1
	ld a,0x07
	endif
	inc h
.l1	add a,l
	ld l,h
	ld h,a
	xor a
	srl h
	rr a
	srl h
	rr a
	add a,l
	ld l,a
	if TEXTMODE
	set 6,h
	else
	set 7,h
	endif
	ret
	
cursor
	WIN_GET_AT h,l
	WIN_GETXY d,e
	add hl,de
	ld e,h
	inc e
	jr cursor_v.l1
cursor_v
	WIN_GET_CY a
	WIN_GETXY h,l
	add a,l
	ld l,a
	getw a
	add a,h
	ld e,a
.l1	push hl
	call xy2attr
	ld a,(hl)
	cpl
	ld (hl),a
	pop hl
	inc h
	ld a,h
	cp e
	ret z
	jr .l1
	
input		;de-buffer a-width
	WIN_GET_AT h,l
	WIN_GETXY b,c
	add hl,bc
	push ix,de:ld ix,.istr
	setxy h,l
	WIN_SET_W a
	call print
	xor a
	ld (ix+txt.WIN.cx),a
.l0	call cursor
	KBD_GET_CHAR
	push af:call cursor:pop af
	cp 0x06
	jp z,.l1
	cp 13
	jp nz,.l2
	pop de
	call getstr
	pop ix
	ret
.l1	pop de:xor a:ld (de),a
	pop ix
	ret
.l2	ld (.str),a
	ld de,.str
	call print
	jr .l0
.str	dw 0
.istr	WIN 0,0,0,1,0,0,0x30

getstr		;получить текущую строку de-буфер
	ld l,(ix+WIN.cy)
	ld h,0
.l1	WIN_SET_AT h,l
	getw a
	cp h
	jr nz,.l2
	xor a
	ld (de),a
	ret
.l2	push de
	WIN_GETXY d,e
	add hl,de
	call xy2scr
	ld a,(hl)
	pop de
	ld (de),a
	inc de
	WIN_GET_AT h,l
	inc h
	jr .l1

savewin
	MEM_TBUF
	ld bc,(0xc000)
	WIN_GETXY d,e
	getwh h,l
	add hl,de
	ex hl,de
.l1	push hl
	call xy2scr
	ld a,(hl)
	ld (bc),a
	ld a,0x20
	ld (hl),a
	inc bc
	TXT2ATR
	ld a,(hl)
	ld (bc),a
	getattr a
	ld (hl),a
	inc bc
	pop hl
	inc h
	ld a,d:cp h:jr nz,.l1
	WIN_GETX h
	inc l
	ld a,e:cp l:jr nz,.l1
	ld (0xc000),bc
	ret
	
restscr
	MEM_TBUF
	ld bc,(0xc000)
	WIN_GETXY d,e
	getwh h,l
	add hl,de:ld d,h:ld e,l
.l1	dec h
	push hl
	dec l
	call xy2attr
	dec bc
	ld a,(bc)
	ld (hl),a
	dec bc
	ATR2TXT
	ld a,(bc)
	ld (hl),a
	pop hl
	ld a,h:cp (ix+txt.WIN.x):jr nz,.l1
	ld h,d
	dec l
	ld a,l:cp (ix+txt.WIN.y):jr nz,.l1
	ld (0xc000),bc
	ret
progrbar
.init
	call mem.state.store
	ld a,1:ld (.stat),a
	MEM_SCR
	push ix:ld ix,.win
	push de
	call savewin
	xor a
	WIN_SET_AT a,a
	pop de:call print
	ld de,0x0101
	WIN_SET_AT d,e
	call cursor
	pop ix
	call mem.state.rest
	ret
.tik
	call mem.state.store
	ld a,(.stat):or a:ret z
	MEM_SCR
	push ix:ld ix,.win
	call cursor
	WIN_GET_CX a
	cp 10:jr nz,.l1:xor a
.l1	inc a:WIN_SET_CX a
	call cursor
	pop ix
	call mem.state.rest
	ret
.end
	call mem.state.store
	ld a,(.stat):or a:ret z
	MEM_SCR
	push ix:ld ix,.win
	call restscr
	pop ix
	xor a:ld (.stat),a
	call mem.state.rest
	ret
.stat	db 0
.win	WIN 33,10,12,3,0,0,0x08

menu			;а-текущая позиция de-строка
	add (ix+txt.MENU.start)
	push af,de
	MEM_SCR
	call txt.savewin
	xor a
	WIN_SET_AT a,a
	pop de:call print
	pop af
	WIN_SET_CY a
.l2	CALL txt.cursor_v
.l1	KBD_GET_CHAR
	cp 0x06
	jr z,.curstab
	cp 0x0a
	jp z,.cursdw
	cp 0x0b
	jr z,.cursup
	cp 0x0d
	jr z,.cursent
	jr .l1
.curstab
	call txt.restscr
	ld a,(ix+txt.WIN.cy):sub (ix+txt.MENU.start)
	cp 0xff
	ret
.cursdw
	ld a,(ix+txt.MENU.count):add (ix+txt.MENU.start)
	dec a:cp (ix+txt.WIN.cy):jr z,.l1
	CALL txt.cursor_v
	inc (ix+txt.WIN.cy):jr .l2
.cursup
	ld a,(ix+txt.MENU.start):cp (ix+txt.WIN.cy):jr z,.l1
	CALL txt.cursor_v
	dec (ix+txt.WIN.cy):jr .l2
.cursent
	call txt.restscr
	ld a,(ix+txt.WIN.cy):sub (ix+txt.MENU.start)
	cp a
	ret


asker
	call mem.state.store
	push ix
	push de
	ld ix,.ask
	MEM_SCR
	call txt.savewin
	ld hl,0x0101
	WIN_SET_AT h,l
	pop de
	call txt.print
	PRINTW asker.str
	KBD_GET_CHAR
	push af
	call txt.restscr
	call mem.state.rest
	pop af,ix
	cp 'y':ret z
	cp 'Y':ret
	
.ask	WIN		9,9,60,5,0,0,0x17
.str	byte	13,13," Press 'Y'es('y'es) or any key",0

strnum                     ;перевод числа в десятиричный стринг
                        ;c=0  a-число  de- куда
        dec c           ;c=1  hl-число de- куда
        jr nz,oneb
        ld bc,10000
        call twa
        ld bc,1000
        call twa
        ld bc,100
        call twa
        ld a,l
        ex de,hl
        jr onb2-2
oneb    ex de,hl
        ld c,47
onb1    inc c
        sub 100
        jr nc,onb1
        ld (hl),c
        inc hl
        add a,100
        ld c,47
onb2    inc c
        sub 10
        jr nc,onb2
        ld (hl),c
        inc hl
        add a,58
        ld (hl),a
        inc hl
        ex de,hl
        ret 
twa     ld a,47
        and a
tw1     inc a
        sbc hl,bc
        jr nc,tw1
        add hl,bc
        ld (de),a
        inc de
        ret
