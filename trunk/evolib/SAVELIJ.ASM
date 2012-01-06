
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
;Входные параметры общие:
;HL-адрес загрузки в память
;BCDE-32-х битный номер сектора
;A-количество блоков (блок=512 байт)
;только для многоблочной записи/чтении

P_1F7	EQU #F0			;РЕГИСТР СОСТОЯНИЯ/РЕГИСТР КОМАНД
P_1F6	EQU #D0			;CHS-НОМЕР ГОЛОВЫ И УСТР/LBA АДРЕС 24-27
P_1F5	EQU #B0			;CHS-ЦИЛИНДР 8-15/LBA АДРЕС 16-23
P_1F4	EQU #90			;CHS-ЦИЛИНДР 0-7/LBA АДРЕС 8-15
P_1F3	EQU #70			;CHS-НОМЕР СЕКТОРА/LBA АДРЕС 0-7
P_1F2	EQU #50			;СЧЕТЧИК СЕКТОРОВ
P_1F1	EQU #30			;ПОРТ ОШИБОК/СВОЙСТВ
P_1F0	EQU #10			;ПОРТ ДАННЫХ
P_3F6	EQU #C8			;РЕГИСТР СОСТОЯНИЯ/УПРАВЛЕНИЯ
P_HI	EQU #11			;СТАРШИЕ 8 БИТ
PRT_RW	EQU P_1F0*256+P_HI	;ПОРТЫ ЧТЕНИЯ/ЗАПИСИ ОДНИМ СЛОВОМ

;НА ВЫХОДЕ:
;H-ДЛЯ MASTER 0-HDD, 1-CDROM, #FF-NONE
;L-ДЛЯ SLAVE  0-HDD, 1-CDROM, #FF-NONE
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

;HL-АДРЕС БУФЕРА СЕКТОРА ИДЕНТИФИКАЦИИ
;A=E0-ДЛЯ MASTER, A=F0-ДЛЯ SLAVE
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


;Драйвер SD карты
;LAST UPDATE 14.04.2009 savelij
;Входные параметры общие:
;HL-адрес загрузки в память
;BCDE-32-х битный номер сектора
;A-количество блоков (блок=512 байт) - только для многоблочной записи/чтения
;Ошибки выдаваемые на выходе:
;A=0 - инициализация прошла успешно
;A=1 - карта не найдена или не ответила
;A=2 - карта защищена от записи
;A=3 - попытка записи в сектор 0 карты
P_DATA    EQU #57    ;порт данных
P_CONF    EQU #77    ;порт конфигурации
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
	CALL CS_HIGH    ;включаем питание карты при снятом выборе
    LD BC,P_DATA
    LD DE,#20FF    ;бит выбора карты в <1>
SD_INITloop
	OUT (C),E    ;записываем в порт много единичек
	DEC D    ;количество единичек несколько больше
    JR NZ,SD_INITloop    ;чем надо
    XOR A    ;запускаем счетчик на 256
    EX AF,AF    ;для ожидания инициализации карты
ZAW001    LD HL,CMD00    ;даем команду сброса
    CALL OUTCOM    ;этой командой карточка переводится в режим SPI
    CALL IN_OOUT    ;читаем ответ карты
    EX AF,AF
    DEC A
    JR Z,ZAW003    ;если карта 256 раз не ответила, то карты нет
    EX AF,AF
    DEC A
    JR NZ,ZAW001    ;ответ карты <1>, перевод в SPI прошел успешно
    LD HL,CMD08    ;запрос на поддерживаемые напряжения
    CALL OUTCOM    ;команда поддерживается начиная со спецификации
    CALL IN_OOUT    ;версии 2.0 и только SDHC, мини и микро SD картами
    IN H,(C)    ;в A=код ответа карты
    NOP    ;считываем 4 байта длинного ответа
    IN H,(C)    ;но не используем
    NOP
    IN H,(C)
    NOP
    IN H,(C)
    LD HL,0    ;HL=аргумент для команды инициализации
    BIT 2,A    ;если бит 2 установлен, то карта стандартная
    JR NZ,ZAW006    ;стандартная карта выдаст <ошибка команды>
    LD H,#40    ;если ошибки не было, то карта SDHC, мини или микро SD
ZAW006    LD A,CMD_55    ;запускаем процесс внутренней инициализации
    CALL OUT_COM    ;для карт MMC здесь должна быть другая команда
    CALL IN_OOUT    ;соответственно наличие в слоте MMC-карты
    LD A,ACMD_41    ;вызовет зависание драйвера, от применения
    OUT (C),A    ;общей команды запуска инициализации я отказался
    NOP    ;бит 6 установлен для инициализации SDHC карты
    OUT (C),H    ;для стандартной сброшен
    NOP
    OUT (C),L
    NOP
    OUT (C),L
    NOP
    OUT (C),L
    LD A,#FF
    OUT (C),A
    CALL IN_OOUT    ;ждем перевода карты в режим готовности
    AND A    ;время ожидания примерно 1 секунда
    JR NZ,ZAW006
ZAW004    LD A,CMD_59    ;принудительно отключаем CRC16
    CALL OUT_COM
    CALL IN_OOUT
    AND A
    JR NZ,ZAW004
ZAW005    LD HL,CMD16    ;принудительно задаем размер блока 512 байт
    CALL OUTCOM
    CALL IN_OOUT
    AND A
    JR NZ,ZAW005
;включение питания карты при снятом сигнале выбора карты
CS_HIGH    PUSH AF
    LD A,3
    OUT (P_CONF),A    ;включаем питание, снимаем выбор карты
    XOR A
    OUT (P_DATA),A    ;обнуляем порт данных
    POP AF    ;обнуление порта можно не делать, просто последний
	ld hl,0
    RET    ;записанный бит всегда 1, а при сбросе через вывод
        ;данных карты напряжение попадает на вывод питания
        ;карты и светодиод на питании подсвечивается
;возврат при не ответе карты с кодом ошибки 1
ZAW003    CALL zsd_off
    ld hl,3
    RET
zsd_off    XOR A
    OUT (P_CONF),A    ;выключение питания карты
    OUT (P_DATA),A    ;обнуление порта данных
	ld hl,0
    RET
;выбираем карту сигналом 0
CS__LOW    PUSH AF
    LD A,1
    OUT (P_CONF),A
    POP AF
    RET
;запись в карту команды с неизменяемым параметром из памяти
;адрес команды в <HL>
OUTCOM    CALL CS__LOW
    PUSH BC
    LD BC,#600+P_DATA
    OTIR    ;передаем 6 байт команды из памяти
    POP BC
    RET
;запись в карту команды с нулевыми аргументами
;А-код команды, аргумент команды равен 0
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
    OUT (C),A    ;пишем пустой CRC7 и стоповый бит
    POP BC
    RET
;запись команды чтения/записи с номером сектора в BCDE для карт стандартного размера
;при изменяемом размере сектора номер сектора нужно умножать на его размер, для карт 
;SDHC, мини и микро размер сектора не требует умножения
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
    BIT 6,A    ;проверяем 30 бит регистра OCR (6 бит в <А>)        
    POP HL    ;при установленном бите умножение номера сектора
    JR NZ,SECN200    ;не требуется
    EX DE,HL    ;при сброшенном бите соответственно
    ADD HL,HL    ;умножаем номер сектора на 512 (#200)
    EX DE,HL
    ADC HL,HL
    LD H,L
    LD L,D
    LD D,E
    LD E,0
SECN200    POP AF    ;заготовленный номер сектора находится в <HLDE>
    OUT (C),A    ;пишем команду из <А> на SD карту
    NOP    ;записываем 4 байта аргумента
    OUT (C),H    ;пишем номер сектора от старшего
    NOP
    OUT (C),L
    NOP
    OUT (C),D
    NOP
    OUT (C),E    ;до младшего байта
    LD A,#FF
    OUT (C),A    ;пишем пустой CRC7 и стоповый бит
    POP BC
    POP DE
    POP HL
    RET
;чтение ответа карты до 32 раз, если ответ не #FF - немедленный выход
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
    ;команда сброса и перевода карты в SPI режим после включения питания
CMD08    DEFB  #48,#00,#00,#01,#AA,#87 ;SEND_IF_COND
    ;запрос поддерживаемых напряжений
CMD16    DEFB #50,#00,#00,#02,#00,#FF ;SET_BLOCKEN
    ;команда изменения размера блока
;читаем один сектор из карты в память, адрес чтения в <HL>
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
;записываем один сектор из памяти в карту, адрес записи в <HL>
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
;многосекторное чтение
zsd_read
   ;EX AF,AF    ;прячем счетчик секторов
    LD A,CMD_18
    CALL SECM200    ;даем команду многосекторного чтения
    EX AF,AF
RDMULT1    EX AF,AF
RDMULT2
    CALL IN_OOUT
    CP #FE
    JR NZ,RDMULT2    ;ждем маркер готовности #FE для начала чтения
    CALL RD_SECT    ;читаем сектор
    EX AF,AF
    DEC A
    JR NZ,RDMULT1    ;продолжаем пока не обнулится счетчик
    LD A,CMD_12    ;по окончании чтения даем команду карте <СТОП>
    CALL OUT_COM    ;команда мультичтения не имеет счетчика и
RDMULT3
    CALL IN_OOUT    ;должна останавливаться здесь командой 12
    INC A
    JR NZ,RDMULT3    ;ждем освобождения карты
    JP CS_HIGH    ;снимаем выбор с карты и выходим с кодом 0

;многосекторная запись
zsd_write
    ;EX AF,AF    ;прячем счетчик секторов
	LD A,CMD_25 ;даем команду мультисекторной записи
    CALL SECM200
WRMULTI2
    CALL IN_OOUT
    INC A
    JR NZ,WRMULTI2 ;ждем освобождения карты
    EX AF,AF
WRMULT1 EX AF,AF
    LD A,#FC ;пишем стартовый маркер, сам блок и пустое CRC16
    CALL WR_SECT
WRMULTI3
    CALL IN_OOUT
    INC A
    JR NZ,WRMULTI3 ;ждем освобождения карты
    EX AF,AF
    DEC A
    JR NZ,WRMULT1 ;продолжаем пока счетчик не обнулится
    LD C,P_DATA
    LD A,#FD
    OUT (C),A ;даем команду остановки записи
WRMULTI4
    CALL IN_OOUT
    INC A
    JR NZ,WRMULTI4 ;ждем освобождения карты
    JP CS_HIGH ;снимаем выбор карты и выходим с кодом 0