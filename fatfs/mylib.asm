MODULE mylib
  PUBLIC tablcall
  PUBLIC LD_CLUST
  PUBLIC get_fattime
  EXTERN f_mount
  EXTERN f_open
  EXTERN f_read
  EXTERN f_lseek
  EXTERN f_close
  EXTERN f_opendir
  EXTERN f_readdir
  EXTERN f_stat
  EXTERN f_write
  EXTERN f_getfree
  EXTERN f_truncate
  EXTERN f_sync
  EXTERN f_unlink
  EXTERN f_mkdir
  EXTERN f_chmod
  EXTERN f_utime
  EXTERN f_rename
  EXTERN f_chdrive
  EXTERN f_chdir
  EXTERN ?L_MUL_L03
  
  RSEG NEAR_Z

  RSEG RCODE
tablcall:  
  DEFW f_mount
  DEFW f_open
  DEFW f_read
  DEFW f_lseek
  DEFW f_close
  DEFW f_opendir
  DEFW f_readdir
  DEFW f_stat
  DEFW f_write
  DEFW f_getfree
  DEFW f_truncate
  DEFW f_sync
  DEFW f_unlink
  DEFW f_mkdir
  DEFW f_chmod
  DEFW f_utime
  DEFW f_rename
  DEFW f_chdrive
  DEFW f_chdir
//VolToPart:
//        DEFB 0,0,1,0
  DEFW ?L_MUL_L03 

LD_CLUST:
  LD HL,20
  ADD HL,DE
  LD C,(HL)
  INC HL
  LD B,(HL)
  LD HL,26
  ADD HL,DE
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  ret
  
    
minmes    
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
bcd2bin
    ld b,0xdf
    out (c),a
    ld b,0xbf
    in a,(c)
    ret
    
get_fattime:
    push bc
    push de
    ex de,hl
    ld bc,0x0bbe
    in a,(c)
    ld bc,0xeff7
    or 0x80
    out (c),a
    ld a,0x0b
    ld b,0xdf
    out (c),a
    ld b,0xbf
    in a,(c)
    or 0x04
    out (c),a
    xor a		//sec
    call bcd2bin
    srl a
    ld (hl),a
    
    ld a,2		//min
    call bcd2bin
    call minmes
    
    ld a,4		//h
    call bcd2bin
    sla a
    sla a
    sla a
    add a,(hl)
    ld (hl),a
    
    ld a,7		//day
    call bcd2bin
    inc hl
    ld (hl),a
    
    ld a,8		//mes
    call bcd2bin
    call minmes
    
    ld a,9		//god
    call bcd2bin
    add a,20
    sla a
    add a,(hl)
    ld (hl),a 
    ld bc,0x0bbe
    in a,(c)
    ld bc,0xeff7
    xor 0x80
    out (c),a
    pop de
    pop bc
    ret


ENDMOD
END

