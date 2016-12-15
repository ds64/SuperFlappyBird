; SNES DMA register adresses
; $420B - main DMA register. It is used to enable DMA channel transfer.
; $43x0 - specifies how channel is supposed to perform transfer using bitmask
;         (where x is DMA channel index. From 0 to 7. 0 has the highest priority)
; $43x1 - DMA channel x destination address ($21XX) where XX - address stored in $43x1 register
; $43x2 - DMA channel x source address offset (low-bytes)
; $43x3 - DMA channel x source address offset (high-bytes)
; $43x4 - DMA channel x source address bank
; $43x5 - DMA channel x transfer size (low-bytes)
; $43x6 - DMA channel x transfer size (high-bytes)

; SetPalette PaletteLabel CG-RAM_Address Palette_Size
.macro SetPalette
    ; Saving current A and P values
    pha     ; push A register to stack
    php     ; push P register to stack

    rep #$20        ; Use A as 16-bit register
                    ; This actually resets 6th bit in P register to 0
                    ; 6th-bit in P sets A register size (if 1 - A is 8-bit, if 0 - 16-bit)
                    ; By default it is set to 1 with sep #$30 command in snesinit.asm file
    
    lda #\3         ; Load 3rd macro parameter to A which is Palette_Size
    sta $4305       ; Store A to DMA channel 0 transfer size registers
    
    lda #\1         ; Load PaletteLabel address to A
    sta $4302       ; Store A to DMA channel source address offset registers

    sep #$20        ; Set A size to 8-bit

    lda #:\1        ; Load palette bank address in memory to A
    sta $4304       ; Store A to DMA channel 0 source address bank register
    lda #\2         ; Load CG-RAM_Address to A
    sta $2121       ; Store A to Address for CG-RAM Write register

    stz $4300       ; Set 1-byte increment DMA channel transfer mode (0)
    lda #$22        ; Load address 0x22 as destination ($2122 - CG-RAM Data register)
    sta $4301       ; Store A to DMA channel destination address register

    lda #$01
    sta $420B       ; Set 1 to main DMA register. DMA Channel 0 transfer enable code.

    ; Restoring A and P values
    plp             ; Pop P from stack
    pla             ; Pop A from stack

.ENDM

; LoadVRAM VRAM_Label VRAM_Address Size
.macro LoadVRAM

    ; Saving current A, Y and P values
    pha             ; Push A to stack
    phy             ; Push Y to stack
    php             ; Push P to stack

    rep #$20        ; Set A size 16-bit
    sep #$10        ; Set X and Y size 8-bit
                    ; This actually sets 5th bit in P register to 1
                    ; 5th-bit in P sets X and Y registers size (if 1 - X and Y are 8-bit, if 0 - 16-bit)
                    ; By default it is set to 1 with sep #$30 command in snesinit.asm file
                    ; But we'll set it again just to be sure that 5th bit is 1 every time we use this macro

    ldy #$80        ; Load 0x80 to A
    sty $2115       ; Store A to $2115
                    ; $2115 - VRAM address increment value register
                    ; We set this to 0x80 to increment VRAM addres after $2119 access so we will be able to write entire word

    lda #\2         ; Load VRAM_Address to A
    sta $2116       ; Store A to Address for VRAM Read/Write registers

    lda #\3         ; Load Size value to DMA channel 0 transfer size registers
    sta $4305

    sep #20         ; Set A size 8-bit

    ; Setting VRAM source address to DMA registers the same way as in SetPalette macro

    lda #\1
    sta $4302
    lda #:\1
    sta $4304
    lda #$01        ; But this time we set 1 to $4300 which means word increment instead of byte increment
    sta $4300       
    lda #$18        ; This time we use $2118 (Data for VRAM Write register) as destination
    sta $4301

    ; Enable DMA channel 0 transfer
    lda #$01
    sta $420B

    ; Restoring X,Y and P values
    plp             ; Pop P from stack
    ply             ; Pop Y from stack
    pla             ; Pop A from stack

.ENDM

.macro ClearVRAM
   pha
   phx
   php

   REP #$30		; mem/A = 8 bit, X/Y = 16 bit
   SEP #$20

   LDA #$80
   STA $2115         ;Set VRAM port to word access
   LDX #$1809
   STX $4300         ;Set DMA mode to fixed source, WORD to $2118/9
   LDX #$0000
   STX $2116         ;Set VRAM port address to $0000
   STX $0000         ;Set $00:0000 to $0000 (assumes scratchpad ram)
   STX $4302         ;Set source address to $xx:0000
   LDA #$00
   STA $4304         ;Set source bank to $00
   LDX #$FFFF
   STX $4305         ;Set transfer size to 64k-1 bytes
   LDA #$01
   STA $420B         ;Initiate transfer

   STZ $2119         ;clear the last byte of the VRAM

   plp
   plx
   pla

.ENDM

;----------------------------------------------------------------------------
; ClearPalette -- Reset all palette colors to zero
; In: None
; Out: None
; Modifies: flags
;----------------------------------------------------------------------------
.macro ClearPalette
   PHX
   PHP
   REP #$30		; mem/A = 8 bit, X/Y = 16 bit
   SEP #$20

   STZ $2121
   LDX #$0100
ClearPaletteLoop:
   STZ $2122
   STZ $2122
   DEX
   BNE ClearPaletteLoop

   PLP
   PLX

.ENDM