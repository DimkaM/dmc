	DEVICE ZXSPECTRUM128

MEM_FREE=0x3000
	ORG #0
START
INI
	DI
	JP INI_CONT+#8000
	org 0x0006
	dw ngs_sd.UKLAD1
rst18
	org #18
	;push hl
	ADD A,A
	LD HL,fatfs.tabl
	ADD A,L
	LD L,A
	LD A,H
	ADC A,0
	LD H,A
	LD A,(HL)
	INC HL
	LD H,(HL)
	LD L,A
	jp (hl)

	org #38
	PUSH AF,BC,DE,HL
	CALL kbd.int_call
	POP HL,DE,BC,AF
	ei
	ret

	INCLUDE "main_h.asm"

INI_CONT
	ld a,1
	out (#BF),a
	ld a,0x7f&mem.main_p
	LD BC,#3FF7
	out (c),a
	LD BC,#7FF7
	ld a,0x7f&mem.fat_p
	OUT (C),A
	LD hl,#8000
	ld de,#0000
	ld bc,#8000
	LDIR
	jp .l1
.l1	LD BC,0x7ff7
	ld a,0x7f&mem.txt_p
	OUT (C),A
	LD BC,0xbff7
	ld a,0x7f&mem.txt_p
	OUT (C),A
	LD BC,#fff7
	ld a,0x7f&mem.txt_p
	OUT (C),A
	LD SP,#4000
;	ld a,0
;	out (#BF),a	
	call SAMPLE.begin
.l2	inc hl
	halt
	jr .l2


	module kbd
	INCLUDE "kbd.asm",1
	endmodule

	module SAMPLE
	include "sample.asm",1
	endmodule
	
	module ngs_sd
	include "ngs_sd.asm",1
	endmodule
	
	display $
	
	org #4000
	MODULE fatfs
tabl
	incbin "fatfs.raw"
	ENDMODULE
ENDPROG
	SAVEBIN "aa",START,ENDPROG-START
	
	ORG #8000
	incbin "aa"
	SAVEHOB  "proj44.$c","proj44.C",#8000,#8000