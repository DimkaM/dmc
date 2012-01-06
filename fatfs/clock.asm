XDEF gluk_fattime
.gluk_fattime
    ld bc,0xeff7
    ld a,128
    out (c),a
    xor a		;секунды
    call bcd2bin
    srl a
    ld (hl),a
    
    ld a,2		;минуты
    call bcd2bin
    call minmes
    
    ld a,4		;час
    call bcd2bin
    sla a
    sla a
    sla a
    add a,(hl)
    ld (hl),a
    
    ld a,7		;день
    call bcd2bin
    inc hl
    ld (hl),a
    
    ld a,8		;мес€ц
    call bcd2bin
    call minmes
    
    ld a,9		;год
    call bcd2bin
    add a,20
    sla a
    add a,(hl)
    ld (hl),a
    ret
    
.minmes    
    ld d,a
    xor a
    srl d
    rr a
    srl d
    rr a
    srl d
    rr a
    add a,(hl)
    ld (hl),a
    inc hl
    ld (hl),d
    ret
.bcd2bin
    ld b,0xdf
    out (c),a
    ld b,0xbf
    in a,(c)
    ld e,a
    and a,0xf0
    srl a
    ld d,a
    srl d
    srl d
    add a,d
    ld d,a
    ld a,e
    and a,0xf
    add a,d
    ret
