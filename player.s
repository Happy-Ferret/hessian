        ; Scrolling center position in chars

SCRCENTER_X     = 19
SCRCENTER_Y     = 13

        ; Fixed human frame numbers

FR_STAND        = 0
FR_WALK         = 1
FR_JUMP         = 9
FR_DUCK         = 12
FR_DIE          = 14
FR_CLIMB        = 17
FR_ROLL         = 21
FR_PREPARE      = 27
FR_ATTACK       = 29

HEALTH_RECHARGE_DELAY = 50

DEATH_DISAPPEAR_DELAY = 75
DEATH_FLASH_DELAY = 25
DEATH_HEIGHT    = -3                            ;Ceiling check height for dead bodies
DEATH_YSPEED    = -5*8
DEATH_MAX_XSPEED = 6*8
DEATH_ACCEL     = 6
DEATH_BRAKING   = 6

HUMAN_MAX_YSPEED = 6*8

        ; Player update routine
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y,temp1-temp8,loader temp vars

MovePlayer:     lda actHp,x                     ;Restore health if not dead and not at
                beq MP_NoHealthRecharge         ;full health
                cmp #HP_PLAYER
                bcs MP_NoHealthRecharge
                inc healthRecharge              ;Health recharge: recharge fast when health
                bmi MP_NoHealthRecharge         ;low, slower when more health
                asl
                cmp healthRecharge
                bcs MP_NoHealthRecharge
                lda #$00
                sta healthRecharge
                inc actHp,x
MP_NoHealthRecharge:
                lda actCtrl,x
                sta actPrevCtrl,x
                lda joystick
                sta actCtrl,x
                cmp #JOY_FIRE
                bcc MP_NewMoveCtrl
                and #$0f                        ;When fire held down, eliminate the opposite
                tay                             ;directions from the previous move control
                lda moveCtrlAndTbl,y
                ldy actF1,x                     ;If holding a duck, keep the down direction
                cpy #FR_DUCK+1                  ;regardless of joystick position
                bne MP_NotDucked
                ora #JOY_DOWN
MP_NotDucked:   and actMoveCtrl,x
MP_NewMoveCtrl: sta actMoveCtrl,x

        ; Humanoid character move and attack routine
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y,temp1-temp8,loader temp vars

MoveAndAttackHuman:
                jsr MoveHuman
                jmp AttackHuman

        ; Humanoid character move routine
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y,temp1-temp8,loader temp vars

MH_DeathAnim:   lda #DEATH_HEIGHT                ;Actor height for ceiling check
                sta temp4
                lda #DEATH_ACCEL
                ldy #HUMAN_MAX_YSPEED
                jsr MoveWithGravity             ;Actually move & check collisions
                lsr
                bcs MH_DeathGrounded
                lda #FR_DIE
                ldy actSY,x
                bmi MH_DeathSetFrame
                lda #FR_DIE+1
                bne MH_DeathSetFrame
MH_DeathGrounded:
                lda #DEATH_BRAKING
                jsr BrakeActorX
                lda #FR_DIE+2
MH_DeathSetFrame:
                sta actF1,x
                sta actF2,x
                bcc MH_DeathDone
MH_DeathCheckRemove:
                dec actTime,x
                bmi MH_DeathRemove
                lda actTime,x
                cmp #DEATH_FLASH_DELAY
                bne MH_DeathDone
                lda #$80
                sta actC,x
MH_DeathDone:   rts
MH_DeathRemove: jmp RemoveActor

MoveHuman:      ldy #AL_SIZEUP                  ;Set size up based on currently displayed
                lda (actLo),y                   ;frame
                ldy actF1,x
                sec
                sbc humanSizeReduceTbl,y
                sta actSizeU,x
                lda actMoveFlags,x
                sta temp1
                lda #$00                        ;Roll flag
                sta temp2
                ldy #AL_MOVECAPS
                lda (actLo),y
                sta temp3                       ;Movement capabilities
                iny
                lda (actLo),y
                sta temp4                       ;Movement speed
                lda actF1,x                     ;Check if climbing
                cmp #FR_DIE
                bcc MH_NoRoll
                cmp #FR_CLIMB
                bcc MH_DeathAnim
                cmp #FR_ROLL                    ;If rolling, automatically accelerate
                bcs MH_Rolling                  ;to facing direction
                jmp MH_Climbing
MH_Rolling:     inc temp2
                lda actD,x
                bmi MH_AccLeft
                bpl MH_AccRight
MH_NoRoll:      cmp #FR_DUCK+1
                lda actMoveCtrl,x               ;Check turning / X-acceleration / braking
                and #JOY_LEFT
                beq MH_NotLeft
                lda #$80
                sta actD,x
                bcs MH_Brake                    ;If ducking, brake
MH_AccLeft:     lda temp1
                lsr                             ;Faster acceleration when on ground
                ldy #AL_GROUNDACCEL
                bcs MH_OnGroundAccL
                ldy #AL_INAIRACCEL
MH_OnGroundAccL:lda (actLo),y
                ldy temp4
                jsr AccActorXNeg
                jmp MH_NoBraking
MH_NotLeft:     lda actMoveCtrl,x
                and #JOY_RIGHT
                beq MH_NotRight
                lda #$00
                sta actD,x
                bcs MH_Brake                    ;If ducking, brake
MH_AccRight:    lda temp1
                lsr                             ;Faster acceleration when on ground
                ldy #AL_GROUNDACCEL
                bcs MH_OnGroundAccR
                ldy #AL_INAIRACCEL
MH_OnGroundAccR:lda (actLo),y
                ldy temp4
                jsr AccActorX
                jmp MH_NoBraking
MH_NotRight:    lda temp1                       ;No braking when jumping
                lsr
                bcc MH_NoBraking
MH_Brake:       ldy #AL_BRAKING                 ;When grounded and not moving, brake X-speed
                lda (actLo),y
                jsr BrakeActorX
MH_NoBraking:   lda temp1
                and #AMF_HITWALL|AMF_LANDED     ;If hit wall (and did not land simultaneously), reset X-speed
                cmp #AMF_HITWALL
                bne MH_NoHitWall
                lda temp3
                and #AMC_WALLFLIP
                beq MH_NoWallFlip
                lda temp1                       ;Check for wallflip (push joystick up & opposite to wall)
                lsr
                bcs MH_NoWallFlip
                lda actSY,x                     ;Must not have started descending yet
                bpl MH_NoWallFlip
                lda #JOY_UP|JOY_RIGHT
                ldy actSX,x
                beq MH_NoWallFlip
                bmi MH_WallFlipRight
                lda #JOY_UP|JOY_LEFT
MH_WallFlipRight:
                cmp actMoveCtrl,x
                bne MH_NoWallFlip
                ldy #AL_HALFSPEEDRIGHT
                cmp #JOY_UP|JOY_RIGHT
                beq MH_WallFlipRight2
                ldy #AL_HALFSPEEDLEFT
MH_WallFlipRight2:
                lda (actLo),y
                sta actSX,x
                bne MH_StartJump
MH_NoWallFlip:  lda #$00
                sta actSX,x
MH_NoHitWall:   lda temp1
                lsr                             ;Grounded bit to C
                and #AMF_HITCEILING/2
                bne MH_NoNewJump
                bcc MH_NoNewJump
                lda actCtrl,x                   ;When holding fire can not initiate jump
                and #JOY_FIRE                   ;or grab a ladder
                bne MH_NoNewJump
                lda actMoveCtrl,x               ;If on ground, can initiate a jump
                and #JOY_UP                     ;except if in the middle of a roll
                beq MH_NoNewJump
                lda temp2
                bne MH_NoNewJump
                lda temp3
                and #AMC_CLIMB
                beq MH_NoInitClimbUp
                jsr GetCharInfo4Above           ;Jump or climb?
                and #CI_CLIMB
                beq MH_NoInitClimbUp
                jmp MH_InitClimb
MH_NoInitClimbUp:
                lda temp3
                and #AMC_JUMP
                beq MH_NoNewJump
                lda actPrevCtrl,x
                and #JOY_UP
                bne MH_NoNewJump
MH_StartJump:   ldy #AL_JUMPSPEED
                lda (actLo),y
                sta actSY,x
                lda #$00                        ;Reset grounded flag manually for immediate
                sta actMoveFlags,x              ;jump physics
MH_NoNewJump:   ldy #AL_HEIGHT                  ;Actor height for ceiling check
                lda (actLo),y
                sta temp4
                ldy #AL_FALLACCEL               ;Make jump longer by holding joystick up
                lda actSY,x                     ;as long as still has upward velocity
                bpl MH_NoLongJump
                lda actMoveCtrl,x
                and #JOY_UP
                beq MH_NoLongJump
                ldy #AL_LONGJUMPACCEL
MH_NoLongJump:  lda (actLo),y
                ldy #HUMAN_MAX_YSPEED
                jsr MoveWithGravity             ;Actually move & check collisions
                sta temp1                       ;Updated move flags to temp1
                lsr
                lda temp2                       ;If rolling, continue roll animation
                bne MH_RollAnim
                bcs MH_GroundAnim
                lda actSY,x                     ;Check for grabbing a ladder while
                bpl MH_GrabLadderOk             ;in midair
                cmp #-2*8                       ;Can not grab while still going up fast
                bcc MH_JumpAnim
MH_GrabLadderOk:lda actMoveCtrl,x
                and #JOY_UP
                beq MH_JumpAnim
                lda actCtrl,x                   ;If fire is held, do not grab ladder
                and #JOY_FIRE
                bne MH_JumpAnim
                lda temp3
                and #AMC_CLIMB
                beq MH_JumpAnim
                jsr GetCharInfo4Above
                and #CI_CLIMB
                beq MH_JumpAnim
                jmp MH_InitClimb
MH_JumpAnim:    ldy #FR_JUMP+1
                lda actSY,x
                bpl MH_JumpAnimDown
MH_JumpAnimUp:  cmp #-1*8
                bcs MH_JumpAnimDone
                dey
                bcc MH_JumpAnimDone
MH_JumpAnimDown:cmp #2*8
                bcc MH_JumpAnimDone
                iny
MH_JumpAnimDone:tya
                jmp MH_AnimDone
MH_AnimDone3:   rts
MH_RollAnim:    lda #$01
                jsr AnimationDelay
                bcc MH_AnimDone3
                lda actF1,x
                adc #$00
                cmp #FR_ROLL+6                  ;Transition from roll to low duck
                bcc MH_RollAnimDone
                lda temp1                       ;If rolling and falling, transition
                lsr                             ;to jump instead
                bcs MH_RollToDuck
MH_RollToJump:  lda #FR_JUMP+2
                bne MH_RollAnimDone
MH_RollToDuck:  lda #FR_DUCK+1
MH_RollAnimDone:jmp MH_AnimDone
MH_GroundAnim:  lda actMoveCtrl,x
                and #JOY_DOWN
                beq MH_NoDuck
MH_NewDuckOrRoll:
                lda actF1,x
                cmp #FR_DUCK
                bcs MH_NoNewRoll
                lda temp3
                and #AMC_ROLL
                beq MH_NoNewRoll
                lda actMoveCtrl,x               ;To initiate a roll, must push the
                cmp actPrevCtrl,x               ;joystick diagonally while standing
                beq MH_NoNewRoll                ;or walking
                and #JOY_LEFT|JOY_RIGHT
                beq MH_NoNewRoll
MH_StartRoll:   lda #$00
                sta actFd,x
                lda #FR_ROLL
                jmp MH_AnimDone
MH_NoNewRoll:   lda temp3
                and #AMC_CLIMB
                beq MH_NoInitClimbDown
                lda actCtrl,x                   ;When holding fire can not initiate climbing
                and #JOY_FIRE
                bne MH_NoInitClimbDown
                jsr GetCharInfo                 ;Duck or climb?
                and #CI_CLIMB
                beq MH_NoInitClimbDown
                jmp MH_InitClimb
MH_NoInitClimbDown:
                lda temp3
                and #AMC_DUCK
                beq MH_NoDuck
                lda actF1,x
                cmp #FR_DUCK
                bcs MH_DuckAnim
                lda #$00
                sta actFd,x
                lda #FR_DUCK
                bne MH_AnimDone
MH_DuckAnim:    lda actF1,x                     ;Check if already ducked
                cmp #FR_DUCK+1
                bcs MH_AnimDone2
                lda #$01
                jsr AnimationDelay
                bcc MH_AnimDone2
                txa                             ;Check item pickup if player
                bne MH_NoPickupCheck
                jsr CheckPickup
MH_NoPickupCheck:
                lda actF1,x
                clc
                adc #$01
                bne MH_AnimDone
MH_NoDuck:      lda actF1,x
                cmp #FR_DUCK
                bcc MH_StandOrWalk
MH_DuckStandUpAnim:
                lda #$01
                jsr AnimationDelay
                bcc MH_AnimDone2
                lda actF1,x
                sbc #$01
                cmp #FR_DUCK
                bcc MH_StandAnim
                bcs MH_AnimDone
MH_StandOrWalk: lda temp1
                and #AMF_HITWALL
                bne MH_StandAnim
MH_WalkAnim:    lda actMoveCtrl,x
                and #JOY_LEFT|JOY_RIGHT
                beq MH_StandAnim
                lda actSX,x
                asl
                bcc MH_WalkAnimSpeedPos
                eor #$ff
                adc #$00
MH_WalkAnimSpeedPos:
                adc #$40
                adc actFd,x
                sta actFd,x
                lda actF1,x
                adc #$00
                cmp #FR_WALK+8
                bcc MH_AnimDone
                lda #FR_WALK
                bcs MH_AnimDone
MH_StandAnim:   lda #$00
                sta actFd,x
                lda #FR_STAND
MH_AnimDone:    sta actF1,x
                sta actF2,x
MH_AnimDone2:   rts

MH_InitClimb:   lda #$80
                sta actXL,x
                sta actFd,x
                lda actYL,x
                and #$e0
                sta actYL,x
                and #$30
                cmp #$20
                lda #FR_CLIMB
                adc #$00
                sta actF1,x
                sta actF2,x
                lda #$00
                sta actSX,x
                sta actSY,x
                jmp NoInterpolation

MH_Climbing:    ldy #AL_CLIMBSPEED
                lda (actLo),y
                sta zpSrcLo
                lda actF1,x                     ;Reset frame in case attack ended
                sta actF2,x
                lda actMoveCtrl,x
                lsr
                bcc MH_NoClimbUp
                jmp MH_ClimbUp
MH_NoClimbUp:   lsr
                bcs MH_ClimbDown
                lda actMoveCtrl,x               ;Exit ladder?
                and #JOY_LEFT|JOY_RIGHT
                beq MH_ClimbDone
                lsr                             ;Left bit to direction
                lsr
                lsr
                ror
                sta actD,x
                jsr GetCharInfo                 ;Check ground bit
                lsr
                bcs MH_ClimbExit
                lda actYL,x                     ;If half way a char, check also 1 char
                and #$20                        ;below
                beq MH_ClimbDone
                jsr GetCharInfo1Below
                lsr
                bcc MH_ClimbDone
MH_ClimbExitBelow:
                lda #8*8
                jsr MoveActorY
MH_ClimbExit:   lda actYL,x
                and #$c0
                sta actYL,x
                jsr NoInterpolation
                jmp MH_StandAnim

MH_ClimbDown:   jsr GetCharInfo
                and #CI_CLIMB
                beq MH_ClimbDone
                ldy #4*8
                bne MH_ClimbCommon
MH_ClimbDone:   rts

MH_ClimbUp:     jsr GetCharInfo4Above
                sta temp1
                and #CI_OBSTACLE
                bne MH_ClimbUpNoJump
                lda actMoveCtrl,x               ;Check for exiting the ladder
                cmp actPrevCtrl,x               ;by jumping
                beq MH_ClimbUpNoJump
                and #JOY_LEFT|JOY_RIGHT
                beq MH_ClimbUpNoJump
                jsr GetCharInfo                 ;If in the middle of an obstacle
                and #CI_OBSTACLE                ;block, can not exit by jump
                bne MH_ClimbUpNoJump
                lda #-2
                jsr GetCharInfoOffset
                and #CI_OBSTACLE
                bne MH_ClimbUpNoJump
                lda actMoveCtrl,x
                cmp #JOY_RIGHT
                ldy #AL_HALFSPEEDRIGHT
                bcs MH_ClimbUpJumpRight
                ldy #AL_HALFSPEEDLEFT
MH_ClimbUpJumpRight:
                lda (actLo),y
                sta actSX,x
                sta actD,x
                jmp MH_StartJump
MH_ClimbUpNoJump:
                lda actYL,x
                and #$20
                bne MH_ClimbUpOk
                lda temp1
                and #CI_CLIMB
                beq MH_ClimbDone
MH_ClimbUpOk:   ldy #-4*8
MH_ClimbCommon: lda zpSrcLo                     ;Climbing speed
                clc
                adc actFd,x
                sta actFd,x
                bcc MH_ClimbDone
                lda #$01                        ;Add 1 or 3 depending on climbing dir
                cpy #$80
                bcc MH_ClimbAnimDown
                lda #$02                        ;C=1, add one less
MH_ClimbAnimDown:
                adc actF1,x
                sbc #FR_CLIMB-1                 ;Keep within climb frame range
                and #$03
                adc #FR_CLIMB-1
                sta actF1,x
                sta actF2,x
                tya
                jsr MoveActorY
                jmp NoInterpolation

        ; Humanoid character destroy routine
        ;
        ; Parameters: X actor index,Y damage source actor or $ff if none
        ; Returns: -
        ; Modifies: A,temp3-temp8

HumanDeath:     lda #FR_DIE
                sta actF1,x
                sta actF2,x
                lda #DEATH_DISAPPEAR_DELAY
                sta actTime,x
                lda #DEATH_YSPEED
                sta actSY,x
                lda #$00
                sta actMoveFlags,x              ;Not grounded anymore
                stx temp3
                sty temp4
                lda actWpn,x                    ;Check if should spawn the weapon item
                beq HD_NoItem                   ;TODO: spawn other items like med-kits or
                lda #ACTI_FIRSTITEM             ;quest items if necessary
                ldy #ACTI_LASTITEM
                jsr GetFreeActor
                bcc HD_NoItem                   ;TODO: if item is important, it needs to be
                lda #$00                        ;stored directly to leveldata if no room
                sta temp5
                sta temp6
                lda #<ITEM_SPAWN_OFFSET
                sta temp7
                lda #>ITEM_SPAWN_OFFSET
                sta temp8
                lda #ACT_ITEM
                jsr SpawnWithOffset
                lda actWpn,x
                sec
                sbc #$01
                sta actF1,y
                lda #ITEM_YSPEED
                sta actSY,y
                tya
                tax
                jsr SetActorSize
                ldx temp3
HD_NoItem:      ldy temp4                      ;Check if has a damage source
                bmi HD_NoDamageSource
                lda actHp,y
                asl
                sta temp8
                lda actSX,y                     ;Check if final attack came from right or left
                bmi HD_LeftImpulse
                bne HD_RightImpulse
                lda actXL,x
                sec
                sbc actXL,y
                lda actXH,x
                sbc actXH,y
                bmi HD_LeftImpulse
HD_RightImpulse:lda temp8
                ldy #DEATH_MAX_XSPEED
                jmp AccActorX
HD_LeftImpulse: lda temp8
                ldy #DEATH_MAX_XSPEED
                jmp AccActorXNeg

        ; Scroll screen around the player actor
        ;
        ; Parameters: -
        ; Returns: scrollSX,scrollSY new scrolling speed
        ; Modifies: A,X,Y,temp1-temp2

ScrollPlayer:   ldx #ACTI_PLAYER
                jsr GetActorCharCoords
                sty temp1
                ldx #0
                ldy #0
                cmp #SCRCENTER_X-3
                bcs SP_NotLeft1
                dex
SP_NotLeft1:    cmp #SCRCENTER_X-1
                bcs SP_NotLeft2
                dex
SP_NotLeft2:    cmp #SCRCENTER_X+2
                bcc SP_NotRight1
                inx
SP_NotRight1:   cmp #SCRCENTER_X+4
                bcc SP_NotRight2
                inx
SP_NotRight2:   lda temp1
                cmp #SCRCENTER_Y-3
                bcs SP_NotUp1
                dey
SP_NotUp1:      cmp #SCRCENTER_Y-1
                bcs SP_NotUp2
                dey
SP_NotUp2:      cmp #SCRCENTER_Y+2
                bcc SP_NotDown1
                iny
SP_NotDown1:    cmp #SCRCENTER_Y+4
                bcc SP_NotDown2
                iny
SP_NotDown2:    stx scrollSX
                sty scrollSY
HD_NoDamageSource:
                rts