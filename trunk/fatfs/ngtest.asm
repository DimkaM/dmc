
;������� SD-CARD ��� NGS

;�室�� ��ࠬ���� ��騥:
;HL-���� ����㧪� � ������
;BCDE-32-� ���� ����� ᥪ��
;A-������⢮ ������ (����=512 ����)
;⮫쪮 ��� ��������筮� �����/�⥭��

;�訡�� �뤠����� �� ��室�:
;A=0-���樠������ ��諠 �ᯥ譮
;A=1-���� �� ������� ��� �� �⢥⨫�


GSCOM		EQU 0XBB	; write-only, command for NGS
GSDAT		EQU 0XB3	; read-write
GSCTR		EQU 0X33	; write-only, control register for NGS:
;����� ����������� �������� �� NeoGS
SETUPSD		EQU #5B00

;����� �������� ��� ������/������, ��� ����� �� �����
RD_WR		EXA
		EX (SP),HL
		LD A,(HL)
		INC HL
		EX (SP),HL
		ADD A,A
		PUSH HL
		LD HL,NGSSDT
		ADD A,L
		LD L,A
		LD A,0
		ADC A,H
		LD H,A
		LD A,(HL)
		INC HL
		LD H,(HL)
		LD L,A
		EXA
		EX (SP),HL
		RET

NGSSDT		DW GSDINIT		;���� SD �����
		DW GSDOFF		;���������� SD �����
		DW SDRDSIN		;������ 1 ������
		DW SDRDMUL		;������ "A" ��������
		DW SDWRSIN		;������ 1 ������
		DW SDWRMUL		;������ "A" ��������

;������ "A" ��������
SDWRMUL		EXA
		LD A,5
		JR SDWRSN3

;������ ������ �������
SDWRSIN		LD A,1
		EXA
		LD A,4
SDWRSN3		CALL COMM2SD
		EXA
		PUSH DE
		PUSH BC
		LD BC,GSDAT
SDWRSN1		EXA
		OUT (GSCOM),A
		CALL WC_
		LD DE,#0200
SDWRSN2		OUTI
		CALL WD_
		DEC DE
		LD A,D
		OR E
		JR NZ,SDWRSN2
		EXA
		DEC A
		JR NZ,SDWRSN1
		CALL WN_
		IN A,(C)
		CP #77
		JR NZ,$-4
		POP BC
		POP DE
		XOR A
		RET

;������ "A" ��������
SDRDMUL		EXA
		LD A,3
		JR SDRDSN3

;������ ������ �������
SDRDSIN		LD A,1
		EXA
		LD A,2
SDRDSN3		CALL COMM2SD
		EXA
		PUSH DE
		PUSH BC
		LD BC,GSDAT
SDRDSN1		EXA
		OUT (GSCOM),A
		CALL WC_
		LD DE,#0200
SDRDSN2		CALL WN_
		INI
		DEC DE
		LD A,D
		OR E
		JR NZ,SDRDSN2
		EXA
		DEC A
		JR NZ,SDRDSN1
		CALL WN_
		IN A,(C)
		CP #77
		JR NZ,$-4
		POP BC
		POP DE
		XOR A
		RET

;���������� ������ ��������
GSDOFF		LD A,1
		JR GSDINIT+1

;������������� ��������
GSDINIT		XOR A
		CALL COMM2SD
		CALL WN_
		IN A,(GSDAT)
		CP #77
		JR NZ,SD_NO
		XOR A
		RET

SD_NO		LD A,1
		RET

;���������� ������/���������� � ������� �� NeoGS
COMM2SD		OUT (GSDAT),A			;���� ������� ��������
	        LD A,#1E
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
		EXA
		OUT (GSDAT),A
		EXA
		DS 9
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
INSTSDD		LD A,#80
		OUT (GSCTR),A
		EI
		HALT
		HALT
		DI
		LD A,#F3
		LD B,#30
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
		LD DE,#0300
		LD HL,SETUPSD
		OUT (C),E
		LD A,#14
		OUT (GSCOM),A
		CALL WC_
		OUT (C),D
		CALL WD_
		OUT (C),L
		CALL WD_
		OUT (C),H
		CALL WD_
		LD HL,UKLAD1
ISDD3		OUTI
		CALL WD_
		DEC DE
		LD A,D
		OR E
		JR NZ,ISDD3
		LD HL,SETUPSD
		OUT (C),L
		LD A,#13
		OUT (GSCOM),A
		CALL WC_
		OUT (C),H
		EI
		HALT
		HALT
		DI
		IN A,(GSDAT)
		CP #77
		JP NZ,SD_NO
		XOR A
		RET
