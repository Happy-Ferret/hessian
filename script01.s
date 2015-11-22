                include macros.s
                include mainsym.s

        ; Script 1, loadable enemy movement routines + data

FR_DEADRATAIR = 12
FR_DEADRATGROUND = 13
FR_DEADSPIDERAIR = 3
FR_DEADSPIDERGROUND = 4
FR_DEADFLY = 2
FR_DEADBATGROUND = 6
FR_DEADWALKERAIR = 12
FR_DEADWALKERGROUND = 13

                org scriptCodeStart

                dc.w MoveDroid
                dc.w MoveFlyingCraft
                dc.w MoveWalker
                dc.w MoveTank
                dc.w MoveFloatingMine
                dc.w MoveRollingMine
                dc.w MoveTurret
                dc.w MoveFire
                dc.w MoveSmokeCloud
                dc.w MoveRat
                dc.w MoveSpider
                dc.w MoveFly
                dc.w MoveBat
                dc.w MoveFish
                dc.w MoveRock
                dc.w MoveFireball
                dc.w MoveSteam
                dc.w MoveOrganicWalker
                dc.w DestroyFire
                dc.w RatDeath
                dc.w SpiderDeath
                dc.w FlyDeath
                dc.w BatDeath
                dc.w DestroyRock
                dc.w OrganicWalkerDeath

        ; Floating droid update routine
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y,temp1-temp8,loader temp vars

MoveDroid:      lda #$02
                tay
                jsr LoopingAnimation
                jsr MoveAccelerateFlyer
MFC_CanAttack:  jmp AttackGeneric

        ; Flying craft update routine
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y,temp1-temp8,loader temp vars

MoveFlyingCraft:lda actHp,x
                beq MFC_Fall
                jsr MoveAccelerateFlyer
                lda actSX,x
                clc
                adc #2*8+4
                bpl MFC_FrameOK1
                lda #0
MFC_FrameOK1:   lsr
                lsr
                lsr
                cmp #5
                bcc MFC_FrameOK2
                lda #4
MFC_FrameOK2:   sta actF1,x
                cmp #2                          ;Cannot fire when no speed (middle frame)
                bne MFC_CanAttack
                rts
MFC_Fall:       jsr FallingMotionCommon
                tay
                beq MFC_ContinueFall
                jmp ExplodeEnemy2_8             ;Drop item & explode at any collision
MFC_ContinueFall:rts

        ; Walking robot update routine
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y,temp1-temp8,loader temp vars

MoveWalker:     jsr MoveGeneric
                jmp AttackGeneric

        ; Tank update routine
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y,temp1-temp8,loader temp vars

MoveTank:       jsr MoveGeneric                   ;Use human movement for physics
                ldy #tankTurretOfs-turretFrameTbl
                lda #0
                jsr AnimateTurret
                jsr AttackGeneric
                lda actSX,x                       ;Tracks animation from absolute speed
                bpl MT_SpeedPos
                clc
                eor #$ff
                adc #$01
MT_SpeedPos:    clc
                adc actFd,x
                cmp #$30
                bcc MT_NoWrap
                sbc #$30
MT_NoWrap:      sta actFd,x
                lsr
                lsr
                lsr
                lsr
                sta actF1,x
                ldy #AL_SIZEUP                      ;Modify size up based on turret direction
                lda (actLo),y
                ldy actF2,x
                clc
                adc tankSizeAddTbl,y
                sta actSizeU,x
MC_NoCollision:
MFM_NoExplosion:rts

        ; Floating mine update routine
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y,temp1-temp8,loader temp vars

MoveFloatingMine:
                lda #$03
                ldy #$03
                jsr LoopingAnimation
                jsr MoveAccelerateFlyer
MineCommon:     ldy actAITarget,x
                bmi MC_NoCollision
                lda #DMG_ENEMYMINE
                jsr CollideAndDamageTarget
                bcc MC_NoCollision
                jmp DestroyActorNoSource

        ; Rolling mine update routine
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y,temp1-temp8,loader temp vars

MoveRollingMine:jsr MoveGeneric
                lda actMB,x                         ;If not grounded and hitting wall,
                cmp #MB_HITWALL                     ;climb up the wall
                bne MRM_NoClimb
                lda #10
                ldy #4*8
                jsr AccActorYNeg
MRM_NoClimb:    inc actFd,x
                lda actFd,x
                and #$01
                sta actF1,x
                bpl MineCommon

        ; Ceiling turret update routine
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y,temp1-temp8,loader temp vars

MoveTurret:     lda actF2,x
                ldy actFd,x                         ;Start from middle frame
                bne MT_NoInit
                inc actFd,x
                lda #2
                sta actF2,x
MT_NoInit:      ldy #ceilingTurretOfs-turretFrameTbl
                jsr AnimateTurret
                lda actF2,x
                sta actF1,x                         ;Ceiling turret uses only 1-part animation, so copy to frame1
                jmp AttackGeneric

        ; Fire movement
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y,temp1-temp8,loader temp vars

MoveFire:       lda actTime,x                   ;Restore oxygen level if not extinguished
                beq MF_FullOxygen               ;completely, destroy if depleted enough
                cmp #EXTINGUISH_THRESHOLD
                bcs MF_Destroy
                dec actTime,x
                bcc MF_Flash
MF_FullOxygen:  sta actFlash,x                  ;Stop flickering at full oxygen
MF_Flash:       lda #DMG_FIRE
                jsr CollideAndDamagePlayer
                lda #2
                ldy #3
                jsr LoopingAnimation
                lda actF1,x
                ora actFd,x
                bne MF_NoSpawn
                lda #ACTI_FIRSTEFFECT
                ldy #ACTI_LASTNPCBULLET
                jsr GetFreeActor
                bcc MF_NoSpawn
                lda #ACT_SMOKECLOUD
                jsr SpawnActor
                tya
                tax
                jsr InitActor                   ;Set collision size
                lda #-15*8
                jsr MoveActorY
                lda #COLOR_FLICKER
                sta actFlash,x
                ldx actIndex
MSC_NoRemove:
MF_NoSpawn:     rts
MF_Destroy:     ldy #ACTI_FIRSTPLRBULLET        ;Make sure player receives score
                jmp DestroyActor

        ; Smokecloud movement
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y,temp1-temp8,loader temp vars

MoveSmokeCloud: lda upgrade
                bmi MSC_NoSmokeDamage           ;If filter installed, no damage
                lda #DMG_SMOKE
                jsr CollideAndDamagePlayer
MSC_NoSmokeDamage:
                lda #-12
                jsr MoveActorY
                lda #4
                ldy #3
                jsr OneShotAnimation
                bcc MSC_NoRemove
                jmp RemoveActor

        ; Rat movement
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y,temp1-temp8,loader temp vars

MoveRat:        lda #FR_DEADRATGROUND
                sta temp1
                lda actHp,x
                beq MR_Dead
                jsr MoveGeneric
                jmp AttackGeneric
MR_Dead:        jsr DeadAnimalMotion
                bcs MR_DeadGrounded
                rts
MR_DeadGrounded:lda #$00
                sta actSX,x                     ;Instant braking
                lda temp1
                sta actF1,x
                rts

        ; Spider movement
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y,temp1-temp8,loader temp vars
        
MoveSpider:     lda #FR_DEADSPIDERGROUND
                sta temp1
                lda actHp,x
                beq MR_Dead
                jsr MoveGeneric
                lda #2
                ldy #2
                jsr LoopingAnimation
MS_Damage:      lda actFd,x
                lsr
                bcs MS_NoDamage                 ;Touch damage only each third frame
                lda #DMG_SPIDER
                jmp CollideAndDamagePlayer
MS_NoDamage:    rts

        ; Fly movement
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y,temp1-temp8,loader temp vars

MoveFly:        lda actHp,x
                beq MF_Dead
                dec actTime,x
                bpl MF_NoNewControls
                jsr Random
                and #$03
                tay
                lda flyerDirTbl,y
                sta actMoveCtrl,x
                jsr Random
                and #$1f
                sta actTime,x
MF_NoNewControls:
                jsr MoveAccelerateFlyer
                inc actFd,x
                lda actFd,x
                and #$01
                sta actF1,x
                jmp MS_Damage                   ;Use same damage code as spider
MF_Dead:        lda #2
                ldy #FR_DEADFLY+1
                jmp OneShotAnimateAndRemove

        ; Bat movement
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y,temp1-temp8,loader temp vars

MB_Dead:        lda #FR_DEADBATGROUND
                sta temp1
                jmp MR_Dead
MoveBat:        lda actHp,x
                beq MB_Dead
                lda #2                          ;Wings flapping acceleration up
                cmp actF1,x                     ;or gravity acceleration down,
                bcc MB_Gravity                  ;depending on frame
                lda actMoveCtrl,x
                and #JOY_UP
                bne MB_StrongFlap
                lda #2
                skip2
MB_StrongFlap:  lda #7
                bne MB_Accel
MB_Gravity:     lda #2
MB_Accel:       ldy #2*8
                jsr AccActorYNegOrPos
                lda #$00
                sta temp6
                jsr MFE_NoVertAccel             ;Left/right acceleration & move
                lda #2
                ldy #FR_DEADBATGROUND-1
MB_BatCommon:   jsr LoopingAnimation
                ldy #ACTI_PLAYER
                jsr GetActorDistance
                lda temp5                       ;No damage after has flown past player
                eor actD,x                      ;Otherwise use same damage code as spider
                bmi MB_NoDamage
                jmp MS_Damage
MB_NoDamage:    rts

        ; Fish movement
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y,temp1-temp8,loader temp vars

MoveFish:       lda #CI_WATER
                jsr MFE_CustomCharInfo
                lda #2
                ldy #1
                bne MB_BatCommon

        ; Rock movement
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y,temp1-temp8,loader temp vars

MoveRock:       lda actTime,x                   ;Randomize X-speed on first frame
                bne MR_HasRandomSpeed
                inc actTime,x
                jsr Random
                and #$0f
                sec
                sbc #$08
                sta actSX,x
MR_HasRandomSpeed:
                ldy actF1,x                     ;Set size according to frame
                lda rockSizeTbl,y
                sta actSizeH,x
                asl
                sta actSizeU,x
                lda actSY,x
                bmi MR_NoDamage                 ;No damage if not falling
                lda actHp+ACTI_PLAYER           ;No damage if player already dead
                beq MR_NoDamage
                lda rockDamageTbl,y             ;Damage based on frame (size)
                jsr CollideAndDamagePlayer
                bcc MR_NoDamage                 ;Damage sound already played
                jmp DestroyActorNoSource        ;Destroy self on collision
MR_NoDamage:    lda #-1                         ;Ceiling check offset
                sta temp4
                lda #GRENADE_ACCEL-1
                ldy #GRENADE_MAX_YSPEED
                jsr MoveWithGravity
                lda actMB,x
                lsr
                and #MB_HITWALL/2
                beq MR_NoHitWall
                php
                lda actSX,x
                eor #$ff
                adc #$00                        ;Assume C=0 (not grounded)
                sta actSX,x
                plp
MR_NoHitWall:   bcc MR_NoCollision
DestroyRock:    lda #SFX_DAMAGE
                jsr PlaySfx
                inc actF1,x
                lda actF1,x
                cmp #3
                bcs RemoveRock
                lda #-2*8
                jsr MR_RandomizeSmallerRock
                lda #ACTI_FIRSTNPC
                ldy #ACTI_LASTNPC
                jsr GetFreeActor
                bcc MR_NoSpawn
                lda #ACT_ROCK
                jsr SpawnActor
                lda actF1,x
                sta actF1,y
                stx temp6
                tya
                tax
                jsr InitActor
                jsr SetNotPersistent
                lda #$00
                jsr MR_RandomizeSmallerRock
                ldx temp6
MR_NoCollision:
MR_NoSpawn:     rts
RemoveRock:     lda #-4*8
                jsr MoveActorY
                jsr NoInterpolation
                lda #COLOR_FLICKER
                sta actFlash,x
                lda #ACT_SMOKETRAIL
                jmp TransformBullet
MR_RandomizeSmallerRock:
                sta temp1
                jsr Random
                and #$0f
                clc
                adc temp1
                sta actSX,x
                lda #-4*8
                sta actSY,x
                lda #$00                        ;Reset ground flag
                sta actMB,x
                lda #HP_ROCK                    ;Reset hitpoints if was destroyed
                sta actHp,x
                rts

        ; Fireball movement
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y,temp1-temp8,loader temp vars

MoveFireball:   lda actTime,x                   ;Randomize X-speed on first frame
                bne MFB_HasRandomSpeed          ;and set upward motion
                inc actTime,x
                jsr Random
                and #$0f
                sec
                sbc #$08
                sta actSX,x
                jsr Random
                and #$0f
                sec
                sbc #6*8
                sta actSY,x
                lda #SFX_GRENADELAUNCHER
                jsr PlaySfx
MFB_HasRandomSpeed:
                lda #DMG_FIREBALL
                jsr CollideAndDamagePlayer
                lda #1
                ldy #3
                jsr LoopingAnimation
                lda #GRENADE_ACCEL-2
                ldy #GRENADE_MAX_YSPEED
                jsr AccActorY
                lda actSX,x
                jsr MoveActorX
                lda actSY,x
                jmp MoveActorY
                rts

        ; Steam movement
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y,temp1-temp8,loader temp vars

MoveSteam:      lda #COLOR_FLICKER
                sta actFlash,x
                inc actTime,x
                bmi MS_Invisible
                lda #1
                ldy #2
                jsr LoopingAnimation
                lda #DMG_STEAM
                jmp CollideAndDamagePlayer
MS_Invisible:   lda #3
                sta actF1,x
                rts

        ; Organic walker movement
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y,temp1-temp8,loader temp vars

MoveOrganicWalker:
                lda actHp,x
                beq MOW_Dead
                jsr MoveGeneric
                jmp AttackGeneric
MOW_Dead:       lda #FR_DEADWALKERGROUND
                sta temp1
                jmp MR_Dead

        ; Fire destruction (transform into smoke)
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y,temp1-temp8,loader temp vars

DestroyFire:    lda #ACT_SMOKECLOUD
                jmp TransformBullet

        ; Rat death
        ;
        ; Parameters: X actor index,Y damage source actor or $ff if none
        ; Returns: -
        ; Modifies: A

RatDeath:       lda #FR_DEADRATAIR
RD_Common:      pha
                jsr HD_Common
                lda #SFX_ANIMALDEATH
                jsr PlaySfx
                pla
RD_SetFrameAndSpeed:
                sta actF1,x
                lda #-28
                sta actSY,x
                rts

        ; Spider death
        ;
        ; Parameters: X actor index,Y damage source actor or $ff if none
        ; Returns: -
        ; Modifies: A

SpiderDeath:    lda #FR_DEADSPIDERAIR
                bne RD_Common

        ; Fly / bat death
        ;
        ; Parameters: X actor index,Y damage source actor or $ff if none
        ; Returns: -
        ; Modifies: A

FlyDeath:       lda #FR_DEADFLY
                sta actF1,x
BatDeath:       lda #SFX_ANIMALDEATH
                jsr PlaySfx
                jmp HD_Common

        ; Organic walker death
        ;
        ; Parameters: X actor index,Y damage source actor or $ff if none
        ; Returns: -
        ; Modifies: A

OrganicWalkerDeath:
                jsr HumanDeath
                lda #FR_DEADWALKERAIR
                bne RD_SetFrameAndSpeed

        ; Common flying enemy movement
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y,temp1-temp8,loader temp vars

MoveAccelerateFlyer:
                lda #$00
MFE_CustomCharInfo:
                sta temp6
                ldy #AL_YMOVESPEED
                lda (actLo),y
                sta temp4                       ;Vertical max. speed
                lda actMoveCtrl,x
                and #JOY_UP|JOY_DOWN
                beq MFE_NoVertAccel
                cmp #JOY_UP
                beq MFE_AccelUp                 ;C=1 accelerate up (negative)
                clc
MFE_AccelUp:    iny
                lda (actLo),y                   ;Vertical acceleration
                ldy temp4
                jsr AccActorYNegOrPos
MFE_NoVertAccel:ldy #AL_XMOVESPEED
                lda (actLo),y
                sta temp4                       ;Horizontal max. speed
                lda actMoveCtrl,x
                and #JOY_LEFT|JOY_RIGHT
                beq MFE_NoHorizAccel
                and #JOY_LEFT
                beq MFE_TurnRight
                lda #$80
MFE_TurnRight:  sta actD,x
                asl                             ;Direction to carry
                iny
                lda (actLo),y                   ;Horizontal acceleration
                ldy temp4
                jsr AccActorXNegOrPos
MFE_NoHorizAccel:
                ldy #AL_XCHECKOFFSET            ;Horizontal obstacle check offset
                lda (actLo),y
                sta temp4
                iny
                lda (actLo),y                   ;Vertical obstacle check offset
                ldy actSY,x                     ;Reverse if going up
                bpl MFE_NoNegate
                clc
                eor #$ff
                adc #$01
MFE_NoNegate:   jsr MF_HasCharInfo
                ldy actAIHelp,x                 ;Zero speed and reverse dir if requested
                lda actMB,x
                and #MB_HITWALL
                beq MFE_NoHorizWall
                lda #$00
                sta actSX,x
                tya
                beq MFE_NoHorizTurn
                lda #JOY_LEFT|JOY_RIGHT
                jsr MFE_Reverse
MFE_NoHorizTurn:
MFE_NoHorizWall:lda actMB,x
                and #MB_HITWALLVERTICAL
                beq MFE_NoVertWall
                lda #$00
                sta actSY,x
                tya
                beq MFE_NoVertTurn
                lda #JOY_UP|JOY_DOWN
MFE_Reverse:    eor actMoveCtrl,x
                sta actMoveCtrl,x
MFE_NoVertTurn:
MFE_NoVertWall: rts

        ; Turret animation routine
        ;
        ; Parameters: X actor index, A default frame, Y turret frame table start index
        ; Returns: Frame in actF2
        ; Modifies: A,Y,temp1-temp8,loader temp vars

AnimateTurret:  sta AT_Default+1
AT_Loop:        lda turretFrameTbl,y
                beq AT_Default
                cmp actCtrl,x
                beq AT_Found
                iny
                iny
                bne AT_Loop
AT_Found:       lda turretFrameTbl+1,y
                skip2
AT_Default:     lda #$00
AT_FrameDone:   cmp actF2,x
                beq AT_NoAnim
                ldy actAttackD,x
                bne AT_NoAnim
                bcc AT_AnimDown
AT_AnimUp:      inc actF2,x
                bne AT_AnimCommon
AT_AnimDown:    dec actF2,x
AT_AnimCommon:  lda #TURRET_ANIMDELAY
                sta actAttackD,x
                lda actTime,x
                bpl AT_NoOngoingAttack
                sec
                sbc #TURRET_ANIMDELAY
                sta actTime,x                       ;Restore time to the AI attack counter,
AT_NoOngoingAttack:                                 ;since time was lost animating
AT_NoAnim:      rts

        ; Common dead animal falling motion
        ;
        ; Parameters: X actor index
        ; Returns: C Grounded status
        ; Modifies: A,Y,temp1-temp8,loader temp vars

DeadAnimalMotion:
                jsr DeathFlickerAndRemove
                jsr FallingMotionCommon
                bpl DAM_NoWater
                pha
                lda #WATER_XBRAKING
                jsr BrakeActorX
                lda #WATER_YBRAKING*2
                jsr BrakeActorY
                pla
DAM_NoWater:    and #MB_HITWALL
                beq DAM_NoWallHit
                lda #$00
                sta actSX,x
DAM_NoWallHit:  lda actMB,x
                lsr
                rts

        ; Tank Y-size addition table (based on turret direction)

tankSizeAddTbl: dc.b 0,6,8

        ; Rock size & damage tablestable

rockSizeTbl:    dc.b 9,7,5
rockDamageTbl:  dc.b DMG_ROCK,DMG_ROCK/2,DMG_ROCK/3

        ; Turret firing ctrl + frame table

turretFrameTbl:
tankTurretOfs:  dc.b JOY_LEFT|JOY_FIRE,0
                dc.b JOY_RIGHT|JOY_FIRE,0
                dc.b JOY_LEFT|JOY_UP|JOY_FIRE,1
                dc.b JOY_RIGHT|JOY_UP|JOY_FIRE,1
                dc.b JOY_UP|JOY_FIRE,2
                dc.b 0
ceilingTurretOfs:
                dc.b JOY_RIGHT|JOY_FIRE,0
                dc.b JOY_RIGHT|JOY_DOWN|JOY_FIRE,1
                dc.b JOY_DOWN|JOY_FIRE,2
                dc.b JOY_LEFT|JOY_DOWN|JOY_FIRE,3
                dc.b JOY_LEFT|JOY_FIRE,4
                dc.b 0

                checkscriptend

