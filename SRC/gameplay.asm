; Variables stored in RAM
.EQU PlayerX $0300                      ; Player X coordinates
.EQU PlayerY $0302                      ; Player Y coordinates
.EQU PipeX $0304                        ; Pipe X starting coord
.EQU PipeY $0305                        ; Pipe Y coordinate. Should be set with 0. Used in pipe cycle
.EQU CurrentSpriteTile $0306            ; Used to store current tile number to render.
.EQU SpriteAddress $0307                ; Address of current sprite info is stored here. 
                                        ; Used only to save this value after cycle
.EQU Counter $0308                      ; Counter used to count cycle repeat number
.EQU Temp $030A                         ; Temporary value to count address in sprite table 2
.EQU CurrentPipeBeginAddress $030C      ; Used to store current pipe sprites begin address
.EQU CurrentPipeEndAddress $030E        ; Used to store current pipe sprites end address
.EQU SpriteTable2InitValue $0310        ; Pipe initial 9th X coordinate is stored here
.EQU RandSeed $0312                     ; Used as a random seed counter
.EQU IsGameOver $0314                   ; Used to check if game is over. 0 - game over, 1 - game not over
.EQU PipeScrollSpeed $0315              ; Pipe scroll speed
.EQU PlayerYSpriteAddress $0317         ; Player Y sprite coordinate address in table 1
.EQU PipesStartAddress    $0319         ; Pipes sprites start address in table 1
.EQU CurrentState         $0328         ; 0 - title screen, 1 - game

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
        rep #$20
        lda #$0051
        sta PlayerYSpriteAddress
        sep #$20
        lda #(256/2 - 80)
        sta $0050
        sta PlayerX
        lda #(224/2 - 8)
        sta $0051
        sta PlayerY
        stz $0052
        lda #$30
        sta $0053

        ; Sprite Table 2 (2 bits per sprite)
        ; bits 0,2,4,6 - Enable or disable the X coordinate's 9th bit.
        ; bits 1,3,5,7 - Toggle Sprite size: 0 - small size   1 - large size
        ; 54 - 0101 0100
        lda #$54
        sta $0205

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
        ldx #$02
        stx CurrentSpriteTile
        ldx #$AA
        stx SpriteTable2InitValue
        ldx #$01
        stx Counter
        jsr pipeCycleMain

        ldy SpriteAddress
        ldx #128
        stx PipeX
        ldx #$00
        stx PipeY
        ldx #$02
        stx CurrentSpriteTile
        ldx #$AA
        stx SpriteTable2InitValue
        ldx #$01
        stx Counter
        jsr pipeCycleMain

        ldy SpriteAddress
        ldx #1
        stx PipeX
        ldx #$00
        stx PipeY
        ldx #$02
        stx CurrentSpriteTile
        ldx #$FF
        stx SpriteTable2InitValue
        ldx #$01
        stx Counter
        jsr pipeCycleMain

        ldy SpriteAddress
        ldx #129
        stx PipeX
        ldx #$00
        stx PipeY
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
        lda #$30
        sta $00,Y
        iny

        ; Check current rendered tiles number.
        ldx #$01
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
        ; Return tile number to $02. (Default pipe)
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

; Check pipe collision cycle
checkPipeCollision:

        ldy PipesStartAddress
        sty CurrentPipeBeginAddress

pipeCollisionNextIter:
        jsr pipeGet2ndTableAddress
        lda $00, X
        cmp #$AA
        bne nextPipe

        lda PlayerX
        clc
        adc #16
        sta Temp
        ldx CurrentPipeBeginAddress
        lda $00, X
        cmp Temp
        bpl nextPipe

        lda PlayerX
        sta Temp
        lda $00, X
        clc
        adc #32
        cmp Temp
        bmi nextPipe

        lda PlayerY
        sta Temp
        lda $01, X
        clc
        adc #64
        cmp Temp
        bpl pipeCollided

        lda PlayerY
        clc
        adc #16
        sta Temp
        lda $01, X
        clc
        adc #128
        cmp Temp
        bmi pipeCollided

        jsr scoreIncrement

nextPipe:
        lda CurrentPipeBeginAddress
        clc
        adc #$0020
        cmp SpriteAddress
        beq exitCollisionCycle
        sta CurrentPipeBeginAddress
        jmp pipeCollisionNextIter

pipeCollided:
        lda #$00
        sta IsGameOver

exitCollisionCycle:
        rts

; Pipe scrolling cycle
PipeScrolling:
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
        rts

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
        beq returnFromProc
        sta CurrentPipeBeginAddress
        jmp pipeScrollBegin

returnFromProc:
        rts

; Player fall
playerFall:
        lda PlayerY
        ldx PlayerYSpriteAddress
        sta $00,X
        rts

.ENDS