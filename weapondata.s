WPN_NONE        = 0
WPN_FISTS       = 1
WPN_KNIFE       = 2
WPN_PISTOL      = 3
WPN_GRENADE     = 4

DMG_FISTS       = 1
DMG_KNIFE       = 2
DMG_PISTOL      = 4
DMG_GRENADE     = 16

DMG_BULLETSTAYS = $80                           ;Bullet does not disappear after damage
                                                ;(flamethrower etc.)

        ; Weapon/attack tables

attackTbl:      dc.b AIM_NONE                   ;None
                dc.b AIM_UP                     ;Up
                dc.b AIM_DOWN                   ;Down
                dc.b AIM_NONE                   ;Up+Down
                dc.b AIM_HORIZONTAL             ;Left
                dc.b AIM_DIAGONALUP             ;Left+Up
                dc.b AIM_DIAGONALDOWN           ;Left+Down
                dc.b AIM_NONE                   ;Left+Up+Down
                dc.b AIM_HORIZONTAL             ;Right
                dc.b AIM_DIAGONALUP             ;Right+Up
                dc.b AIM_DIAGONALDOWN           ;Right+Down
                dc.b AIM_NONE                   ;Right+Up+Down
                dc.b AIM_NONE                   ;Right+Left
                dc.b AIM_NONE                   ;Right+Left+Up
                dc.b AIM_NONE                   ;Right+Left+Down
                dc.b AIM_NONE                   ;Right+Left+Up+Down

bulletXSpdTbl:  dc.b 0,6,8,6,0                  ;Normal bullets
                dc.b 0,-6,-8,-6,0
                dc.b 0,8,8,8,0                  ;Grenades
                dc.b 0,-8,-8,-8,0

bulletYSpdTbl:  dc.b -8,-6,0,6,8                ;Normal bullets
                dc.b -8,-6,0,6,8
                dc.b -8,-7,-4,-1,0              ;Grenades
                dc.b -8,-7,-4,-1,0

        ; Weapon data pointers

wpnTblLo:       dc.b <wdFists
                dc.b <wdKnife
                dc.b <wdPistol
                dc.b <wdGrenade

wpnTblHi:       dc.b >wdFists
                dc.b >wdKnife
                dc.b >wdPistol
                dc.b >wdGrenade

        ; Weapon data

wdFists:        dc.b WDB_NOWEAPONSPRITE|WDB_MELEE ;Weapon bits
                dc.b AIM_HORIZONTAL             ;First aim direction
                dc.b AIM_HORIZONTAL+1           ;Last aim direction+1
                dc.b 5                          ;Attack delay
                dc.b ACT_MELEEHIT               ;Bullet actor type
                dc.b DMG_FISTS                  ;Bullet damage
                dc.b 1                          ;Bullet time duration
                dc.b 1                          ;Bullet speed in pixels
                dc.b 0                          ;Bullet speed table offset
                dc.b SFX_PUNCH                  ;Sound effect

wdKnife:        dc.b WDB_MELEE                  ;Weapon bits
                dc.b AIM_HORIZONTAL             ;First aim direction
                dc.b AIM_HORIZONTAL+1           ;Last aim direction+1
                dc.b 7                          ;Attack delay
                dc.b ACT_MELEEHIT               ;Bullet actor type
                dc.b DMG_KNIFE                  ;Bullet damage
                dc.b 1                          ;Bullet time duration
                dc.b 1                          ;Bullet speed in pixels
                dc.b 0                          ;Bullet speed table offset
                dc.b SFX_MELEE                  ;Sound effect
                dc.b 8                          ;Idle weapon frame (right)
                dc.b 8                          ;Idle weapon frame (left)
                dc.b 9                          ;Prepare weapon frame (right)
                dc.b 10                         ;Prepare weapon frame (left)
                dc.b 9,9,9,9,9                  ;Attack weapon frames (right)
                dc.b 10,10,10                   ;Attack weapon frames (left)

wdPistol:       dc.b WDB_BULLETDIRFRAME|WDB_FLASHBULLET ;Weapon bits
                dc.b AIM_UP                     ;First aim direction
                dc.b AIM_DOWN+1                 ;Last aim direction+1
                dc.b 7                          ;Attack delay
                dc.b ACT_BULLET                 ;Bullet actor type
                dc.b DMG_PISTOL                 ;Bullet damage
                dc.b 18                         ;Bullet time duration
                dc.b 12                         ;Bullet speed in pixels
                dc.b 0                          ;Bullet speed table offset
                dc.b SFX_PISTOL                 ;Sound effect
                dc.b 2                          ;Idle weapon frame (right)
                dc.b 6                          ;Idle weapon frame (left)
                dc.b 2                          ;Prepare weapon frame (right)
                dc.b 6                          ;Prepare weapon frame (left)
                dc.b 0,1,2,3,4                  ;Attack weapon frames (right)
                dc.b 0,5,6,7,4                  ;Attack weapon frames (left)
                dc.b 25                         ;Reload delay
                dc.b SFX_RELOAD                 ;Reload sound

wdGrenade:      dc.b WDB_NOWEAPONSPRITE|WDB_THROW ;Weapon bits
                dc.b AIM_DIAGONALUP             ;First aim direction
                dc.b AIM_DIAGONALDOWN+1         ;Last aim direction+1
                dc.b 15                         ;Attack delay
                dc.b ACT_GRENADE                ;Bullet actor type
                dc.b DMG_GRENADE                ;Bullet damage
                dc.b 30                         ;Bullet time duration
                dc.b 6                          ;Bullet speed in pixels
                dc.b 10                         ;Bullet speed table offset
                dc.b SFX_THROW                  ;Sound effect
