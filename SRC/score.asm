.BANK 0 SLOT 0
.ORG 0
.SECTION "ScoreCode" SEMIFREE
scoreInit:
        ; Score sprites init

        lda #(256/2 + 16)
        sta $0000
        lda #(224/8 - 8)
        sta $0001
        lda #$40
        sta $0002
        lda #$10
        sta $0003

        lda #(256/2)
        sta $0004
        lda #(224/8 - 8)
        sta $0005
        lda #$40
        sta $0006
        lda #$10
        sta $0007

        lda #(256/2 - 16)
        sta $0008
        lda #(224/8 - 8)
        sta $0009
        lda #$40
        sta $000A
        lda #$10
        sta $000B

        lda #(256/2 - 32)
        sta $000C
        lda #(224/8 - 8)
        sta $000D
        lda #$40
        sta $000E
        lda #$10
        sta $000F  

        lda #$00
        sta $0200

        rts
.ENDS