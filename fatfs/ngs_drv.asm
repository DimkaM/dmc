
;LAST UPDATE: 19.02.2010 savelij

;     FATALL
;  ,     
;             
;       

;    INSTSDD
;    RD_WR
;         

; 
		CALL INSTSDD	; 
		CALL RD_WR
		DB 0		; 
		LD HL,#8000
		LD BC,0
		LD DE,0
		CALL RD_WR
		DB 2		; 1   0  
		LD HL,#9000
		LD BC,0
		LD DE,5
		LD A,3
		CALL RD_WR
		DB 3		; 3    5  
;     CALL   4  5 

;    
COMINT_		EQU #026E

;    NeoGS
SETUPSD		EQU #5B00

; SD-CARD  NGS

;ๅฎคญ๋ฅ ฏ เ ฌฅโเ๋ ฎก้จฅ:
;HL- คเฅแ ง ฃเใงชจ ข ฏ ฌ๏โ์
;BCDE-32-ๅ กจโญ๋ฉ ญฎฌฅเ แฅชโฎเ 
;A-ชฎซจ็ฅแโขฎ กซฎชฎข (กซฎช=512 ก ฉโ)
;โฎซ์ชฎ คซ๏ ฌญฎฃฎกซฎ็ญฎฉ ง ฏจแจ/็โฅญจจ

;่จกชจ ข๋ค ข ฅฌ๋ฅ ญ  ข๋ๅฎคฅ:
;A=0-จญจๆจ ซจง ๆจ๏ ฏเฎ่ซ  ใแฏฅ่ญฎ
;A=1-ช เโ  ญฅ ญ ฉคฅญ  จซจ ญฅ ฎโขฅโจซ 

;   /,    
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

NGSSDT		DW GSDINIT		; SD 
		DW GSDOFF		; SD 
		DW SDRDSIN		; 1 
		DW SDRDMUL		; "A" 
		DW SDWRSIN		; 1 
		DW SDWRMUL		; "A" 

; "A" 
SDWRMUL		EXA
		LD A,5
		JR SDWRSN3

;  
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

; "A" 
SDRDMUL		EXA
		LD A,3
		JR SDRDSN3

;  
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

;  
GSDOFF		LD A,1
		JR GSDINIT+1

; 
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

; /    NeoGS
COMM2SD		OUT (GSDAT),A			;  
	        LD A,#1E
	        OUT (GSCOM),A
	        CALL WC_			;  
		LD A,B
		OUT (GSDAT),A
		CALL WD_			;  31-24 
		LD A,C
		OUT (GSDAT),A
		CALL WD_			;  23-16 
		LD A,D
		OUT (GSDAT),A
		CALL WD_			;  15-8 
		LD A,E
		OUT (GSDAT),A
		CALL WD_			;  7-0 
		EXA
		OUT (GSDAT),A
		EXA
		DS 9
		RET				; - 

;  NeoGS  
WD_		IN A,(GSCOM)
		RLA
		JR C,$-3
		RET

;  NeoGS  
WN_		IN A,(GSCOM)
		RLA
		JR NC,$-3
		RET

;  NeoGS  
WC_		IN A,(GSCOM)
		RRA
		JR C,$-3
		RET

;   NeoGS
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

UKLAD1						;    

		DISP SETUPSD

;    NeoGS
		DI
		LD A,#9C
		OUT (SCTRL),A			; NeoGS
		CALL AVTODET
		AND A
		LD A,#77			;#77-NeoGS 
		JR Z,$+4
		LD A,#CC			;#CC- OLDGS
		OUT (ZXDATWR),A
		OUT (CLRCBIT),A
		JP NZ,COMINT_
		DI
		IN A,(GSCFG0)
		RES B_RAMRO,A
		OUT (GSCFG0),A
		LD HL,#1D00
		LD (#0300+(#1E*2)),HL
		LD DE,UKLAD2
		LD BC,GSDDRVE-GSDDRV
		EX DE,HL
		LDIR
		IN A,(GSCFG0)
		SET B_RAMRO,A
		OUT (GSCFG0),A
		JP COMINT_

;   NeoGS    24MHz
AVTODET		IN A,(GSCFG0)
		AND #CF
		OUT (GSCFG0),A			;     
						; 5-4     24 ๆ
		LD D,A
		IN A,(GSCFG0)
		CP D
		LD A,0
		RET Z
		DEC A
		RET

UKLAD2						;  

		ENT

		DISP #1D00

;     
GSDDRV		DI
		IN A,(ZXDATRD)			;  
		OUT (CLRCBIT),A			; COMANDBIT
		LD HL,COMINT_
		PUSH HL
		ADD A,A
		LD E,A
		LD D,0
		LD HL,TABLSDG
		ADD HL,DE
		LD E,(HL)
		INC HL
		LD D,(HL)
		EX DE,HL
		CALL WDY
		IN A,(ZXDATRD)			;  31-24 
		LD B,A
		CALL WDY
		IN A,(ZXDATRD)			;  23-16 
		LD C,A
		CALL WDY
		IN A,(ZXDATRD)			;  15-8 
		LD D,A
		CALL WDY
		IN A,(ZXDATRD)			;  7-0 
		LD E,A
		CALL WDY
		IN A,(ZXDATRD)			; - 
		JP (HL)

TABLSDG		DW SDINITG			;0   ,   A
						;   2 
		DW SDOFFG			;1    SD 
		DW RDSING			;2  1 
		DW RDMULG			;3  "A" 
		DW WRSING			;4  1 
		DW WRMULG			;5  "A" 

ZAW003G		CALL CSHIGHG
		LD A,#EE
		JP OUTSTAT

SDINITG		CALL CSHIGHG
		LD BC,SD_SEND
		LD DE,#20FF
		OUT (C),E
		DEC D
		JR NZ,$-3
		LD BC,SD_RSTR
		XOR A
		EXA
ZAW001G		LD HL,CMD00G
		CALL OUTCOMG
		CALL INOOUTG
		EXA
		DEC A
		JR Z,ZAW003G
		EXA
		DEC A
		JR NZ,ZAW001G
		LD HL,CMD08G
		CALL OUTCOMG
		CALL INOOUTG
		IN H,(C)
		NOP
		IN H,(C)
		NOP
		IN H,(C)
		NOP
		IN H,(C)
		LD HL,0
		BIT 2,A
		JR NZ,ZAW006G
		LD H,#40
ZAW006G		LD A,CMD_55
		CALL OUT_COG
		CALL INOOUTG
		LD BC,SD_SEND
		LD A,ACMD_41
		OUT (C),A
		NOP
		OUT (C),H
		NOP
		OUT (C),L
		NOP
		OUT (C),L
		NOP
		OUT (C),L
		LD A,#FF
		OUT (C),A
		CALL INOOUTG
		AND A
		JR NZ,ZAW006G
ZAW004G		LD A,CMD_59
		CALL OUT_COG
		CALL INOOUTG
		AND A
		JR NZ,ZAW004G
ZAW005G		LD HL,CMD16G
		CALL OUTCOMG
		CALL INOOUTG
		AND A
		JR NZ,ZAW005G

SDOFFG		JP OK_WORK

CSHIGHG		PUSH AF
		LD A,M_SDNCS+M_SNCLR			;#81
		OUT (SCTRL),A
		POP AF
		RET

CSLOWG		PUSH AF
		LD A,M_SDNCS				;1
		OUT (SCTRL),A
		POP AF
		RET

OUTCOMG		CALL CSLOWG
		PUSH BC
		LD BC,#0600+SD_SEND
		OTIR
		POP BC
		RET

OUT_COG		PUSH BC
		CALL CSLOWG
		LD BC,SD_SEND
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
		OUT (C),A
		POP BC
		RET

SECM20G		PUSH HL
		PUSH DE
		PUSH BC
		PUSH AF
		PUSH BC
		LD A,CMD_58
		LD BC,SD_RSTR
		CALL OUT_COG
		CALL INOOUTG
		IN A,(C)
		NOP
		IN H,(C)
		NOP
		IN H,(C)
		NOP
		IN H,(C)
		BIT 6,A
		POP HL
		JR NZ,SECN20G
		EX DE,HL
		ADD HL,HL
		EX DE,HL
		ADC HL,HL
		LD H,L
		LD L,D
		LD D,E
		LD E,0
SECN20G		POP AF
		LD BC,SD_SEND
		OUT (C),A
		NOP
		OUT (C),H
		NOP
		OUT (C),L
		NOP
		OUT (C),D
		NOP
		OUT (C),E
		LD A,#FF
		OUT (C),A
		POP BC
		POP DE
		POP HL
		RET

INOOUTG		PUSH DE
		LD DE,#20FF
INWAITG		IN A,(SD_RSTR)
		CP E
		JR NZ,INEXITG
		DEC D
		JR NZ,INWAITG
INEXITG		POP DE
		RET

CMD00G		DB #40,#00,#00,#00,#00,#95		;GO_IDLE_STATE
CMD08G		DB #48,#00,#00,#01,#AA,#87		;SEND_IF_COND
CMD16G		DB #50,#00,#00,#02,#00,#FF		;SET_BLOCKEN

;    SD 
WRSECTG		LD BC,SD_SEND
		OUT (C),A
		IN A,(ZXSTAT)
		RRA
		JR NC,$-3
		OUT (CLRCBIT),A
		LD HL,#0200
		CALL WDY
		IN A,(ZXDATRD)
		DEC HL
		OUT (C),A
		LD A,H
		OR L
		JR NZ,$-10
		LD A,#FF
		OUT (C),A
		NOP
		OUT (C),A
		RET

;    
RDSECTG		IN A,(ZXSTAT)
		RRA
		JR NC,$-3
		OUT (CLRCBIT),A
		LD BC,SD_RSTR
		LD HL,#0200
		IN A,(C)
		DEC HL
		OUT (ZXDATWR),A
		CALL WDN
		LD A,H
		OR L
		JR NZ,$-10
		IN A,(C)
		NOP
		IN A,(C)
		RET

;  
RDSING		LD A,CMD_17
		CALL SECM20G
		CALL INOOUTG
		CP #FE
		JR NZ,$-5
		CALL RDSECTG
		CALL INOOUTG
		INC A
		JR NZ,$-4
		JR OK_WORK

; "A" 
RDMULG		EXA
		LD A,CMD_18
		CALL SECM20G
		EXA
RDMULG1		EXA
		CALL INOOUTG
		CP #FE
		JR NZ,$-5
		CALL RDSECTG
		EXA
		DEC A
		JR NZ,RDMULG1
		LD A,CMD_12
		CALL OUT_COG
		CALL INOOUTG
		INC A
		JR NZ,$-4
		JR OK_WORK

;  
WRSING		LD A,CMD_24
		CALL SECM20G
		CALL INOOUTG
		INC A
		JR NZ,$-4
		LD A,#FE
		CALL WRSECTG
		CALL INOOUTG
		INC A
		JR NZ,$-4
		JR OK_WORK

; "A" 
WRMULG		EXA
		LD A,CMD_25
		CALL SECM20G
		CALL INOOUTG
		INC A
		JR NZ,$-4
		EXA
WRMULG1		EXA
		LD A,#FC
		CALL WRSECTG
		CALL INOOUTG
		INC A
		JR NZ,$-4
		EXA
		DEC A
		JR NZ,WRMULG1
		LD C,SD_SEND
		LD A,#FD
		OUT (C),A
		CALL INOOUTG
		INC A
		JR NZ,$-4

OK_WORK		CALL CSHIGHG
		LD A,#77

OUTSTAT		OUT (ZXDATWR),A

;     
WDN		IN A,(ZXSTAT)
		RLA
		JR C,WDN
		RET

;     
WDY		IN A,(ZXSTAT)
		RLA
		JR NC,WDY
		RET

GSDDRVE
		ENT
