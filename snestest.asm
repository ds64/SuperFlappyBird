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

        lda #$FF            ; Load low-byte to A
        sta $2122           ; Store A to Data for CG-RAM Write register
        lda #$7F            ; Load high-byte to A
        sta $2122           ; Store A to Data for CG-RAM Write register

        ; Turn on screen, full brightness
        lda #$0F            ; Load brightness level to A. (15 - maximum)
        sta $2100           ; Store A to screen display register

; Infinite loop
forever:
        jmp forever

.ENDS