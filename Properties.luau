--	GENERIC PURPOSE REGISTERS
local m = {}


m.AX = {}
m.BX = {}
m.CX = {}
m.DX = {}
--	AX
m.AH = {}
m.AL = {}
--	BX
m.BH = {}
m.BL = {}
--	CX
m.CH = {}
m.CL = {}
--	DX
m.DH = {}
m.DL = {}	
--	POINTER/INDEX REGISTERS
m.SP = {}
m.BP = {}
m.SI = {}
m.DI = {}
--	SEGMENT REGISTERS
m.CS = {}
m.SS = {}
m.DS = {}
m.ES = {}
--	FLAGS
m.CF = {}
m.PF = {}
m.AF = {}
m.ZF = {}
m.SF = {}
m.TF = {}
m.IF = {}
m.DF = {}
m.OF = {}
--	ADDITIONAL
m.IP = {}

m.AX.size = 16
m.BX.size = 16
m.CX.size = 16
m.DX.size = 16

m.AH.size = 8
m.AL.size = 8
m.BH.size = 8
m.BL.size = 8
m.CH.size = 8
m.CL.size = 8
m.DH.size = 8
m.DL.size = 8

m.SP.size = 16
m.BP.size = 16
m.SI.size = 16
m.DI.size = 16

m.CS.size = 16
m.SS.size = 16
m.DS.size = 16
m.ES.size = 16

m.IP.size = 16

m.CF.size = 1
m.PF.size = 1
m.AF.size = 1
m.ZF.size = 1
m.SF.size = 1
m.TF.size = 1
m.IF.size = 1
m.DF.size = 1
m.OF.size = 1

--	OPCODE PROPERTIES

-- 0x
m["00"] = {size = 8, modrm = true, cycles = 3}   -- ADD r/m8, r8		#
m["01"] = {size = 16, modrm = true, cycles = 3}  -- ADD r/m16, r16		#
m["02"] = {size = 8, modrm = true, cycles = 3}   -- ADD r8, r/m8		#
m["03"] = {size = 16, modrm = true, cycles = 3}  -- ADD r16, r/m16		#
m["04"] = {size = 8, cycles = 4}                 -- ADD AL, d8			#
m["05"] = {size = 16, cycles = 4}                -- ADD AX, d16			#
m["06"] = {size = 0, cycles = 14}                -- PUSH ES				#
m["07"] = {size = 0, cycles = 12}                -- POP ES				#
m["08"] = {size = 8, modrm = true, cycles = 3}   -- OR r/m8, r8			#
m["09"] = {size = 16, modrm = true, cycles = 3}  -- OR r/m16, r16		#
m["0A"] = {size = 8, modrm = true, cycles = 3}   -- OR r8, r/m8			#
m["0B"] = {size = 16, modrm = true, cycles = 3}  -- OR r16, r/m16		#
m["0C"] = {size = 8, cycles = 4}                 -- OR AL, d8			#		
m["0D"] = {size = 16, cycles = 4}                -- OR AX, d16			#
m["0E"] = {size = 0, cycles = 14}                -- PUSH CS				#
m["0F"] = {size = 0, cycles = 12}                -- *POP CS				#

-- 1x
m["10"] = {size = 8, modrm = true, cycles = 3}   -- ADC r/m8, r8		#
m["11"] = {size = 16, modrm = true, cycles = 3}  -- ADC r/m16, r16		#
m["12"] = {size = 8, modrm = true, cycles = 3}   -- ADC r8, r/m8		#
m["13"] = {size = 16, modrm = true, cycles = 3}  -- ADC r16, r/m16		#
m["14"] = {size = 8, cycles = 4}                 -- ADC AL, d8			#
m["15"] = {size = 16, cycles = 4}                -- ADC AX, d16			#
m["16"] = {size = 0, cycles = 14}                -- PUSH SS				#
m["17"] = {size = 0, cycles = 12}                -- POP SS				#
m["18"] = {size = 8, modrm = true, cycles = 3}   -- SBB r/m8, r8		#
m["19"] = {size = 16, modrm = true, cycles = 3}  -- SBB r/m16, r16		#
m["1A"] = {size = 8, modrm = true, cycles = 3}   -- SBB r8, r/m8		#
m["1B"] = {size = 16, modrm = true, cycles = 3}  -- SBB r16, r/m16		#
m["1C"] = {size = 8, cycles = 4}                 -- SBB AL, d8			#
m["1D"] = {size = 16, cycles = 4}                -- SBB AX, d16			#
m["1E"] = {size = 0, cycles = 14}                -- PUSH DS				#
m["1F"] = {size = 0, cycles = 12}                -- POP DS				#

-- 2x
m["20"] = {size = 8, modrm = true, cycles = 3}   -- AND r/m8, r8		#
m["21"] = {size = 16, modrm = true, cycles = 3}  -- AND r/m16, r16		#
m["22"] = {size = 8, modrm = true, cycles = 3}   -- AND r8, r/m8		#
m["23"] = {size = 16, modrm = true, cycles = 3}  -- AND r16, r/m16		#	
m["24"] = {size = 8, cycles = 4}                 -- AND AL, d8			#
m["25"] = {size = 16, cycles = 4}                -- AND AX, d16			#
m["26"] = {size = 0, cycles = 2}                 -- ES:					#
m["27"] = {size = 0, cycles = 4}                 -- DAA					#
m["28"] = {size = 8, modrm = true, cycles = 3}   -- SUB r/m8, r8		#	
m["29"] = {size = 16, modrm = true, cycles = 3}  -- SUB r/m16, r16		#
m["2A"] = {size = 8, modrm = true, cycles = 3}   -- SUB r8, r/m8		#
m["2B"] = {size = 16, modrm = true, cycles = 3}  -- SUB r16, r/m16		#	
m["2C"] = {size = 8, cycles = 4}                 -- SUB AL, d8			#
m["2D"] = {size = 16, cycles = 4}                -- SUB AX, d16			#
m["2E"] = {size = 0, cycles = 2}                 -- CS:					#
m["2F"] = {size = 0, cycles = 4}                 -- DAS					#

-- 3x
m["30"] = {size = 8, modrm = true, cycles = 3}   -- XOR r/m8, r8		#
m["31"] = {size = 16, modrm = true, cycles = 3}  -- XOR r/m16, r16		#
m["32"] = {size = 8, modrm = true, cycles = 3}   -- XOR r8, r/m8		#
m["33"] = {size = 16, modrm = true, cycles = 3}  -- XOR r16, r/m16		#
m["34"] = {size = 8, cycles = 4}                 -- XOR AL, d8			#
m["35"] = {size = 16, cycles = 4}                -- XOR AX, d16			#
m["36"] = {size = 0, cycles = 2}                 -- SS:					#
m["37"] = {size = 0, cycles = 8}                 -- AAA					#
m["38"] = {size = 8, modrm = true, cycles = 3}   -- CMP r/m8, r8		#
m["39"] = {size = 16, modrm = true, cycles = 3}  -- CMP r/m16, r16		#
m["3A"] = {size = 8, modrm = true, cycles = 3}   -- CMP r8, r/m8		#
m["3B"] = {size = 16, modrm = true, cycles = 3}  -- CMP r16, r/m16		#
m["3C"] = {size = 8, cycles = 4}                 -- CMP AL, d8			#
m["3D"] = {size = 16, cycles = 4}                -- CMP AX, d16			#
m["3E"] = {size = 0, cycles = 2}                 -- DS:					#
m["3F"] = {size = 0, cycles = 8}                 -- AAS					#

-- 4x
m["40"] = {size = 16, cycles = 3}                -- INC AX				#
m["41"] = {size = 16, cycles = 3}                -- INC CX				#
m["42"] = {size = 16, cycles = 3}                -- INC DX				#
m["43"] = {size = 16, cycles = 3}                -- INC BX				#
m["44"] = {size = 16, cycles = 3}                -- INC SP				#	
m["45"] = {size = 16, cycles = 3}                -- INC BP				#
m["46"] = {size = 16, cycles = 3}                -- INC SI				#		
m["47"] = {size = 16, cycles = 3}                -- INC DI				#		
m["48"] = {size = 16, cycles = 3}                -- DEC AX				#
m["49"] = {size = 16, cycles = 3}                -- DEC CX				#	
m["4A"] = {size = 16, cycles = 3}                -- DEC DX				#
m["4B"] = {size = 16, cycles = 3}                -- DEC BX				#
m["4C"] = {size = 16, cycles = 3}                -- DEC SP				#
m["4D"] = {size = 16, cycles = 3}                -- DEC BP				#
m["4E"] = {size = 16, cycles = 3}                -- DEC SI				#
m["4F"] = {size = 16, cycles = 3}                -- DEC DI				#

-- 5x
m["50"] = {size = 16, cycles = 15}               -- PUSH AX				#
m["51"] = {size = 16, cycles = 15}               -- PUSH CX				#
m["52"] = {size = 16, cycles = 15}               -- PUSH DX				#
m["53"] = {size = 16, cycles = 15}               -- PUSH BX				#
m["54"] = {size = 16, cycles = 15}               -- PUSH SP				#
m["55"] = {size = 16, cycles = 15}               -- PUSH BP				#
m["56"] = {size = 16, cycles = 15}               -- PUSH SI				#
m["57"] = {size = 16, cycles = 15}               -- PUSH DI				#
m["58"] = {size = 16, cycles = 12}               -- POP AX				#
m["59"] = {size = 16, cycles = 12}               -- POP CX				#
m["5A"] = {size = 16, cycles = 12}               -- POP DX				#
m["5B"] = {size = 16, cycles = 12}               -- POP BX				#
m["5C"] = {size = 16, cycles = 12}               -- POP SP				#
m["5D"] = {size = 16, cycles = 12}               -- POP BP				#
m["5E"] = {size = 16, cycles = 12}               -- POP SI				#
m["5F"] = {size = 16, cycles = 12}               -- POP DI				#

-- 6x 
m["60"] = {size = 0, cycles = 1}				-- PRINT(ADDR)			#
m["61"] = {size = 8, modrm = true, cycles = 1}	-- PRINT(MODRM8)		#
m["62"] = {size = 16, modrm = true, cycles = 1}	-- PRINT(MODRM16)		#
m["63"] = {size = 0, cycles = 1}				-- PASS
m["64"] = {size = 0, cycles = 1}				-- PASS
m["65"] = {size = 0, cycles = 1}				-- PASS
m["66"] = {size = 0, cycles = 1}				-- PASS
m["67"] = {size = 0, cycles = 1}				-- PASS
m["68"] = {size = 0, cycles = 1}				-- PASS
m["69"] = {size = 0, cycles = 1}				-- PASS
m["6A"] = {size = 0, cycles = 1}				-- PASS
m["6B"] = {size = 0, cycles = 1}				-- PASS
m["6C"] = {size = 0, cycles = 1}				-- PASS
m["6D"] = {size = 0, cycles = 1}				-- PASS
m["6E"] = {size = 0, cycles = 1}				-- PASS
m["6F"] = {size = 0, cycles = 1}				-- PASS

-- 7x
m["70"] = {size = 8, cycles = 4}                 -- JO rel8				#		
m["71"] = {size = 8, cycles = 4}                 -- JNO rel8			#
m["72"] = {size = 8, cycles = 4}                 -- JB/JNAE rel8		#
m["73"] = {size = 8, cycles = 4}                 -- JNB/JAE rel8		#
m["74"] = {size = 8, cycles = 4}                 -- JE/JZ rel8			#
m["75"] = {size = 8, cycles = 4}                 -- JNE/JNZ rel8		#
m["76"] = {size = 8, cycles = 4}                 -- JBE/JNA rel8		#
m["77"] = {size = 8, cycles = 4}                 -- JNBE/JA rel8		#
m["78"] = {size = 8, cycles = 4}                 -- JS rel8				#
m["79"] = {size = 8, cycles = 4}                 -- JNS rel8			#
m["7A"] = {size = 8, cycles = 4}                 -- JP/JPE rel8			#
m["7B"] = {size = 8, cycles = 4}                 -- JNP/JPO rel8		#
m["7C"] = {size = 8, cycles = 4}                 -- JL/JNGE rel8		#
m["7D"] = {size = 8, cycles = 4}                 -- JNL/JGE rel8		#
m["7E"] = {size = 8, cycles = 4}                 -- JLE/JNG rel8		#
m["7F"] = {size = 8, cycles = 4}                 -- JNLE/JG rel8		#

-- 8x
m["80"] = {size = 8, modrm = true, cycles = 4}   -- _ALU1 r/m8, d8		#
m["81"] = {size = 16, modrm = true, cycles = 4}  -- _ALU1 r/m16, d16	#
m["82"] = {size = 8, modrm = true, cycles = 4}   -- *_ALU1 r/m8, d8		#
m["83"] = {size = 16, modrm = true, cycles = 4}  -- _ALU1 r/m16, d8		#
m["84"] = {size = 8, modrm = true, cycles = 3}   -- TEST r/m8, r8		#
m["85"] = {size = 16, modrm = true, cycles = 3}  -- TEST r/m16, r16		#
m["86"] = {size = 8, modrm = true, cycles = 4}   -- XCHG r8, r/m8		#
m["87"] = {size = 16, modrm = true, cycles = 4}  -- XCHG r16, r/m16		#
m["88"] = {size = 8, modrm = true, cycles = 2}   -- MOV r/m8, r8		#
m["89"] = {size = 16, modrm = true, cycles = 2}  -- MOV r/m16, r16		#
m["8A"] = {size = 8, modrm = true, cycles = 2}   -- MOV r8, r/m8		#
m["8B"] = {size = 16, modrm = true, cycles = 2}  -- MOV r16, r/m16		#
m["8C"] = {size = 16, modrm = true, cycles = 2}  -- _MOV r/m16, sr		#
m["8D"] = {size = 16, modrm = true, cycles = 2}  -- LEA r16, r/m16		#
m["8E"] = {size = 16, modrm = true, cycles = 2}  -- _MOV sr, r/m16		#
m["8F"] = {size = 16, modrm = true, cycles = 12} -- _POP r/m16			#

-- 9x
m["90"] = {size = 0, cycles = 3}                 -- NOP					#
m["91"] = {size = 16, cycles = 3}                -- XCHG AX, CX			#
m["92"] = {size = 16, cycles = 3}                -- XCHG AX, DX			#
m["93"] = {size = 16, cycles = 3}                -- XCHG AX, BX			#
m["94"] = {size = 16, cycles = 3}                -- XCHG AX, SP			#
m["95"] = {size = 16, cycles = 3}                -- XCHG AX, BP			#
m["96"] = {size = 16, cycles = 3}                -- XCHG AX, SI			#
m["97"] = {size = 16, cycles = 3}                -- XCHG AX, DI			#
m["98"] = {size = 0, cycles = 2}                 -- CBW					#
m["99"] = {size = 0, cycles = 5}                 -- CWD					#					
m["9A"] = {size = 32, cycles = 36}               -- CALL seg:a16		#
m["9B"] = {size = 0, cycles = 4}                 -- WAIT				#	
m["9C"] = {size = 0, cycles = 14}                -- PUSHF				#	
m["9D"] = {size = 0, cycles = 12}                -- POPF				#
m["9E"] = {size = 0, cycles = 4}                 -- SAHF				#
m["9F"] = {size = 0, cycles = 4}                 -- LAHF				#

-- Ax
m["A0"] = {size = 8, cycles = 14}                -- MOV AL, [addr]		#
m["A1"] = {size = 16, cycles = 14}               -- MOV AX, [addr]		#
m["A2"] = {size = 8, cycles = 14}                -- MOV [addr], AL		#
m["A3"] = {size = 16, cycles = 14}               -- MOV [addr], AX		#
m["A4"] = {size = 0, cycles = 18}                -- MOVSB				#	
m["A5"] = {size = 0, cycles = 26}                -- MOVSW				#	
m["A6"] = {size = 0, cycles = 22}                -- CMPSB				#
m["A7"] = {size = 0, cycles = 30}                -- CMPSW				#
m["A8"] = {size = 8, cycles = 4}                 -- TEST AL, d8			#
m["A9"] = {size = 16, cycles = 4}                -- TEST AX, d16		#
m["AA"] = {size = 0, cycles = 11}                -- STOSB				#
m["AB"] = {size = 0, cycles = 15}                -- STOSW				#
m["AC"] = {size = 0, cycles = 12}                -- LODSB				#
m["AD"] = {size = 0, cycles = 16}                -- LODSW				#
m["AE"] = {size = 0, cycles = 15}                -- SCASB				#
m["AF"] = {size = 0, cycles = 19}                -- SCASW				#

-- Bx
m["B0"] = {size = 8, cycles = 4}                 -- MOV AL, d8			#
m["B1"] = {size = 8, cycles = 4}                 -- MOV CL, d8			#
m["B2"] = {size = 8, cycles = 4}                 -- MOV DL, d8			#
m["B3"] = {size = 8, cycles = 4}                 -- MOV BL, d8			#
m["B4"] = {size = 8, cycles = 4}                 -- MOV AH, d8			#
m["B5"] = {size = 8, cycles = 4}                 -- MOV CH, d8			#
m["B6"] = {size = 8, cycles = 4}                 -- MOV DH, d8			#
m["B7"] = {size = 8, cycles = 4}                 -- MOV BH, d8			#
m["B8"] = {size = 16, cycles = 4}                -- MOV AX, d16			#
m["B9"] = {size = 16, cycles = 4}                -- MOV CX, d16			#
m["BA"] = {size = 16, cycles = 4}                -- MOV DX, d16			#
m["BB"] = {size = 16, cycles = 4}                -- MOV BX, d16			#
m["BC"] = {size = 16, cycles = 4}                -- MOV SP, d16			#
m["BD"] = {size = 16, cycles = 4}                -- MOV BP, d16			#	
m["BE"] = {size = 16, cycles = 4}                -- MOV SI, d16			#	
m["BF"] = {size = 16, cycles = 4}                -- MOV DI, d16			#	

-- Cx
m["C0"] = {size = 0, cycles = 0}                 -- (empty)					
m["C1"] = {size = 0, cycles = 0}                 -- (empty)
m["C2"] = {size = 16, cycles = 24}               -- RET d16				#
m["C3"] = {size = 0, cycles = 20}                -- RET					#
m["C4"] = {size = 32, modrm = true, cycles = 24} -- LES r16, m32		#
m["C5"] = {size = 32, modrm = true, cycles = 24} -- LDS r16, m32		#
m["C6"] = {size = 8, modrm = true, cycles = 4}   -- _MOV r/m8, d8		#	
m["C7"] = {size = 16, modrm = true, cycles = 4}  -- _MOV r/m16, d16		#
m["C8"] = {size = 0, cycles = 0}                 -- (empty)
m["C9"] = {size = 0, cycles = 0}                 -- (empty)
m["CA"] = {size = 16, cycles = 34}               -- RETF d16			#	
m["CB"] = {size = 0, cycles = 33}                -- RETF				#
m["CC"] = {size = 0, cycles = 72}                -- INT 3				#
m["CD"] = {size = 8, cycles = 71}                -- INT d8				#
m["CE"] = {size = 0, cycles = 73}                -- INTO				#
m["CF"] = {size = 0, cycles = 44}                -- IRET				#

-- Dx
m["D0"] = {size = 8, modrm = true, cycles = 2}   -- _ROT r/m8, 1		#	
m["D1"] = {size = 16, modrm = true, cycles = 2}  -- _ROT r/m16, 1		#
m["D2"] = {size = 8, modrm = true, cycles = 8}   -- _ROT r/m8, CL		#
m["D3"] = {size = 16, modrm = true, cycles = 8}  -- _ROT r/m16, CL		#
m["D4"] = {size = 8, cycles = 83}                -- AAM *d8				#	
m["D5"] = {size = 8, cycles = 60}                -- AAD *d8				#
m["D6"] = {size = 0, cycles = 2}                 -- *SALC				#
m["D7"] = {size = 0, cycles = 11}                -- XLAT				#
m["D8"] = {size = 0, cycles = 2}                 -- ESC 0				#
m["D9"] = {size = 0, cycles = 2}                 -- ESC 1				#
m["DA"] = {size = 0, cycles = 2}                 -- ESC 2				#
m["DB"] = {size = 0, cycles = 2}                 -- ESC 3				#
m["DC"] = {size = 0, cycles = 2}                 -- ESC 4				#
m["DD"] = {size = 0, cycles = 2}                 -- ESC 5				#
m["DE"] = {size = 0, cycles = 2}                 -- ESC 6				#
m["DF"] = {size = 0, cycles = 2}                 -- ESC 7				#

-- Ex
m["E0"] = {size = 8, cycles = 18}                -- LOOPNZ/NE rel8		#
m["E1"] = {size = 8, cycles = 18}                -- LOOPZ/E rel8		#
m["E2"] = {size = 8, cycles = 17}                -- LOOP rel8			#
m["E3"] = {size = 8, cycles = 18}                -- JCXZ rel8			#
m["E4"] = {size = 8, cycles = 14}                -- IN AL, [d8]			#
m["E5"] = {size = 16, cycles = 14}               -- IN AX, [d8]			#
m["E6"] = {size = 8, cycles = 14}                -- OUT [d8], AL		#
m["E7"] = {size = 16, cycles = 14}               -- OUT [d8], AX		#
m["E8"] = {size = 16, cycles = 23}               -- CALL rel16			#
m["E9"] = {size = 16, cycles = 15}               -- JMP rel16			#
m["EA"] = {size = 32, cycles = 15}               -- JMP seg:a16			#
m["EB"] = {size = 8, cycles = 15}                -- JMP rel8			#
m["EC"] = {size = 8, cycles = 12}                -- IN AL, [DX]			#
m["ED"] = {size = 16, cycles = 12}               -- IN AX, [DX]			#
m["EE"] = {size = 8, cycles = 12}                -- OUT [DX], AL		#
m["EF"] = {size = 16, cycles = 12}               -- OUT [DX], AX		#

-- Fx
m["F0"] = {size = 0, cycles = 2}                 -- LOCK				#
m["F1"] = {size = 0, cycles = 0}                 -- (empty)
m["F2"] = {size = 0, cycles = 0}                 -- REPNE/REPNZ			#
m["F3"] = {size = 0, cycles = 0}                 -- REP/REPE/REPZ		#
m["F4"] = {size = 0, cycles = 2}                 -- HLT					#
m["F5"] = {size = 0, cycles = 2}                 -- CMC					#
m["F6"] = {size = 8, modrm = true, cycles = 2}   -- _ALU2 r/m8, d8		#
m["F7"] = {size = 16, modrm = true, cycles = 2}  -- _ALU2 r/m16, d16	#
m["F8"] = {size = 0, cycles = 2}                 -- CLC					#
m["F9"] = {size = 0, cycles = 2}                 -- STC					#
m["FA"] = {size = 0, cycles = 2}                 -- CLI					#
m["FB"] = {size = 0, cycles = 2}                 -- STI					#
m["FC"] = {size = 0, cycles = 2}                 -- CLD					#
m["FD"] = {size = 0, cycles = 2}                 -- STD					#
m["FE"] = {size = 8, modrm = true, cycles = 3}   -- _MISC r/m8
m["FF"] = {size = 16, modrm = true, cycles = 3}  -- _MISC r/m16




return m
