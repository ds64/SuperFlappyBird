.EQU RecordScore    $031B       ; Best result score
.EQU LastPassedPipe $031D       ; Address of first sprite of LastPassedPipe
; Current score
.EQU Ones           $031F
.EQU Tens           $0320
.EQU Hundreds       $0321
.EQU Thousands      $0322
; Record Score
.EQU OnesRec        $0323
.EQU TensRec        $0324
.EQU HunRec         $0325
.EQU ThouRec        $0326

; Menu selection
.EQU MenuSelection  $0327

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

        ; Disable showing record score
        lda #$55
        sta $0201

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

recordScoreSpritesInit:
        ; Record score sprites init
        lda #(256/2 + 13)
        sta $001C
        lda #(256/2 + 24)
        sta $0018
        lda #(256/2 + 35)
        sta $0014
        lda #(256/2 + 46)
        sta $0010

        lda #(224/2 - 9)
        sta $0011
        sta $0015
        sta $0019
        sta $001D

        lda #$40
        sta $0012
        sta $0016
        sta $001A
        sta $001E

        lda #$30
        sta $0013
        sta $0017
        sta $001B
        sta $001F
        
        lda #$00
        sta $0201

        rts

        ; Increment score by 1 when passing a pipe
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
        clc
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

; Init high score table sprites
initHighScore:
        ; lda #(256/2 - 128)
        ; sta $01D0
        ; sta $01E0
        ; lda #(256/2 - 96)
        ; sta $01D0
        ; sta $01D8
        lda #(256/2 - 64)
        sta $0030
        sta $0040
        lda #(256/2 - 32)
        sta $0034
        sta $0044
        lda #(256/2 - 0)
        sta $0038
        sta $0048
        lda #(256/2 + 32)
        sta $003C
        sta $004C
        ; lda #(256/2 + 64)
        ; sta $01D4
        ; sta $01DC
        ; lda #(256/2 + 96)
        ; sta $01DC
        ; sta $01EC

        lda #(224/2 - 32)
        sta $0031
        sta $0035
        sta $0039
        sta $003D
        ; sta $01D1
        ; sta $01D5
        ; sta $01D9
        ; sta $01DD
        lda #(224/2)
        sta $0041
        sta $0045
        sta $0049
        sta $004D
        ; sta $01D9
        ; sta $01DD
        ; sta $01E9
        ; sta $01ED

        lda #$80
        sta $0032
        lda #$84
        sta $0036
        lda #$88
        sta $003A
        sta $003E
        ; sta $01D2
        ; sta $01D6
        ; sta $01DA
        ; sta $01DE
        ; sta $01E2
        ; sta $01E6
        ; sta $01EA
        ; sta $01EE
        ; lda #$8C
        ; sta $003E
        lda #$C0
        sta $0042
        lda #$C4
        sta $0046
        lda #$C8
        sta $004A  
        lda #$CC
        sta $004E

        lda #$30
        sta $0033
        sta $0037
        sta $003B
        sta $003F
        sta $0043
        sta $0047
        sta $004B
        sta $004F
        ; sta $01D3
        ; sta $01D7
        ; sta $01DB
        ; sta $01DF
        ; sta $01E3
        ; sta $01E7
        ; sta $01EB
        ; sta $01EF

        ; Arrow init
        lda #$00
        sta MenuSelection
        lda #(256/2 - 64)
        sta $0020
        lda #(224/2 + 5)
        sta $0021
        lda #$64
        sta $0022
        lda #$30
        sta $0023

        lda #$55
        sta $0202
        sta $0203
        sta $0204
        ; sta $021D
        ; sta $021E     

        rts

; Show high score table after game over
showHighScore
        php
        sep #$20
        ; Enable table
        lda #$AA
        sta $0203
        sta $0204
        ; sta $021D
        ; sta $021E
        ; Enable arrow
        lda #$54
        sta $0202

        ; Update arrow position
        lda MenuSelection
        jsr mult10
        clc
        adc #(224/2 + 5)
        sta $0021
        rep #$20

        jsr moveCurrentScoreSprites
        jsr calculateFinalScore
        plp

        rts

; Move score sprites so they will be displayed on high score table
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

; Calculate final score
calculateFinalScore:
        rep #$20
        lda Ones
        and #$00FF
        sta Temp
        lda Tens
        and #$00FF
        jsr mult10
        clc
        adc Temp
        sta Temp
        lda Hundreds
        and #$00FF
        jsr mult10
        jsr mult10
        clc
        adc Temp
        sta Temp
        lda Thousands
        and #$00FF
        jsr mult10
        jsr mult10
        jsr mult10
        clc
        adc Temp
        sta Temp
        sep #$20
        clc
        cmp RecordScore
        bpl updateRecord
updateReturn:
        jsr renderRecordScore
        rts

; Update record score components if needed
updateRecord:
        lda Temp
        sta RecordScore
        lda Ones
        sta OnesRec
        lda Tens
        sta TensRec
        lda Hundreds
        sta HunRec
        lda Thousands
        sta ThouRec
        jsr updateRecordSprites
        jmp updateReturn

; Show record on the high score table
renderRecordScore:
        lda #$00
        sta $0201
        rts

; Change record sprites if we have a new record
updateRecordSprites:
        php
        sep #$20
        lda OnesRec
        clc
        rol a
        cmp #$10
        bmi skipOnesRec
        jsr add16
skipOnesRec:
        clc
        adc #$40
        sta $0012
        lda TensRec
        rol a
        cmp #$10
        bmi skipTensRec
        jsr add16
skipTensRec:
        clc
        adc #$40
        sta $0016
        lda HunRec
        rol a
        cmp #$10
        bmi skipHundredsRec
        jsr add16
skipHundredsRec:
        clc
        adc #$40
        sta $001A
        lda ThouRec
        rol a
        cmp #$10
        bmi skipThousandsRec
        jsr add16
skipThousandsRec:
        clc
        adc #$40
        sta $001E
        rep #$20
        plp
        rts
.ENDS