.BANK 0
.ORG 0
.SECTION "SpriteCode" SEMIFREE
SpriteInit:
    php         ; Save P register state

    rep #$30    ; Use 16-bit A, X and Y

    ldx #$0000
    lda #$01
; Put all sprites offscreen at X coordinate -255
; Filling first sprite table
; Sprite Table 1 (4-bytes per sprite)         
; Byte 1:    xxxxxxxx    x: X coordinate
; Byte 2:    yyyyyyyy    y: Y coordinate
; Byte 3:    cccccccc    c: Starting tile #
; Byte 4:    vhoopppc    v: vertical flip h: horizontal flip  o: priority bits
;                        p: palette #
_putoffscreen:
    sta $0000, X
    inx
    inx
    inx
    inx
    cpx #$0200
    bne _putoffscreen
; Filling sprite table 2
; Sprite Table 2 (2 bits per sprite)
; bits 0,2,4,6 - Enable or disable the X coordinate's 9th bit.
; bits 1,3,5,7 - Toggle Sprite size: 0 - small size   1 - large size
    lda #$5555
_xmsb:
    sta $0000, X
    inx
    inx
    cpx #$0220
    bne _xmsb

    plp
    rts
.ENDS