.INCLUDE "header.inc"
.INCLUDE "snesinit.asm"
.INCLUDE "graphics.asm"

.BANK 0 SLOT 0
.ORG 0
.SECTION "MainCode"

Start:
        Snes_Init            ; Call Snes_Init macro for initialization

        ; Load palette and pattern
        LoadPalette Palette, 0, 16              
        LoadBlockToVRAM Pattern, $0000, 32

        jsr SetupVideo

; Infinite loop
forever:
        jmp forever

SetupVideo:
        php                 ; Push P register to stack

        lda #$00
        sta $2105           ; Set Video mode 0 (8x8 tiles, 4 color BG1/BG2/BG3/BG4)

        lda #$04            ; Set BG1's Tile Map offset to $0400 (Word address)
        sta $2107           ; And the Tile Map size to 32x32

        lda #$0F
        sta $2100           ; Turn on screen, full Brightness

        plp                 ; Restore P from stack
        rts

.ENDS

.BANK 1
.ORG 0
.SECTION "TileData"

Palette:
        .db $00, $00, $FF, $03, $03, $E0, $FF, $7F
Pattern:
        .db $FF, $FF, $7E, $FE, $3C, $FC, $18, $F8, $18, $F0, $3C, $E0, $7E, $C0, $FF, $80

.ENDS