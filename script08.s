                include macros.s
                include mainsym.s

        ; Script 8, nether tunnels interactions

                org scriptCodeStart

                dc.w TunnelMachine
                dc.w TunnelMachineItems
                dc.w TunnelMachineRun
                dc.w RadioJormungandr
                dc.w RadioJormungandrRun
                dc.w AfterSurgery
                dc.w AfterSurgeryRun
                dc.w AfterSurgeryZone
                dc.w AfterSurgeryNoAir
                dc.w AfterSurgeryFollow
                dc.w AfterSurgeryNoAirDie
                
        ; Tunnel machine script routine
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: various

tmChoice        = menuCounter

TunnelMachine:  lda #PLOT_BATTERY
                jsr GetPlotBit
                beq TM_NoBattery
                lda #PLOT_FUEL
                jsr GetPlotBit
                beq TM_NoFuel
                lda #$00
                sta tmTime1
                sta tmTime2
                sta tmChoice
                lda #<EP_TUNNELMACHINERUN
                ldx #>EP_TUNNELMACHINERUN
                jsr SetScript
                ldx #MENU_INTERACTION
                jsr SetMenuMode
                lda #<txtReady
                ldx #>txtReady
                jsr PrintPanelTextIndefinite
                jmp TMR_RedrawNoSound
TM_NoBattery:   lda #<txtNoBattery
                ldx #>txtNoBattery
                bne TM_TextCommon
TM_NoFuel:      lda #1
                sta shakeScreen
                lda #SFX_GENERATOR
                jsr PlaySfx
                lda #<txtNoFuel
                ldx #>txtNoFuel
TM_TextCommon:  ldy #REQUIREMENT_TEXT_DURATION
                jmp PrintPanelText

        ; Tunnel machine decision runloop
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: various

TunnelMachineRun:
                inc tmTime1
                lda tmTime1
                and #$01
                sta shakeScreen
                inc tmTime2
                lda tmTime2
                cmp #3
                bcc TMR_NoSound
                lda #$00
                sta tmTime2
                lda #SFX_GENERATOR
                jsr PlaySfx
TMR_NoSound:    lda joystick
                and #JOY_DOWN
                bne TMR_Finish
                lda keyType
                bpl TMR_Finish
                jsr GetFireClick
                bcs TMR_Decision
                jsr MenuControl
                ldy tmChoice
                lsr
                bcs TMR_MoveLeft
                lsr
                bcs TMR_MoveRight
TMR_NoMove:     rts
TMR_MoveLeft:   tya
                beq TMR_NoMove
                dey
                sty tmChoice
TMR_Redraw:     lda #SFX_SELECT
                jsr PlaySfx
TMR_RedrawNoSound:
                ldy #$00
TMR_RedrawLoop: ldx tmArrowPosTbl,y
                lda #$20
                cpy tmChoice
                bne TMR_NoArrow
                lda #62
TMR_NoArrow:    jsr PrintPanelChar
                iny
                cpy #2
                bcc TMR_RedrawLoop
                rts
TMR_MoveRight:  tya
                bne TMR_NoMove
                iny
                sty tmChoice
                bne TMR_Redraw
TMR_Decision:   lda tmChoice
                bne TMR_Drive
TMR_Finish:     jsr StopScript
                jmp SetMenuMode                 ;X=0 on return
TMR_Drive:      jsr AddQuestScore
                jsr TMR_Finish
                lda #$00
                sta tmTime1                     ;TODO: replace with cutscene
                jsr BlankScreen
TMR_BreakWallLoop:
                jsr WaitBottom
                jsr Random
                cmp #$40
                bcs TMR_BreakWallNoSound
                lda #$00
                sta PSfx_LastSfx+1
                lda #SFX_EXPLOSION
                jsr PlaySfx
TMR_BreakWallNoSound:
                inc tmTime1
                bpl TMR_BreakWallLoop
                lda #PLOT_WALLBREACHED
                jsr SetPlotBit
                lda #$32
                jmp ULO_EnterDoorDest

        ; Tunnel machine item installation script routines
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: various

TunnelMachineItems:
                lda itemIndex
                cmp #ITEM_TRUCKBATTERY
                bne TMI_Fuel
TMI_Battery:    lda #PLOT_BATTERY
                jsr SetPlotBit
                lda #<txtBatteryInstalled
                ldx #>txtBatteryInstalled
                bne TMI_Common
TMI_Fuel:       lda #PLOT_FUEL
                jsr SetPlotBit
                lda #<txtRefueled
                ldx #>txtRefueled
TMI_Common:     jsr TM_TextCommon
                ldy itemIndex
                jsr RemoveItem
                jsr AddQuestScore
                lda #SFX_POWERUP
                jmp PlaySfx

        ; Jormungandr speaks
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: various

RadioJormungandr:lda #<EP_RADIOJORMUNGANDRRUN
                ldx #>EP_RADIOJORMUNGANDRRUN
                jsr SetScript
                lda #SFX_RADIO
                jsr PlaySfx
                ldy #ACT_PLAYER
                lda #<txtRadioJormungandr
                ldx #>txtRadioJormungandr
                jmp SpeakLine

        ; Jormungandr speaks, running script (screen shake)
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: various

RadioJormungandrRun:
                lda menuMode
                beq RJR_Stop
                jsr Random
                and #$01
                sta shakeScreen
                rts
RJR_Stop:       jmp StopScript

        ; After surgery ambush
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: various

AfterSurgery:   lda scriptVariable
                asl
                tay
                lda asJumpTbl,y
                sta AS_Jump+1
                lda asJumpTbl+1,y
                sta AS_Jump+2
AS_Jump:        jmp $0000

AS_1:           jsr AfterSurgeryRun             ;Ensure player position right when the screen turns on
                lda upgrade
                ora #UPG_TOXINFILTER
                sta upgrade                     ;Has the filter upgrade now
                lda #HP_PLAYER                  ;Always full HP, as there will be an attack
                sta actHp+ACTI_PLAYER
                lda battery+1                   ;Ensure minimal battery, as there will be EMP attacks
                cmp #LOW_BATTERY
                bcs AS_1BatteryOK
                lda #LOW_BATTERY
                sta battery+1
AS_1BatteryOK:  jsr AddQuestScore
                lda #SFX_POWERUP
                jsr PlaySfx
                inc scriptVariable
                ldy #ACT_SCIENTIST2
                lda #<txtAfterSurgery_1
                ldx #>txtAfterSurgery_1
                jmp SpeakLine

AS_2:           jsr Random
                and #$01
                sta shakeScreen
                jsr Random
                cmp #$10
                bcs AS_2NoExplosion
                jsr HeavyShake
AS_2NoExplosion:lda #ACT_SCIENTIST3
                jsr FindActor
                inc actTime,x
                lda actTime,x
                cmp #50
                bcc AS_2Wait
                inc scriptVariable
AS_2Wait:       rts

AS_3:           inc scriptVariable
                ldy #ACT_SCIENTIST3
                lda #<txtAfterSurgery_2
                ldx #>txtAfterSurgery_2
                jmp SpeakLine

AS_4:           lda #ACT_HIGHWALKER
                jsr FindLevelActor
                lda lvlActY,y                   ;Unhide waiting enemy now
                and #$7f
                sta lvlActY,y
                inc scriptVariable
                lda #ACT_SCIENTIST2
                jsr FindActor
                lda #AIMODE_IDLE
                sta actAIMode,x
                lda #HP_SCIENTIST1              ;Make possible to die
                sta actHp,x
HeavyShake:     lda #SFX_EXPLOSION              ;One final shake + explosion
                jsr PlaySfx
                lda #$02
                sta shakeScreen
                rts

AS_5:           lda #ACT_HIGHWALKER
                jsr FindActor
                bcc AS_5Wait
                lda actXH,x
                cmp #$46
                php
                lda #ACT_SCIENTIST2
                jsr FindActor
                plp
                lda #JOY_DOWN+JOY_RIGHT
                bcc AS_5Duck
                lda #0
AS_5Duck:       sta actMoveCtrl,x
                lda actF1,x
                cmp #FR_DIE+2
                bcc AS_5Wait
AS_5Done:       lda #ACT_SCIENTIST3
                jsr FindActor
                lda #AIMODE_SNIPER
                sta actAIMode,x
                inc scriptVariable
AS_6Wait:
AS_5Wait:       rts

AS_6:           lda #ACT_HIGHWALKER
                jsr FindActor
                bcs AS_6Wait
                lda #ACT_EXPLOSIONGENERATORRISING
                jsr FindActor
                bcs AS_6Wait
                inc scriptVariable
                ldy #ACT_SCIENTIST3
                lda #<txtAfterSurgery_3
                ldx #>txtAfterSurgery_3
                jmp SpeakLine

AS_7:           ldx #ACTI_PLAYER                ;Player regains control
                lda #-9*8
                jsr MoveActorX
                lda #8*8
                jsr MoveActorY
                jsr NoInterpolation
                jsr StopScript
                lda #FR_STAND
                sta actF1+ACTI_PLAYER
                sta actF2+ACTI_PLAYER
                inc scriptVariable
AS_8Wait:       rts

AS_8:           lda actXH+ACTI_PLAYER
                cmp #$40
                beq AS_8Wait
                lda #<EP_AFTERSURGERYFOLLOW   ;Change to following script
                sta actScriptEP+1
                ldy #ACT_SCIENTIST3
                lda #<txtAfterSurgery_4
                ldx #>txtAfterSurgery_4
                jmp SpeakLine

asJumpTbl:      dc.w AS_1
                dc.w AS_2
                dc.w AS_3
                dc.w AS_4
                dc.w AS_5
                dc.w AS_6
                dc.w AS_7
                dc.w AS_8

        ; After surgery continuous script, keep player in place
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: various

AfterSurgeryRun:lda joystick
                and #JOY_FIRE                   ;Fire must be possible to advance dialogue
                sta joystick
                lda #$00
                sta actXL+ACTI_PLAYER
                sta actD+ACTI_PLAYER
                sta actSY+ACTI_PLAYER
                lda #FR_DIE+2
                sta actF1+ACTI_PLAYER
                sta actF2+ACTI_PLAYER
                lda #$58
                sta actYL+ACTI_PLAYER
                lda #$41
                sta actXH+ACTI_PLAYER
                lda #$55
                sta actYH+ACTI_PLAYER
ASZ_AlreadySet: rts

        ; After surgery zone script
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: various

AfterSurgeryZone:
                lda levelNum
                cmp #$08
                bne ASZ_Stop
                lda #ACT_SCIENTIST3
                jsr TransportNPCToPlayer
                lda #PLOT_LOWERLABSNOAIR
                jsr GetPlotBit
                bne ASZ_AlreadySet
                lda #$00
                sta UA_SpawnDelay+1             ;Wait a bit before next dialogue, ensure
                lda #<EP_AFTERSURGERYNOAIR      ;no enemy spawn in the meanwhile
                sta actScriptEP+1
                lda #PLOT_LOWERLABSNOAIR
                jmp SetPlotBit
ASZ_Stop:       jmp StopZoneScript

        ; After surgery follow script (refresh follow mode & zone script)
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: various

AfterSurgeryFollow:
                ldx actIndex
                lda oxygen              ;Die if run out of oxygen,
                beq ASF_Die             ;almost reach lift,
                lda actXH+ACTI_PLAYER   ;or if player goes to nether tunnel
                cmp #$39
                bcc ASF_Die
                cmp #$6d
                bcc ASF_CoordOK
                lda actYH+ACTI_PLAYER
                cmp #$53
                bcs ASF_Die
ASF_CoordOK:    lda #AIMODE_FOLLOW
                sta actAIMode,x
                lda #ACTI_PLAYER
                sta actAITarget,x
                lda #<EP_AFTERSURGERYZONE
                ldx #>EP_AFTERSURGERYZONE
                jmp SetZoneScript
ASF_Die:        ldx actIndex
                lda #AIMODE_IDLE
                sta actAIMode,x
                lda #JOY_DOWN
                sta actMoveCtrl,x
                lda #75
                sta actTime,x
                lda actSX,x                 ;Wait for zero X-speed for the speech bubble
                bne ASF_DieWait
                jsr StopZoneScript
                ldx actIndex
                lda #-15*8
                sta temp4
                lda #ITEM_EMPGENERATOR
                jsr DI_ItemNumber
                lda #ITEM_NONE
                sta actWpn,x
                lda #<EP_AFTERSURGERYNOAIRDIE
                sta actScriptEP+1
                ldy #ACT_SCIENTIST3
                lda #<txtAfterSurgeryNoAirDie
                ldx #>txtAfterSurgeryNoAirDie
                jmp SpeakLine
ASF_DieWait:    rts

        ; After surgery "no air" dialogue
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: various

AfterSurgeryNoAir:
                ldx actIndex                    ;Stay in place until dialogue
                lda #AIMODE_TURNTO              ;so that speech bubble doesn't levitate
                sta actAIMode,x
                lda oxygen                      ;Let player notice first
                cmp #MAX_OXYGEN-5
                bcs ASNA_Wait
                lda #<EP_AFTERSURGERYFOLLOW     ;Restore follow script again
                sta actScriptEP+1
                ldy #ACT_SCIENTIST3
                lda #<txtAfterSurgeryNoAir
                ldx #>txtAfterSurgeryNoAir
                jmp SpeakLine
ASNAD_NotRemoved:
ASNA_Wait:      rts

        ; NPC death when running out of oxygen
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: various

AfterSurgeryNoAirDie:
                ldx actIndex
                jsr SetNotPersistent
                lda #JOY_DOWN
                sta actMoveCtrl,x
                jmp DeathFlickerAndRemove

        ; Tables & variables

tmArrowPosTbl:  dc.b 9,14
tmTime1:        dc.b 0
tmTime2:        dc.b 0

        ; Messages

txtNoBattery:   dc.b "BATTERY DEAD",0
txtNoFuel:      dc.b "NO FUEL",0
txtBatteryInstalled:
                dc.b "NEW BATTERY INSTALLED",0
txtRefueled:    dc.b "REFUELED",0
txtReady:       dc.b " STOP DRIVE",0

txtRadioJormungandr:
                dc.b 34,"GREETINGS SEMI-HUMAN. I AM JORMUNGANDR. I RESIDE BEYOND THE DEAD END IN FRONT OF YOU. "
                dc.b "TURN BACK NOW, THERE IS NOTHING YOU CAN GAIN BY PROCEEDING. WHEN I RECEIVE THE SIGNAL "
                dc.b "FROM MY MASTER, OR IF HE SHOULD FALL SILENT, I WILL TRAVEL THE CRUST AND MAKE THE EARTH BREATHE "
                dc.b "FIRE AND ASH, BRINGING THE POST-HUMAN AGE. AND SHOULD I FALL, HE WILL AVENGE ME.",34,0

txtAfterSurgery_1:
                dc.b 34,"MINOR COMPLICATIONS. THE RESTORATIVE NANO-BOTS WILL TAKE CARE.",34,0
txtAfterSurgery_2:
                dc.b 34,"WHAT'S THAT?",34,0
txtAfterSurgery_3:
                dc.b 34,"AMOS.. TOO LATE.",34,0
txtAfterSurgery_4:
                dc.b 34,"YOU OK? WE NEED TO GET OUT OF HERE.",34,0
txtAfterSurgeryNoAir:
                dc.b 34,"DO YOU NOTICE? IT'S HARDER TO BREATH. DAMN.. IT'S THE AI DOING THIS!",34,0
txtAfterSurgeryNoAirDie:
                dc.b 34,"CAN'T.. MAKE IT FURTHER. YOU GO..",34,0

                checkscriptend