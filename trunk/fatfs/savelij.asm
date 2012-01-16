MODULE SAVELIJ  ;15950
  PUBLIC disk_initialize
  PUBLIC disk_read
  PUBLIC disk_write
  PUBLIC ds_m
  PUBLIC FatFs
  PUBLIC Fsid
  PUBLIC CurrVol
  PUBLIC dio_par
  EXTERN f_mount
  EXTERN f_open
  EXTERN f_mkdir
  
  RSEG NEAR_Z

  RSEG CODE

dio_par:
        DEFB 1        ;DRV
        DEFW 0x4000   ;*BUF
        DEFW 0        ;*sec
        DEFB 32       ;NUM
CurrVol:
        DEFB 0
FatFs:
        DEFW 0,0
Fsid:
        DEFW 0
ds_m:
        DEFB 1,1,1,1
        
disk_initialize:
        ld d,0
        ld hl,ds_m
        add hl,de
        ld a,(hl)
        or a
        ret z
        ld h,b
        ld l,c
	LD A,e
	or a
	jr nz,di_l1
	call zsd_init
	ld (ds_m),a
	ret
di_l1	dec a
	jr nz,di_l2
	ld a,0xe0
	call nemo_init
	ld (ds_m+1),a
	ret
di_l2	dec a
	jr nz,di_l3
	ld a,0xf0
	call nemo_init
	ld (ds_m+2),a
	ret
di_l3	dec a
	jr nz,di_l4
	call GSDINIT
	ld (ds_m+3),a
	ret
di_l4	ld a,1
	ret

	
get_params
        ld hl,(dio_par+3)
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ld c,(hl)
        inc hl
        ld b,(hl)
        ld hl,(dio_par+1)
        ld a,(dio_par+5)
        ex af,af
        ld a,(dio_par)
        or a
	ret
	
disk_read:
        call get_params
	jp z,zsd_read
	dec a
	jr nz,disk_read_nomaster
	ld a,$e0
	jp nemo_read
disk_read_nomaster
	dec a
	jr nz,disk_read_nonemo
	ld a,$f0
	jp nemo_read
disk_read_nonemo
	dec a
	jp z,SDRDMUL
	ld a,1
	ret
	
disk_write:
        call get_params
	jp z,zsd_write
	dec a
	jr nz,disk_write_nomaster
	ld a,$e0
	jp nemo_write
disk_write_nomaster
	dec a
	jr nz,disk_write_nonemo
	ld a,$f0
	jp nemo_write
disk_write_nonemo
	dec a
	jp z,SDWRMUL
	ld a,1
	ret
;�室�� ��ࠬ���� ��騥:
;HL-���� ����㧪� � ������
;BCDE-32-� ���� ����� ᥪ��
;A-������⢮ ������ (����=512 ����)
;⮫쪮 ��� ��������筮� �����/�⥭��

P_1F7	EQU 0xF0			;������� ���������/������� ������
P_1F6	EQU 0xD0			;CHS-����� ������ � ����/LBA ����� 24-27
P_1F5	EQU 0xB0			;CHS-������� 8-15/LBA ����� 16-23
P_1F4	EQU 0x90			;CHS-������� 0-7/LBA ����� 8-15
P_1F3	EQU 0x70			;CHS-����� �������/LBA ����� 0-7
P_1F2	EQU 0x50			;������� ��������
P_1F1	EQU 0x30			;���� ������/�������
P_1F0	EQU 0x10			;���� ������
P_3F6	EQU 0xC8			;������� ���������/����������
P_HI	EQU 0x11			;������� 8 ���
PRT_RW	EQU P_1F0*256+P_HI	;����� ������/������ ����� ������

;�� ������:
;H-��� MASTER 0-HDD, 1-CDROM, 0xFF-NONE
;L-��� SLAVE  0-HDD, 1-CDROM, 0xFF-NONE
nemo_init:
		PUSH HL
		CALL ID_DEV
		POP HL
		AND A
		CALL Z,INIT_91
nemo_off:
		RET

INIT_91:
		PUSH HL
		ld d,h
		ld e,l
		LD hl,49*2+1
		add hl,de
		LD A,(HL)
		AND 2
		JR Z,INI_912
		LD BC,0xFF00+P_1F2
		LD hl,0x0C
		add hl,de
		LD A,(HL)
		OUT (C),A
		LD hl,6
		LD C,P_1F6
		add hl,de
		LD A,(HL)
		DEC A
		OUT (C),A
		LD C,P_1F7
		LD A,0x91
		OUT (C),A
		LD DE,0x1000
INI_911:
		DEC DE
		LD A,D
		OR E
		JR Z,INI_912
		IN A,(C)
		AND 0x80
		JR NZ,INI_911
		POP HL
		RET

INI_912:
		LD A,0xFF
		POP HL
		RET

;READ "A" SECTORS HDD
nemo_read:        
	        add a,b
	        ld b,a
		CALL SETHREG
		EX AF,AF
		LD C,0xf0
		LD A,0x20
		OUT (C),A
		LD C,0xf0
HDDRD1:
		IN A,(C)
		AND 0x88
		CP 8
		JR NZ,HDDRD1
		EX AF,AF
HDDRD2:
		EX AF,AF
		CALL READSEC
		LD C,0xf0
HDDRD3:	
		IN A,(C)
		AND 0x80
		JR NZ,HDDRD3
		EX AF,AF
		DEC A
		JR NZ,HDDRD2
		JR EXITNHD

;WRITE "A" SECTORS HDD
nemo_write:
	        add a,b
	        ld b,a
		CALL SETHREG
		EX AF,AF
		LD C,P_1F7
		LD A,0x30
		OUT (C),A
		LD C,P_1F7
HDDWR1:	
		IN A,(C)
		AND 0x88
		CP 8
		JR NZ,HDDWR1
		EX AF,AF
HDDWR2:	
                
		EX AF,AF
		CALL WRITSEC
		inc h
		inc h
		LD C,P_1F7
HDDWR3:	
		IN A,(C)
		AND 0x80
		JR NZ,HDDWR3
		EX AF,AF
		DEC A
		JR NZ,HDDWR2
EXITNHD:
		ld a,0
		RET

;READ SECTOR (512 BYTES)
READSEC:
		LD A,0x40
		LD C,P_1F0	;HI
READSC1:
		IN E,(C)
		INC C
		IN D,(C)
		DEC C
		LD (HL),E
		INC HL
		LD (HL),D
		INC HL
		IN E,(C)
		INC C
		IN D,(C)
		DEC C
		LD (HL),E
		INC HL
		LD (HL),D
		INC HL
		IN E,(C)
		INC C
		IN D,(C)
		DEC C
		LD (HL),E
		INC HL
		LD (HL),D
		INC HL
		IN E,(C)
		INC C
		IN D,(C)
		DEC C
		LD (HL),E
		INC HL
		LD (HL),D
		INC HL
		DEC A
		JR NZ,READSC1
		RET

;SAVE SECTOR (512 BYTES)
WRITSEC:
		PUSH HL
		LD (WR_SEC_SP+1),SP
		LD SP,HL
		LD A,0x40
		LD HL,PRT_RW
WR_SEC1:
		POP DE
		LD C,L
		OUT (C),D
		LD C,H
		OUT (C),E
		POP DE
		LD C,L
		OUT (C),D
		LD C,H
		OUT (C),E
		POP DE
		LD C,L
		OUT (C),D
		LD C,H
		OUT (C),E
		POP DE
		LD C,L
		OUT (C),D
		LD C,H
		OUT (C),E
		DEC A
		JR NZ,WR_SEC1
WR_SEC_SP	LD SP,0
		POP HL
		RET

;SET HDD PORTS
SETHREG:
		PUSH DE
		LD D,B
		LD E,C
		LD BC,0xffd0
		OUT (C),D
		LD C,0xf0
SETHRE1:
		IN A,(C)
		AND 0x80
		JR NZ,SETHRE1
		LD C,0xb0
		OUT (C),E
		POP DE
		LD C,0x90
		OUT (C),D
		LD C,0x70
		OUT (C),E
		LD C,0x50
		EX AF,AF
		OUT (C),A
		RET

;HL-����� ������ ������� �������������
;A=E0-��� MASTER, A=F0-��� SLAVE
ID_DEV:
		LD BC,0xFF00+P_1F6
		OUT (C),A
		LD C,P_1F7
		LD D,26
ID_DEV3:
                ei
		HALT
		di
		DEC D
		JR Z,NO_DEV
		IN A,(C)
		BIT 7,A
		JR NZ,ID_DEV3
		AND A
		JR Z,NO_DEV
		INC A
		JR Z,NO_DEV
		XOR A
		LD C,P_1F5
		OUT (C),A
		LD C,P_1F4
		OUT (C),A
		LD A,0xEC
		LD C,P_1F7
		OUT (C),A
		LD C,P_1F7
ID_DEV1:
		IN A,(C)
		AND A
		JR Z,NO_DEV
		INC A
		JR Z,NO_DEV
		DEC A
		RRCA
		JR C,ID_DEV2
		RLCA
		AND 0x88
		CP 8
		JR NZ,ID_DEV1
ID_DEV2:
		LD C,P_1F4
		IN E,(C)
		LD C,P_1F5
		IN D,(C)
		LD A,D
		OR E
		JP Z,READSEC
		LD HL,0xEB14
		SBC HL,DE
		LD A,1
		RET Z
NO_DEV:
		LD A,0xFF
		RET


;�ࠩ��� SD �����
;LAST UPDATE 14.04.2009 savelij
;�室�� ��ࠬ���� ��騥:
;HL-���� ����㧪� � ������
;BCDE-32-� ���� ����� ᥪ��
;A-������⢮ ������ (����=512 ����) - ⮫쪮 ��� ��������筮� �����/�⥭��
;�訡�� �뤠����� �� ��室�:
;A=0 - ���樠������ ��諠 �ᯥ譮
;A=1 - ���� �� ������� ��� �� �⢥⨫�
;A=2 - ���� ���饭� �� �����
;A=3 - ����⪠ ����� � ᥪ�� 0 �����
P_DATA    EQU 0x0057    ;���� ������
P_CONF    EQU 0x8057    ;���� ���䨣��樨
CMD_12    EQU 0x4C    ;STOP_TRANSMISSION
CMD_17    EQU 0x51    ;READ_SINGLE_BLOCK
CMD_18    EQU 0x52    ;READ_MULTIPLE_BLOCK
CMD_24    EQU 0x58    ;WRITE_BLOCK
CMD_25    EQU 0x59    ;WRITE_MULTIPLE_BLOCK
CMD_55    EQU 0x77    ;APP_CMD
CMD_58    EQU 0x7A    ;READ_OCR
CMD_59    EQU 0x7B    ;CRC_ON_OFF
ACMD_41   EQU 0x69   ;SD_SEND_OP_COND

zsd_init
    CALL CS_HIGH    ;����砥� ��⠭�� ����� �� ��⮬ �롮�
    LD BC,P_DATA
    LD DE,0x20FF    ;��� �롮� ����� � <1>
SD_INITloop
    OUT (C),E    ;�����뢠�� � ���� ����� �����祪
    DEC D    ;������⢮ �����祪 ��᪮�쪮 �����
    JR NZ,SD_INITloop    ;祬 ����
    XOR A    ;����᪠�� ���稪 �� 256
    EX AF,AF    ;��� �������� ���樠����樨 �����
ZAW001    
    LD HL,CMD00    ;���� ������� ���
    CALL OUTCOM    ;�⮩ �������� ����窠 ��ॢ������ � ०�� SPI
    CALL IN_OOUT    ;�⠥� �⢥� �����
    EX AF,AF
    DEC A
    JR Z,ZAW003    ;�᫨ ���� 256 ࠧ �� �⢥⨫�, � ����� ���
    EX AF,AF
    DEC A
    JR NZ,ZAW001    ;�⢥� ����� <1>, ��ॢ�� � SPI ��襫 �ᯥ譮
    LD HL,CMD08    ;����� �� �����ন����� ����殮���
    CALL OUTCOM    ;������� �����ন������ ��稭�� � ᯥ�䨪�樨
    CALL IN_OOUT    ;���ᨨ 2.0 � ⮫쪮 SDHC, ���� � ���� SD ���⠬�
    IN H,(C)    ;� A=��� �⢥� �����
    NOP    ;���뢠�� 4 ���� �������� �⢥�
    IN H,(C)    ;�� �� �ᯮ��㥬
    NOP
    IN H,(C)
    NOP
    IN H,(C)
    LD HL,0    ;HL=��㬥�� ��� ������� ���樠����樨
    BIT 2,A    ;�᫨ ��� 2 ��⠭�����, � ���� �⠭���⭠�
    JR NZ,ZAW006    ;�⠭���⭠� ���� �뤠�� <�訡�� �������>
    LD H,0x40    ;�᫨ �訡�� �� �뫮, � ���� SDHC, ���� ��� ���� SD
ZAW006    
    LD A,CMD_55    ;����᪠�� ����� ����७��� ���樠����樨
    CALL OUT_COM    ;��� ���� MMC ����� ������ ���� ��㣠� �������
    CALL IN_OOUT    ;ᮮ⢥��⢥��� ����稥 � ᫮� MMC-�����
    LD A,ACMD_41    ;�맮��� ����ᠭ�� �ࠩ���, �� �ਬ������
    OUT (C),A    ;��饩 ������� ����᪠ ���樠����樨 � �⪠�����
    NOP    ;��� 6 ��⠭����� ��� ���樠����樨 SDHC �����
    OUT (C),H    ;��� �⠭���⭮� ��襭
    NOP
    OUT (C),L
    NOP
    OUT (C),L
    NOP
    OUT (C),L
    LD A,0xFF
    OUT (C),A
    CALL IN_OOUT    ;���� ��ॢ��� ����� � ०�� ��⮢����
    AND A    ;�६� �������� �ਬ�୮ 1 ᥪ㭤�
    JR NZ,ZAW006
ZAW004    LD A,CMD_59    ;�ਭ㤨⥫쭮 �⪫�砥� CRC16
    CALL OUT_COM
    CALL IN_OOUT
    AND A
    JR NZ,ZAW004
ZAW005    LD HL,CMD16    ;�ਭ㤨⥫쭮 ������ ࠧ��� ����� 512 ����
    CALL OUTCOM
    CALL IN_OOUT
    AND A
    JR NZ,ZAW005
;����祭�� ��⠭�� ����� �� ��⮬ ᨣ���� �롮� �����
CS_HIGH    
    PUSH AF
    LD A,3
    ld bc,P_CONF
    OUT (c),A    ;����砥� ��⠭��, ᭨���� �롮� �����
    XOR A
    dec b	; P_DATA
    OUT (c),A    ;����塞 ���� ������
    POP AF    ;���㫥��� ���� ����� �� ������, ���� ��᫥����
    ld a,0
    RET    ;����ᠭ�� ��� �ᥣ�� 1, � �� ��� �१ �뢮�
        ;������ ����� ����殮��� �������� �� �뢮� ��⠭��
        ;����� � ᢥ⮤��� �� ��⠭�� ���ᢥ稢�����
;������ �� �� �⢥� ����� � ����� �訡�� 1
ZAW003    
    CALL zsd_off
    ld a,3
    RET
zsd_off    ;patch
    XOR A
	ld bc,P_CONF
    OUT (c),A    ;�몫�祭�� ��⠭�� �����
	dec b		;P_DATA
    OUT (c),A    ;���㫥��� ���� ������
    RET
;�롨ࠥ� ����� ᨣ����� 0
CS__LOW    ;patch
    PUSH AF
    LD A,1
	ld bc,P_CONF
    OUT (c),A
    POP AF
    RET
;������ � ����� ������� � �������塞� ��ࠬ��஬ �� �����
;���� ������� � <HL>
OUTCOM    ;patch
    CALL CS__LOW
    LD BC,0x600+P_DATA
    OTIR    ;��।��� 6 ���� ������� �� �����
    RET
;������ � ����� ������� � �㫥�묨 ��㬥�⠬�
;�-��� �������, ��㬥�� ������� ࠢ�� 0
OUT_COM    ;patch
    CALL CS__LOW
    LD BC,P_DATA
    OUT (C),A
    XOR A
    OUT (C),A
    NOP
    OUT (C),A
    NOP
    OUT (C),A
    NOP
    OUT (C),A
    DEC A
    OUT (C),A    ;��襬 ���⮩ CRC7 � �⮯��� ���
    RET
;������ ������� �⥭��/����� � ����஬ ᥪ�� � BCDE ��� ���� �⠭���⭮�� ࠧ���
;�� �����塞�� ࠧ��� ᥪ�� ����� ᥪ�� �㦭� 㬭����� �� ��� ࠧ���, ��� ���� 
;SDHC, ���� � ���� ࠧ��� ᥪ�� �� �ॡ�� 㬭������
SECM200    PUSH HL  ;patch
    PUSH DE
    PUSH BC
    PUSH AF
    PUSH BC
    LD A,CMD_58
    LD BC,P_DATA
    CALL OUT_COM
    CALL IN_OOUT
    IN A,(C)
    NOP
    IN H,(C)
    NOP
    IN H,(C)
    NOP
    IN H,(C)
    BIT 6,A    ;�஢��塞 30 ��� ॣ���� OCR (6 ��� � <�>)        
    POP HL    ;�� ��⠭�������� ��� 㬭������ ����� ᥪ��
    JR NZ,SECN200    ;�� �ॡ����
    EX DE,HL    ;�� ��襭��� ��� ᮮ⢥��⢥���
    ADD HL,HL    ;㬭����� ����� ᥪ�� �� 512 (0x200)
    EX DE,HL
    ADC HL,HL
    LD H,L
    LD L,D
    LD D,E
    LD E,0
SECN200    
    POP AF    ;����⮢����� ����� ᥪ�� ��室���� � <HLDE>
    OUT (C),A    ;��襬 ������� �� <�> �� SD �����
    NOP    ;�����뢠�� 4 ���� ��㬥��
    OUT (C),H    ;��襬 ����� ᥪ�� �� ���襣�
    NOP
    OUT (C),L
    NOP
    OUT (C),D
    NOP
    OUT (C),E    ;�� ����襣� ����
    LD A,0xFF
    OUT (C),A    ;��襬 ���⮩ CRC7 � �⮯��� ���
    POP BC
    POP DE
    POP HL
    RET
;�⥭�� �⢥� ����� �� 32 ࠧ, �᫨ �⢥� �� 0xFF - ���������� ��室
IN_OOUT    ;patch
    push de
    LD DE,0x20FF
	ld bc,P_DATA
IN_WAIT    IN A,(c)
    CP E
    JR NZ,IN_EXIT
IN_NEXT    DEC D
    JR NZ,IN_WAIT
IN_EXIT    POP DE
    RET
CMD00    DEFB  0x40,0x00,0x00,0x00,0x00,0x95 ;GO_IDLE_STATE
    ;������� ��� � ��ॢ��� ����� � SPI ०�� ��᫥ ����祭�� ��⠭��
CMD08    DEFB  0x48,0x00,0x00,0x01,0xAA,0x87 ;SEND_IF_COND
    ;����� �����ন������ ����殮���
CMD16    DEFB 0x50,0x00,0x00,0x02,0x00,0xFF ;SET_BLOCKEN
    ;������� ��������� ࠧ��� �����
;�⠥� ���� ᥪ�� �� ����� � ������, ���� �⥭�� � <HL>
RD_SECT    PUSH BC
    LD BC,P_DATA+0x7F00
    INIR
    LD B,0x7F
    INIR
    LD B,0x7F
    INIR
    LD B,0x7F
    INIR
    LD B,0x04
    INIR
    NOP
    IN A,(C)
    NOP
    IN A,(C)
    POP BC
    RET
;�����뢠�� ���� ᥪ�� �� ����� � �����, ���� ����� � <HL>
WR_SECT    PUSH BC
    LD BC,P_DATA
    OUT (C),A
    LD B,0x80
    OTIR
    LD B,0x80
    OTIR
    LD B,0x80
    OTIR
    LD B,0x80
    OTIR
    LD A,0xFF
    OUT (C),A
    NOP
    OUT (C),A
    POP BC
    RET
;�����ᥪ�୮� �⥭��
zsd_read ld a,1
    out (0xbf),a
    LD A,CMD_18
    CALL SECM200    ;���� ������� �����ᥪ�୮�� �⥭��
    EX AF,AF
RDMULT1    EX AF,AF
RDMULT2
    CALL IN_OOUT
    CP 0xFE
    JR NZ,RDMULT2    ;���� ��થ� ��⮢���� 0xFE ��� ��砫� �⥭��
    CALL RD_SECT    ;�⠥� ᥪ��
    EX AF,AF
    DEC A
    JR NZ,RDMULT1    ;�த������ ���� �� ���㫨��� ���稪
    LD A,CMD_12    ;�� ����砭�� �⥭�� ���� ������� ���� <����>
    CALL OUT_COM    ;������� �����⥭�� �� ����� ���稪� �
RDMULT3
    CALL IN_OOUT    ;������ ��⠭���������� ����� �������� 12
    INC A
    JR NZ,RDMULT3    ;���� �᢮�������� �����
    JP CS_HIGH    ;᭨���� �롮� � ����� � ��室�� � ����� 0

;�����ᥪ�ୠ� ������
zsd_write ld a,1
    out (0xbf),a
    LD A,CMD_25 ;���� ������� ����ᥪ�୮� �����
    CALL SECM200
WRMULTI2
    CALL IN_OOUT
    INC A
    JR NZ,WRMULTI2 ;���� �᢮�������� �����
    EX AF,AF
WRMULT1 EX AF,AF
    LD A,0xFC ;��襬 ���⮢� ��થ�, ᠬ ���� � ���⮥ CRC16
    CALL WR_SECT
WRMULTI3
    CALL IN_OOUT
    INC A
    JR NZ,WRMULTI3 ;���� �᢮�������� �����
    EX AF,AF
    DEC A
    JR NZ,WRMULT1 ;�த������ ���� ���稪 �� ���㫨���
    LD C,P_DATA
    LD A,0xFD
    OUT (C),A ;���� ������� ��⠭���� �����
WRMULTI4
    CALL IN_OOUT
    INC A
    JR NZ,WRMULTI4 ;���� �᢮�������� �����
    JP CS_HIGH ;᭨���� �롮� ����� � ��室�� � ����� 0
    
    
;------------------------------------------------------
;---------------------------=NeoGS=--------------------
;------------------------------------------------------



GSCOM		EQU 0XBB	; write-only, command for NGS
GSDAT		EQU 0XB3	; read-write
GSCTR		EQU 0X33	; write-only, control register for NGS:
;����� ����������� �������� �� NeoGS
SETUPSD		EQU 0x5B00

;NGSSDT		DEFW GSDINIT		;���� SD �����
;		DEFW GSDOFF		;���������� SD �����
;		DEFW SDRDSIN		;������ 1 ������
;		DEFW SDRDMUL		;������ "A" ��������
;		DEFW SDWRSIN		;������ 1 ������
;		DEFW SDWRMUL		;������ "A" ��������

;������ "A" ��������
SDWRMUL		LD A,5
SDWRSN3		CALL COMM2SD
		EX AF,AF
		PUSH DE
		PUSH BC
		LD BC,GSDAT
SDWRSN1		EX AF,AF
		OUT (GSCOM),A
		CALL WC_
		LD DE,0x0200
SDWRSN2		OUTI
		CALL WD_
		DEC DE
		LD A,D
		OR E
		JR NZ,SDWRSN2
		EX AF,AF
		DEC A
		JR NZ,SDWRSN1
		CALL WN_
		IN A,(C)
		CP 0x77
		JR NZ,$-4
		POP BC
		POP DE
		XOR A
		RET

;������ "A" ��������
SDRDMUL		LD A,3
SDRDSN3		CALL COMM2SD
		EX AF,AF
		PUSH DE
		PUSH BC
		LD BC,GSDAT
SDRDSN1		EX AF,AF
		OUT (GSCOM),A
		CALL WC_
		LD DE,0x0200
SDRDSN2		CALL WN_
		INI
		DEC DE
		LD A,D
		OR E
		JR NZ,SDRDSN2
		EX AF,AF
		DEC A
		JR NZ,SDRDSN1
		CALL WN_
		IN A,(C)
		CP 0x77
		JR NZ,$-4
		POP BC
		POP DE
		XOR A
		RET

;���������� ������ ��������
GSDOFF		LD A,1
		JR GSDINIT+1

;������������� ��������
GSDINIT		CALL INSTSDD
                OR A
                RET NZ
                XOR A
		CALL COMM2SD
		CALL WN_
		IN A,(GSDAT)
		CP 0x77
		JR NZ,SD_NO
		XOR A
		RET

SD_NO		LD A,1
		RET

;���������� ������/���������� � ������� �� NeoGS
COMM2SD		OUT (GSDAT),A			;���� ������� ��������
	        LD A,0x1E
	        OUT (GSCOM),A
	        CALL WC_			;���� ������� ��������
		LD A,B
		OUT (GSDAT),A
		CALL WD_			;���� ���� 31-24 ����������
		LD A,C
		OUT (GSDAT),A
		CALL WD_			;���� ���� 23-16 ����������
		LD A,D
		OUT (GSDAT),A
		CALL WD_			;���� ���� 15-8 ����������
		LD A,E
		OUT (GSDAT),A
		CALL WD_			;���� ���� 7-0 ����������
		EX AF,AF
		OUT (GSDAT),A
		EX AF,AF
		DEFS 9
		RET				;���� ���-�� ��������

;�������� ����� NeoGS ���� �������
WD_		IN A,(GSCOM)
		RLA
		JR C,$-3
		RET

;�������� ����� NeoGS ���� ����
WN_		IN A,(GSCOM)
		RLA
		JR NC,$-3
		RET

;�������� ����� NeoGS ������� �������
WC_		IN A,(GSCOM)
		RRA
		JR C,$-3
		RET

;���������� �������� �� NeoGS
INSTSDD		LD A,0x80
		OUT (GSCTR),A
		EI
		HALT
		HALT
		DI
		LD A,0xF3
		LD B,0x30
		OUT (GSCOM),A
ISDD1		EI
		HALT
		DI
		DEC B
		JR Z,SD_NO
		IN A,(GSCOM)
		RRA
		JR C,ISDD1
		LD BC,GSDAT
		IN A,(C)
		LD DE,0x0300
		LD HL,SETUPSD
		OUT (C),E
		LD A,0x14
		OUT (GSCOM),A
		CALL WC_
		OUT (C),D
		CALL WD_
		OUT (C),L
		CALL WD_
		OUT (C),H
		CALL WD_
		LD HL,(0x0006)
ISDD3		OUTI
		CALL WD_
		DEC DE
		LD A,D
		OR E
		JR NZ,ISDD3
		LD HL,SETUPSD
		OUT (C),L
		LD A,0x13
		OUT (GSCOM),A
		CALL WC_
		OUT (C),H
		EI
		HALT
		HALT
		DI
		IN A,(GSDAT)
		CP 0x77
		JP NZ,SD_NO
		XOR A
		RET



ENDMOD
END


