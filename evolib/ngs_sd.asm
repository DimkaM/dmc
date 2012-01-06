		
;LAST UPDATE: 19.02.2010 savelij

;€„…‘ –‹€ ™… ‘ ‘…
COMINT_		EQU #026E

;€„…‘ “‘’€‚™€ „€‰‚…€ € NeoGS
SETUPSD		EQU #5B00

GSCOM		EQU 0XBB	; write-only, command for NGS
GSDAT		EQU 0XB3	; read-write
GSCTR		EQU 0X33	; write-only, control register for NGS:
SCTRL		EQU 0X11		; Serial ConTRoL: read-write, read:
				; current state of below bits, write - see GS_info
ZXDATRD		EQU 0X02		; read-only, ZX DATa ReaD: a byte
				; written by ZX into GSDAT appears here
				; upon reading this port, data bit is cleared
ZXDATWR		EQU 0X03		; write-only, ZX DATa WRite: a byte
				; written here is available for ZX in
				; GSDAT upon writing here, data bit is set
ZXSTAT		EQU 0X04		; read-only, read ZX STATus: command and
				; data bits. positions are defined by
				; *_CBIT and *_DBIT above
CLRCBIT		EQU 0X05		; read-write, upon either reading or
				; writing this port, the Command BIT is CLeaRed
GSCFG0		EQU 0X0F		; read-write, GS ConFiG port 0: acts as
				; memory cell, reads previously written
				; value. Bits and fields follow:
SD_SEND		EQU 0X13		; SD card SEND, write-only, when
				; written, byte transfer starts with
				; written byte
SD_READ		EQU 0X13		; SD card READ, read-only, reads byte
				; received in previous byte transfer
SD_RSTR		EQU 0X14		; SD card Read and STaRt, read-only,
				; reads previously received byte and
				; starts new byte transfer with 0XFF
M_SDNCS		EQU 1
M_SNCLR		EQU 0X80		; M_SETNCLR
B_RAMRO		EQU 1		; =1 - ram absolute adresses 0X0000-7FFF
				; (zeroth big page) are write-protected
P_DATA    EQU #57    ;―®ΰβ ¤ ­­λε
P_CONF    EQU #77    ;―®ΰβ ª®­δ¨£γΰ ζ¨¨
CMD_12    EQU #4C    ;STOP_TRANSMISSION
CMD_17    EQU #51    ;READ_SINGLE_BLOCK
CMD_18    EQU #52    ;READ_MULTIPLE_BLOCK
CMD_24    EQU #58    ;WRITE_BLOCK
CMD_25    EQU #59    ;WRITE_MULTIPLE_BLOCK
CMD_55    EQU #77    ;APP_CMD
CMD_58    EQU #7A    ;READ_OCR
CMD_59    EQU #7B    ;CRC_ON_OFF
ACMD_41   EQU #69   ;SD_SEND_OP_COND


UKLAD1						;’“„€ „ € ƒ‘ ‡€„›‚€’

		DISP SETUPSD

;‘€ “‘’€‚™ „€‰‚…€ „‹ NeoGS
		DI
		LD A,#9C
		OUT (SCTRL),A			;”ƒ“€’ NeoGS
		CALL AVTODET
		AND A
		LD A,#77			;#77-NeoGS €‰„…
		JR Z,$+4
		LD A,#CC			;#CC-€‰„… OLDGS
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

;‚…€ —’ ’ NeoGS  ‚‹—…… —€‘’’› 24MHz
AVTODET		IN A,(GSCFG0)
		AND #CF
		OUT (GSCFG0),A			;€’€ ‡€‘ ‚ ’ ‘ ‘…›
						;’€ 5-4 ‚‹—€…’ —€‘’’“ –…‘‘€ €‚› 24 ƒζ
		LD D,A
		IN A,(GSCFG0)
		CP D
		LD A,0
		RET Z
		DEC A
		RET

UKLAD2						;’“„€ „ ……„›‚€’

		ENT

		DISP #1D00

;™€ ’—€ ‚•„€ „‹ €’› ‘
GSDDRV		DI
		IN A,(ZXDATRD)			;… €„› „€‰‚…€
		OUT (CLRCBIT),A			;‘‘ COMANDBIT
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
		IN A,(ZXDATRD)			;… ’‚ 31-24 €€…’€
		LD B,A
		CALL WDY
		IN A,(ZXDATRD)			;… ’‚ 23-16 €€…’€
		LD C,A
		CALL WDY
		IN A,(ZXDATRD)			;… ’‚ 15-8 €€…’€
		LD D,A
		CALL WDY
		IN A,(ZXDATRD)			;… ’‚ 7-0 €€…’€
		LD E,A
		CALL WDY
		IN A,(ZXDATRD)			;… ‹-‚ ‘…’‚
		JP (HL)

TABLSDG		DW SDINITG			;0 €€…’‚ … ’…“…’, € ‚›•„… A
						;‘’ ‚›… …‚›… 2 ‡€—…
		DW SDOFFG			;1 ‘’ ‘’… ‚›€ SD €’›
		DW RDSING			;2 —’€’ 1 ‘…’
		DW RDMULG			;3 —’€’ "A" ‘…’‚
		DW WRSING			;4 ‘€’ 1 ‘…’
		DW WRMULG			;5 ‘€’ "A" ‘…’‚

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

;……„€—€ „ƒ ‘…’€ ‚ SD €’“
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

;……„€—€ „ƒ ‘…’€ € ‘…
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

;‡€ƒ“‡€ „ƒ ‘…’€
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

;‡€ƒ“‡€ "A" ‘…’‚
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

;‡€‘ „ƒ ‘…’€
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

;‡€‘ "A" ‘…’‚
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

;†„€… ƒ„€ ‘… ‡€……’ €‰’ „€›•
WDN		IN A,(ZXSTAT)
		RLA
		JR C,WDN
		RET

;†„€… ƒ„€ ‘… „€‘’ €‰’ „€›•
WDY		IN A,(ZXSTAT)
		RLA
		JR NC,WDY
		RET

GSDDRVE
		ENT
		