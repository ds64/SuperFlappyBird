.BANK 0 SLOT 0
.ORG 0
.SECTION "MathCode" SEMIFREE
; Multiplies A by 10
; Result returns in A
mult10:
        php
        sep #$20
        sta $4202
        lda #10
        sta $4203
        nop
        nop
        nop
        nop
        plp
        lda $4216
        rts

add16:
        clc
        adc #16
        rts
.ENDS