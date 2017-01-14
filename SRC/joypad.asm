.ENUM $0304
Joy1Raw DW
Joy1Press DW
Joy1Hold DW
.ENDE

; Register $4200: Counter Enable (1b/W)
; n-vh---j        n: NMI enable                   v: vertical counter enable
;                 h: horizontal enable register   j: joypad enable

; Register $4212: Status Register (1b/RW)
; vh-----j        v:  0 = Not in VBlank state.
;                     1 = In VBlank state.
;                 h:  0 = Not in HBlank state.
;                     1 = In HBlank state.
;                 j:  0 = Joypad not ready.
;                     1 = Joypad ready.

; Register $4218: Joypad #1 status register (Low Byte) (1b/R)
; axlriiii        a: A button
;                 x: X button
;                 l: L
;                 r: R
;                 i: Identification code

; Register $4219: Joypad #1 status register (High Byte) (1b/R)
; bystudlr
;                 b: B button                u: Up
;                 y: Y button                d: Down
;                 s: Select                  l: Left
;                 t: Start                   r: Right

; Input Cheat Sheet
; $4218
; $80 = A
; $40 = X
; $20 = L
; $10 = R
; 
; $4219:
; $80 = B
; $40 = Y
; $20 = Select
; $10 = Start
; $08 = Up
; $04 = Down
; $02 = Left
; $01 = Right

; $4218
.EQU Button_A      $80
.EQU Button_X      $40
.EQU Button_L      $20
.EQU Button_R      $10

; $4219
.EQU Button_B      $80
.EQU Button_Y      $40
.EQU Button_Select $20
.EQU Button_Start  $10
; D-PAD
.EQU Dpad_Up       $08
.EQU Dpad_Down     $04
.EQU Dpad_Left     $02
.EQU Dpad_Right    $01

.BANK 0
.ORG 0
.SECTION "JoypadCode" SEMIFREE
Joypad:
    lda $4212
    and #$01
    bne Joypad

    rep #$30

    ldx Joy1Raw     ; Read last frame joypad status
    lda $4218       ; Read this frame joypad status
    sta Joy1Raw     ; Store this frame joypad status to Joy1Raw
    txa             ; Transfer last frame status from X to A
    eor Joy1Raw     ; Get buttons with changed states
    and Joy1Raw     ; Get only pressed buttons
    sta Joy1Press   ; Save to Joy1Press
    txa             ; Transfer last fram status from X to A
    and Joy1Raw     ; Find buttons that are still pressed
    sta Joy1Hold    ; Save to Joy1Hold

    sep #$20
    ldx #$0000

    lda $4016
    bne _done
    stx Joy1Raw
    stx Joy1Press
    stx Joy1Press

_done:
    RTS
.ENDS
    
