.INCLUDE "header.inc"
.INCLUDE "snesinit.asm"
.INCLUDE "graphics.asm"
.INCLUDE "sprites.asm"
.INCLUDE "joypad.asm"

.MACRO Stall
        .REPT 3
                WAI
        .ENDR
.ENDM

.EQU PlayerX $0300
.EQU PlayerY $0302

.BANK 0 SLOT 0
.ORG 0
.SECTION "MainCode"

Start:
        InitSNES           ; Call macro for initialization

        stz $4016

        lda #$09
        sta $2105

        stz $2121
        lda #$08
        sta $2122
        sta $2122

        ; Load palette and pattern
        ; LoadPalette Palette, 0, 16
        LoadPalette PlayerPalette, 128, 16              
        ; LoadBlockToVRAM Pattern, $0000, $0030
        LoadBlockToVRAM PlayerTiles, $0000, $0400

        jsr SpriteInit

        ; lda #$80
        ; sta $2115
        ; $2116
        ; vhopppcc cccccccc
        ; v - vertical flip
        ; h - horizontal flip
        ; o - priority bit
        ; p - palette number (0-7)
        ; c - location on screen

        ; Using palette #1
        ; Rendering character at location (0;0)
        ; ldx #$0400
        ; stx $2116
        ; $2118 - character number in tile data to put on screen
        ; Using pattern 2 from tile data
        ; lda #$02
        ; sta $2118
        ; Using palette #1 and rendering character at (27;31) - last tile visible on screen
        ; ldx #$077F
        ; stx $2116
        ; Using pattern 1 from tile data
        ; lda #$01
        ; sta $2118

        ; Sprite Table 1 (4-bytes per sprite)         
        ; Byte 1:    xxxxxxxx    x: X coordinate
        ; Byte 2:    yyyyyyyy    y: Y coordinate
        ; Byte 3:    cccccccc    c: Starting tile #
        ; Byte 4:    vhoopppc    v: vertical flip h: horizontal flip  o: priority bits
        ;                        p: palette #

        lda #(256/2 - 8)
        sta $0000
        sta PlayerX
        lda #(224/2 - 8)
        sta $0001
        sta PlayerY
        stz $0002
        stz $0003

        ; Sprite Table 2 (2 bits per sprite)
        ; bits 0,2,4,6 - Enable or disable the X coordinate's 9th bit.
        ; bits 1,3,5,7 - Toggle Sprite size: 0 - small size   1 - large size
        ; 54 - 0101 0100
        lda #$54
        sta $0200

        jsr SetupVideo

        ; Enable NMI
        lda #$81
        sta $4200

; Infinite loop
forever:
        Stall               ; Wait for interrupt macro call

        pha
        phx
        php
        rep #$30
        lda Joy1Press
        and #$80
        beq _endButtonTest
        ; Change X coordinate

        lda PlayerX
        cmp #$FF
        beq _setXzero
        ina
        jmp _storeX
_setXzero:
        lda #$0000
_storeX:
        sta PlayerX
_endButtonTest:
        plp
        plx
        pla
        jmp forever
        

; NMI interrupt handler
VBlank:
        php
        rep #$10
        sep #$20

        lda PlayerX
        sta $0000

        ; Transfer Sprite data

        stz $2102
        stz $2103

        ldy #$0400
        sty $4300
        stz $4302
        stz $4303
        ldy #$0220
        sty $4305
        lda #$7E
        sta $4304
        lda #$01
        sta $420B

        ; Polling input

        jsr Joypad

        lda $4210           ; Clear NMI flag

        plp

        rti

SetupVideo:
        php

        ; lda #$00
        ; sta $2105           ; Set Video mode 0, 8x8 tiles, 4 color BG1/BG2/BG3/BG4

        ; lda #$04            ; Set BG1's Tile Map offset to $0400 (Word address)
        ; sta $2107           ; And the Tile Map size to 32x32

        ; stz $210B           ; Set BG1's Character VRAM offset to $0000 (word address)

        ; Set sprite properties

        ; sssnnbbb
        ; s - size
        ; 000 - 8x8 small, 16x16 large
        ; 001 - 8x8 small, 32x32 large
        ; 010 - 8x8 small, 64x64 large
        ; 011 - 16x16 small, 32x32 large
        ; 100 - 16x16 small, 64x64 large
        ; 101 - 32x32 small, 64x64 large

        lda #$60
        sta $2101

        lda #$10            ; Enable sprites
        sta $212C

        ; lda #$FF
        ; sta $210E
        ; sta $210E

        lda #$0F
        sta $2100           ; Turn on screen, full Brightness

        plp
        rts

.ENDS

.BANK 1 SLOT 0
.ORG 0
.SECTION "TileData"

Palette:
        .db $00, $00, $FF, $03, $E0, $03, $FF, $7F
Pattern:
        .db $FF, $00, $FF, $00, $FF, $00, $FF, $00, $FF, $00, $FF, $00, $FF, $00, $FF, $00
        .db $FF, $FF, $7E, $FE, $3C, $FC, $18, $F8, $18, $F0, $3C, $E0, $7E, $C0, $FF, $80
        .db $F8, $18, $F0, $3C, $E0, $7E, $C0, $FF, $80, $FF, $FF, $7E, $FE, $3C, $FC, $18

PlayerPalette:
        .INCBIN ".\\mrflap.clr"

PlayerTiles:
        .INCBIN ".\\mrflap.pic"

.ENDS