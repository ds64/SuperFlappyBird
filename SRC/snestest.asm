.INCLUDE "header.inc"
.INCLUDE "snesinit.asm"
.INCLUDE "graphics.asm"
.INCLUDE "sprites.asm"
.INCLUDE "joypad.asm"
.INCLUDE "gameplay.asm"

.BANK 0 SLOT 0
.ORG 0
.SECTION "MainCode"

Start:
        InitSNES           ; Call macro for initialization

        stz $4016

        lda #$09
        sta $2105

        ; Set Background Color
        stz $2121
        lda #$08
        sta $2122
        sta $2122

        ; Load palette and pattern
        LoadPalette SpritePalette, 128, 16
        LoadBlockToVRAM SpriteTiles, $0000, $0800

        jsr SpriteInit

        jsr playerSetup
        ldy #$0010
        sty SpriteAddress
        jsr pipeCycleConfig
        jsr SetupVideo

        ; Enable NMI
        lda #$81
        sta $4200

; Infinite loop
forever:
        wai              ; Wait for interrupt macro call

        pha
        phx
        php
        rep #$30
        lda PlayerY
        cmp #$D2
        bpl _gameOver
        cmp #$00
        bmi _gameOverFall
        adc #$01
        sta PlayerY
        jmp joypadCheck
_gameOver:
        lda #$00
        sta IsGameOver
        jmp _endButtonTest

_gameOverFall:
        lda #$00
        sta IsGameOver
        lda PlayerY
        adc #$01
        sta PlayerY
        jmp _endButtonTest

joypadCheck:
        lda IsGameOver
        cmp #$00
        beq _endButtonTest
        lda Joy1Press
        and #$80
        beq _endButtonTest
        ; Change X coordinate

        lda PlayerY
        cmp #$FF
        beq _storeY
        sbc #$18
        jmp _storeY
_storeY:
        sta PlayerY

_endButtonTest:
        lda RandSeed
        adc Joy1Press
        ror A
        adc Joy1Hold
        ror A
        ror A
        sta RandSeed
        lda $0030
        adc RandSeed
        sta RandSeed
        plp
        plx
        pla
        jmp forever
        

; NMI interrupt handler
VBlank:
        php
        rep #$10
        sep #$20

        ; Player fall
        lda PlayerX
        sta $0000
        lda PlayerY
        sta $0001

        ldx IsGameOver
        cpx #$00
        beq _transfer

        ; Pipe Scroll X
        ldy #$0010
        sty CurrentPipeBeginAddress
pipeScrollBegin:
        ldy CurrentPipeBeginAddress
        clc
        lda CurrentPipeBeginAddress
        adc #$0020
        sta CurrentPipeEndAddress
pipescrollX:
        ; Scroll by axis X
        lda $00,Y
        dea
        sta $00,Y
        iny
        iny
        iny
        iny
        cpy CurrentPipeEndAddress
        beq _checkPipeX
        jmp pipescrollX

; Set X coordinate 9 bit (offscreen negative coordinates)
pipeFlipScrollX:
        jsr pipeGet2ndTableAddress
        lda $00,X
        and #$01
        cmp #$01
        beq pipeSetScrollX
        lda #$FF
        sta $00,X
        sta $01,X
        jmp pipeScrollCheckAllScrolled

; Set X coordinate 9 bit to 0 (onscreen positive coordinates)
pipeSetScrollX:
        jsr pipeScrollY
        lda #$AA
        sta $00,X
        sta $01,X
        jmp pipeScrollCheckAllScrolled

; Check if there was overflow
_checkPipeX:
        ldy CurrentPipeBeginAddress
        lda $00,Y
        cmp #$FF
        beq pipeFlipScrollX

; Check if all pipes checked
pipeScrollCheckAllScrolled:
        lda CurrentPipeBeginAddress
        clc
        adc #$0020
        cmp SpriteAddress
        beq _transfer
        sta CurrentPipeBeginAddress
        jmp pipeScrollBegin


        ; Transfer Sprite data
_transfer:
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

SpritePalette:
        .INCBIN "..\\RES\\sprites.clr"

SpriteTiles:
        .INCBIN "..\\RES\\sprites.pic"

.ENDS