                processor 6502

                include memory.s

                org lvlCodeStart

UpdateLevel:    ldy chars+23*8+7
                ldx #$06
UL_Loop:        lda chars+23*8,x
                sta chars+23*8+1,x
                dex
                bpl UL_Loop
                sty chars+23*8
                rts

                org charInfo
                incbin bg/level02.chi
                incbin bg/level02.chc

                org chars
                incbin bg/level02.chr

                org lvlDataActX
                incbin bg/level02.lva

                org lvlLoadName
                dc.b "TESTING",0

                org lvlLoadWaterSplashColor
                dc.b 0                          ;Water splash color override
                dc.b 0                          ;Water toxicity delay counter ($80=not affected by filter)
                dc.b 0                          ;Air toxicity delay counter

                org blockInfo
                incbin bg/level02.bli