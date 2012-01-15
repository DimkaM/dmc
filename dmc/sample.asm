	INCLUDE "text_h.asm"
	INCLUDE "samp_h.asm"


begin
	MEM_SCR
	call txt.settxtmode
	
	ld ix,rpan
	call txt.clsall
	ld a,0x20
	ld (ix+txt.WIN.atr),a
	MEM_FAT
	F_CHDRIVE 0
	F_MOUNT 0,lfatfs
	F_MOUNT 1,rfatfs
	call readfnos
	call pr_flist_new
	ld ix,help.win
	call txt.clswin
	xor a
	WIN_SET_AT a,a
	PRINTW help.str
	ld ix,lpan
	call readfnos
	call pr_flist_new

mainloop
	MEM_SCR
	CALL txt.cursor_v
.l1	KBD_GET_CHAR
	cp 0x06
	jp z,curstab
	cp 0x08
	jp z,cursleft
	cp 0x09
	jp z,cursright
	cp 0x0a
	jp z,cursdw
	cp 0x0b
	jp z,cursup
	cp 0x0d
	jp z,cursent
	;cp 0x20
	;jp z,mark
	cp 0x31
	jp z,about
	cp 0x32
	jp z,chdrv
	cp 0x33
	jp z,view
	cp 0x35
	jp z,copy
	cp 0x36
	jp z,rename
	cp 0x37
	jp z,mkdir
	cp 0x38
	jp z,delete
	jr mainloop.l1
	
mark
	CALL txt.cursor_v
	;call getfnocurs
	DEC hl
	ld a,0x10:and (hl):jp nz,mainloop
	ld de,FILINFO.MARK-FILINFO.FATTRIB
	add hl,de
	ld a,(hl):cpl:ld (hl),a
	ld e,0x20
	or a:jr z,.l1
	ld e,'*'
.l1	ld a,e:ld (.str),a
	xor a:WIN_SET_CX a
	PRINTW mark.str
	jp mainloop
.str byte 0,0

chdrv
	CALL txt.cursor_v
.l3	WIN_GET_FATFS h,l
	inc hl:ld a,(hl)
	WIN_GETXY h,l
	push ix,af
	ld ix,.win
	setxy h,l
	ld a,3:ld (ix+txt.MENU.start),a
	pop af
.l4	ld de,.strchdrv
	call txt.menu
	jr nz,.l4
	pop ix
	WIN_GET_FATFS b,c
	inc bc:ld (bc),a
	
	WIN_GET_FATFS h,l
	inc hl,hl:ld a,(hl)
	WIN_GETXY h,l
	push ix,af
	ld ix,.menupart
	setxy h,l
	ld a,3:ld (ix+txt.MENU.start),a
	pop af
	ld de,.strpart
	call txt.menu
	pop ix
	jr nz,.l3
	WIN_GET_FATFS b,c
	push bc:inc bc,bc:ld (bc),a
	
	MEM_FAT
	WIN_DRIVE e
	pop bc
	F_MNT
	ld a,(ix+txt.FWIN.drive):add 0x30:ld (curdir),a
	ld de,dir
	ld bc,curdir
	F_OPDIR
	CHK_ERR_JMP .l3
	jp cursent.l2
.win	txt.MENU 0,0,13,8,0,0,0x30,0,4
.strchdrv	byte 13,"   Drive:",13,13,"   Z-Card",13
			byte " Nemo master",13," Nemo slave",13,"   nGS-SD",0
.menupart	txt.MENU 0,0,7,7,0,0,0x30,0,4
.strpart	byte 13," Part:",13,13,"   1",13
			byte "   2",13,"   3",13,"   4",0
			
about
	CALL txt.cursor_v
	push ix:ld ix,.win
	call txt.savewin
	ld a,1
	WIN_SET_AT a,a
	PRINTW about.txt
	KBD_GET_CHAR
	call txt.restscr
	pop ix
	jp mainloop
.win	txt.WIN 27,8,25,10,0,0,0x30
.txt	byte "assembly of 08.11.11",13
	byte " Used sources:",13
	byte " FatFs library......ChaN",13
	byte " SD/HDD drivers..Savelij",13
	byte " keyboard driver..Breeze",13
	byte " shell............DimkaM",13
	byte " Thanks: NedoPC,Vitamin,",13
	byte " Deathsoft,TS-Labs",0
	
mkdir
	CALL txt.cursor_v
	MEM_SET inpstr,' ',12
	xor a
	WIN_SET_CX a
	PRINTW inpstr
	xor a
	WIN_SET_CX a
	ld de,inpstr
	ld a,8
	call txt.input
	ld de,inpstr:ld a,(de):or a
	jp z,cursent.l2
	MEM_FAT
	F_MKDIR
	CHK_ERR
	jp cursent.l2
	
copy
	CALL txt.cursor_v
	call get_fno.name
	ld de,inpstr:ld bc,12:ldir
	WIN_GET_PAN h,l
	push hl:ex (sp),ix
	ld de,inpstr:call txt.progrbar.init
	MEM_FAT
	ld e,(ix+txt.FWIN.drive)
	ld a,0x30:add a,e
	ld (drvstr),a
	MEM_SET .fp1,0,FIL*2
	F_OPEN .fp1,inpstr,FA_OPEN_EXISTING|FA_READ
	CHK_ERR_JMP .err1
	F_OPEN .fp2,drvstr,FA_CREATE_NEW|FA_WRITE
	cp 0x08:jr nz,.l2
	ld de,.strcpy
	call txt.asker
	jp nz,.err1
	MEM_FAT
	F_OPEN .fp2,drvstr,FA_CREATE_ALWAYS|FA_WRITE
.l2	CHK_ERR_JMP .err1
	MEM_FBUF
	ld hl,.res:push hl
.l1	call txt.progrbar.tik
	;MEM_FAT
	ld de,.fp1
	ld bc,0xc000
	ld hl,0x4000:push hl
	F_READ
	pop hl
	CHK_ERR_JR .err
	ld de,(.res):ld a,e:or d:jr z,.end
	ld (.res1),de:push de
	ld de,.fp2
	ld bc,0xc000
	F_WRITE
	pop de
	CHK_ERR_JR .err
	ld de,(.res1):ld hl,(.res):sbc hl,de
	jr z,.l1
.err
	MEM_FAT
	ld de,drvstr
	F_UNLINK
.end
	pop hl
	MEM_FAT
	F_CLOSE .fp1
	F_CLOSE .fp2
.err1
	MEM_FAT
	call readfnos
	call txt.progrbar.end
	call pr_flist_new
	pop ix
	jp mainloop
.fp1=MEM_FREE
.fp2=.fp1+FIL
.res	dw 0
.res1	dw 0
.strcpy	byte	"This file name exists. Overwrite?",0

	
delete
	ld de,.strdel
	call txt.asker
	jp nz,mainloop.l1
	CALL txt.cursor_v
	call get_fno.name
	ex hl,de
	MEM_FAT
	F_UNLINK
	CHK_ERR
	jp cursent.l2
.strdel	byte	"Deleting a file, are you sure?",0
	
rename
	CALL txt.cursor_v
	call get_fno.name
	ld a,'.':cp (hl):jp z,mainloop
	push hl
	ld de,inpstr:xor a:ld (de),a
	ld a,1
	WIN_SET_CX A
	ld a,12
	call txt.input
	ld de,inpstr:ld a,(de):or a
	jp z,cursent.l2
	MEM_FAT
	pop de
	ld bc,inpstr
	F_RENAME
	CHK_ERR
	jp cursent.l2
	
curstab
	CALL txt.cursor_v
	ld l,(ix+txt.FWIN.pan)
	ld h,(ix+txt.FWIN.pan+1)
	push hl:pop ix
	LD a,(IX+txt.FWIN.p_poz)
	ld bc,mem.b3:out (c),a
	MEM_FAT
	ld e,(ix+txt.FWIN.drive)
	F_CHDR
	jp mainloop
cursent
	CALL txt.cursor_v
	MEM_FAT
	call get_fno.name
	DEC hl
	ld a,0x10
	and (hl)
	jr z,.l1
	inc hl
	ex hl,de
	F_CHDIR
	CHK_ERR_JMP mainloop
.l2	call readfnos
.l3	call pr_flist_new
.l1	jp mainloop
cursright
	CALL txt.cursor_v
	ld d,(ix+txt.WIN.h):ld a,(ix+txt.WIN.cy)
	inc a:sub d:ld d,a:jr nz,.l1
	call pr_flist:ld a,0xe0:and l
	ld (IX+txt.FWIN.poz+1),h
	ld (IX+txt.FWIN.poz),a:exa
	ld (IX+txt.FWIN.p_poz),a
	ld a,(ix+txt.FWIN.curss)
	dec a:ld (ix+txt.WIN.cy),a
	jp mainloop
.l1	call get_fno.next:jp z,mainloop
	inc (ix+txt.WIN.cy)
	inc d:jr nz,.l1
	jp mainloop
cursdw
	CALL txt.cursor_v
	call get_fno.next
	jp z,mainloop
	inc (ix+txt.WIN.cy)
	WIN_GET_CY a
	cp (ix+txt.FWIN.curss)
	jp nz,mainloop
.l1	call pr_flist
	jp mainloop

cursleft
	display $
	CALL txt.cursor_v
	xor a
	or (ix+txt.WIN.cy):jr nz,.l1
	ld a,(ix+txt.WIN.h):ld (ix+txt.WIN.cy),a
.l1	call get_fno.prev
	jr z,.l2
	dec (ix+txt.WIN.cy):jp nz,.l1
.l2	call pr_flist
	jp mainloop
	
cursup
	CALL txt.cursor_v
	call get_fno.prev
	jp z,mainloop
	dec (ix+txt.WIN.cy)
	jp p,mainloop
.l1	ld hl,(IX+txt.FWIN.poz)
	ld a,(IX+txt.FWIN.p_poz)
	push hl,af
	ld e,0
.l3	inc e:ld a,e
	cp (ix+txt.WIN.h):jr z,.l2
	call get_fno.prev
	jr nz,.l3
.l2	dec e:push de
	call pr_flist
	pop de:ld (ix+txt.WIN.cy),e
	pop af,hl
	ld (IX+txt.FWIN.poz),hl
	ld (IX+txt.FWIN.p_poz),a
	jp mainloop
	
printerr
	or a
	ret z
.l1	push ix
	push af
	ld ix,.werr
	MEM_SCR
	call txt.savewin
	ld hl,0x0101
	WIN_SET_AT h,l
	PRINTW messerr
	pop af:push af
	add a,a
	ld e,a
	ld d,0
	ld hl,FRESULT
	add hl,de
	ld e,(hl)
	inc hl
	ld d,(hl)
	ld a,1
	WIN_SET_CX a
	inc (ix+txt.WIN.cy)
	CALL txt.print
	ld a,1
	WIN_SET_CX a
	inc (ix+txt.WIN.cy)
	ld de,anykey
	CALL txt.print
	KBD_GET_CHAR
	call txt.restscr
	;MEM_FFF
	pop af
	pop ix
	ret
.werr	txt.WIN 9,9,60,5,0,0,0x17

readfnos				;de=dir
	;MEM_UNHIDE
	ld a,mem.fat_p
	ld bc,mem.b1
	out (c),a
	ld a,(ix+txt.FWIN.pages)
	ld b,high mem.b2
	out (c),a
	;MEM_HIDE
	
	ld a,(ix+txt.FWIN.drive):add a,0x30:ld (curdir),a
	WIN_GETPAGES a
	ld (.num),a
	ld de,dir
	ld bc,curdir
	F_OPDIR
.l2	ld bc,0x8000
.l1	ld de,dir
	F_RDIR
	ld a,FILINFO.FNAME:add c:ld c,a
	LD A,(BC)
	or a
	ret z
	dec c:ld a,(bc):and 0x10:jr nz,.cat
	ld a,0x20
.cat	ld (bc),a
	ld d,b,e,c
	push bc
	;MEM_UNHIDE
	ld iy,0xfff8:add iy,bc ;-8+bc
	call fno_sort
	;MEM_HIDE
	pop bc
	ADDBC8 0x18
	bit 6,b:jr z,.l1
	ld hl,.num:inc (hl)
	;MEM_UNHIDE
	ld bc,mem.b2:ld a,(hl)
	out (c),a
	;MEM_HIDE
	ld bc,0x8000
	jr .l1
.num	word 0

fno_sort
	xor a:ld hl,0x8008:sbc hl,de:jp z,.first
	ld a,(ix+txt.FWIN.p_fno_1)
	ld bc,mem.b3
	out (c),a
	ld (.num),a
	ld a,(ix+txt.FWIN.fno_1):ld h,(ix+txt.FWIN.fno_1+1)
	add FILINFO.FATTRIB:ld l,a
.l3	ld a,(de):cp (hl):jr .cat
.l2	inc l,e
	ld a,(de):or (hl):jr z,.prev
	ld a,(de):cp (hl)
.cat	jr z,.l2
	jr c,.prev
	ld a,l
	and %11100000:or FILINFO.NEXT:ld l,a ;get fno
	ld c,(hl):inc hl:ld b,(hl):inc hl:ld a,(hl)
	or a:jr z,.new
	ld hl,FILINFO.FNAME-1 ; -4000+9
	add hl,bc
	ld bc,mem.b3:out (c),a
	ld (.num),a
	ld a,e:and %11100000
	or FILINFO.FATTRIB:ld e,a ;взад на имя
	jr .l3
.new	;добавим после текущего
	ld a,l:and %11100000:ld l,a	;смещение в ноль
	push hl:ex (sp),ix			;в индексный
	push iy:pop de:set 6,d
	xor a
	ld (iy+FILINFO.NEXTP),a		;устанавливаем следующий фно zero
	ld a,(.num)
	ld (iy+FILINFO.PREVP),a	;устанавливаем предыдущий
	ld (iy+FILINFO.PREV),hl
	ld (ix+FILINFO.NEXT),de		;устанавливаем следующий
	ld a,(readfnos.num)
	ld (ix+FILINFO.NEXTP),a		
	pop ix:ret
	
.prev	;вставим перед текущим
	ld a,l:and %11100000:ld l,a	;смещение в ноль
	push hl:ex (sp),ix			;в индексный
	push iy:pop de:set 6,d
	ld a,(.num)
	ld (iy+FILINFO.NEXTP),a
	ld (iy+FILINFO.NEXT),hl	;устанавливаем следующий фно
	ld hl,(ix+FILINFO.PREV)		;берём предыдущий фно
	ld (iy+FILINFO.PREV),hl		;устанавливаем предыдущий
	ld (ix+FILINFO.PREV),de		;устанавливаем предыдущий
	ld a,(readfnos.num):ld b,a
	ld a,(ix+FILINFO.PREVP)
	ld (ix+FILINFO.PREVP),b
	ld (iy+FILINFO.PREVP),a
	pop ix
	or a:jr z,.firstfno	;если ноль то первый элемент списка
	ld bc,mem.b3:out (c),a
	push hl:pop iy
	ld (iy+FILINFO.NEXT),de	;установим следующим
	ld a,(readfnos.num)
	ld (iy+FILINFO.NEXTP),a
	ret
.first
	push iy:pop de:set 6,d
	xor a
	ld (iy+FILINFO.PREVP),a
	ld (iy+FILINFO.NEXTP),a
.firstfno
	ld (ix+txt.FWIN.fno_1),de	;запомним первый элемент списка
	ld a,(readfnos.num)
	ld (ix+txt.FWIN.p_fno_1),a
	ret
.num db 0
	
; SNA
; .NAMEBUF=MEM_FREE
; .NAMEBUF2=.NAMEBUF+13
; .FILE=.NAMEBUF2+33
        ; LD HL,.FILE     ;описатель файла
        ; PUSH HL
        ; LD HL,.NAMEBUF       ;имя файла
        ; PUSH HL
        ; LD HL,3             ;режим - открыть r/w
        ; PUSH HL
        ; CALL SET_FAT_PAGE   ;втыкаем стр. с фат
        ; CALL FATFS.OPEN     ;откр. фыйл
        ; POP BC,BC           ;снимаем со стека не нужное
        ; LD HL,.NAMEBUF2      ;сюда грузим заголовок SNA
        ; PUSH HL
        ; LD HL,27            ;заголовок 27 байт
        ; PUSH HL
        ; LD HL,.NAMEBUF2+31   ;тут вернётся кол-во
        ; PUSH HL             ;прочитанных байт
        ; CALL FATFS.READ     ;читаем
        ; POP BC,BC,BC        ;снимем не нужное
        ; LD D,5              ;будем грузить в пятую стр.
        ; CALL LOAD4X4
        ; LD D,2              ;и во вторую тоже
        ; CALL LOAD4X4
        ; LD D,0              ;а вот тут хер знает в какую
        ; CALL LOAD4X4        ;попробуем в нулевую
        ; LD HL,.NAMEBUF2+27      ;сюда грузим второй заголовок SNA
        ; PUSH HL
        ; LD HL,4            ;заголовок 4 байта
        ; PUSH HL
        ; LD HL,.NAMEBUF2+31   ;тут вернётся кол-во
        ; PUSH HL             ;прочитанных байт
        ; CALL FATFS.READ     ;читаем
        ; POP BC,BC,BC        ;снимаем
        ; LD HL,(.NAMEBUF2+31)   ;кол-во прочитанных байт
        ; LD A,H              ;проверим на ноль
        ; OR L
        ; JR NZ,.L6           ;ЕСЛИ НЕ, ТО ОБРАЗ 128КБ
        ; LD A,#10            ;7ффд для 48к
        ; LD (.NAMEBUF2+29),A
        ; XOR A
        ; LD (SLOTS.III),A        ;сохраняем
        ; LD (.SNA_L8),A       ;убираем сохранение РС на стеке он там уже есть
        ; JR .SNA_L7           ;обходим загрузку 128к
; .L6     LD A,(.NAMEBUF2+29)  ;Смотрим 7ФФД
        ; AND %111            ;отсекаем лишнее
        ; LD (SLOTS.III),A        ;сохраняем
        ; LD D,0              ;Смотрим нужно ли загр.
        ; CP D                ;нулевую стр.
        ; JR Z,.SNA_L5
        ; LD BC,#BFF7         ;Тваю мать, промахнулись
        ; XOR %1000000        ;нада перекинуть в нужную
        ; OUT (C),A           ;и загр. нулевую
        ; LD HL,#4000
        ; LD BC,HL
        ; LD DE,#8000
        ; LDIR
        ; LD BC,#BFF7
        ; LD A,FAT_PAGE
        ; OUT (C),A
        ; LD D,0
        ; CALL LOAD4X4
; .SNA_L5
        ; LD A,(SLOTS.III)
        ; LD D,1
        ; CP D
        ; CALL NZ,LOAD4X4
        ; LD A,(SLOTS.III)
        ; LD D,3
        ; CP D
        ; CALL NZ,LOAD4X4
        ; LD A,(SLOTS.III)
        ; LD D,4
        ; CP D
        ; CALL NZ,LOAD4X4
        ; LD A,(SLOTS.III)
        ; LD D,6
        ; CP D
        ; CALL NZ,LOAD4X4
        ; LD A,(SLOTS.III)
        ; LD D,7
        ; CP D
        ; CALL NZ,LOAD4X4
; .SNA_L7
        ; CALL FATFS.CLOSE
        ; POP BC
        ; LD HL,#0205
        ; LD (SLOTS.I),HL
        ; CALL SET_SLOTS_PAGES    ;расставим стр.
        ; LD SP,.NAMEBUF2-1
        ; POP AF
        ; LD I,A
        ; POP HL        ;забираем алтерн. регистры
        ; POP DE
        ; POP BC
        ; POP AF
        ; EXA
        ; EXX
        ; LD A,(.NAMEBUF2+29)  ;восстановим 7ФФД
        ; LD BC,#7FFD
        ; OUT (C),A
        ; LD SP,.NAMEBUF2+13
        ; POP BC              ;забираем регистры
        ; POP IY
        ; POP IX
        ; LD SP,.NAMEBUF2+21   ;забираем АФ
        ; POP AF
        ; LD SP,(.NAMEBUF2+23) ;стек
        ; LD HL,(.NAMEBUF2+27) ;PC
; .SNA_L8
        ; PUSH HL             ;Закидываем
        ; PUSH AF             ;добро
        ; PUSH BC             ;на стек
        ; LD A,(.NAMEBUF2+19)
        ; CP 0
        ; JR Z,.SNA_L1
        ; LD A,#FB
        ; LD (.ONST_DI),A
; .SNA_L1
        ; LD A,(.NAMEBUF2+25)  ;режим прерываний
        ; LD B,#46
        ; CP 1
        ; JR C,$+4
        ; SET 4,B
        ; CP 2
        ; JR C,$+4
        ; SET 3,B
        ; LD A,B
        ; LD (.SNA_L2),A
; .SNA_L2=$+1
        ; IM 0
        ; LD HL,(.NAMEBUF2+23)
        ; LD DE,6+.SNA_L3-.ON_STACK
        ; SUB HL,DE
        ; LD (.SNA_L4),HL
        ; LD DE,.ON_STACK
        ; EX HL,DE
        ; LD BC,.SNA_L3-.ON_STACK
        ; LDIR
        ; ld a,1
        ; OUT (#BF),A
        ; LD BC,#3ff7
        ; LD A,%10111111
        ; LD HL,(.NAMEBUF2+9)
        ; LD DE,(.NAMEBUF2+11)
; .SNA_L4=$+1
        ; JP #0000
; .ON_STACK
        ; OUT (C),A
        ; XOR A
        ; OUT (#BF),A
        ; POP BC
        ; POP AF
; .ONST_DI
        ; DI
        ; RET
; .SNA_L3

lpan		txt.FWIN 1,3,38,20,0,0,0x20,0,0,0,0,0,mem.lfno1,rpan,0,lfatfs
rpan		txt.FWIN 40,3,38,20,0,0,0x00,0,0,0,0,0,mem.rfno1,lpan,1,rfatfs
drvstr		byte " :"
inpstr		block 12,0xaa:db 0
curdir		byte " :",0
anykey		byte "Press any key",0
messerr		byte "Error:",0
ok			byte 13,0
lfatfs		FATFS
dir		DIR
rfatfs		FATFS
help
.win		txt.WIN 1,24,77,1,0,0,0x30
.str		byte "Tab-Panel 1-About 2-ChDrv 5-Copy 6-Rename 7-MkDir 8-Delete",0 