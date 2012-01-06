
        macro KBD_GET_CHAR
        call kbd.get_char
        endm
;-------------------------
; ZX KEYBOARD LIB
;-------------------------
last_key    db 0
last_char   db 0
repit       db 25


get_char
	ei
	halt
	di
	ld hl,kbd.last_char
	ld a,(hl)
	or a
	jr z,get_char
    exa
    xor a
    ld (hl),a
    exa
    ret


int_call
        call get_key
        ld hl,(last_key)
        ld (last_key),a
        or a
        jr nz,.l1
        cp l
        ret z
        ld a,25
.l2     ld (repit),a
        ld a,l
        ld (last_char),a
        ret
.l1     ld a,(repit)
        dec a
        ld (repit),a
        ret nz
        ld a,(last_key)
        ld l,a
        ld a,5
        jr .l2
        
get_key CALL GET_KEYCODE2
        PUSH AF
        CP #01
        JR NZ,GET_KEYCODE0
        XOR A
        LD (kRUSLAT),A

GET_KEYCODE0
        CP #02
        JR NZ,GET_KEYCODE1
        LD  A,1
        LD (kRUSLAT),A

GET_KEYCODE1
        POP AF
        or a
        ret z
        RET 

GET_KEYCODE2
        LD E,#08 ;Цикл по 8-ми полурядам.
        LD BC,#7FFE

GET_KEYCODE3
        LD HL,MASKS ;Маска адресов
        LD D,0
        ADD HL,DE
        LD D,(HL)

        IN A,(C)     ;Опрос полуряда.
        XOR #FF
                     ;Гасим 3 ненужных бита.
        AND D
        JR NZ,GET_KEYCODE4

        RRC B        ;Переход к следующему полуряду.
        DEC E
        JR NZ,GET_KEYCODE3
        RET 

GET_KEYCODE4
        PUSH AF
        DEC E
        LD A,E
        ADD A,A
        LD B,0
        LD C,A
        LD HL,kb_LIST

GET_KEYCODE5
        LD A,(kRUSLAT)
        CP 1
        JR Z,MODE_RUS

        PUSH BC
        LD BC,#FEFE
        IN A,(C)
        BIT 0,A
        JR NZ,GET_KEYCODE6
        LD HL,KB_LIST

GET_KEYCODE6
        POP BC

        PUSH BC
        LD BC,#7FFE
        IN A,(C)
        BIT 1,A
        JR NZ,GET_KEYCODE7
        LD HL,Kb_LIST
GET_KEYCODE7
        POP BC
        JR MODE_LAT

MODE_RUS
        LD HL,R1_LIST
        PUSH BC
        LD BC,#FEFE
        IN A,(C)
        BIT 0,A
        JR NZ,MODE_RUS0
        LD HL,R2_LIST
MODE_RUS0
        POP  BC

        PUSH BC
        LD BC,#7FFE
        IN A,(C)
        BIT 1,A
        JR NZ,MODE_RUS1
        LD HL,R3_LIST   ;R3
MODE_RUS1
        POP BC

MODE_LAT
        ADD HL,BC
        LD A,(HL)
        INC HL
        LD H,(HL)
        LD L,A
        POP AF
        CP 1
        JR Z,O_0
        CP 2
        JR Z,O_1
        CP 4
        JR Z,O_2
        CP 8
        JR Z,O_3
        CP 16
        JR Z,O_4

MODE_LAT0
        LD B,0
        LD C,A
        ADD HL,BC
        LD A,(HL)
        RET 

O_0     LD A,0
        JR MODE_LAT0
O_1     LD A,1
        JR MODE_LAT0
O_2     LD A,2
        JR MODE_LAT0
O_3     LD A,3
        JR MODE_LAT0
O_4     LD A,4
        JR MODE_LAT0

;-------------------------
lastkey db 0
kRUSLAT DB 0         ;0-LAT,1-RUS

MASKS   DB 0
        DB %00011110
        DB %00011111
        DB %00011111
        DB %00011111

        DB %00011111
        DB %00011111
        DB %00011111
        DB %00011101

kb_LIST DW kb_FEFE,kb_FDFE,kb_FBFE,kb_F7FE
        DW kb_EFFE,kb_DFFE,kb_BFFE,kb_7FFE

KB_LIST DW KB_FEFE,KB_FDFE,KB_FBFE,KB_F7FE
        DW KB_EFFE,KB_DFFE,KB_BFFE,KB_7FFE

Kb_LIST DW Kb_FEFE,Kb_FDFE,Kb_FBFE,Kb_F7FE
        DW Kb_EFFE,Kb_DFFE,Kb_BFFE,Kb_7FFE

R1_LIST DW R1_FEFE,R1_FDFE,R1_FBFE,kb_F7FE
        DW kb_EFFE,R1_DFFE,R1_BFFE,R1_7FFE

R2_LIST DW R2_FEFE,R2_FDFE,R2_FBFE,kb_F7FE
        DW kb_EFFE,R2_DFFE,R2_BFFE,R2_7FFE

R3_LIST DW R3_FEFE,R3_FDFE,R3_FBFE,R3_F7FE
        DW R3_EFFE,R3_DFFE,R3_BFFE,R3_7FFE

kb_F7FE DB "1","2","3","4","5"
kb_FBFE DB "q","w","e","r","t"
kb_FDFE DB "a","s","d","f","g"
kb_FEFE DB "?","z","x","c","v"
kb_EFFE DB "0","9","8","7","6"
kb_DFFE DB "p","o","i","u","y"
kb_BFFE DB #0D,"l","k","j","h"
kb_7FFE DB " ","?","m","n","b"

Kb_F7FE DB "!","@","#","$","%"
KB_FBFE DB "Q","W","E","R","T"
KB_FDFE DB "A","S","D","F","G"
Kb_EFFE DB "_",")","(","'","&"
KB_FEFE DB "?","Z","X","C","V"
KB_DFFE DB "P","O","I","U","Y"
KB_BFFE DB #0D,"L","K","J","H"
KB_7FFE DB #06,"?","M","N","B"

KB_F7FE DB #07,#06,#04,#05,#08
Kb_FBFE DB #01,#02,#03,"<",">"
Kb_FDFE DB "~","|",#5C,"{","}"
Kb_FEFE DB "?",":","`","?","/"
KB_EFFE DB #0C,#0F,#09,#0B,#0A
Kb_DFFE DB #22,";",#04,"]","["
Kb_BFFE DB #0D,"=","+","-","^"
Kb_7FFE DB " ","?",".",",","*"

R1_F7FE DB "1","2","3","4","5"
R1_FBFE DB "й","ц","у","к","е"
R1_FDFE DB "ф","ы","в","а","п"
R1_FEFE DB "?","я","ч","с","м"

R1_EFFE DB "0","9","8","7","6"
R1_DFFE DB "з","щ","ш","г","н"
R1_BFFE DB #0D,"д","л","о","р"
R1_7FFE DB " ","?","ь","т","и"

R2_FBFE DB "Й","Ц","У","К","Е"
R2_FDFE DB "Ф","Ы","В","А","П"
R2_FEFE DB "?","Я","Ч","С","М"
R2_DFFE DB "З","Щ","Ш","Г","Н"
R2_BFFE DB #0D,"Д","Л","О","Р"
R2_7FFE DB " ","?","Ь","Т","И"

R3_F7FE DB "!",#22,#FC,";","%"
R3_FBFE DB #01,#02,#03,#81,#9E
R3_FDFE DB #F0,"|",#5C,#95,#9A
R3_FEFE DB "?",#86,#F1,"?","/"
R3_EFFE DB "_",")","(",#ED,":"
R3_DFFE DB #9D,#A6,#04,#EA,"x"
R3_BFFE DB #0D,"=","+","-","^"
R3_7FFE DB " ","?",#EE,#A1,"*"
