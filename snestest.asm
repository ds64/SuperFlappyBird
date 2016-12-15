.INCLUDE "header.inc"
.INCLUDE "snesinit.asm"
.INCLUDE "graphics.asm"

.BANK 0 SLOT 0
.ORG 0
.SECTION "MainCode"

Start:
        Snes_Init            ; Call Snes_Init macro for initialization

        ; Write white color palette to CGRAM data
        ; The format is: 0bbbbbgg gggrrrrr

        ;lda #$FF            ; Load low-byte to A
        ;sta $2122           ; Store A to Data for CG-RAM Write register
        ;lda #$7F            ; Load high-byte to A
        ;sta $2122           ; Store A to Data for CG-RAM Write register

        ClearPalette
        ClearVRAM
        SetPalette Palette, 0, 8
        LoadVRAM Pattern, $0000, $0020

        jsr SetupVideo

; Infinite loop
forever:
        jmp forever

SetupVideo:
        php

        lda #$02
        sta $2105           ; Set Video mode 0, 8x8 tiles, 4 color BG1/BG2/BG3/BG4

        lda #$04            ; Set BG1's Tile Map offset to $0400 (Word address)
        sta $2107           ; And the Tile Map size to 32x32

        stz $210B           ; Set BG1's Character VRAM offset to $0000 (word address)

        lda #$01            ; Enable BG1
        sta $212C

        lda #$FF
        sta $210E
        sta $210E

        ; Turn on screen, full brightness
        lda #$0F            ; Load brightness level to A. (15 - maximum)
        sta $2100           ; Store A to screen display register


        plp
        rts

.ENDS

.BANK 1 SLOT 0
.ORG 0
.SECTION "Data"

Palette:
        .db $FF, $7F, $00, $00, $FF, $7F, $00, $00
Pattern:
        .db $FF, $00, $DB, $00, $DB, $00, $DB, $00, $FF, $00, $7E, $00, $00, $00, $FF, $00
        .db $FF, $00, $DB, $00, $DB, $00, $DB, $00, $FF, $00, $7E, $00, $00, $00, $FF, $00

.ENDS