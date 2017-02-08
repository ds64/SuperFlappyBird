; Variables stored in RAM
.EQU PlayerX $0300                      ; Player X coordinates
.EQU PlayerY $0302                      ; Player Y coordinates
.EQU PipeX $0304                        ; Pipe X starting coord
.EQU TilesTop $0306                     ; (Tiles rendered before gap -1). Should be set with values from 1 to 5
                                        ; The gap Y coordinate will be set from (TilesTop+1)*32 
                                        ; to (TilesTop+2)*32 pixels from top
.EQU PipeY $0308                        ; Pipe Y coordinate. Should be set with 0. Used in pipe cycle
.EQU CurrentSpriteTile $030A            ; Used to store current tile number to render.
.EQU SpriteAddress $030C                ; Address of current sprite info is stored here. 
                                        ; Used only to save this value after cycle
.EQU Counter $030E                      ; Counter used to count cycle repeat number
.EQU Temp $0310                         ; Temporary value to count address in sprite table 2
.EQU CurrentPipeBeginAddress $0312      ; Used to store current pipe sprites begin address
.EQU CurrentPipeEndAddress $0314        ; Used to store current pipe sprites end address
.EQU SpriteTable2InitValue $0316        ; Pipe initial 9th X coordinate is stored here
.EQU RandSeed $0318                     ; Used as a random seed counter
.EQU IsGameOver $031A                   ; Used to check if game is over. 0 - game over, 1 - game not over

.BANK 0 SLOT 0
.ORG 0
.SECTION "GameCode" SEMIFREE

playerSetup:
        ; Sprite Table 1 (4-bytes per sprite)         
        ; Byte 1:    xxxxxxxx    x: X coordinate
        ; Byte 2:    yyyyyyyy    y: Y coordinate
        ; Byte 3:    cccccccc    c: Starting tile #
        ; Byte 4:    vhoopppc    v: vertical flip h: horizontal flip  o: priority bits
        ;                        p: palette #

        ; Player Sprites
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

        lda #$01
        sta IsGameOver

        rts

pipeCycleConfig:
        ; Setting cycle variables
        ldy SpriteAddress
        ldx #0
        stx PipeX
        ldx #$00
        stx PipeY
        ldx #$01
        stx TilesTop
        ldx #$02
        stx CurrentSpriteTile
        ldx #$AA
        stx SpriteTable2InitValue
        ldx #$01
        stx Counter
        jsr pipeCycleMain

        ldy SpriteAddress
        ldx #102
        stx PipeX
        ldx #$00
        stx PipeY
        ldx #$01
        stx TilesTop
        ldx #$02
        stx CurrentSpriteTile
        ldx #$AA
        stx SpriteTable2InitValue
        ldx #$01
        stx Counter
        jsr pipeCycleMain

        ldy SpriteAddress
        ldx #204
        stx PipeX
        ldx #$00
        stx PipeY
        ldx #$01
        stx TilesTop
        ldx #$02
        stx CurrentSpriteTile
        ldx #$AA
        stx SpriteTable2InitValue
        ldx #$01
        stx Counter
        jsr pipeCycleMain

        ldy SpriteAddress
        ldx #51
        stx PipeX
        ldx #$00
        stx PipeY
        ldx #$01
        stx TilesTop
        ldx #$02
        stx CurrentSpriteTile
        ldx #$FF
        stx SpriteTable2InitValue
        ldx #$01
        stx Counter
        jsr pipeCycleMain

        ldy SpriteAddress
        ldx #153
        stx PipeX
        ldx #$00
        stx PipeY
        ldx #$01
        stx TilesTop
        ldx #$02
        stx CurrentSpriteTile
        ldx #$FF
        stx SpriteTable2InitValue
        ldx #$01
        stx Counter
        jsr pipeCycleMain

        rts
        ; Y register value will be used as indexed register for sprite table 1
        ; Do not modify its value during this cycle
pipeCycleMain:
        ; Store X coordinate in sprite table 1
        lda PipeX
        sta $00,Y
        iny

        ; Store Y coordinate in sprite table 1
        lda PipeY
        sta $00,Y
        iny

        ; Store tile number tp render in sprite table 1
        lda CurrentSpriteTile
        sta $00,Y

        ; Check if current rendered tile was $0A (Pipe entry from top).
        cmp #$0A
        beq pipeSetGap

        ; Check if current rendered tile was $06 (Pipe entry from bottom).
        cmp #$06
        beq pipeSetDefSprite
pipeReturnFromSetGap:
        iny
        ; Set vertical and horizontal flip, priority and palette to 0 in sprite table 1
        lda #$00
        sta $00,Y
        iny

        ; Check current rendered tiles number.
        ldx TilesTop
        cpx Counter
        beq pipeSetTop
pipeReturnFromSetTop:
        ; Increment next sprite Y coordinate by 32. (Our pipe tiles are 32x32)
        lda PipeY
        clc
        adc #32
        sta PipeY

        ; Check if we need to exit cycle or not
        lda Counter
        ina
        sta Counter
        cmp #$09
        bne pipeCycleMain
        jmp pipeEndCycle

pipeSetTop:
        ; Change next tile number to $0A
        ldx #$0A
        stx CurrentSpriteTile
        jmp pipeReturnFromSetTop

pipeSetGap:
        ; Set gap. Change next tile number to $06 and add 32 to Y coordinate
        ldx #$06
        stx CurrentSpriteTile
        lda PipeY
        clc
        adc #32
        clc
        adc #32
        sta PipeY
        jmp pipeReturnFromSetGap

pipeSetDefSprite:
        ; Rreturn tile number to $02. (Default pipe)
        ldx #$02
        stx CurrentSpriteTile
        jmp pipeReturnFromSetGap

pipeEndCycle:
        ; Save next sprite info in sprite table 1 address
        sty SpriteAddress

        ; Find address of info in sprite table 2 for this rendered pipe
        rep #$20
        lda SpriteAddress
.REPT 4
        ror A
        clc
.ENDR  
        and #$00FF
        sbc #$0002
        adc #$0200
        sta Temp
        sep #$20

        ldy Temp

        lda SpriteTable2InitValue
        sta $00,Y

        iny
        lda SpriteTable2InitValue
        sta $00,Y

        rts

pipeGet2ndTableAddress:
        rep #$20
        lda CurrentPipeBeginAddress
.REPT 4
        ror A
        clc
.ENDR
        and #$00FF
        adc #$0200
        sta Temp
        ldx Temp
        sep #$20
        rts

; Set new Y coordinate on entering the screen
pipeScrollY:
        lda RandSeed
        ror A
        and #$00FF
        sta RandSeed
PipeYCorrect:
        ldy CurrentPipeBeginAddress
        jsr pipeScrollYMainCycle
        ldy CurrentPipeBeginAddress
        lda $01, Y
        cmp #170
        bpl PipeYCycleExit
        ldy CurrentPipeBeginAddress
        lda $01, Y
        cmp #106
        bpl PipeYCorrect
PipeYCycleExit:
        rts 

pipeScrollYMainCycle:
.REPT 8
        iny
        lda $00,Y
        clc
        adc RandSeed
        sta $00,Y
        iny
        iny
        iny
.ENDR
        rts

.ENDS