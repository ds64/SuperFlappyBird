.BANK 0 SLOT 0
.ORG 0
.SECTION "MathCode" SEMIFREE
; Multiplies A by 10
mult10:
        sta $4202
        lda #10
        sta $4203
        nop
        nop
        nop
        nop
        lda $4216
        rts
.ENDS