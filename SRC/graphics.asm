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
.macro LoadPalette
    rep #$10        ; Set X and Y size to 16-bit
    lda #\2         ; Load CG-RAM_Address to A
    sta $2121       ; Store A to Address for CG-RAM Write register

    lda #:\1        ; Load palette bank address in memory to A
    ldx #\1         ; Load PaletteLabel address to X
    ldy #(\3 * 2)   ; Load 3rd macro parameter to Y which is Palette_Size
    jsr DMAPalette
.ENDM

; LoadBlockToVRAM Block_Addr VRAM_Address Size
.macro LoadBlockToVRAM
    rep #$10        ; Set X and Y size to 16-bit
    lda $80         ; Set VRAM transfer mode to word-access, increment by 1
    sta $2115

    ldx #\2         ; Load VRAM destination address to X
    stx $2116       ; Store X to Address for VRAM Read/Write registers

    lda #:\1        ; Load block src bank to A
    ldx #\1         ; Load block src offset to X
    ldy #\3         ; Load block size to Y
    jsr LoadVRAM
.ENDM

.BANK 0
.ORG 0
.SECTION "DMAPaletteCode" SEMIFREE
DMAPalette:
    ; Saving current B and P values
    phb         ; push current bank to stack
    php         ; push P register to stack

    stx $4302   ; Store X to DMA channel source address offset registers
    sta $4304   ; Store A into DMA channel 0 source bank register
    sty $4305   ; Store Y to DMA channel 0 transfer size register

    stz $4300   ; Set DMA Mode (byte, normal increment)
    lda #$22    ; Load address 0x22 as destination ($2122 - CG-RAM Data register)
    sta $4301   ; Store A to DMA channel destination address register
    lda #$01    ; Initiate DMA transfer on channel 0
    sta $420B

    sep #$10    ; Set X and Y size to 8-bit

    ; Restoring B and P values
    plp         ; Pop P from stack
    plb         ; Pop B from stack
    rts         ; return from subroutine
.ENDS

.BANK 0
.ORG 0
.SECTION "LoadVRAMCode" SEMIFREE
LoadVRAM:
    phb
    php         ; Preserve Registers

    stx $4302   ; Store X to DMA channel 0 source address offset register
    sta $4304   ; Store A to DMA channel 0 source address bank register
    sty $4305   ; Store Y to DMA channel 0 transfer size register

    lda #$01
    sta $4300   ; Set DMA mode (word, normal increment)
    lda #$18    ; Set the destination register ($2118 - VRAM write register)
    sta $4301
    lda #$01    ; Initiate DMA transfer (channel 0)
    sta $420B

    sep #$10    ; Set X and Y size to 8-bit

    plp         ; restore registers
    plb
    rts         ; return
.ENDS