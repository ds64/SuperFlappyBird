.INCLUDE "header.inc"
.INCLUDE "snesinit.asm"
.INCLUDE "graphics.asm"

.BANK 0 SLOT 0
.ORG 0
.SECTION "MainCode"

Start:
        InitSNES           ; Call macro for initialization

        ; Load palette and pattern
        LoadPalette Palette, 0, 16              
        LoadBlockToVRAM Pattern, $0000, $0030

        lda #$80
        sta $2115
        ; $2116
        ; vhopppcc cccccccc
        ; v - vertical flip
        ; h - horizontal flip
        ; o - priority bit
        ; p - palette number (0-7)
        ; c - location on screen

        ; Using palette #1
        ; Rendering character at location (0;0)
        ldx #$0400
        stx $2116
        ; $2118 - character number in tile data to put on screen
        ; Using pattern 2 from tile data
        lda #$02
        sta $2118
        ; Using palette #1 and rendering character at (0;1)
        ldx #$0401
        stx $2116
        ; Using pattern 1 from tile data
        lda #$01
        sta $2118

        jsr SetupVideo

; Infinite loop
forever:
        jmp forever

SetupVideo:
        php

        lda #$00
        sta $2105           ; Set Video mode 0, 8x8 tiles, 4 color BG1/BG2/BG3/BG4

        lda #$04            ; Set BG1's Tile Map offset to $0400 (Word address)
        sta $2107           ; And the Tile Map size to 32x32

        stz $210B           ; Set BG1's Character VRAM offset to $0000 (word address)

        lda #$01            ; Enable BG1
        sta $212C

        lda #$FF
        sta $210E
        sta $210E

        lda #$0F
        sta $2100           ; Turn on screen, full Brightness

        plp
        rts

.ENDS

.BANK 1
.ORG 0
.SECTION "TileData"

Palette:
        .db $00, $00, $FF, $03, $E0, $03, $FF, $7F
Pattern:
        .db $FF, $00, $FF, $00, $FF, $00, $FF, $00, $FF, $00, $FF, $00, $FF, $00, $FF, $00
        .db $FF, $FF, $7E, $FE, $3C, $FC, $18, $F8, $18, $F0, $3C, $E0, $7E, $C0, $FF, $80
        .db $F8, $18, $F0, $3C, $E0, $7E, $C0, $FF, $80, $FF, $FF, $7E, $FE, $3C, $FC, $18

.ENDS