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
        lda #$00
        sta Tens
        lda #$00
        sta Hundreds
        lda #$00
        sta Thousands

        rep #$20
        lda #$FFFF
        sta LastPassedPipe
        sep #$20

        ; Score sprites init
        lda #(256/2 + 16)
        sta $0000
        lda #(224/8 - 8)
        sta $0001
        lda #$40
        sta $0002
        lda #$30
        sta $0003

        lda #(256/2)
        sta $0004
        lda #(224/8 - 8)
        sta $0005
        lda #$40
        sta $0006
        lda #$30
        sta $0007

        lda #(256/2 - 16)
        sta $0008
        lda #(224/8 - 8)
        sta $0009
        lda #$40
        sta $000A
        lda #$30
        sta $000B

        lda #(256/2 - 32)
        sta $000C
        lda #(224/8 - 8)
        sta $000D
        lda #$40
        sta $000E
        lda #$30
        sta $000F  

        lda #$00
        sta $0200

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

showHighScore:
        lda #(256/2 - 64)
        sta $00A0
        lda #(224/2 - 32)
        sta $00A1
        lda #$60
        sta $00A2
        lda #$30
        sta $00A3

        lda #(256/2 - 32)
        sta $00A4
        lda #(224/2 - 32)
        sta $00A5
        lda #$64
        sta $00A6
        lda #$30
        sta $00A7

        lda #(256/2 - 0)
        sta $00A8
        lda #(224/2 - 32)
        sta $00A9
        lda #$68
        sta $00AA
        lda #$30
        sta $00AB

        lda #(256/2 + 32)
        sta $00AC
        lda #(224/2 - 32)
        sta $00AD
        lda #$6B
        sta $00AE
        lda #$30
        sta $00AF

        lda #$AA
        sta $020A

        rts
.ENDS