.INCLUDE "header.inc"
.INCLUDE "snesinit.asm"
.INCLUDE "graphics.asm"
.INCLUDE "sprites.asm"
.INCLUDE "joypad.asm"
.INCLUDE "gameplay.asm"
.INCLUDE "math.asm"
.INCLUDE "score.asm"

.BANK 0 SLOT 0
.ORG 0
.SECTION "MainCode"

Start:
        InitSNES           ; Call macro for initialization

        stz $4016

        lda #$09
        sta $2105

        ; Load palette and pattern
        LoadPalette SpritePalette, 128, 16
        LoadBlockToVRAM SpriteTiles, $0000, $2000
        LoadPalette BgPalette 0, 16
        LoadBlockToVRAM BgMap, $2000, $0800
        LoadBlockToVRAM BgTiles, $3000, $1640

        jsr SpriteInit
        jsr SetupVideo

        lda #$0000
        sta RecordScore
        lda #$00
        sta OnesRec
        sta TensRec
        sta HunRec
        sta ThouRec

        jsr recordScoreSpritesInit

        ; Enable NMI
        lda #$81
        sta $4200

_restart:
        jsr playerSetup
        ldy #$0060
        sty SpriteAddress
        sty PipesStartAddress
        jsr pipeCycleConfig
        jsr scoreInit

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
        pha
        php
        jsr checkPipeCollision
        plp
        pla
        lda IsGameOver
        cmp #$00
        beq _gameOverFall
        lda PlayerY
        clc
        adc #$01
        and #$00FF
        sta PlayerY
        jmp joypadCheck
_gameOver:
        lda #$00
        sta IsGameOver
        lda #$D2
        sta PlayerY
        jmp _endButtonTest

_gameOverFall:
        lda #$00
        sta IsGameOver
        lda PlayerY
        adc #$03
        sta PlayerY
        jmp _randSeed

joypadCheck:
        lda IsGameOver
        cmp #$00
        beq _endButtonTest
        lda Joy1Press
        and #$80
        beq _randSeed
        ; Change Y coordinate

        lda PlayerY
        cmp #$FF
        beq _storeY
        sbc #$18
        jmp _storeY
_storeY:
        sta PlayerY
        jmp _randSeed

_endButtonTest:
        jsr showHighScore
        lda Joy2Press
        and #$10
        beq _randSeed
        jmp _restart
_randSeed:
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

        ; Render score
        jsr renderCurrentScore

        ; Player fall
        lda PlayerY
        ldx PlayerYSpriteAddress
        sta $00,X

        ldx IsGameOver
        cpx #$00
        beq _transfer

        ; Pipe scroll speed
        ldx PipeScrollSpeed
        inx
        cpx #$02                ; This will set the scroll speed
        bne saveSpeedVariable
        ldx #$00
saveSpeedVariable:
        stx PipeScrollSpeed
        cpx #$00
        beq pipeScrollCycle
        jmp _transfer

pipeScrollCycle:
        ; Pipe Scroll X
        ldy PipesStartAddress
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

        ; $2105 - Screen mode register
        ; dcbapmmm
        ; d - BG4 tile size, c - BG3 tile size
        ; b - BG2 tile size, a - BG1 tile size
        ; Tile sizes: 0 - 8x8, 1 - 16x16
        ; p - order of BG priorities
        ; m - Screen mode
        ; Screen modes:
        ; MODE | # of BGs | Max colors per Tile | Palettes         | Total colors
        ; =========================================================++====================
        ; 0    | 4        | 4                   | 32 (8 per BG)    | 128 (32 per BG * 4)
        ; 1    | 3        | BG1,2 - 16 BG3 - 4  | 8                | BG1,2 - 128, BG3 - 4
        ; 2    | 2        | 16                  | 8                | 128
        ; 3    | 2        | BG1 - 256, BG2 - 16 | BG1 - 1, BG2 - 8 | BG1 - 256. BG2 - 128
        ; 4    | 2        | BG1 - 256, BG2 - 4  | BG1 - 1, BG2 - 8 | BG1 - 256, BG2 - 32
        ; 5    | 2        | BG1 - 16, BG2 - 4   | 8                | BG1 - 128, BG2 - 32
        ; 6    | 1        | 16                  | 8                | 128 (Interlaced)
        ; 7    | 1        | 256                 | 1                | 256

        lda #$03
        sta $2105

        ; $2107 - $210A - Tile map location registers
        ; $2107 - BG1, $2108 - BG2, $2109 - BG3, $210A - BG4
        ; aaaaaass
        ; a - Tile map address (address = aaaaaa * $0400)
        ; Address can be calculated shifting aaaaaa left by 10
        ; ss - Screen size in tiles
        ; 00 = 32x32, 01 = 64x32, 10 = 32x64, 11 = 64x64

        lda #$20
        sta $2107

        ; $210B, $210C - Character location registers
        ; $210B - BG1/BG2, $210C - BG3/BG4
        ; aaaabbbb
        ; aaaa - Base address for BG2 (BG4)
        ; bbbb - Base address for BG1 (BG3)
        ; Address is set in $1000 intervals in VRAM. 

        lda #$03
        sta $210B

        ; $212C - Enabling sprites and background
        ; ---abcde
        ; a - Enable sprites
        ; b - Enable BG4
        ; c - Enable BG3
        ; d - Enable BG2
        ; e - Enable BG1
        
        lda #$11            ; Enable sprites and BG1
        sta $212C

        lda #$0F
        sta $2100           ; Turn on screen, full Brightness

        plp
        rts

.ENDS

.BANK 1 SLOT 0
.ORG 0
.SECTION "TileData"

SpritePalette:
        .INCBIN "..\\RES\\sprites.clr"

SpriteTiles:
        .INCBIN "..\\RES\\sprites.pic"

BgPalette:
        .INCBIN "..\\RES\\bg.clr"

BgTiles:
        .INCBIN "..\\RES\\bg.pic"

BgMap:
        .INCBIN "..\\RES\\bg.map"

.ENDS