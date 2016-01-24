                include macros.s
                include mainsym.s

        ; Script 15, escort finish, hideout ambush setup

                org scriptCodeStart

                dc.w EscortScientistsFinish
                dc.w ThroneChief
                dc.w RadioFindFilter
                dc.w BeginAmbush
                dc.w RadioConstruct2

        ; Escort scientists sequence finish
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: various

EscortScientistsFinish:
                ldx actIndex
                ldy actT,x
                lda npcBrakeTbl-ACT_FIRSTPERSISTENTNPC,y
                jsr BrakeActorX  ;Move at slightly different speed to not look stupid
                lda actXH,x
                cmp npcStopPos-ACT_FIRSTPERSISTENTNPC,y
                bcc ESF_Stop
                lda #JOY_LEFT
                sta actMoveCtrl,x
                lda #AIMODE_IDLE
                beq ESF_StoreMode
ESF_Stop:       cpy #ACT_SCIENTIST3
                bne ESF_NoDialogue
                lda actSX,x
                bne ESF_NoDialogue
                lda #$00                        ;Stop actor script exec for now
                sta actScriptF
                sta actScriptF+1
                ldy #ACT_SCIENTIST2
                gettext txtEscortFinish
                jmp SpeakLine
ESF_NoDialogue: lda #AIMODE_TURNTO
ESF_StoreMode:  sta actAIMode,x
                rts

        ; Throne chief corpse
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: various

ThroneChief:    lda #ITEM_BIOMETRICID           ;Todo: cutscene
                sta temp2
                ldx #1
                jsr AddItem
                jsr TP_PrintItemName
SetupAmbush:    lda #<EP_BEGINAMBUSH            ;On next zone transition
                ldx #>EP_BEGINAMBUSH
                jmp SetZoneScript

        ; Find filter script. Also move scientists to final positions before surgery
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: various

RadioFindFilter:jsr StopZoneScript
                lda #ACT_SCIENTIST3
                jsr FindLevelActor
                lda #$3f
                ldx #$30+AIMODE_TURNTO
                jsr MoveScientistSub2
                lda #ACT_SCIENTIST2
                jsr FindLevelActor
                lda #$42
                ldx #$00+AIMODE_TURNTO
                jsr MoveScientistSub2
                lda #<EP_BEGINSURGERY
                ldx #>EP_BEGINSURGERY
                sta actScriptEP
                stx actScriptF
                jsr SetupAmbush
                gettext txtRadioFindFilter
RadioMsg:       ldy #ACT_PLAYER
                jsr SpeakLine
                lda #SFX_RADIO
                jmp PlaySfx
MoveScientistSub2:
                sta lvlActX,y                   ;Set also Y & level so that this can be used as shortcut in testing
                lda #$56
                sta lvlActY,y
                txa
                sta lvlActF,y
                lda #$08+ORG_GLOBAL
                sta lvlActOrg,y
BA_Skip:        rts

        ; Begin hideout ambush
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: various

BeginAmbush:    jsr StopZoneScript
                lda #PLOT_ELEVATOR1             ;No action until elevator fixed and has the biometric ID
                jsr GetPlotBit
                beq BA_Skip
                ldy #ITEM_BIOMETRICID
                jsr FindItem
                bcc BA_Skip
                lda #PLOT_HIDEOUTOPEN           ;Already resolved?
                jsr GetPlotBit
                beq BA_Skip
                lda #PLOT_HIDEOUTAMBUSH         ;Already happening?
                jsr GetPlotBit
                bne BA_Skip
                lda #ACT_HACKER                 ;Check that Jeff is in hideout
                jsr FindLevelActor
                lda lvlActOrg,y
                cmp #$04+ORG_GLOBAL
                bne BA_Skip
                lda #PLOT_HIDEOUTAMBUSH
                jsr SetPlotBit
                ldy lvlDataActBitsStart+$04     ;Enable ambush enemies now
                lda lvlStateBits+2,y
                ora #$c0
                sta lvlStateBits+2,y
                lda lvlStateBits+3,y
                ora #$03
                sta lvlStateBits+3,y
                lda #<EP_HACKERAMBUSH
                sta actScriptEP+2
                lda #>EP_HACKERAMBUSH
                sta actScriptF+2
                lda #<EP_RADIOCONSTRUCT2
                ldx #>EP_RADIOCONSTRUCT2
                jmp SetScript

        ; Radio briefing on Construct, part 2 (when ambush begins)
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: various

RadioConstruct2:jsr StopScript
                gettext txtRadioConstruct2
                jmp RadioMsg

        ; Tables

npcStopPos:     dc.b $4e,$4d
npcBrakeTbl:    dc.b 4,0

        ; Messages
        ; Reordered to compress better

txtRadioFindFilter:
                dc.b 34,"LINDA HERE. WE GOT AHEAD OF OURSELVES - THERE'S NO LUNG FILTERS STORED IN HERE. AMOS IS QUITE ANGRY WITH HIMSELF. "
                dc.b "SINCE YOU'RE MUCH BETTER SUITED TO EXPLORING, "
                dc.b "WE'LL HAVE TO ASK YOU TO FIND ONE. THERE SHOULD BE AT LEAST ONE PACKAGE IN THE LOWER LABS SOMEWHERE.",34,0

txtEscortFinish:dc.b 34,"WE'D NEVER HAVE MADE IT ALONE. NOW WE NEED TIME TO SET UP. WE'LL GIVE YOU A CALL WHEN READY.",34,0

txtRadioConstruct2:
                dc.b 34,"IT'S JEFF. SAW YOU FOUND ACCESS TO THE BIO-DOME. NASTY. IT'S POSSIBLE THE AI IS SITUATED SOMEWHERE INSIDE. "
                dc.b "FOUND ALSO SOMETHING MORE. THERE'S A BLACKOUT TO THE OUTSIDE, RIGHT? BUT A DEDICATED LINK "
                dc.b "WAS INSTALLED FOR THE MILITARY CONTRACT. I CAN SEE THAT THERE'S TRAFFIC ON IT, BUT CAN'T SEE WHAT WITHOUT "
                dc.b "PHYSICAL ACCESS. I BET IT'S THE AI. HMM.. WHAT? I'M SEEING MOVE-",34," (STATIC)",0

                checkscriptend