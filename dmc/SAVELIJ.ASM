
DISK_INIT
	POP IX
	pop bc
	POP HL
	PUSH IX
	LD A,C
	and a
	jp z,zsd_init
	ld b,#e0
	cp 1
	jp z,nemo_init
	ld b,#f0
	cp 2
	jp z,nemo_init
	ld hl,1
	ret

DISK_OFF
	POP IX
	POP HL
	PUSH IX
	LD A,L
	and a
	jp zsd_off
	ld hl,0
	cp 1
	ret z
	ld l,1
	ret
RDMULTI
	pop ix
	pop hl
	ld a,l
	ex af,af
	pop hl
	ld a,l
	ex af,af
	pop de
	pop bc
	pop hl
	push ix
	and a
	jp z,zsd_read
	cp 1
	jr nz,disk_read_nomaster
	ld a,$e0
	add a,b
	ld b,a
	jp nemo_read
disk_read_nomaster
	cp 2
	jr nz,disk_read_nonemo
	ld a,$f0
	add a,b
	ld b,a
	jp nemo_read
disk_read_nonemo
	ld hl,1
	ret
WRMULTI
	pop ix
	pop hl
	ld a,l
	ex af,af
	pop hl
	ld a,l
	ex af,af
	pop de
	pop bc
	pop hl
	push ix
	and a
	jp z,zsd_write
	cp 1
	jr nz,disk_write_nomaster
	ld a,$e0
	add a,b
	ld b,a
	jp nemo_write
disk_write_nomaster
	cp 2
	jr nz,disk_write_nonemo
	ld a,$f0
	add a,b
	ld b,a
	jp nemo_write
disk_write_nonemo
	ld hl,1
	ret
;�室�� ��ࠬ���� ��騥:
;HL-���� ����㧪� � ������
;BCDE-32-� ���� ����� ᥪ��
;A-������⢮ ������ (����=512 ����)
;⮫쪮 ��� ��������筮� �����/�⥭��

P_1F7	EQU #F0			;������� ���������/������� ������
P_1F6	EQU #D0			;CHS-����� ������ � ����/LBA ����� 24-27
P_1F5	EQU #B0			;CHS-������� 8-15/LBA ����� 16-23
P_1F4	EQU #90			;CHS-������� 0-7/LBA ����� 8-15
P_1F3	EQU #70			;CHS-����� �������/LBA ����� 0-7
P_1F2	EQU #50			;������� ��������
P_1F1	EQU #30			;���� ������/�������
P_1F0	EQU #10			;���� ������
P_3F6	EQU #C8			;������� ���������/����������
P_HI	EQU #11			;������� 8 ���
PRT_RW	EQU P_1F0*256+P_HI	;����� ������/������ ����� ������

;�� ������:
;H-��� MASTER 0-HDD, 1-CDROM, #FF-NONE
;L-��� SLAVE  0-HDD, 1-CDROM, #FF-NONE
nemo_init:
		LD A,b
		PUSH HL
		CALL ID_DEV
		POP HL
		AND A
		CALL Z,INIT_91
		LD H,0
		LD L,A		
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
		LD BC,#FF00+P_1F2
		LD hl,#0C
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
		LD A,#91
		OUT (C),A
		LD DE,#1000
INI_911:
		DEC DE
		LD A,D
		OR E
		JR Z,INI_912
		IN A,(C)
		AND #80
		JR NZ,INI_911
		POP HL
		RET

INI_912:
		LD A,#FF
		POP HL
		RET

;READ "A" SECTORS HDD
nemo_read:
		PUSH BC
		PUSH DE
		CALL SETHREG
		EX AF,AF
		LD C,#f0
		LD A,#20
		OUT (C),A
		LD C,#f0
HDDRD1:
		IN A,(C)
		AND #88
		CP 8
		JR NZ,HDDRD1
		EX AF,AF
HDDRD2:
		EX AF,AF
		CALL READSEC
		LD C,#f0
HDDRD3:	
		IN A,(C)
		AND #80
		JR NZ,HDDRD3
		EX AF,AF
		DEC A
		JR NZ,HDDRD2
		JR EXITNHD

;WRITE "A" SECTORS HDD
nemo_write:
		PUSH BC
		PUSH DE
		CALL SETHREG
		EX AF,AF
		LD C,P_1F7
		LD A,#30
		OUT (C),A
		LD C,P_1F7
HDDWR1:	
		IN A,(C)
		AND #88
		CP 8
		JR NZ,HDDWR1
		EX AF,AF
HDDWR2:	
		EX AF,AF
		CALL WRITSEC
		LD C,P_1F7
HDDWR3:	
		IN A,(C)
		AND #80
		JR NZ,HDDWR3
		EX AF,AF
		DEC A
		JR NZ,HDDWR2
EXITNHD:
		POP DE
		POP BC
		LD A,B
		AND #0F
		LD B,A
		ld hl,0
		RET

;READ SECTOR (512 BYTES)
READSEC:
		LD A,#40
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
		EXX
		PUSH HL
		LD HL,0
		ADD HL,SP
		EXX
		LD SP,HL
		LD A,#40
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
		LD HL,0
		ADD HL,SP
		EXX
		LD SP,HL
		POP HL
		EXX
		RET

;SET HDD PORTS
SETHREG:
		PUSH DE
		LD D,B
		LD E,C
		LD BC,#ffd0
		OUT (C),D
		;EX AF,AF
		LD C,#f0
SETHRE1:
		IN A,(C)
		AND #80
		JR NZ,SETHRE1
		LD C,#b0
		OUT (C),E
		POP DE
		LD C,#90
		OUT (C),D
		LD C,#70
		OUT (C),E
		LD C,#50
		EX AF,AF
		OUT (C),A
		RET

;HL-����� ������ ������� �������������
;A=E0-��� MASTER, A=F0-��� SLAVE
ID_DEV:
		LD BC,#FF00+P_1F6
		OUT (C),A
		LD C,P_1F7
		LD D,26
ID_DEV3:
		EI
		HALT
		DI
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
		LD A,#EC
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
		AND #88
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
		LD HL,#EB14
		SBC HL,DE
		LD A,1
		RET Z
NO_DEV:
		LD A,#FF
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
P_DATA    EQU #57    ;���� ������
P_CONF    EQU #77    ;���� ���䨣��樨
CMD_12    EQU #4C    ;STOP_TRANSMISSION
CMD_17    EQU #51    ;READ_SINGLE_BLOCK
CMD_18    EQU #52    ;READ_MULTIPLE_BLOCK
CMD_24    EQU #58    ;WRITE_BLOCK
CMD_25    EQU #59    ;WRITE_MULTIPLE_BLOCK
CMD_55    EQU #77    ;APP_CMD
CMD_58    EQU #7A    ;READ_OCR
CMD_59    EQU #7B    ;CRC_ON_OFF
ACMD_41   EQU #69   ;SD_SEND_OP_COND

zsd_init
	CALL CS_HIGH    ;����砥� ��⠭�� ����� �� ��⮬ �롮�
    LD BC,P_DATA
    LD DE,#20FF    ;��� �롮� ����� � <1>
SD_INITloop
	OUT (C),E    ;�����뢠�� � ���� ����� �����祪
	DEC D    ;������⢮ �����祪 ��᪮�쪮 �����
    JR NZ,SD_INITloop    ;祬 ����
    XOR A    ;����᪠�� ���稪 �� 256
    EX AF,AF    ;��� �������� ���樠����樨 �����
ZAW001    LD HL,CMD00    ;���� ������� ���
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
    LD H,#40    ;�᫨ �訡�� �� �뫮, � ���� SDHC, ���� ��� ���� SD
ZAW006    LD A,CMD_55    ;����᪠�� ����� ����७��� ���樠����樨
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
    LD A,#FF
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
CS_HIGH    PUSH AF
    LD A,3
    OUT (P_CONF),A    ;����砥� ��⠭��, ᭨���� �롮� �����
    XOR A
    OUT (P_DATA),A    ;����塞 ���� ������
    POP AF    ;���㫥��� ���� ����� �� ������, ���� ��᫥����
	ld hl,0
    RET    ;����ᠭ�� ��� �ᥣ�� 1, � �� ��� �१ �뢮�
        ;������ ����� ����殮��� �������� �� �뢮� ��⠭��
        ;����� � ᢥ⮤��� �� ��⠭�� ���ᢥ稢�����
;������ �� �� �⢥� ����� � ����� �訡�� 1
ZAW003    CALL zsd_off
    ld hl,3
    RET
zsd_off    XOR A
    OUT (P_CONF),A    ;�몫�祭�� ��⠭�� �����
    OUT (P_DATA),A    ;���㫥��� ���� ������
	ld hl,0
    RET
;�롨ࠥ� ����� ᨣ����� 0
CS__LOW    PUSH AF
    LD A,1
    OUT (P_CONF),A
    POP AF
    RET
;������ � ����� ������� � �������塞� ��ࠬ��஬ �� �����
;���� ������� � <HL>
OUTCOM    CALL CS__LOW
    PUSH BC
    LD BC,#600+P_DATA
    OTIR    ;��।��� 6 ���� ������� �� �����
    POP BC
    RET
;������ � ����� ������� � �㫥�묨 ��㬥�⠬�
;�-��� �������, ��㬥�� ������� ࠢ�� 0
OUT_COM    PUSH BC
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
    POP BC
    RET
;������ ������� �⥭��/����� � ����஬ ᥪ�� � BCDE ��� ���� �⠭���⭮�� ࠧ���
;�� �����塞�� ࠧ��� ᥪ�� ����� ᥪ�� �㦭� 㬭����� �� ��� ࠧ���, ��� ���� 
;SDHC, ���� � ���� ࠧ��� ᥪ�� �� �ॡ�� 㬭������
SECM200    PUSH HL
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
    ADD HL,HL    ;㬭����� ����� ᥪ�� �� 512 (#200)
    EX DE,HL
    ADC HL,HL
    LD H,L
    LD L,D
    LD D,E
    LD E,0
SECN200    POP AF    ;����⮢����� ����� ᥪ�� ��室���� � <HLDE>
    OUT (C),A    ;��襬 ������� �� <�> �� SD �����
    NOP    ;�����뢠�� 4 ���� ��㬥��
    OUT (C),H    ;��襬 ����� ᥪ�� �� ���襣�
    NOP
    OUT (C),L
    NOP
    OUT (C),D
    NOP
    OUT (C),E    ;�� ����襣� ����
    LD A,#FF
    OUT (C),A    ;��襬 ���⮩ CRC7 � �⮯��� ���
    POP BC
    POP DE
    POP HL
    RET
;�⥭�� �⢥� ����� �� 32 ࠧ, �᫨ �⢥� �� #FF - ���������� ��室
IN_OOUT    PUSH DE
    LD DE,#20FF
IN_WAIT    IN A,(P_DATA)
    CP E
    JR NZ,IN_EXIT
IN_NEXT    DEC D
    JR NZ,IN_WAIT
IN_EXIT    POP DE
    RET
CMD00    DEFB  #40,#00,#00,#00,#00,#95 ;GO_IDLE_STATE
    ;������� ��� � ��ॢ��� ����� � SPI ०�� ��᫥ ����祭�� ��⠭��
CMD08    DEFB  #48,#00,#00,#01,#AA,#87 ;SEND_IF_COND
    ;����� �����ন������ ����殮���
CMD16    DEFB #50,#00,#00,#02,#00,#FF ;SET_BLOCKEN
    ;������� ��������� ࠧ��� �����
;�⠥� ���� ᥪ�� �� ����� � ������, ���� �⥭�� � <HL>
RD_SECT    PUSH BC
    LD BC,P_DATA
    INIR
    NOP
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
    NOP
    OTIR
    NOP
    OTIR
    LD A,#FF
    OUT (C),A
    NOP
    OUT (C),A
    POP BC
    RET
;�����ᥪ�୮� �⥭��
zsd_read
   ;EX AF,AF    ;���祬 ���稪 ᥪ�஢
    LD A,CMD_18
    CALL SECM200    ;���� ������� �����ᥪ�୮�� �⥭��
    EX AF,AF
RDMULT1    EX AF,AF
RDMULT2
    CALL IN_OOUT
    CP #FE
    JR NZ,RDMULT2    ;���� ��થ� ��⮢���� #FE ��� ��砫� �⥭��
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
zsd_write
    ;EX AF,AF    ;���祬 ���稪 ᥪ�஢
	LD A,CMD_25 ;���� ������� ����ᥪ�୮� �����
    CALL SECM200
WRMULTI2
    CALL IN_OOUT
    INC A
    JR NZ,WRMULTI2 ;���� �᢮�������� �����
    EX AF,AF
WRMULT1 EX AF,AF
    LD A,#FC ;��襬 ���⮢� ��થ�, ᠬ ���� � ���⮥ CRC16
    CALL WR_SECT
WRMULTI3
    CALL IN_OOUT
    INC A
    JR NZ,WRMULTI3 ;���� �᢮�������� �����
    EX AF,AF
    DEC A
    JR NZ,WRMULT1 ;�த������ ���� ���稪 �� ���㫨���
    LD C,P_DATA
    LD A,#FD
    OUT (C),A ;���� ������� ��⠭���� �����
WRMULTI4
    CALL IN_OOUT
    INC A
    JR NZ,WRMULTI4 ;���� �᢮�������� �����
    JP CS_HIGH ;᭨���� �롮� ����� � ��室�� � ����� 0