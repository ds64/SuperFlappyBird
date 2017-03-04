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
        lda #$00
        sta CurrentState

        lda #$0000
        sta RecordScore
        lda #$00
        sta OnesRec
        sta TensRec
        sta HunRec
        sta ThouRec

reInit:
        InitSNES           ; Call macro for initialization

        jsr SpriteInit
        jsr recordScoreSpritesInit

        ; Load palette and pattern
        LoadPalette SpritePalette, 128, 16
        LoadBlockToVRAM SpriteTiles, $0000, $2000
        LoadPalette BgPalette 0, 16
        LoadBlockToVRAM BgMap, $2000, $0800
        LoadBlockToVRAM BgTiles, $3000, $1640

        jsr SetupVideo

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
        and #$20
        bne _changeMenuSelection
        lda Joy2Press
        and #$10
        beq _randSeed
        jmp _checkSelection
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
_changeMenuSelection:
        lda MenuSelection
        clc
        adc #$01
        and #$01
        sta MenuSelection
        jmp _randSeed
_checkSelection:
        lda MenuSelection
        cmp #$00
        bne _randSeed
        jmp _restart
        

; NMI interrupt handler
VBlank:
        php
        rep #$10
        sep #$20

        ; Render score
        jsr renderCurrentScore

        ; Player falling
        jsr playerFall

        ; Skip pipe scroll on game over
        ldx IsGameOver
        cpx #$00
        beq _transfer

        jsr PipeScrolling

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

DisableVideo:
        php
        lda #$00
        sta $2101

        lda #$03
        sta $2105

        lda #$00
        sta $2107

        lda #$00
        sta $210B

        lda #$00
        sta $212C

        lda #$00
        sta $2100

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