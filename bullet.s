GRENADE_DMG_RADIUS = 48

        ; Bullet update routine with muzzle flash as first frame
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y

MBltMF_FirstFrame:
                inc actFd,x
                rts

MoveBulletMuzzleFlash:
                lda actFd,x                     ;First frame: just show the muzzle flash
                beq MBltMF_FirstFrame           ;and do not move
                lda actF1,x
                cmp #$0a
                bcs MoveBullet
                adc #$0a
                sta actF1,x
                jsr MoveBullet
                jmp NoInterpolation             ;No interpolation on second frame
                                                ;to prevent flash from appearing in different
                                                ;position dependent on flashing order

        ; Melee hit update routine
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y

MoveMeleeHit:   dec actTime,x
                bmi MBlt_Remove
                jmp CheckBulletCollisions

        ; Bullet update routine
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y

MBlt_Remove:    jmp RemoveActor
MoveBullet:     dec actTime,x
                bmi MBlt_Remove
                jsr MoveProjectile
                and #CI_OBSTACLE
                bne MBlt_Remove

        ; Check bullet collisions
        ;
        ; Parameters: X bullet actor index
        ; Returns: -
        ; Modifies: A,Y,temp variables

CheckBulletCollisions:
                lda actGrp,x
                bmi CBC_CheckHeroes
CBC_CheckVillains:
                lda #<villainList
                sta CBC_GetNextVillain+1
CBC_GetNextVillain:
                ldy villainList
                bmi CBC_Done
                inc CBC_GetNextVillain+1
                jsr CheckActorCollision
                bcc CBC_GetNextVillain
CBC_HasCollision:
                sty temp8
                lda actHp,x                     ;Damage target
                pha
                and #$7f
                ldx temp8
                jsr DamageActor
                ldx actIndex
                pla
                bmi CBC_BulletStays
                jmp DestroyActor
CBC_BulletStays:lda #$80                        ;In bullet stays-mode, do damage only once
                sta actHp,x
                rts

CBC_CheckHeroes:lda #<heroList
                sta CBC_GetNextHero+1
CBC_GetNextHero:ldy heroList
                bmi CBC_Done
                inc CBC_GetNextHero+1
                jsr CheckActorCollision
                bcc CBC_GetNextHero
                bcs CBC_HasCollision

        ; Explode grenade and do radius damage
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A

ExplodeGrenade: lda #GRENADE_DMG_RADIUS         ;Expand grenade collision size for radius damage
                sta actSizeH,x
                sta actSizeU,x
                sta actSizeD,x
                lda actHp,x
                jsr RadiusDamage

        ; Turn an actor into an explosion
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A

ExplodeActor:   lda #$00
                sta actF1,x
                sta actFd,x
                sta actC,x                      ;Remove flashing
                lda #ACT_EXPLOSION
                sta actT,x
                lda #SFX_EXPLOSION
                jmp PlaySfx

        ; Explosion update routine
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y

MoveExplosion:  lda #1
                jsr AnimationDelay
                bcc MExpl_NoAnimation
                inc actF1,x
                lda actF1,x
                cmp #5
                bcc MExpl_NoRemove
                jmp RemoveActor
CBC_Done:
MExpl_NoAnimation:
MExpl_NoRemove: rts

        ; Grenade update routine
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y

MoveGrenade:    dec actTime,x
                bmi ExplodeGrenade
                lda #$00                        ;Grenade never stays grounded
                sta actMoveFlags,x
                lda actSY,x                     ;Store original Y-speed for bounce
                sta temp1
                lda #-1                         ;Ceiling check offset
                sta temp4
                lda #4
                ldy #-3*8
                jsr MoveWithGravity
                lsr
                bcc MGrn_NoBounce
                lda temp1                       ;Bounce: negate and halve velocity
                jsr Negate8Asr8
                sta actSY,x
                lda #8                          ;Brake X-speed with each bounce
                jsr BrakeActorX
MGrn_NoBounce:  lda actMoveFlags,x
                and #AMF_HITWALL|AMF_HITCEILING
                cmp #AMF_HITWALL
                bne MGrn_NoHitWall
                lda actSX,x
                jsr Negate8Asr8
                jmp MGrn_StoreNewXSpeed
MGrn_NoHitWall: and #AMF_HITCEILING             ;Halve X-speed when hit ceiling
                beq MGrn_Done
                lda actSX,x
                jsr Asr8
MGrn_StoreNewXSpeed:
                sta actSX,x
MGrn_Done:      rts

        ; Give radius damage to both heroes & villains
        ;
        ; Parameters: X source actor index (must also be in actIndex), A damage amount
        ; Returns: -
        ; Modifies: A,Y,temp1,temp2,temp5-temp8,possibly other temp registers

RadiusDamage:   sta temp1
                ldy #ACTI_LASTNPC
RD_Loop:        lda actT,y
                beq RD_Next
                lda actHp,y
                beq RD_Next
                jsr CheckActorCollision
                bcc RD_Next
                tya
                tax
                lda temp1
                jsr DamageActor
                ldx actIndex
RD_Next:        dey
                bpl RD_Loop
                rts
