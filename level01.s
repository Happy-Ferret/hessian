                processor 6502

                include memory.s

                org lvlObjX
                incbin bg/level01.lvo

                org lvlSpawnT
                incbin bg/level01.lvr

                org lvlName
                dc.b "SECRET CHAMBER",0

                org lvlCodeStart

InitLevel:      jmp DoNothing

UpdateLevel:
DoNothing:      rts

                org charInfo
                incbin bg/level01.chi
                incbin bg/level01.chc

                org chars
                incbin bg/level01.chr
