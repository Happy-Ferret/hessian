                processor 6502

                include memory.s
                include mainsym.s

                org lvlCodeStart

UpdateLevel:    rts

                org charInfo
                incbin bg/world12.chi
                incbin bg/world12.chc

                org chars
                incbin bg/world12.chr

                org charsetLoadBlockInfo
                incbin bg/world12.bli

                org charsetLoadProperties
                dc.b 0                          ;Water splash color override
                dc.b 0                          ;Water toxicity delay counter ($80=not affected by filter)
                dc.b 20                         ;Air toxicity delay counter