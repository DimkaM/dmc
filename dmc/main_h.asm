; REG
; .DAT=0xF8EF	;80-bf
; .DLL=0xF8EF	;80-9f
; .DLM=0xF9EF	;a0-bf
; .LCR=0xFBEF	;a0-10100000
; .LSR=0xFDEF	;80-10000000
	; display $
; REGINI
	; LD BC,REG.LCR
	; LD A,%10000000
	; OUT (C),A
	; LD B,HIGH REG.DLL
	; LD A,12
	; OUT (C),A
	; INC B
	; XOR A
	; OUT (C),A
	; LD B,HIGH REG.LCR
	; LD A,3
	; OUT (C),A
	; RET
; send_ix
	; LD BC,REG.DAT
	; push ix:pop hl
	; OUT (C),h
	; nop
	; nop
	; nop
	; OUT (C),l
	; ld a,32
	; OUT (C),a
	; ret
	;display $

; VolToPart=0x4026
	MACRO MEM_SET _ADDR,_BYTE,_SIZE
	IF _BYTE
	LD A,_BYTE
	ELSE
	XOR A
	ENDIF
	ld hl,_ADDR:ld (hl),A:ld de,_ADDR+1
	LD BC,_SIZE-1:LDIR
	ENDM

	MACRO MEM_CPY _SRC,_DST,_SIZE
	ld hl,_SRC
	ld de,_DST
	LD BC,_SIZE:LDIR
	ENDM
	
	MACRO STR_CPY _SRC,_DST
	xor a
	ld hl,_SRC
	ld de,_DST
._STR_CPY_LOOP
	cp (hl):JR Z,._STR_CPY_END
	ldi
	jr ._STR_CPY_LOOP
._STR_CPY_END
	ENDM
	
	MACRO MEM_SCR
	call mem.setscr
	ENDM
	
	MACRO MEM_FAT
	call mem.setfat
	ENDM

	MACRO MEM_FBUF
	ld a,mem.fbuf
	ld bc,mem.b3
	out (c),a
	ENDM

	MACRO MEM_TBUF
	ld a,mem.tbuf
	ld bc,mem.b3
	out (c),a
	ENDM

	module mem
main_p=0x18^0xff
fat_p=0x19^0xff

txt_p=8^0xff
tbuf=0x17^0xff
fbuf=0x1a^0xff
lfno1=0xBF^0xff
rfno1=0x9F^0xff
b0=0x37f7
b1=0x77f7
b2=0xb7f7
b3=0xf7f7

state	;состояние памяти
.store	;сохраняем
	ld bc,0x05be
	in a,(c):ld (.p1+1),a
	inc b
	in a,(c):ld (.p2+1),a
	inc b
	in a,(c):ld (.p3+1),a
	ret
.rest	;восстанавливаем
	ld bc,b1
.p1	ld a,0
	out (c),a
	ld b,high b2
.p2	ld a,0
	out (c),a
	ld b,high b3
.p3	ld a,0
	out (c),a
	ret

setscr
	ld a,txt_p
	ld bc,b1
	out (c),a
	ret
	
setfat
	ld a,fat_p
	ld bc,b1
	out (c),a
	ret
	
	endmodule
; Эдесь лежат макросы FatFs.
; Все аргументы передаются через стек, в порядке их перечисления.
; Длинна аргумента кратна двум, то есть, если аргумент типа BYTE,
; то он занимает на стеке два байта.
; Если аргумент типа DWORD, то на стек сначала кладем старшие два байта, затем младшие.
; После выполнения функции все аргументы остаются на стеке
; , не забывайте снимать не нужные (за исключением f_voltopart).
; 
; При попадании в функцию на стеке должен быть адрес возврата, затем список переменных,
; в связи с этим в RST18 JP, а не CALL.
; 
; Строковая переменная должна заканчиватся 0x0 (нулём).
; Можно использовать как абсолютный, так 
; относительный путь:
; 	"file.txt"		A file in the current directory of the current drive
; 	"/file.txt"		A file in the root directory of the current drive
; 	""				The current directory of the current drive
; 	"/"				The root directory of the current drive
; 	"2:"			The current directory of the drive 2
; 	"2:/"			The root directory of the drive 2
; 	"2:file.txt"	A file in the current directory of the drive 2
; 	"../file.txt"	A file in the parent directory
; 	"."				This directory
; 	".."			Parent directory of the current directory
; 	"dir1/.."		The current directory
; 	"/.."			The root directory (sticks the top level)

;
; Возвращаемый параметр лежит в HL, если DWORD то DEHL.
; 
; FatFs юзает RST0x18 для доступа к устройствам (0-3 функции).
; Левые порты должны быть скрыты (MEM_HIDE)
; 31 и 30 страницы памяти должны быть в 0 и 1 банках.
; Стек должен быть в текущем адресном пространстве (юзается очень сильно байт 100-200 
; свободно может заюзать). И переменные(если на них есть указатель в 
; аргументах, а также глобальные переменные типа FATFS), тоже должны быть доступны.

;------------------------СТРУКТУРЫ--------------------------------------

FA_READ=0x01			;Specifies read access to the object. Data can be read from the file.
					;Combine with FA_WRITE for read-write access.
FA_WRITE=0x02			;Specifies write access to the object. Data can be written to the file.
					;Combine with FA_READ for read-write access.
FA_OPEN_EXISTING=0x00	;Opens the file. The function fails if the file is not existing. (Default)
FA_OPEN_ALWAYS=0x10	;Opens the file if it is existing. If not, a new file is created.
					;To append data to the file, use f_lseek function after file open in this method.
FA_CREATE_NEW=0x04		;Creates a new file. The function fails with FR_EXIST if the file is existing.
FA_CREATE_ALWAYS=0x08	;Creates a new file. If the file is existing, it is truncated and overwritten.



/* File system object structure (FATFS) */

	STRUCT FATFS
fs_type		BYTE;		/* FAT sub-type (0:Not mounted) */
drv			BYTE 0;		/* Physical drive number */
part		BYTE 0;		/* Partition # (0-3) */
csize		BYTE;		/* Sectors per cluster (1,2,4...128) */
n_fats		BYTE;		/* Number of FAT copies (1,2) */
wflag		BYTE;		/* win[] dirty flag (1:must be written back) */
fsi_flag	BYTE;		/* fsinfo dirty flag (1:must be written back) */
id			WORD;		/* File system mount ID */
n_rootdir	WORD;		/* Number of root directory entries (FAT12/16) */
last_clust	DWORD;		/* Last allocated cluster */
free_clust	DWORD;		/* Number of free clusters */
fsi_sector	DWORD;		/* fsinfo sector (FAT32) */
cdir		DWORD;		/* Current directory start cluster (0:root) */
n_fatent	DWORD;		/* Number of FAT entries (= number of clusters + 2) */
fsize		DWORD;		/* Sectors per FAT */
fatbase		DWORD;		/* FAT start sector */
dirbase		DWORD;		/* Root directory start sector (FAT32:Cluster#) */
database	DWORD;		/* Data start sector */
winsect		DWORD;		/* Current sector appearing in the win[] */
win			BLOCK 512;	/* Disk access window for Directory, FAT (and Data on tiny cfg) */
	ENDS
	
;/* Directory object structure (DIR) */
	STRUCT DIR
FS		WORD	;/* POINTER TO THE OWNER FILE SYSTEM OBJECT */
ID		WORD	;/* OWNER FILE SYSTEM MOUNT ID */
INDEX	WORD	;/* CURRENT READ/WRITE INDEX NUMBER */
SCLUST	DWORD	;/* TABLE START CLUSTER (0:ROOT DIR) */
CLUST	DWORD	;/* CURRENT CLUSTER */
SECT	DWORD	;/* CURRENT SECTOR */
DIR		WORD	;/* POINTER TO THE CURRENT SFN ENTRY IN THE WIN[] */
FN		WORD	;/* POINTER TO THE SFN (IN/OUT) {FILE[8],EXT[3],STATUS[1]} */
	ENDS
	
/* FILE STATUS STRUCTURE (FILINFO) */
	STRUCT FILINFO
FSIZE	DWORD		;/* FILE SIZE */
FDATE	WORD		;/* LAST MODIFIED DATE */
FTIME	WORD		;/* LAST MODIFIED TIME */
FATTRIB	BYTE		;/* ATTRIBUTE */
FNAME	BLOCK 16,0	;/* SHORT FILE NAME (8.3 FORMAT) */
MARK	byte		;marking
NEXT	WORD
NEXTP	BYTE
PREV	WORD
PREVP	BYTE
;RESERV	dw			
	ENDS
	
/* File object structure (FIL) */

	struct FIL
FS		WORD	;/* Pointer to the owner file system object */
ID		WORD	;/* Owner file system mount ID */
FLAG	BYTE	;/* File status flags */
PAD1	BYTE	;
FPTR	DWORD	;/* File read/write pointer (0 on file open) */
FSIZE	DWORD	;/* File size */
FCLUST	DWORD	;/* File start cluster (0 when fsize==0) */
CLUST	DWORD	;/* Current cluster */
DSECT	DWORD	;/* Current data sector */
DIR_SECT	DWORD	;/* Sector containing the directory entry */
DIR_PTR		WORD	;/* Ponter to the directory entry in the window */
BUF		BLOCK 512	;/* File data read/write buffer */
	ENDS
	
;---------------------------------МАКРОСЫ--------------------------------------
	
	
	MACRO F_VOLTOPART _VOL,_DRIVE,_PART	; Это типа виртуального предмонтирования, чтоли.
	; BYTE VOL - под каким номером монтировать (0-3).
	; BYTE DRIVE - физическое устройство(0-ZSD,1-NEMO master,2-NEMO slave).
	; BYTE PART - номер раздела(0-3).
	LD HL,_VOL		;Кидаем на стек аргументы
	PUSH HL 
	LD L,_DRIVE
	PUSH HL
	LD L,_PART
	PUSH HL
	LD A,4			; номер функции, кстати она исключение из правил, на стеке
	RST 0x18			; остаётся только VOL, а он как раз пригодится нам в F_MOUNT
	ENDM
	
	
;/*-----------------------------------------------------------------------*/
;/* Mount/Unmount a Logical Drive                                         */
;/*-----------------------------------------------------------------------*/
;
;FRESULT f_mount (
;	BYTE vol,		/* Logical drive number to be mounted/unmounted */
;	FATFS *fs		/* Pointer to new file system object (NULL for unmount)*/
;)
	MACRO F_MOUNT _VOL,_FS	;vol - уже лежит на стеке.
	ld e,_VOL
	LD bc,_FS
	LD A,0
	RST 0x18
	ENDM
	MACRO F_MNT
	LD A,0
	RST 0x18
	ENDM
	
	
; FRESULT f_open (
	; FIL *fp,			/* Pointer to the blank file object */
	; TCHAR *path,	/* Pointer to the file name */
	; BYTE mode			/* Access mode and file open mode flags */
; )
	MACRO F_OPEN _FP,_PATH,_MODE
	LD de,_FP
	LD bc,_PATH
	LD HL,_MODE
	PUSH HL
	LD A,1
	RST 0x18
	POP BC
	ENDM
	
	
;/*-----------------------------------------------------------------------*/
;/* Read File                                                             */
;/*-----------------------------------------------------------------------*/
;FRESULT f_read 
;	FIL *fp, 		/* Pointer to the file object */
;	void *buff,		/* Pointer to data buffer */
;	UINT btr,		/* Number of bytes to read */
;	UINT *br		/* Pointer to number of bytes read */
	MACRO F_READ
	LD A,2
	RST 0x18
	ENDM

;/*-----------------------------------------------------------------------*/
;/* Write File                                                            */
;/*-----------------------------------------------------------------------*/
;FRESULT f_write
;	FIL *fp,			/* Pointer to the file object */
;	const void *buff,	/* Pointer to the data to be written */
;	UINT btw,			/* Number of bytes to write */
;	UINT *bw			/* Pointer to number of bytes written */
	MACRO F_WRITE
	LD A,8
	RST 0x18
	ENDM

; /*-----------------------------------------------------------------------*/
; /* Close File                                                            */
; /*-----------------------------------------------------------------------*/
; FRESULT f_close (
	; FIL *fp		/* Pointer to the file object to be closed */)
	MACRO F_CLOSE _FP
	ld de,_FP
	LD A,4
	RST 0x18
	ENDM

	
	
; /*-----------------------------------------------------------------------*/
; /* Create a Directroy Object                                             */
; /*-----------------------------------------------------------------------*/
; FRESULT f_opendir
	; DIR *dj,			/* Pointer to directory object to create */
	; TCHAR *path	/* Pointer to the directory path */
	MACRO F_OPENDIR _DJ,_PATH
		LD de,_DJ
		LD bc,_PATH
		F_OPDIR
	ENDM
	MACRO F_OPDIR
	LD A,5
	RST 0x18
	ENDM

; /*-----------------------------------------------------------------------*/
; /* Read Directory Entry in Sequense                                      */
; /*-----------------------------------------------------------------------*/

; FRESULT f_readdir (
	; DIR *dj,			/* Pointer to the open directory object */
	; FILINFO *fno		/* Pointer to file information to return */
; )
	MACRO F_RDIR
	LD A,6
	RST 0x18
	ENDM


;/*-----------------------------------------------------------------------*/
;/* Delete a File or Directory                                            */
;/*-----------------------------------------------------------------------*/
;FRESULT f_unlink
;	const TCHAR *path		/* Pointer to the file or directory path */
	MACRO F_UNLINK
	LD A,12
	RST 0x18
	ENDM
;/*-----------------------------------------------------------------------*/
;/* Create a Directory                                                    */
;/*-----------------------------------------------------------------------*/
;FRESULT f_mkdir
;	const TCHAR *path		/* Pointer to the directory path */
	MACRO F_MKDIR
	LD A,13
	RST 0x18
	ENDM
;/*-----------------------------------------------------------------------*/
;/* Rename File/Directory                                                 */
;/*-----------------------------------------------------------------------*/
;FRESULT f_rename 
;	const TCHAR *path_old,	/* Pointer to the old name */
;	const TCHAR *path_new	/* Pointer to the new name */

	MACRO F_RENAME
	LD A,16
	RST 0x18
	ENDM

;/*-----------------------------------------------------------------------*/
;/* Current Drive/Directory Handlings                                     */
;/*-----------------------------------------------------------------------*/
;FRESULT f_chdrive
;	BYTE drv		/* Drive number */
	MACRO F_CHDR
	LD A,17
	RST 0x18
	ENDM
	MACRO F_CHDRIVE _DRV
	LD e,_DRV
	F_CHDR
	ENDM

; FRESULT f_chdir (
	; TCHAR *path	/* Pointer to the directory path */
; )
	MACRO F_CHDIR 
	LD A,18
	RST 0x18
	ENDM
	
	
	MACRO F_MUL _ARG
	LD DE,0
	PUSH DE
	LD de,_ARG
	push de
	LD A,19
	RST 0x18
	endm

; /* File function return code (FRESULT) */

; typedef enum {
	; FR_OK = 0,				/* (0) Succeeded */
	; FR_DISK_ERR,			/* (1) A hard error occured in the low level disk I/O layer */
	; FR_INT_ERR,				/* (2) Assertion failed */
	; FR_NOT_READY,			/* (3) The physical drive cannot work */
	; FR_NO_FILE,				/* (4) Could not find the file */
	; FR_NO_PATH,				/* (5) Could not find the path */
	; FR_INVALID_NAME,		/* (6) The path name format is invalid */
	; FR_DENIED,				/* (7) Acces denied due to prohibited access or directory full */
	; FR_EXIST,				/* (8) Acces denied due to prohibited access */
	; FR_INVALID_OBJECT,		/* (9) The file/directory object is invalid */
	; FR_WRITE_PROTECTED,		/* (10) The physical drive is write protected */
	; FR_INVALID_DRIVE,		/* (11) The logical drive number is invalid */
	; FR_NOT_ENABLED,			/* (12) The volume has no work area */
	; FR_NO_FILESYSTEM,		/* (13) There is no valid FAT volume on the physical drive */
	; FR_MKFS_ABORTED,		/* (14) The f_mkfs() aborted due to any parameter error */
	; FR_TIMEOUT,				/* (15) Could not get a grant to access the volume within defined period */
	; FR_LOCKED,				/* (16) The operation is rejected according to the file shareing policy */
	; FR_NOT_ENOUGH_CORE,		/* (17) LFN working buffer could not be allocated */
	; FR_TOO_MANY_OPEN_FILES	/* (18) Number of open files > _FS_SHARE */
; } FRESULT;
