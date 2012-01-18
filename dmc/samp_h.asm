fnostart=0xc000
	MACRO CHK_ERR_JMP _ERRJMP
	CALL printerr
	jp nz,_ERRJMP
	ENDM

	MACRO CHK_ERR_JR _ERRJMP
	CALL printerr
	jr nz,_ERRJMP
	ENDM

	MACRO CHK_ERR
	CALL printerr
	ENDM

	MACRO CHK_ERR_RET
	OR A
	jp NZ,printerr.l1
	ENDM
	
	macro ADDBC8 _arg
	ld a,_arg
	add a,c
	ld c,a
	ld a,0
	adc a,b
	ld b,a
	endm

pr_flist_new
	ld hl,(ix+txt.FWIN.fno_1)
	LD (IX+txt.FWIN.poz),hl
	ld a,(ix+txt.FWIN.p_fno_1)
	LD (IX+txt.FWIN.p_poz),a
pr_flist
	MEM_SCR
	call txt.clswin
	xor a
	WIN_SET_AT a,a
	ld (ix+txt.FWIN.curss),a
.l3	LD d,(IX+txt.FWIN.poz+1)
	ld a,FILINFO.FATTRIB:add (IX+txt.FWIN.poz):ld e,a
	LD a,(IX+txt.FWIN.p_poz)
.l1	or a:jr z,.end
	ld bc,mem.b3:out (c),a
   exa
   push de
	inc (ix+txt.FWIN.curss)
	call txt.print
	ld de,ok
	call txt.print
	pop de
	or a
	jr nz,.end
	ld hl,FILINFO.NEXT-FILINFO.FATTRIB:add hl,de
	ld a,FILINFO.FATTRIB:add (hl):ld e,a
	inc hl:ld d,(hl):inc hl:ld a,(hl)
	jr .l1
.end
	xor a
	WIN_SET_AT a,a
	ret
	
calc_mark
	ld de,0
	push de
	call get_mark.start
.l1
	pop de
	or a:jr z,.l2
	inc de:push de
	call get_mark.next
	jr .l1
.l2
	ld a,d:or e:ret nz
	call get_fno.name
	dec hl:ld a,'*':ld (hl),a
	ld de,1
	ret
	
set_all_mark
	ld a,(ix+txt.FWIN.p_fno_1)
	ld e,(ix+txt.FWIN.fno_1):ld d,(ix+txt.FWIN.fno_1+1)
.l1
	or a:ret z
	ld bc,mem.b2:out (c),a
	ld hl,FILINFO.FATTRIB+0xc000:add hl,de
	ld a,(hl)
	cp 0x10:jr z,.l2
	ld a,'*':ld (hl),a
.l2
	ld de,FILINFO.NEXT-FILINFO.FATTRIB
	add hl,de:ld e,(hl):inc hl:ld d,(hl)
	inc hl:ld a,(hl)
	jr .l1
	
inv_all_mark
	ld a,(ix+txt.FWIN.p_fno_1)
	ld e,(ix+txt.FWIN.fno_1):ld d,(ix+txt.FWIN.fno_1+1)
.l1
	or a:ret z
	ld bc,mem.b2:out (c),a
	ld hl,FILINFO.FATTRIB+0xc000:add hl,de
	ld a,(hl)
	cp 0x10:jr z,.l2
	xor 0x20:xor 0x2a:ld (hl),a
.l2
	ld de,FILINFO.NEXT-FILINFO.FATTRIB
	add hl,de:ld e,(hl):inc hl:ld d,(hl)
	inc hl:ld a,(hl)
	jr .l1
	
get_mark
.start
	ld a,(ix+txt.FWIN.p_fno_1)
	ld e,(ix+txt.FWIN.fno_1):ld d,(ix+txt.FWIN.fno_1+1)
.l1
	or a:ret z
	ld bc,mem.b2:out (c),a
	ld hl,FILINFO.FATTRIB+0xc000:add hl,de
	ld a,(hl):cp '*':ret z
.next
	ld de,FILINFO.NEXT-FILINFO.FATTRIB
	add hl,de:ld e,(hl):inc hl:ld d,(hl)
	inc hl:ld a,(hl)
	jr .l1
	
get_fno
.name
	ld a,FILINFO.FNAME
	add (IX+txt.FWIN.poz):ld l,a
	LD h,(IX+txt.FWIN.poz+1)
	ret
.prev
	ld a,FILINFO.PREVP
	jr .l1
.next
	ld a,FILINFO.NEXTP
.l1	add (IX+txt.FWIN.poz):ld l,a
	LD h,(IX+txt.FWIN.poz+1)
	LD a,(hl):or a:ret z
	exa
	dec hl:ld a,(hl):dec hl:ld l,(hl):ld h,a
	exa
	ld (IX+txt.FWIN.poz),hl
	ld (IX+txt.FWIN.p_poz),a
	ld bc,mem.b3:out (c),a
	ret
FRESULT
	dw .OK
	dw .DISK_ERR
	dw .INT_ERR
	dw .NOT_READY
	dw .NO_FILE
	dw .NO_PATH
	dw .INVALID_NAME
	dw .DENIED
	dw .EXIST
	dw .INVALID_OBJECT
	dw .WRITE_PROTECTED
	dw .INVALID_DRIVE
	dw .NOT_ENABLED
	dw .NO_FILESYSTEM
	dw .MKFS_ABORTED
	dw .TIMEOUT
	dw .LOCKED
	dw .NOT_ENOUGH_CORE
	dw .TOO_MANY_OPEN_FILES
.OK				db "Succeeded",0
.DISK_ERR		db "A hard error occured in the low level disk I/O layer",0
.INT_ERR		db "Assertion failed",0
.NOT_READY		db "The physical drive cannot work",0
.NO_FILE		db "Could not find the file",0
.NO_PATH		db "Could not find the path",0
.INVALID_NAME	db "The path name format is invalid",0
.DENIED			db "Acces denied due to prohibited access or directory full",0
.EXIST			db "Acces denied due to prohibited access",0
.INVALID_OBJECT		db "The file/directory object is invalid",0
.WRITE_PROTECTED	db "The physical drive is write protected",0
.INVALID_DRIVE		db "The logical drive number is invalid",0
.NOT_ENABLED		db "The volume has no work area",0
.NO_FILESYSTEM		db "There is no valid FAT volume on the physical drive",0
.MKFS_ABORTED		db "The f_mkfs() aborted due to any parameter error",0
.TIMEOUT		db "Could not get a grant to access the volume within defined period",0
.LOCKED			db "The operation is rejected according to the file shareing policy",0
.NOT_ENOUGH_CORE	db "LFN working buffer could not be allocated",0
.TOO_MANY_OPEN_FILES db "Number of open files > _FS_SHARE",0
