.EQU RecordScore    $031B       ; Best result score
.EQU LastPassedPipe $031D       ; Address of first sprite of LastPassedPipe
; Current score
.EQU Ones           $031F
.EQU Tens           $0320
.EQU Hundreds       $0321
.EQU Thousands      $0322

.BANK 0 SLOT 0
.ORG 0
.SECTION "ScoreCode" SEMIFREE
scoreInit:
        ; Score values init
        lda #$00
        sta Ones
        sta Tens
        sta Hundreds
        sta Thousands

        rep #$20
        lda #$FFFF
        sta LastPassedPipe
        sep #$20

        ; Score sprites init
        lda #(256/2 + 11)
        sta $0000
        lda #(256/2)
        sta $0004
        lda #(256/2 - 11)
        sta $0008
        lda #(256/2 - 22)
        sta $000C

        lda #(224/8 - 8)
        sta $0001
        sta $0005
        sta $0009
        sta $000D

        lda #$40
        sta $0002
        sta $0006
        sta $000A
        sta $000E

        lda #$30
        sta $0003
        sta $0007
        sta $000B
        sta $000F
        
        lda #$00
        sta $0200

        jsr initHighScore

        rts

scoreIncrement:
        lda CurrentPipeBeginAddress
        cmp LastPassedPipe
        beq exitScoreIncCycle
        sta LastPassedPipe
        lda Ones
        ina
        cmp #10
        beq incTens
        sta Ones
exitScoreIncCycle:
        rts

incTens:
        lda #$00
        sta Ones
        lda Tens
        ina
        cmp #10
        beq incHundreds
        sta Tens
        jmp exitScoreIncCycle
incHundreds:
        lda #$00
        sta Tens
        lda Hundreds
        ina
        cmp #10
        beq incThousands
        sta Hundreds
        jmp exitScoreIncCycle
incThousands:
        lda #$00
        sta Hundreds
        lda Thousands
        ina
        cmp #10
        beq incSetThousandsToZero
        sta Thousands
        jmp exitScoreIncCycle
incSetThousandsToZero:
        lda #$00
        sta Thousands
        jmp exitScoreIncCycle


renderCurrentScore:
        lda Ones
        rol a
        cmp #$10
        bmi skipOnes
        jsr add16
skipOnes:
        clc
        adc #$40
        sta $0002
        lda Tens
        rol a
        cmp #$10
        bmi skipTens
        jsr add16
skipTens:
        clc
        adc #$40
        sta $0006
        lda Hundreds
        rol a
        cmp #$10
        bmi skipHundreds
        jsr add16
skipHundreds:
        clc
        adc #$40
        sta $000A
        lda Thousands
        rol a
        cmp #$10
        bmi skipThousands
        jsr add16
skipThousands:
        clc
        adc #$40
        sta $000E
        rts

add16:
        clc
        adc #16
        rts

initHighScore:
        lda #(256/2 - 64)
        sta $0020
        sta $0030
        lda #(256/2 - 32)
        sta $0024
        sta $0034
        lda #(256/2 - 0)
        sta $0028
        sta $0038
        lda #(256/2 + 32)
        sta $002C
        sta $003C

        lda #(224/2 - 32)
        sta $0021
        sta $0025
        sta $0029
        sta $002D
        lda #(224/2)
        sta $0031
        sta $0035
        sta $0039
        sta $003D

        lda #$80
        sta $0022
        lda #$84
        sta $0026
        lda #$88
        sta $002A
        lda #$8C
        sta $002E
        lda #$C0
        sta $0032
        lda #$C4
        sta $0036
        lda #$C8
        sta $003A  
        lda #$CC
        sta $003E

        lda #$30
        sta $0023
        sta $0027
        sta $002B
        sta $002F
        sta $0033
        sta $0037
        sta $003B
        sta $003F

        lda #$55
        sta $0202
        sta $0203     

        rts

showHighScore
        sep #$20
        lda #$AA
        sta $0202
        sta $0203
        rep #$20
        jsr moveCurrentScoreSprites

        rts

moveCurrentScoreSprites:
        lda #(256/2 + 13)
        sta $000C
        lda #(256/2 + 24)
        sta $0008
        lda #(256/2 + 35)
        sta $0004
        lda #(256/2 + 46)
        sta $0000

        lda #(224/2 - 26)
        sta $0001
        sta $0005
        sta $0009
        sta $000D

        rts
.ENDS