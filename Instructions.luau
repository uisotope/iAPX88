local replicatedStorage = game:GetService("ReplicatedStorage")
local register = require(replicatedStorage.CPU.Registers)
local rread, rwrite = register.read, register.write
local ram = require(replicatedStorage.CPU.RAM)
local read, write = ram.read, ram.write
local io = require(replicatedStorage.CPU.IOManager)
local utils = require(replicatedStorage.CPU.Utilities)
local read16, write16 = utils.littleEndianRead16, utils.littleEndianWrite16
local decode = utils.decodeInstruction
local op = utils.calculateWithFlags
local regCodes = require(replicatedStorage.CPU.RegisterCodes)
local ioUpdate = replicatedStorage.Remote.ioUpdate

local cycle = 0
local bit = bit32
local functions = {}


local function incIP (value)
	rwrite("IP", rread("IP") + value)
end

local function parity(val)
	local byte = bit.band(val, 0xFF)
	local bits = 0
	for i=0,7 do
		bits = bits + bit.band(bit.rshift(byte, i), 1)
	end
	return (bits % 2 == 0) and 1 or 0
end

setmetatable(functions, {
	__index = function(_, opcode)
		return function() error("Unimplemented opcode: 0x"..opcode) end
	end
})

functions.execute = function (opcode, addr)
	functions[opcode](addr)
end

-- 0x

functions["00"] = function (addr)	-- ADD r/m8, r8
	local d = decode(addr)
	if not d.effectiveAddress then
		rwrite(d.regSource, op("add", rread(d.regSource), rread(d.regDest)))
		incIP(d.length)
	else
		write(d.effectiveAddress, op("add", rread(d.regSource), read(d.effectiveAddress)))
		incIP(d.length)
	end
end

functions["01"] = function (addr)	-- ADD r/m16, r16
	local d = decode(addr)
	if not d.effectiveAddress then
		rwrite(d.regDest, op("add", rread(d.regDest), rread(d.regSource), 16))
		incIP(d.length)
	else
		write16(d.effectiveAddress, op("add", rread(d.regSource), read16(d.effectiveAddress), 16))
		incIP(d.length)
	end
end

functions["02"] = function (addr)	-- ADD r8, r/m8
	local d = decode(addr)
	if not d.effectiveAddress then
		rwrite(d.regSource, op("add", rread(d.regSource), rread(d.regDest)))
		incIP(d.length)
	else
		rwrite(d.regSource, op("add", rread(d.regSource), read(d.effectiveAddress)))
		incIP(d.length)
	end
end

functions["03"] = function (addr)	-- ADD r16, r/m16
	local d = decode(addr)
	if not d.effectiveAddress then
		rwrite(d.regSource, op("add", rread(d.regSource), rread(d.regDest), 16))
		incIP(d.length)
	else	
		rwrite(d.regSource, op("add", rread(d.regSource), read16(d.effectiveAddress), 16))
		incIP(d.length)
	end
end

functions["04"] = function (addr)	-- ADD AL, d8	
	rwrite("AL", op("add", rread("AL"), read(addr + 1)))
	incIP(2)
end

functions["05"] = function (addr)	-- ADD AX, d16	
	rwrite("AX", op("add", rread("AX"), read16(addr + 1), 16))
	incIP(3)
end

functions["06"] = function (addr)	-- PUSH ES		
	rwrite("SP", rread("SP") - 2)
	write16(rread("SP") + rread("SS") * 16, rread("ES"))
	incIP(1)
end

functions["07"] = function (addr)	-- POP ES	
	rwrite("ES", read16(rread("SP") + rread("SS") * 16))
	rwrite("SP", rread("SP") + 2)
	incIP(1)
end

functions["08"] = function (addr)	-- OR r/m8, r8	
	local d = decode(addr)
	if not d.effectiveAddress then
		rwrite(d.regSource, op("or", rread(d.regSource), rread(d.regDest)))
		incIP(d.length)
	else
		write(d.effectiveAddress, op("or", rread(d.regSource), read(d.effectiveAddress)))
		incIP(d.length)
	end
end

functions["09"] = function (addr)	-- OR r/m16, r16
	local d = decode(addr)
	if not d.effectiveAddress then
		rwrite(d.regDest, op("or", rread(d.regSource), rread(d.regDest), 16))
		incIP(d.length)
	else
		write16(d.effectiveAddress, op("or", rread(d.regSource), read16(d.effectiveAddress), 16))
		incIP(d.length)
	end
end

functions["0A"] = function (addr)	-- OR r8, r/m8
	local d = decode(addr)
	if not d.effectiveAddress then
		rwrite(d.regSource, op("or", rread(d.regSource), rread(d.regDest)))
		incIP(d.length)
	else
		write(d.effectiveAddress, op("or", rread(d.regSource), read(d.effectiveAddress)))
		incIP(d.length)
	end
end

functions["0B"] = function (addr)	-- OR r16, r/m16	
	local d = decode(addr)
	if not d.effectiveAddress then
		rwrite(d.regDest, op("or", rread(d.regSource), rread(d.regDest), 16))
		incIP(d.length)
	else
		write16(d.effectiveAddress, op("or", rread(d.regSource), read16(d.effectiveAddress), 16))
		incIP(d.length)
	end
end

functions["0C"] = function (addr)	-- OR AL, d8
	rwrite("AL", op("or", rread("AL"), read(addr + 1)))
	incIP(2)
end

functions["0D"] = function (addr)	-- OR AX, d16
	rwrite("AX", op("or", rread("AX"), read16(addr + 1), 16))
	incIP(3)
end

functions["0E"] = function (addr)	-- PUSH CS		
	rwrite("SP", rread("SP") - 2)
	write16(rread("SP") + rread("SS") * 16, rread("CS"))
	incIP(1)
end

functions["0F"] = function (addr)	-- POP CS	
	rwrite("CS", read16(rread("SP") + rread("SS") * 16))
	rwrite("SP", rread("SP") + 2)
	incIP(1)
end

-- 1x

functions["10"] = function (addr)	-- ADC r/m8, r8
	local d = decode(addr)
	if not d.effectiveAddress then
		rwrite(d.regSource, op("adc", rread(d.regSource), rread(d.regDest)))
		incIP(d.length)
	else
		write(d.effectiveAddress, op("adc", rread(d.regSource), read(d.effectiveAddress)))
		incIP(d.length)
	end
end

functions["11"] = function (addr)	-- ADC r/m16, r16
	local d = decode(addr)
	if not d.effectiveAddress then
		rwrite(d.regSource, op("adc", rread(d.regSource), rread(d.regDest), 16))
		incIP(d.length)
	else
		write16(d.effectiveAddress, op("adc", rread(d.regSource), read16(d.effectiveAddress), 16))
		incIP(d.length)
	end
end

functions["12"] = function (addr)	-- ADC r8, r/m8
	local d = decode(addr)
	if not d.effectiveAddress then
		rwrite(d.regSource, op("adc", rread(d.regSource), rread(d.regDest)))
		incIP(d.length)
	else
		rwrite(d.regSource, op("adc", rread(d.regSource), read(d.effectiveAddress)))
		incIP(d.length)
	end
end

functions["13"] = function (addr)	-- ADC r16, r/m16
	local d = decode(addr)
	if not d.effectiveAddress then
		rwrite(d.regSource, op("adc", rread(d.regSource), rread(d.regDest), 16))
		incIP(d.length)
	else
		rwrite(d.regSource, op("adc", rread(d.regSource), read16(d.effectiveAddress), 16))
		incIP(d.length)
	end
end

functions["14"] = function (addr)	-- ADC AL, d8	
	rwrite("AL", op("adc", rread("AL"), read(addr + 1)))
	incIP(2)
end

functions["15"] = function (addr)	-- ADC AX, d16	
	rwrite("AX", op("adc", rread("AX"), read16(addr + 1), 16))
	incIP(3)
end

functions["16"] = function (addr)	-- PUSH SS		
	rwrite("SP", rread("SP") - 2)
	write16(rread("SP") + rread("SS") * 16, rread("SS"))
	incIP(1)
end

functions["17"] = function (addr)	 -- POP SS
	rwrite("SS", read16(rread("SP") + rread("SS") * 16))
	rwrite("SP", rread("SP") + 2)
	incIP(1)
end

functions["18"] = function (addr)	-- SBB r/m8, r8
	local d = decode(addr)
	if not d.effectiveAddress then
		rwrite(d.regSource, op("sbb", rread(d.regSource), rread(d.regDest)))
		incIP(d.length)
	else
		write(d.effectiveAddress, op("sbb", rread(d.regSource), read(d.effectiveAddress)))
		incIP(d.length)
	end
end

functions["19"] = function (addr)	-- SBB r/m16, r16
	local d = decode(addr)
	if not d.effectiveAddress then
		rwrite(d.regSource, op("sbb", rread(d.regSource), rread(d.regDest), 16))
		incIP(d.length)
	else
		write16(d.effectiveAddress, op("sbb", rread(d.regSource), read16(d.effectiveAddress), 16))
		incIP(d.length)
	end
end

functions["1A"] = function (addr)	-- SBB r8, r/m8
	local d = decode(addr)
	if not d.effectiveAddress then
		rwrite(d.regSource, op("sbb", rread(d.regSource), rread(d.regDest)))
		incIP(d.length)
	else
		rwrite(d.regSource, op("sbb", rread(d.regSource), read(d.effectiveAddress)))
		incIP(d.length)
	end
end

functions["1B"] = function (addr)	-- SBB r16, r/m16
	local d = decode(addr)
	if not d.effectiveAddress then
		rwrite(d.regSource, op("sbb", rread(d.regSource), rread(d.regDest), 16))
		incIP(d.length)
	else
		rwrite(d.regSource, op("sbb", rread(d.regSource), read16(d.effectiveAddress), 16))
		incIP(d.length)
	end
end

functions["1C"] = function (addr)	-- SBB AL, d8	
	rwrite("AL", op("sbb", rread("AL"), read(addr + 1)))
	incIP(2)
end

functions["1D"] = function (addr)	-- SBB AX, d16	
	rwrite("AX", op("sbb", rread("AX"), read16(addr + 1), 16))
	incIP(3)
end

functions["1E"] = function (addr)	-- PUSH DS		
	rwrite("SP", rread("SP") - 2)
	write16(rread("SP") + rread("SS") * 16, rread("DS"))
	incIP(1)
end

functions["1F"] = function(addr)	-- POP DS
	rwrite("DS", read16(rread("SP") + rread("SS") * 16))
	rwrite("SP", rread("SP") + 2)
	incIP(1)
end

-- 2x

functions["20"] = function (addr)	-- AND r/m8, r8
	local d = decode(addr)
	if not d.effectiveAddress then
		rwrite(d.regSource, op("and", rread(d.regSource), rread(d.regDest)))
		incIP(d.length)
	else
		write(d.effectiveAddress, op("and", rread(d.regSource), read(d.effectiveAddress)))
		incIP(d.length)
	end
end

functions["21"] = function (addr)	-- AND r/m16, r16
	local d = decode(addr)
	if not d.effectiveAddress then
		rwrite(d.regSource, op("and", rread(d.regSource), rread(d.regDest), 16))
		incIP(d.length)
	else
		write16(d.effectiveAddress, op("and", rread(d.regSource), read16(d.effectiveAddress), 16))
		incIP(d.length)
	end
end

functions["22"] = function (addr)	-- AND r8, r/m8
	local d = decode(addr)
	if not d.effectiveAddress then
		rwrite(d.regSource, op("and", rread(d.regSource), rread(d.regDest)))
		incIP(d.length)
	else
		rwrite(d.regSource, op("and", rread(d.regSource), read(d.effectiveAddress)))
		incIP(d.length)
	end
end

functions["23"] = function (addr)	-- AND r16, r/m16
	local d = decode(addr)
	if not d.effectiveAddress then
		rwrite(d.regSource, op("and", rread(d.regSource), rread(d.regDest), 16))
		incIP(d.length)
	else
		rwrite(d.regSource, op("and", rread(d.regSource), read16(d.effectiveAddress), 16))
		incIP(d.length)
	end
end

functions["24"] = function (addr)	-- AND AL, d8	
	rwrite("AL", op("and", rread("AL"), read(addr + 1)))
	incIP(2)
end

functions["25"] = function (addr)	-- AND AX, d16	
	rwrite("AX", op("and", rread("AX"), read16(addr + 1), 16))
	incIP(3)
end

functions["26"] = function (addr)	-- ES:		
	-- PASS
end

functions["27"] = function (addr)	-- DAA
	if (bit.band(rread("AL"), 0x0F) > 9 or rread("AF")) then
		rwrite("AL", rread("AL") + 6)
		rwrite("AF", true)
	else
		rwrite("AF", false)
	end
	if (rread("AL") > 0x9F or rread("CF")) then
		rwrite("AL", rread("AL") + 0x60)
		rwrite("CF", true)
	else
		rwrite("CF", false)
	end
	incIP(1)
end

functions["28"] = function (addr)	-- SUB r/m8, r8
	local d = decode(addr)
	if not d.effectiveAddress then
		rwrite(d.regSource, op("sub", rread(d.regSource), rread(d.regDest)))
		incIP(d.length)
	else
		write(d.effectiveAddress, op("sub", rread(d.regSource), read(d.effectiveAddress)))
		incIP(d.length)
	end
end

functions["29"] = function (addr)	-- SUB r/m16, r16
	local d = decode(addr)
	if not d.effectiveAddress then
		rwrite(d.regSource, op("sub", rread(d.regSource), rread(d.regDest), 16))
		incIP(d.length)
	else
		write16(d.effectiveAddress, op("sub", rread(d.regSource), read16(d.effectiveAddress), 16))
		incIP(d.length)
	end
end

functions["2A"] = function (addr)	-- SUB r8, r/m8
	local d = decode(addr)
	if not d.effectiveAddress then
		rwrite(d.regSource, op("sub", rread(d.regSource), rread(d.regDest)))
		incIP(d.length)
	else
		rwrite(d.regSource, op("sub", rread(d.regSource), read(d.effectiveAddress)))
		incIP(d.length)
	end
end

functions["2B"] = function (addr)	-- SUB r16, r/m16
	local d = decode(addr)
	if not d.effectiveAddress then
		rwrite(d.regSource, op("sub", rread(d.regSource), rread(d.regDest), 16))
		incIP(d.length)
	else
		rwrite(d.regSource, op("sub", rread(d.regSource), read16(d.effectiveAddress), 16))
		incIP(d.length)
	end
end

functions["2C"] = function (addr)	-- SUB AL, d8	
	rwrite("AL", op("sub", rread("AL"), read(addr + 1)))
	incIP(2)
end

functions["2D"] = function (addr)	-- SUB AX, d16	
	rwrite("AX", op("sub", rread("AX"), read16(addr + 1), 16))
	incIP(3)
end

functions["2E"] = function (addr)	-- CS:		
	-- PASS
end

functions["2F"] = function (addr)	-- DAS
	if (bit.band(rread("AL"), 0x0F) > 9 or rread("AF")) then
		rwrite("AL", rread("AL") - 6)
		rwrite("AF", true)
	else
		rwrite("AF", false)
	end
	if (rread("AL") > 0x99 or rread("CF")) then
		rwrite("AL", rread("AL") - 0x60)
		rwrite("CF", true)
	else
		rwrite("CF", false)
	end
	incIP(1)
end

-- 3x

functions["30"] = function (addr)	-- XOR r/m8, r8	
	local d = decode(addr)
	if not d.effectiveAddress then
		rwrite(d.regSource, op("xor", rread(d.regSource), rread(d.regDest)))
		incIP(d.length)
	else
		write(d.effectiveAddress, op("xor", rread(d.regSource), read(d.effectiveAddress)))
		incIP(d.length)
	end
end

functions["31"] = function (addr)	-- XOR r/m16, r16
	local d = decode(addr)
	if not d.effectiveAddress then
		rwrite(d.regDest, op("xor", rread(d.regSource), rread(d.regDest), 16))
		incIP(d.length)
	else
		write16(d.effectiveAddress, op("xor", rread(d.regSource), read16(d.effectiveAddress), 16))
		incIP(d.length)
	end
end

functions["32"] = function (addr)	-- XOR r8, r/m8
	local d = decode(addr)
	if not d.effectiveAddress then
		rwrite(d.regSource, op("xor", rread(d.regSource), rread(d.regDest)))
		incIP(d.length)
	else
		write(d.effectiveAddress, op("xor", rread(d.regSource), read(d.effectiveAddress)))
		incIP(d.length)
	end
end

functions["33"] = function (addr)	-- XOR r16, r/m16	
	local d = decode(addr)
	if not d.effectiveAddress then
		rwrite(d.regDest, op("xor", rread(d.regSource), rread(d.regDest), 16))
		incIP(d.length)
	else
		write16(d.effectiveAddress, op("xor", rread(d.regSource), read16(d.effectiveAddress), 16))
		incIP(d.length)
	end
end

functions["34"] = function (addr)	-- XOR AL, d8
	rwrite("AL", op("xor", rread("AL"), read(addr + 1)))
	incIP(2)
end

functions["35"] = function (addr)	-- XOR AX, d16
	rwrite("AX", op("xor", rread("AX"), read16(addr + 1), 16))
	incIP(3)
end

functions["36"] = function (addr)	-- SS:
	-- PASS
end

functions["37"] = function (addr)	-- AAA
	if (bit.band(rread("AL"), 0x0F) > 9 or rread("AF")) then
		rwrite("AL", bit.band(rread("AL") + 6, 0x0F))
		rwrite("AH", rread("AH") + 1)
		rwrite("AF", 1)
		rwrite("CF", 1)
	else
		rwrite("AF", 0)
		rwrite("CF", 0)
	end
	incIP(1)
end

functions["38"] = function (addr)	-- CMP r/m8, r8	
	local d = decode(addr)
	if not d.effectiveAddress then
		op("sub", rread(d.regSource), rread(d.regDest))
		incIP(d.length)
	else
		op("sub", rread(d.regSource), read(d.effectiveAddress))
		incIP(d.length)
	end
end

functions["39"] = function (addr)	-- CMP r/m16, r16
	local d = decode(addr)
	if not d.effectiveAddress then
		op("sub", rread(d.regSource), rread(d.regDest), 16)
		incIP(d.length)
	else
		op("sub", rread(d.regSource), read16(d.effectiveAddress), 16)
		incIP(d.length)
	end
end

functions["3A"] = function (addr)	-- CMP r8, r/m8
	local d = decode(addr)
	if not d.effectiveAddress then
		op("sub", rread(d.regSource), rread(d.regDest))
		incIP(d.length)
	else
		op("sub", rread(d.regSource), read(d.effectiveAddress))
		incIP(d.length)
	end
end

functions["3B"] = function (addr)	-- CMP r16, r/m16	
	local d = decode(addr)
	if not d.effectiveAddress then
		op("sub", rread(d.regSource), rread(d.regDest), 16)
		incIP(d.length)
	else
		op("sub", rread(d.regSource), read16(d.effectiveAddress), 16)
		incIP(d.length)
	end
end

functions["3C"] = function (addr)	-- CMP AL, d8
	op("sub", rread("AL"), read(addr + 1))
	incIP(2)
end

functions["3D"] = function (addr)	-- CMP AX, d16
	op("xor", rread("AX"), read16(addr + 1), 16)
	incIP(3)
end

functions["3E"] = function (addr)	-- DS:
	-- PASS
end

functions["3F"] = function (addr) -- AAS
	if (bit.band(rread("AL"), 0x0F) > 9 or rread("AF")) then
		rwrite("AL", bit.band(rread("AL") - 6, 0x0F))
		rwrite("AH", rread("AH") - 1)
		rwrite("AF", 1)
		rwrite("CF", 1)
	else
		rwrite("AF", 0)
		rwrite("CF", 0)
	end
	incIP(1)
end

-- 4x

functions["40"] = function (addr) -- INC AX
	rwrite("AX", op("inc", rread("AX"), 1, 16))
	incIP(1)
end

functions["41"] = function (addr) -- INC CX
	rwrite("CX", op("inc", rread("CX"), 1, 16))
	incIP(1)
end

functions["42"] = function (addr) -- INC DX
	rwrite("DX", op("inc", rread("DX"), 1, 16))
	incIP(1)
end

functions["43"] = function (addr) -- INC BX
	rwrite("BX", op("inc", rread("BX"), 1, 16))
	incIP(1)
end

functions["44"] = function (addr) -- INC SP
	rwrite("SP", op("inc", rread("SP"), 1, 16))
	incIP(1)
end

functions["45"] = function (addr) -- INC BP
	rwrite("BP", op("inc", rread("BP"), 1, 16))
	incIP(1)
end

functions["46"] = function (addr) -- INC SI
	rwrite("SI", op("inc", rread("SI"), 1, 16))
	incIP(1)
end

functions["47"] = function (addr) -- INC DI
	rwrite("DI", op("inc", rread("DI"), 1, 16))
	incIP(1)
end

functions["48"] = function (addr) -- DEC AX
	rwrite("AX", op("dec", rread("AX"), 1, 16))
	incIP(1)
end

functions["49"] = function (addr) -- DEC CX
	rwrite("CX", op("dec", rread("CX"), 1, 16))
	incIP(1)
end

functions["4A"] = function (addr) -- DEC DX
	rwrite("DX", op("dec", rread("DX"), 1, 16))
	incIP(1)
end

functions["4B"] = function (addr) -- DEC BX
	rwrite("BX", op("dec", rread("BX"), 1, 16))
	incIP(1)
end

functions["4C"] = function (addr) -- DEC SP
	rwrite("SP", op("dec", rread("SP"), 1, 16))
	incIP(1)
end

functions["4D"] = function (addr) -- DEC BP
	rwrite("BP", op("dec", rread("BP"), 1, 16))
	incIP(1)
end

functions["4E"] = function (addr) -- DEC SI
	rwrite("SI", op("dec", rread("SI"), 1, 16))
	incIP(1)
end

functions["4F"] = function (addr) -- DEC DI
	rwrite("DI", op("dec", rread("DI"), 1, 16))
	incIP(1)
end

-- 5x

functions["50"] = function (addr)	-- PUSH AX		
	rwrite("SP", rread("SP") - 2)
	write16(rread("SP") + rread("SS") * 16, rread("AX"))
	incIP(1)
end

functions["51"] = function (addr)	-- PUSH CX		
	rwrite("SP", rread("SP") - 2)
	write16(rread("SP") + rread("SS") * 16, rread("CX"))
	incIP(1)
end

functions["52"] = function (addr)	-- PUSH DX		
	rwrite("SP", rread("SP") - 2)
	write16(rread("SP") + rread("SS") * 16, rread("DX"))
	incIP(1)
end

functions["53"] = function (addr)	-- PUSH BX		
	rwrite("SP", rread("SP") - 2)
	write16(rread("SP") + rread("SS") * 16, rread("BX"))
	incIP(1)
end

functions["54"] = function (addr)	-- PUSH SP		
	rwrite("SP", rread("SP") - 2)
	write16(rread("SP") + rread("SS") * 16, rread("SP"))
	incIP(1)
end

functions["55"] = function (addr)	-- PUSH BP		
	rwrite("SP", rread("SP") - 2)
	write16(rread("SP") + rread("SS") * 16, rread("BP"))
	incIP(1)
end

functions["56"] = function (addr)	-- PUSH SI
	rwrite("SP", rread("SP") - 2)
	write16(rread("SP") + rread("SS") * 16, rread("SI"))
	incIP(1)
end

functions["57"] = function (addr)	-- PUSH DI		
	rwrite("SP", rread("SP") - 2)
	write16(rread("SP") + rread("SS") * 16, rread("DI"))
	incIP(1)
end

functions["58"] = function (addr)	-- POP AX	
	rwrite("AX", read16(rread("SP") + rread("SS") * 16))
	rwrite("SP", rread("SP") + 2)
	incIP(1)
end

functions["59"] = function (addr)	-- POP CX
	rwrite("CX", read16(rread("SP") + rread("SS") * 16))
	rwrite("SP", rread("SP") + 2)
	incIP(1)
end

functions["5A"] = function (addr)	-- POP DX
	rwrite("DX", read16(rread("SP") + rread("SS") * 16))
	rwrite("SP", rread("SP") + 2)
	incIP(1)
end

functions["5B"] = function (addr)	-- POP BX	
	rwrite("BX", read16(rread("SP") + rread("SS") * 16))
	rwrite("SP", rread("SP") + 2)
	incIP(1)
end

functions["5C"] = function (addr)	-- POP SP
	rwrite("SP", read16(rread("SP") + rread("SS") * 16))
	rwrite("SP", rread("SP") + 2)
	incIP(1)
end

functions["5D"] = function (addr)	-- POP BP
	rwrite("BP", read16(rread("SP") + rread("SS") * 16))
	rwrite("SP", rread("SP") + 2)
	incIP(1)
end

functions["5E"] = function (addr)	-- POP SI
	rwrite("SI", read16(rread("SP") + rread("SS") * 16))
	rwrite("SP", rread("SP") + 2)
	incIP(1)
end

functions["5F"] = function (addr)	-- POP DI
	rwrite("DI", read16(rread("SP") + rread("SS") * 16))
	rwrite("SP", rread("SP") + 2)
	incIP(1)
end

-- 6x (custom)

functions["60"] = function (addr)	-- PRINT(ADDR)
	print(string.format("0x60 called, address: 0x%X", addr))
	incIP(1)
end

functions["61"] = function (addr)	-- PRINT(MODRM8)
	local d = decode(addr)
	if d.effectiveAddress then
		print(string.format("0x61 called, value: %s", read(d.effectiveAddress)))
	else
		print(string.format("0x61 called, value: %s", rread(d.regSource)))
	end
	incIP(d.length)
end

functions["62"] = function (addr)	-- PRINT(MODRM16)
	local d = decode(addr)
	if d.effectiveAddress then
		print(string.format("0x61 called, value: %s", read(d.effectiveAddress)))
	else
		print(string.format("0x61 called, value: %s", rread(d.regSource)))
	end
	incIP(d.length)
end

functions["63"] = function (addr)	-- REG DUMP
	incIP(1)
	utils.dumpRegs()
end

functions["64"] = function (addr)	-- PASS
	incIP(1)
	warn("Attempt to execute 0x64")
end

functions["65"] = function (addr)	-- PASS
	incIP(1)
	warn("Attempt to execute 0x65")
end

functions["66"] = function (addr)	-- PASS
	incIP(1)
	warn("Attempt to execute 0x66")
end

functions["67"] = function (addr)	-- PASS
	incIP(1)
	warn("Attempt to execute 0x67")
end

functions["68"] = function (addr)	-- PASS
	incIP(1)
	warn("Attempt to execute 0x68")
end

functions["69"] = function (addr)	-- PASS
	incIP(1)
	warn("Attempt to execute 0x69")
end

functions["6A"] = function (addr)	-- PASS
	incIP(1)
	warn("Attempt to execute 0x6A")
end

functions["6B"] = function (addr)	-- PASS
	incIP(1)
	warn("Attempt to execute 0x6B")
end

functions["6C"] = function (addr)	-- PASS
	incIP(1)
	warn("Attempt to execute 0x6C")
end

functions["6D"] = function (addr)	-- PASS
	incIP(1)
	warn("Attempt to execute 0x6D")
end

functions["6E"] = function (addr)	-- PASS
	incIP(1)
	warn("Attempt to execute 0x6E")
end

functions["6F"] = function (addr)	-- PASS
	incIP(1)
	warn("Attempt to execute 0x6F")
end

-- 7x

functions["70"] = function (addr)    -- JO rel8
	if rread("OF") == 1 then
		incIP(2 + utils.toSigned8(read(addr + 1))) 
	else
		incIP(2) 
	end
end

functions["71"] = function (addr)    -- JO rel8
	if rread("OF") == 0 then
		local jmp = utils.toSigned8(read(addr + 1))
		incIP(2 + jmp) 
	else
		incIP(2) 
	end
end

functions["72"] = function (addr)    -- JB/JNAE rel8
	if rread("CF") == 1 then  
		local jmp = utils.toSigned8(read(addr + 1))
		incIP(2 + jmp)
	else
		incIP(2)
	end
end

functions["73"] = function (addr)    -- JNB/JAE rel8
	if rread("CF") == 0 then  
		local jmp = utils.toSigned8(read(addr + 1))
		incIP(2 + jmp)
	else
		incIP(2)
	end
end

functions["74"] = function (addr)    -- JE/JZ rel8
	if rread("ZF") == 1 then
		local jmp = utils.toSigned8(read(addr + 1))
		incIP(2 + jmp)
	else
		incIP(2)
	end
end

functions["75"] = function (addr)    -- JNE/JNZ rel8
	if rread("ZF") == 0 then
		local jmp = utils.toSigned8(read(addr + 1))
		incIP(2 + jmp)
	else
		incIP(2)
	end
end

functions["76"] = function (addr)    -- JBE/JNA rel8
	if rread("CF") == 1 or rread("ZF") == 1 then
		local jmp = utils.toSigned8(read(addr + 1))
		incIP(2 + jmp)
	else
		incIP(2)
	end
end

functions["77"] = function (addr)    -- JNBE/JA rel8
	if rread("CF") == 0 and rread("ZF") == 0 then
		local jmp = utils.toSigned8(read(addr + 1))
		incIP(2 + jmp)
	else
		incIP(2)
	end
end

functions["78"] = function (addr)    -- JS rel8
	if rread("SF") == 1 then
		local jmp = utils.toSigned8(read(addr + 1))
		incIP(2 + jmp)
	else
		incIP(2)
	end
end

functions["79"] = function (addr)    -- JNS rel8
	if rread("SF") == 0 then
		local jmp = utils.toSigned8(read(addr + 1))
		incIP(2 + jmp)
	else
		incIP(2)
	end
end

functions["7A"] = function (addr)    -- JP/JPE rel8
	if rread("PF") == 1 then
		local jmp = utils.toSigned8(read(addr + 1))
		incIP(2 + jmp)
	else
		incIP(2)
	end
end

functions["7B"] = function (addr)    -- JNP/JPO rel8
	if rread("PF") == 0 then
		local jmp = utils.toSigned8(read(addr + 1))
		incIP(2 + jmp)
	else
		incIP(2)
	end
end

functions["7C"] = function (addr)    -- JL/JNGE rel8
	if rread("SF") ~= rread("OF") then
		local jmp = utils.toSigned8(read(addr + 1))
		incIP(2 + jmp)
	else
		incIP(2)
	end
end

functions["7D"] = function (addr)    -- JNL/JGE rel8
	if rread("SF") == rread("OF") then
		local jmp = utils.toSigned8(read(addr + 1))
		incIP(2 + jmp)
	else
		incIP(2)
	end
end

functions["7E"] = function (addr)    -- JLE/JNG rel8
	if rread("ZF") == 1 or rread("SF") ~= rread("OF") then
		local jmp = utils.toSigned8(read(addr + 1))
		incIP(2 + jmp)
	else
		incIP(2)
	end
end

functions["7F"] = function (addr)    -- JNLE/JG rel8
	if rread("ZF") == 0 and rread("SF") == rread("OF") then
		local jmp = utils.toSigned8(read(addr + 1))
		incIP(2 + jmp)
	else
		incIP(2)
	end
end

-- 8x

functions["80"] = function (addr) 	-- _ALU1 r/m8, d8
	local d = decode(addr)
	local imm8 = read(addr + d.length - 1)

	local operation = regCodes[d.modrm.reg]

	if operation == 0 then
		if d.effectiveAddress then
			write(d.effectiveAddress, op("add", read(d.effectiveAddress), imm8))
		else
			rwrite(d.regDest, op("add", rread(d.regDest), imm8))
		end
	elseif operation == 1 then
		if d.effectiveAddress then
			write(d.effectiveAddress, op("or", read(d.effectiveAddress), imm8))
		else
			rwrite(d.regDest, op("or", rread(d.regDest), imm8))
		end
	elseif operation == 2 then
		if d.effectiveAddress then
			write(d.effectiveAddress, op("adc", read(d.effectiveAddress), imm8))
		else
			rwrite(d.regDest, op("adc", rread(d.regDest), imm8))
		end
	elseif operation == 3 then
		if d.effectiveAddress then
			write(d.effectiveAddress, op("sbb", read(d.effectiveAddress), imm8))
		else
			rwrite(d.regDest, op("sbb", rread(d.regDest), imm8))
		end
	elseif operation == 4 then
		if d.effectiveAddress then
			write(d.effectiveAddress, op("and", read(d.effectiveAddress), imm8))
		else
			rwrite(d.regDest, op("and", rread(d.regDest), imm8))
		end
	elseif operation == 5 then
		if d.effectiveAddress then
			write(d.effectiveAddress, op("sub", read(d.effectiveAddress), imm8))
		else
			rwrite(d.regDest, op("sub", rread(d.regDest), imm8))
		end
	elseif operation == 6 then
		if d.effectiveAddress then
			write(d.effectiveAddress, op("xor", read(d.effectiveAddress), imm8))
		else
			rwrite(d.regDest, op("xor", rread(d.regDest), imm8))
		end
	elseif operation == 7 then
		if d.effectiveAddress then
			op("sub", read(d.effectiveAddress), imm8)
		else
			op("sub", rread(d.regDest), imm8)
		end
	end
	incIP(d.length)
end

functions["81"] = function (addr)	-- _ALU1 r/m16, d16
	local d = decode(addr)
	local imm16 = read16(addr + d.length - 2)

	local operation = regCodes.upper[d.modrm.reg]

	if operation == 0 then
		if d.effectiveAddress then
			write16(d.effectiveAddress, op("add", read16(d.effectiveAddress), imm16, 16))
		else
			rwrite(d.regDest, op("add", rread(d.regDest), imm16, 16))
		end
	elseif operation == 1 then
		if d.effectiveAddress then
			write16(d.effectiveAddress, op("or", read16(d.effectiveAddress), imm16, 16))
		else
			rwrite(d.regDest, op("or", rread(d.regDest), imm16, 16))
		end
	elseif operation == 2 then
		if d.effectiveAddress then
			write16(d.effectiveAddress, op("adc", read16(d.effectiveAddress), imm16, 16))
		else
			rwrite(d.regDest, op("adc", rread(d.regDest), imm16, 16))
		end
	elseif operation == 3 then
		if d.effectiveAddress then
			write16(d.effectiveAddress, op("sbb", read16(d.effectiveAddress), imm16, 16))
		else
			rwrite(d.regDest, op("sbb", rread(d.regDest), imm16, 16))
		end
	elseif operation == 4 then
		if d.effectiveAddress then
			write16(d.effectiveAddress, op("and", read16(d.effectiveAddress), imm16, 16))
		else
			rwrite(d.regDest, op("and", rread(d.regDest), imm16, 16))
		end
	elseif operation == 5 then
		if d.effectiveAddress then
			write16(d.effectiveAddress, op("sub", read16(d.effectiveAddress), imm16, 16))
		else
			rwrite(d.regDest, op("sub", rread(d.regDest), imm16, 16))
		end
	elseif operation == 6 then
		if d.effectiveAddress then
			write16(d.effectiveAddress, op("xor", read16(d.effectiveAddress), imm16, 16))
		else
			rwrite(d.regDest, op("xor", rread(d.regDest), imm16, 16))
		end
	elseif operation == 7 then
		if d.effectiveAddress then
			op("sub", read16(d.effectiveAddress), imm16, 16)
		else
			op("sub", rread(d.regDest), imm16, 16)
		end
	else
		error(string.format("Unsupported operation at %X", addr))
	end

	incIP(d.length)
end

functions["82"] = function (addr)	-- *_ALU1 r/m8, d8
	local d = decode(addr)
	local imm8 = read(addr + d.length - 1)
	local operation = regCodes[d.modrm.reg]

	if operation == 0 then
		if d.effectiveAddress then
			write(d.effectiveAddress, op("add", read(d.effectiveAddress), imm8))
		else
			rwrite(d.regDest, op("add", rread(d.regDest), imm8))
		end
	elseif operation == 1 then
		if d.effectiveAddress then
			write(d.effectiveAddress, op("or", read(d.effectiveAddress), imm8))
		else
			rwrite(d.regDest, op("or", rread(d.regDest), imm8))
		end
	elseif operation == 2 then
		if d.effectiveAddress then
			write(d.effectiveAddress, op("adc", read(d.effectiveAddress), imm8))
		else
			rwrite(d.regDest, op("adc", rread(d.regDest), imm8))
		end
	elseif operation == 3 then
		if d.effectiveAddress then
			write(d.effectiveAddress, op("sbb", read(d.effectiveAddress), imm8))
		else
			rwrite(d.regDest, op("sbb", rread(d.regDest), imm8))
		end
	elseif operation == 4 then
		if d.effectiveAddress then
			write(d.effectiveAddress, op("and", read(d.effectiveAddress), imm8))
		else
			rwrite(d.regDest, op("and", rread(d.regDest), imm8))
		end
	elseif operation == 5 then
		if d.effectiveAddress then
			write(d.effectiveAddress, op("sub", read(d.effectiveAddress), imm8))
		else
			rwrite(d.regDest, op("sub", rread(d.regDest), imm8))
		end
	elseif operation == 6 then
		if d.effectiveAddress then
			write(d.effectiveAddress, op("xor", read(d.effectiveAddress), imm8))
		else
			rwrite(d.regDest, op("xor", rread(d.regDest), imm8))
		end
	elseif operation == 7 then
		if d.effectiveAddress then
			op("sub", read(d.effectiveAddress), imm8)
		else
			op("sub", rread(d.regDest), imm8)
		end
	else
		error(string.format("Unsupported operation at %X", addr))
	end

	incIP(d.length)
end

functions["83"] = function (addr)	-- _ALU1 r/m16, d8
	local d = decode(addr)
	local imm16 = read(addr + d.length)
	local operation = regCodes.upper[d.modrm.reg]
	
	if operation == 0 then
		if d.effectiveAddress then
			write16(d.effectiveAddress, op("add", read16(d.effectiveAddress), imm16, 16))
		else
			rwrite(d.regDest, op("add", rread(d.regDest), imm16, 16))
		end
	elseif operation == 1 then
		if d.effectiveAddress then
			write16(d.effectiveAddress, op("or", read16(d.effectiveAddress), imm16, 16))
		else
			rwrite(d.regDest, op("or", rread(d.regDest), imm16, 16))
		end
	elseif operation == 2 then
		if d.effectiveAddress then
			write16(d.effectiveAddress, op("adc", read16(d.effectiveAddress), imm16, 16))
		else
			rwrite(d.regDest, op("adc", rread(d.regDest), imm16, 16))
		end
	elseif operation == 3 then
		if d.effectiveAddress then
			write16(d.effectiveAddress, op("sbb", read16(d.effectiveAddress), imm16, 16))
		else
			rwrite(d.regDest, op("sbb", rread(d.regDest), imm16, 16))
		end
	elseif operation == 4 then
		if d.effectiveAddress then
			write16(d.effectiveAddress, op("and", read16(d.effectiveAddress), imm16, 16))
		else
			rwrite(d.regDest, op("and", rread(d.regDest), imm16, 16))
		end
	elseif operation == 5 then
		if d.effectiveAddress then
			write16(d.effectiveAddress, op("sub", read16(d.effectiveAddress), imm16, 16))
		else
			rwrite(d.regDest, op("sub", rread(d.regDest), imm16, 16))
		end
	elseif operation == 6 then
		if d.effectiveAddress then
			write16(d.effectiveAddress, op("xor", read16(d.effectiveAddress), imm16, 16))
		else
			rwrite(d.regDest, op("xor", rread(d.regDest), imm16, 16))
		end
	elseif operation == 7 then
		if d.effectiveAddress then
			op("sub", read16(d.effectiveAddress), imm16, 16)
		else
			op("sub", rread(d.regDest), imm16, 16)
		end
	end
	incIP(d.length + 1)
end

functions["84"] = function (addr)	-- TEST r/m8, r8
	local d = decode(addr)
	if not d.effectiveAddress then
		op("and", rread(d.regSource), rread(d.regDest))
		incIP(d.length)
	else
		op("and", rread(d.regSource), read(d.effectiveAddress))
		incIP(d.length)
	end
end

functions["85"] = function (addr)	-- TEST r/m16, r16
	local d = decode(addr)
	if not d.effectiveAddress then
		op("and", rread(d.regSource), rread(d.regDest), 16)
		incIP(d.length)
	else
		op("and", rread(d.regSource), read16(d.effectiveAddress), 16)
		incIP(d.length)
	end
end

functions["86"] = function (addr)	-- XCHG r8, r/m8
	local d = decode(addr)
	if not d.effectiveAddress then
		local temp = rread(d.regSource)
		rwrite(d.regSource, rread(d.regDest))
		rwrite(d.regDest, temp)
		incIP(d.length)
	else
		local temp = rread(d.regSource)
		rwrite(d.regSource, read(d.effectiveAddress))
		write(d.effectiveAddress, temp)
		incIP(d.length)
	end
end

functions["87"] = function (addr)	-- XCHG r16, r/m16
	local d = decode(addr)
	if not d.effectiveAddress then
		local temp = rread(d.regSource)
		rwrite(d.regSource, rread(d.regDest))
		rwrite(d.regDest, temp)
		incIP(d.length)
	else
		local temp = rread(d.regSource)
		rwrite(d.regSource, read16(d.effectiveAddress))
		write16(d.effectiveAddress, temp)
		incIP(d.length)
	end
end

functions["88"] = function (addr)	-- MOV r/m8, r8	
	local d = decode(addr)
	if not d.effectiveAddress then
		rwrite(d.regDest, rread(d.regSource))
		incIP(d.length)
	else
		write(d.effectiveAddress, rread(d.regSource))
		incIP(d.length)
	end
end

functions["89"] = function (addr)	-- MOV r/m16, r16
	local d = decode(addr)
	if not d.effectiveAddress then
		rwrite(d.regDest, rread(d.regSource))
		incIP(d.length)
	else
		write16(d.effectiveAddress, rread(d.regSource))
		incIP(d.length)
	end
end

functions["8A"] = function (addr)	-- MOV r8, r/m8
	local d = decode(addr)
	if not d.effectiveAddress then
		rwrite(d.regSource, rread(d.regDest))
		incIP(d.length)
	else
		write(d.effectiveAddress, read(d.effectiveAddress))
		incIP(d.length)
	end
end

functions["8B"] = function (addr)    -- MOV r16, r/m16    
	local d = decode(addr)
	if not d.effectiveAddress then
		rwrite(d.regSource, rread(d.regDest))
	else
		rwrite(d.regSource, read16(d.effectiveAddress))
	end
	incIP(d.length)
end

functions["8C"] = function(addr)	-- _MOV r/m16, sr
	local d = decode(addr)
	local srMap = { [0] = "ES", "CS", "SS", "DS" }
	local sr = srMap[bit.band(regCodes.upper[d.modrm.reg], 0x4)]
	local value = rread(sr)
	if d.effectiveAddress then
		write16(d.effectiveAddress, value)
	else
		rwrite(d.regDest, value)
	end
	incIP(d.length)
end

functions["8D"] = function(addr)	-- LEA r16, r/m16
	local d = decode(addr)
	if d.effectiveAddress then
		rwrite(d.regDest, d.effectiveAddress)
	else
		rwrite(d.regDest, d.regSource)
	end
end

functions["8E"] = function(addr)	-- _MOV sr, r/m16
	local d = decode(addr)
	local srMap = { [0] = "ES", "CS", "SS", "DS" }
	local sr = regCodes.upper[d.modrm.reg]
	local value
	if d.effectiveAddress then
		value = read16(d.effectiveAddress)
	else
		value = rread(d.regDest)
	end
	rwrite(srMap[bit.band(sr, 0x4)], value)
	incIP(d.length)
end

functions["8F"] = function(addr)	-- _POP r/m16	
	local d = decode(addr)
	local sp = rread("SP")
	local ss = rread("SS")
	local value = read16(sp + ss * 16)
	rwrite("SP", sp + 2)
	if d.effectiveAddress then
		write16(d.effectiveAddress, value)
	else
		rwrite(d.regDest, value)
	end
	incIP(d.length)
end

-- 9x

functions["90"] = function(addr)	-- NOP
	incIP(1)
end

functions["91"] = function(addr)	-- XCHG AX, CX
	local temp = rread("AX")
	rwrite("AX", rread("CX"))
	rwrite("CX", temp)
	incIP(1)
end

functions["92"] = function(addr)	-- XCHG AX, DX
	local temp = rread("AX")
	rwrite("AX", rread("DX"))
	rwrite("DX", temp)
	incIP(1)
end

functions["93"] = function(addr)	-- XCHG AX, BX
	local temp = rread("AX")
	rwrite("AX", rread("BX"))
	rwrite("BX", temp)
	incIP(1)
end

functions["94"] = function(addr)	-- XCHG AX, SP
	local temp = rread("AX")
	rwrite("AX", rread("SP"))
	rwrite("SP", temp)
	incIP(1)
end

functions["95"] = function(addr)	-- XCHG AX, BP
	local temp = rread("AX")
	rwrite("AX", rread("BP"))
	rwrite("BP", temp)
	incIP(1)
end

functions["96"] = function(addr)	-- XCHG AX, SI
	local temp = rread("AX")
	rwrite("AX", rread("SI"))
	rwrite("SI", temp)
	incIP(1)
end

functions["97"] = function(addr)	-- XCHG AX, DI
	local temp = rread("AX")
	rwrite("AX", rread("DI"))
	rwrite("DI", temp)
	incIP(1)
end

functions["98"] = function(addr)	-- CBW
	rwrite("AH", bit.rshift(rread("AL"), 7) == 0 and 0x00 or 0xFF)  
	incIP(1)
end

functions["99"] = function(addr)	-- CWD
	rwrite("DX", bit.rshift(rread("AX"), 15) == 0 and 0x0000 or 0xFFFF)
	incIP(1)
end

functions["9A"] = function(addr)	-- CALL seg:a16
	rwrite("SP", rread("SP") - 2)
	write16(rread("SP") + rread("SS") * 16, rread("IP") + 5)
	rwrite("CS", read16(addr + 1))
	rwrite("IP", read16(addr + 3))
end

functions["9B"] = function(addr)	-- WAIT
	local met = rread("test#")
	if met then
		rwrite("hlt", true)
		repeat
			met = rread("test#")
			task.wait()
		until not met 
	end
	incIP(1)
end

functions["9C"] = function(addr)	-- PUSHF
	local flagsValue = 0xF02A
	flagsValue = bit.bor(flagsValue, bit.lshift(rread("CF") and 1 or 0, 0))
	flagsValue = bit.bor(flagsValue, bit.lshift(rread("PF") and 1 or 0, 2))
	flagsValue = bit.bor(flagsValue, bit.lshift(rread("AF") and 1 or 0, 4))
	flagsValue = bit.bor(flagsValue, bit.lshift(rread("ZF") and 1 or 0, 6))
	flagsValue = bit.bor(flagsValue, bit.lshift(rread("SF") and 1 or 0, 7))
	flagsValue = bit.bor(flagsValue, bit.lshift(rread("TF") and 1 or 0, 8))
	flagsValue = bit.bor(flagsValue, bit.lshift(rread("IF") and 1 or 0, 9))
	flagsValue = bit.bor(flagsValue, bit.lshift(rread("DF") and 1 or 0, 10))
	flagsValue = bit.bor(flagsValue, bit.lshift(rread("OF") and 1 or 0, 11))

	rwrite("SP", rread("SP") - 2)
	write16(rread("SP") + rread("SS") * 16, flagsValue)
	incIP(1)
end

functions["9D"] = function(addr)	-- POPF
	local flagsValue = read16(rread("SP") + rread("SS") * 16)

	rwrite("SP", rread("SP") + 2)
	rwrite("CF", bit.band(flagsValue, 0x0001))
	rwrite("PF", bit.band(flagsValue, 0x0004))
	rwrite("AF", bit.band(flagsValue, 0x0010))
	rwrite("ZF", bit.band(flagsValue, 0x0040))
	rwrite("SF", bit.band(flagsValue, 0x0080))
	rwrite("TF", bit.band(flagsValue, 0x0100))
	rwrite("IF", bit.band(flagsValue, 0x0200))
	rwrite("DF", bit.band(flagsValue, 0x0400))
	rwrite("OF", bit.band(flagsValue, 0x0800))

	incIP(1)
end

functions["9E"] = function(addr)	-- SAHF
	local ah = rread("AH")
	rwrite("SF", bit.band(ah, 0x80))
	rwrite("ZF", bit.band(ah, 0x40))
	rwrite("AF", bit.band(ah, 0x10))
	rwrite("PF", bit.band(ah, 0x04))
	rwrite("CF", bit.band(ah, 0x01))

	incIP(1)
end

functions["9F"] = function(addr)	-- LAHF
	local ah = 0x02
	if rread("SF") then ah = bit.bor(ah, 0x80) end
	if rread("ZF") then ah = bit.bor(ah, 0x40) end
	if rread("AF") then ah = bit.bor(ah, 0x10) end
	if rread("PF") then ah = bit.bor(ah, 0x04) end
	if rread("CF") then ah = bit.bor(ah, 0x01) end

	rwrite("AH", ah)
	incIP(1)
end

-- Ax

functions["A0"] = function(addr)	-- MOV AL, [addr]
	local d = decode(addr)
	rwrite("AL", read(d.effectiveAddress))
	incIP(d.length)
end

functions["A1"] = function(addr)	-- MOV AX, [addr]
	local d = decode(addr)
	rwrite("AX", read(d.effectiveAddress))
	incIP(d.length)
end

functions["A2"] = function(addr)	-- MOV [addr], AL
	local d = decode(addr)
	write16(d.effectiveAddress, rread("AL"))
	incIP(d.length)
end

functions["A3"] = function(addr)	-- MOV AX, [addr]
	local d = decode(addr)
	write16(d.effectiveAddress, rread("AX"))
	incIP(d.length)
end

functions["A4"] = function(addr)	-- MOVSB
	local d = decode(addr)
	if d.rep then
		repeat
			if cycle == 0 then
				cycle = d.cycles
				write(rread("ES") * 16 + rread("DI"), read(rread(d.segment) * 16 + rread("SI")))
				local df = rread("DF")
				rwrite("DI", rread("DI") + (df == 0 and 1 or -1))
				rwrite("SI", rread("SI") + (df == 0 and 1 or -1))
				rwrite("CX", op("sub", rread("CX"), 1, 16))
			else
				cycle = cycle - 1
			end
		until rread("CX") == 0
	else
		write(rread("ES") * 16 + rread("DI"), read(rread(d.segment) * 16 + rread("SI")))
		local df = rread("DF")
		rwrite("DI", rread("DI") + (df == 0 and 1 or -1))
		rwrite("SI", rread("SI") + (df == 0 and 1 or -1))
	end
	incIP(d.length)
end

functions["A5"] = function(addr)	-- MOVSW
	local d = decode(addr)
	if d.rep then
		repeat
			if cycle == 0 then
				cycle = d.cycles
				write16(rread("ES") * 16 + rread("DI"), read16(rread(d.segment) * 16 + rread("SI")))
				local df = rread("DF")
				rwrite("DI", rread("DI") + (df == 0 and 2 or -2))
				rwrite("SI", rread("SI") + (df == 0 and 2 or -2))
				rwrite("CX", op("sub", rread("CX"), 1, 16))
			else
				cycle = cycle - 1
			end
		until rread("CX") == 0
	else
		if cycle == 0 then
			cycle = d.cycles
			write16(rread("ES") * 16 + rread("DI"), read16(rread(d.segment) * 16 + rread("SI")))
			local df = rread("DF")
			rwrite("DI", rread("DI") + (df == 0 and 2 or -2))
			rwrite("SI", rread("SI") + (df == 0 and 2 or -2))
		else
			cycle = cycle - 1
		end
	end
	incIP(d.length)
end

functions["A6"] = function(addr)	-- CMPSB
	local d = decode(addr)
	if d.rep == "REPE" then
		repeat
			if cycle == 0 then
				cycle = d.cycles
				op("sub", read(rread(d.segment) * 16 + rread("SI"), read(rread("ES") * 16 + rread("DI"))), 8)
				local df = rread("DF")
				rwrite("DI", rread("DI") + (df == 0 and 1 or -1))
				rwrite("SI", rread("SI") + (df == 0 and 1 or -1))
				rwrite("CX", rread("CX") - 1)
			else
				cycle = cycle - 1
			end
		until rread("CX") == 0 or rread("ZF") == 0
	elseif d.rep == "REPNE" then
		repeat
			if cycle == 0 then
				cycle = d.cycles
				op("sub", read(rread(d.segment) * 16 + rread("SI"), read(rread("ES") * 16 + rread("DI"))), 8)
				local df = rread("DF")
				rwrite("DI", rread("DI") + (df == 0 and 1 or -1))
				rwrite("SI", rread("SI") + (df == 0 and 1 or -1))
				rwrite("CX", rread("CX") - 1)
			else
				cycle = cycle - 1
			end
		until rread("CX") == 0 or rread("ZF") == 1
	else
		op("sub", read(rread(d.segment) * 16 + rread("SI"), read(rread("ES") * 16 + rread("DI"))), 8)
		local df = rread("DF")
		rwrite("DI", rread("DI") + (df == 0 and 1 or -1))
		rwrite("SI", rread("SI") + (df == 0 and 1 or -1))
	end
	incIP(d.length)
end

functions["A7"] = function(addr)	-- CMPSW
	local d = decode(addr)
	if d.rep == "REPE" then
		repeat
			if cycle == 0 then
				cycle = d.cycles
				op("sub", read16(rread(d.segment) * 16 + rread("SI"), read16(rread("ES") * 16 + rread("DI"))), 8)
				local df = rread("DF")
				rwrite("DI", rread("DI") + (df == 0 and 2 or -2))
				rwrite("SI", rread("SI") + (df == 0 and 2 or -2))
				rwrite("CX", rread("CX") - 1)
			else
				cycle = cycle - 1
			end
		until rread("CX") == 0 or rread("ZF") == 0
	elseif d.rep == "REPNE" then
		repeat
			if cycle == 0 then
				cycle = d.cycles
				op("sub", read16(rread(d.segment) * 16 + rread("SI"), read16(rread("ES") * 16 + rread("DI"))), 8)
				local df = rread("DF")
				rwrite("DI", rread("DI") + (df == 0 and 2 or -2))
				rwrite("SI", rread("SI") + (df == 0 and 2 or -2))
				rwrite("CX", rread("CX") - 1)
			else
				cycle = cycle - 1
			end
		until rread("CX") == 0 or rread("ZF") == 1
	else
		op("sub", read16(rread(d.segment) * 16 + rread("SI"), read16(rread("ES") * 16 + rread("DI"))), 8)
		local df = rread("DF")
		rwrite("DI", rread("DI") + (df == 0 and 2 or -2))
		rwrite("SI", rread("SI") + (df == 0 and 2 or -2))
	end
	incIP(d.length)
end

functions["A8"] = function(addr)	-- TEST AL, d8
	op("and", rread("AL"), read(addr + 1))
	incIP(2)
end

functions["A9"] = function(addr)	-- TEST AX, d16
	op("and", rread("AX"), read16(addr + 1))
	incIP(2)
end

functions["AA"] = function(addr)	-- STOSB
	local d = decode(addr, "ES")
	if d.rep then
		repeat
			if cycle == 0 then
				cycle = d.cycles
				write(rread(d.segment) * 16 + rread("DI"), rread("AL"))
				local df = rread("DF")
				rwrite("DI", rread("DI") + (df == 0 and 1 or -1))
				rwrite("CX", rread("CX") - 1)
			else
				cycle = cycle - 1
			end
		until rread("CX") == 0
	else
		write(rread(d.segment) * 16 + rread("DI"), rread("AL"))
		local df = rread("DF")
		rwrite("DI", rread("DI") + (df == 0 and 1 or -1))
	end
	incIP(d.length)
end

functions["AB"] = function(addr)	-- STOSW
	local d = decode(addr, "ES")
	if d.rep then
		repeat
			if cycle == 0 then
				cycle = d.cycles
				write16(rread(d.segment) * 16 + rread("DI"), rread("AX"))
				local df = rread("DF")
				rwrite("DI", rread("DI") + (df == 0 and 2 or -2))
				rwrite("CX", rread("CX") - 1)
			else
				cycle = cycle - 1
			end
		until rread("CX") == 0
	else
		write16(rread(d.segment) * 16 + rread("DI"), rread("AX"))
		local df = rread("DF")
		rwrite("DI", rread("DI") + (df == 0 and 2 or -2))
	end
	incIP(d.length)
end

functions["AC"] = function(addr)  -- LODSB
	local d = decode(addr)
	if d.rep then
		repeat
			if cycle == 0 then
				cycle = d.cycles
				rwrite("AL", read(rread(d.segment) * 16 + rread("SI")))
				local df = rread("DF")
				rwrite("SI", rread("SI") + (df == 0 and 1 or -1))
				rwrite("CX", rread("CX") - 1)
			else
				cycle = cycle - 1
			end
		until rread("CX") == 0
	else
		rwrite("AL", read(rread(d.segment) * 16 + rread("SI")))
		local df = rread("DF")
		rwrite("SI", rread("SI") + (df == 0 and 1 or -1))
	end
	incIP(d.length)
end

functions["AD"] = function(addr)  -- LODSW
	local d = decode(addr)
	if d.rep then
		repeat
			if cycle == 0 then
				cycle = d.cycles
				rwrite("AX", read16(rread(d.segment) * 16 + rread("SI")))
				local df = rread("DF")
				rwrite("SI", rread("SI") + (df == 0 and 2 or -2))
				rwrite("CX", rread("CX") - 1)
			else
				cycle = cycle - 1
			end
		until rread("CX") == 0
	else
		rwrite("AX", read16(rread(d.segment) * 16 + rread("SI")))
		local df = rread("DF")
		rwrite("SI", rread("SI") + (df == 0 and 2 or -2))
	end
	incIP(d.length)
end

functions["AE"] = function(addr)	-- SCASB
	local d = decode(addr, "ES")
	if d.rep == "REPE" then
		repeat
			if cycle == 0 then
				cycle = d.cycles
				local memValue = read(rread("ES") * 16 + rread("DI"))
				op("sub", memValue, rread("AL"), 8)
				local df = rread("DF")
				rwrite("DI", rread("DI") + (df == 0 and 1 or -1))
				rwrite("CX", rread("CX") - 1)
			else
				cycle = cycle - 1
			end
		until rread("CX") == 0 or rread("ZF") == 0
	elseif d.rep == "REPNE" then
		repeat
			if cycle == 0 then
				cycle = d.cycles
				local memValue = read(rread("ES") * 16 + rread("DI"))
				op("sub", memValue, rread("AL"), 8)
				local df = rread("DF")
				rwrite("DI", rread("DI") + (df == 0 and 1 or -1))
				rwrite("CX", rread("CX") - 1)
			else
				cycle = cycle - 1
			end
		until rread("CX") == 0 or rread("ZF") == 1
	else
		local memValue = read(rread("ES") * 16 + rread("DI"))
		op("sub", memValue, rread("AL"), 8)
		local df = rread("DF")
		rwrite("DI", rread("DI") + (df == 0 and 1 or -1))
	end
	incIP(d.length)
end

functions["AF"] = function(addr)	-- SCASW
	local d = decode(addr, "ES") 
	if d.rep == "REPE" then
		repeat
			if cycle == 0 then
				cycle = d.cycles
				local memValue = read16(rread("ES") * 16 + rread("DI"))
				op("sub", memValue, rread("AX"), 16)
				local df = rread("DF")
				rwrite("DI", rread("DI") + (df == 0 and 2 or -2))
				rwrite("CX", rread("CX") - 1)
			else
				cycle = cycle - 1
			end
		until rread("CX") == 0 or rread("ZF") == 0
	elseif d.rep == "REPNE" then
		repeat
			if cycle == 0 then
				cycle = d.cycles
				local memValue = read16(rread("ES") * 16 + rread("DI"))
				op("sub", memValue, rread("AX"), 16)
				local df = rread("DF")
				rwrite("DI", rread("DI") + (df == 0 and 2 or -2))
				rwrite("CX", rread("CX") - 1)
			else
				cycle = cycle - 1
			end
		until rread("CX") == 0 or rread("ZF") == 1
	else
		local memValue = read16(rread("ES") * 16 + rread("DI"))
		op("sub", memValue, rread("AX"), 16)
		local df = rread("DF")
		rwrite("DI", rread("DI") + (df == 0 and 2 or -2))
	end
	incIP(d.length)
end

-- Bx

functions["B0"] = function(addr)	-- MOV AL, d8
	rwrite("AL", read(addr + 1))
	incIP(2)
end

functions["B1"] = function(addr)	-- MOV CL, d8
	rwrite("CL", read(addr + 1))
	incIP(2)
end

functions["B2"] = function(addr)	-- MOV DL, d8
	rwrite("DL", read(addr + 1))
	incIP(2)
end

functions["B3"] = function(addr)	-- MOV BL, d8
	rwrite("BL", read(addr + 1))
	incIP(2)
end

functions["B4"] = function(addr)	-- MOV AH, d8
	rwrite("AH", read(addr + 1))
	incIP(2)
end

functions["B5"] = function(addr)	-- MOV CH, d8
	rwrite("CH", read(addr + 1))
	incIP(2)
end

functions["B6"] = function(addr)	-- MOV DH, d8
	rwrite("DH", read(addr + 1))
	incIP(2)
end

functions["B7"] = function(addr)	-- MOV BH, d8
	rwrite("BH", read(addr + 1))
	incIP(2)
end

functions["B8"] = function(addr)	-- MOV AX, d16
	rwrite("AX", read16(addr + 1))
	incIP(3)
end

functions["B9"] = function(addr)	-- MOV CX, d16
	rwrite("CX", read16(addr + 1))
	incIP(3)
end

functions["BA"] = function(addr)	-- MOV DX, d16
	rwrite("DX", read16(addr + 1))
	incIP(3)
end

functions["BB"] = function(addr)	-- MOV BX, d16
	rwrite("BX", read16(addr + 1))
	incIP(3)
end

functions["BC"] = function(addr)	-- MOV SP, d16
	rwrite("SP", read16(addr + 1))
	incIP(3)
end

functions["BD"] = function(addr)	-- MOV BP, d16
	rwrite("BP", read16(addr + 1))
	incIP(3)
end

functions["BE"] = function(addr)	-- MOV SI, d16
	rwrite("SI", read16(addr + 1))
	incIP(3)
end

functions["BF"] = function(addr)	-- MOV DI, d16
	rwrite("DI", read16(addr + 1))
	incIP(3)
end

-- Cx

functions["C0"] = function(addr)	-- PASS
	incIP(1)
	warn("Attempt to execute 0xC0")
end

functions["C1"] = function(addr)	-- PASS
	incIP(1)
	warn("Attempt to execute 0xC1")
end

functions["C2"] = function(addr)  -- RET imm16
	rwrite("IP", read16(rread("SP") + rread("SS") * 16))
	rwrite("SP", rread("SP") + 2 + read16(addr + 1))
end

functions["C3"] = function(addr)  -- RET
	rwrite("IP", read16(rread("SP") + rread("SS") * 16))
	rwrite("SP", rread("SP") + 2)
end

functions["C4"] = function(addr)  -- LES r16, m32
	local d = decode(addr)
	if d.effectiveAddress then
		local offset = read16(d.effectiveAddress)
		local segment = read16(d.effectiveAddress + 2)
		rwrite(d.regDest, offset)
		rwrite("ES", segment)
		incIP(d.length)
	else
		error("LES instruction requires a memory operand")
	end
end

functions["C5"] = function(addr)  -- LDS r16, m32
	local d = decode(addr)
	if d.effectiveAddress then
		local offset = read16(d.effectiveAddress)
		local segment = read16(d.effectiveAddress + 2)
		rwrite(d.regDest, offset)
		rwrite("DS", segment)
		incIP(d.length)
	else
		error("LDS instruction requires a memory operand")
	end
end

functions["C6"] = function (addr) 	-- _MOV r/m8, d8
	local d = decode(addr)
	local imm8 = read(addr + d.length - 1)
	if d.effectiveAddress then
		write(d.effectiveAddress, imm8)
	else
		rwrite(d.regDest, imm8)
	end

	incIP(d.length)
end

functions["C7"] = function (addr) 	-- _MOV r/m16, d16
	local d = decode(addr)
	local imm16 = read16(addr + d.length - 2)
	if d.effectiveAddress then
		write16(d.effectiveAddress, imm16)
	else
		rwrite(d.regDest, imm16)
	end

	incIP(d.length)
end

functions["C8"] = function (addr) 	-- PASS
	incIP(1)
end

functions["C9"] = function (addr) 	-- PASS
	incIP(1)
end

functions["CA"] = function(addr)	-- RET d16
	rwrite("IP", read16(rread("SP") + rread("SS") * 16))
	rwrite("SP", rread("SP") + 2)
	rwrite("CS", read16(rread("SP") + rread("SS") * 16))
	rwrite("SP", rread("SP") + 2)
	rwrite("SP", rread("SP") + read16(addr + 1))
end

functions["CB"] = function(addr)	-- RET
	rwrite("IP", read16(rread("SP") + rread("SS") * 16))
	rwrite("SP", rread("SP") + 2)
	rwrite("CS", read16(rread("SP") + rread("SS") * 16))
	rwrite("SP", rread("SP") + 2)
end

functions["CC"] = function(addr)	-- INT 3
	local intNumber = read(addr + 1)  
	local vectorAddr = 0xC
	local ss = rread("SS")
	local sp = rread("SP")
	local flagsValue = 0xFFFF
	flagsValue = bit.band(flagsValue, bit.lshift(rread("CF") and 1 or 0, 0))   
	flagsValue = bit.band(flagsValue, bit.lshift(rread("PF") and 1 or 0, 2))   
	flagsValue = bit.band(flagsValue, bit.lshift(rread("AF") and 1 or 0, 4))   
	flagsValue = bit.band(flagsValue, bit.lshift(rread("ZF") and 1 or 0, 6))   
	flagsValue = bit.band(flagsValue, bit.lshift(rread("SF") and 1 or 0, 7))   
	flagsValue = bit.band(flagsValue, bit.lshift(rread("TF") and 1 or 0, 8))   
	flagsValue = bit.band(flagsValue, bit.lshift(rread("IF") and 1 or 0, 9))   
	flagsValue = bit.band(flagsValue, bit.lshift(rread("DF") and 1 or 0, 10))  
	flagsValue = bit.band(flagsValue, bit.lshift(rread("OF") and 1 or 0, 11))  
	sp = sp - 2
	write16(ss * 16 + sp, flagsValue)  
	sp = sp - 2
	write16(ss * 16 + sp, rread("CS")) 
	sp = sp - 2
	write16(ss * 16 + sp, addr + 2)    
	rwrite("SP", sp)
	local newIP = read16(vectorAddr)
	local newCS = read16(vectorAddr + 2)
	rwrite("CS", newCS)
	rwrite("IP", newIP)
	rwrite("IF", 0)
	rwrite("TF", 0)
end

functions["CD"] = function(addr)	-- INT d8
	local intNumber = read(addr + 1)  
	local vectorAddr = intNumber * 4  
	local ss = rread("SS")
	local sp = rread("SP")
	local flagsValue = 0x0000
	flagsValue = bit.bor(flagsValue, bit.lshift(rread("CF") and 1 or 0, 0))   
	flagsValue = bit.bor(flagsValue, bit.lshift(rread("PF") and 1 or 0, 2))   
	flagsValue = bit.bor(flagsValue, bit.lshift(rread("AF") and 1 or 0, 4))   
	flagsValue = bit.bor(flagsValue, bit.lshift(rread("ZF") and 1 or 0, 6))   
	flagsValue = bit.bor(flagsValue, bit.lshift(rread("SF") and 1 or 0, 7))   
	flagsValue = bit.bor(flagsValue, bit.lshift(rread("TF") and 1 or 0, 8))   
	flagsValue = bit.bor(flagsValue, bit.lshift(rread("IF") and 1 or 0, 9))   
	flagsValue = bit.bor(flagsValue, bit.lshift(rread("DF") and 1 or 0, 10))  
	flagsValue = bit.bor(flagsValue, bit.lshift(rread("OF") and 1 or 0, 11))  
	sp = sp - 2
	write16(ss * 16 + sp, flagsValue)  
	sp = sp - 2
	write16(ss * 16 + sp, rread("CS")) 
	sp = sp - 2
	write16(ss * 16 + sp, addr + 2)    
	rwrite("SP", sp)
	local newIP = read16(vectorAddr)
	local newCS = read16(vectorAddr + 2)
	rwrite("CS", newCS)
	rwrite("IP", newIP)
	rwrite("IF", 0)
	rwrite("TF", 0)
end

functions["CE"] = function(addr)	-- INTO
	if rread("OF") == 1 then
		rwrite("SP", rread("SP") - 2)
		write16(rread("SP") + rread("SS") * 16, rread("IP"))
		local flagsValue = 0xF02A
		flagsValue = bit.bor(flagsValue, bit.lshift(rread("CF") and 1 or 0, 0))
		flagsValue = bit.bor(flagsValue, bit.lshift(rread("PF") and 1 or 0, 2))
		flagsValue = bit.bor(flagsValue, bit.lshift(rread("AF") and 1 or 0, 4))
		flagsValue = bit.bor(flagsValue, bit.lshift(rread("ZF") and 1 or 0, 6))
		flagsValue = bit.bor(flagsValue, bit.lshift(rread("SF") and 1 or 0, 7))
		flagsValue = bit.bor(flagsValue, bit.lshift(rread("TF") and 1 or 0, 8))
		flagsValue = bit.bor(flagsValue, bit.lshift(rread("IF") and 1 or 0, 9))
		flagsValue = bit.bor(flagsValue, bit.lshift(rread("DF") and 1 or 0, 10))
		flagsValue = bit.bor(flagsValue, bit.lshift(rread("OF") and 1 or 0, 11))
		rwrite("SP", rread("SP") - 2)
		write16(rread("SP") + rread("SS") * 16, flagsValue)
		rwrite("IP", read16(0x4 * 4))
		rwrite("CS", read16(0x4 * 4 + 2))
	else
		incIP(1)
	end
end

functions["CF"] = function(addr)	-- IRET
	local flagsValue = read16(rread("SP") + rread("SS") * 16)
	rwrite("SP", rread("SP") + 2)
	rwrite("CF", bit.band(flagsValue, 0x0001))
	rwrite("PF", bit.band(flagsValue, 0x0004))
	rwrite("AF", bit.band(flagsValue, 0x0010))
	rwrite("ZF", bit.band(flagsValue, 0x0040))
	rwrite("SF", bit.band(flagsValue, 0x0080))
	rwrite("TF", bit.band(flagsValue, 0x0100))
	rwrite("IF", bit.band(flagsValue, 0x0200))
	rwrite("DF", bit.band(flagsValue, 0x0400))
	rwrite("OF", bit.band(flagsValue, 0x0800))

	rwrite("IP", read16(rread("SP") + rread("SS") * 16))
	rwrite("SP", rread("SP") + 2)
	rwrite("CS", read16(rread("SP") + rread("SS") * 16))
	rwrite("SP", rread("SP") + 2)
end

-- Dx

functions["D0"] = function (addr)	-- _ROT r/m8, 1
	local d = decode(addr)
	local operation = regCodes[d.modrm.reg]

	if operation == 0 then
		if d.effectiveAddress then
			write(d.effectiveAddress, op("rol", read(d.effectiveAddress), 1))
		else
			rwrite(d.regDest, op("rol", rread(d.regDest), 1))
		end
	elseif operation == 1 then
		if d.effectiveAddress then
			write(d.effectiveAddress, op("ror", read(d.effectiveAddress), 1))
		else
			rwrite(d.regDest, op("ror", rread(d.regDest), 1))
		end
	elseif operation == 2 then
		if d.effectiveAddress then
			write(d.effectiveAddress, op("rcl", read(d.effectiveAddress), 1))
		else
			rwrite(d.regDest, op("rcl", rread(d.regDest), 1))
		end
	elseif operation == 3 then
		if d.effectiveAddress then
			write(d.effectiveAddress, op("rcr", read(d.effectiveAddress), 1))
		else
			rwrite(d.regDest, op("rcr", rread(d.regDest), 1))
		end
	elseif operation == 4 then
		if d.effectiveAddress then
			write(d.effectiveAddress, op("lsh", read(d.effectiveAddress), 1))
		else
			rwrite(d.regDest, op("lsh", rread(d.regDest), 1))
		end
	elseif operation == 5 then
		if d.effectiveAddress then
			write(d.effectiveAddress, op("rsh", read(d.effectiveAddress), 1))
		else
			rwrite(d.regDest, op("rsh", rread(d.regDest), 1))
		end
	elseif operation == 6 then
		if d.effectiveAddress then
			write(d.effectiveAddress, op("lsh", read(d.effectiveAddress), 1))
		else
			rwrite(d.regDest, op("lsh", rread(d.regDest), 1))
		end	
	else
		if d.effectiveAddress then
			write(d.effectiveAddress, bit.bor(op("rsh", rread(d.regDest), 1), 0x80))
		else
			rwrite(d.regDest, bit.bor(op("rsh", rread(d.regDest), 1), 0x80))
		end
	end

	incIP(d.length)
end

functions["D1"] = function (addr)	-- _ROT r/m16, 1
	local d = decode(addr)
	local operation = regCodes[d.modrm.reg]

	if operation == 0 then
		if d.effectiveAddress then
			write16(d.effectiveAddress, op("rol", read16(d.effectiveAddress), 1), 16)
		else
			rwrite(d.regDest, op("rol", rread(d.regDest), 1), 16)
		end
	elseif operation == 1 then
		if d.effectiveAddress then
			write16(d.effectiveAddress, op("ror", read16(d.effectiveAddress), 1), 16)
		else
			rwrite(d.regDest, op("ror", rread(d.regDest), 1), 16)
		end
	elseif operation == 2 then
		if d.effectiveAddress then
			write16(d.effectiveAddress, op("rcl", read16(d.effectiveAddress), 1), 16)
		else
			rwrite(d.regDest, op("rcl", rread(d.regDest), 1), 16)
		end
	elseif operation == 3 then
		if d.effectiveAddress then
			write16(d.effectiveAddress, op("rcr", read16(d.effectiveAddress), 1), 16)
		else
			rwrite(d.regDest, op("rcr", rread(d.regDest), 1), 16)
		end
	elseif operation == 4 then
		if d.effectiveAddress then
			write16(d.effectiveAddress, op("lsh", read16(d.effectiveAddress), 1), 16)
		else
			rwrite(d.regDest, op("lsh", rread(d.regDest), 1), 16)
		end
	elseif operation == 5 then
		if d.effectiveAddress then
			write16(d.effectiveAddress, op("replicatedStorageh", read16(d.effectiveAddress), 1), 16)
		else
			rwrite(d.regDest, op("replicatedStorageh", rread(d.regDest), 1), 16)
		end
	elseif operation == 6 then
		if d.effectiveAddress then
			write16(d.effectiveAddress, op("lsh", read16(d.effectiveAddress), 1), 16)
		else
			rwrite(d.regDest, op("lsh", rread(d.regDest), 1), 16)
		end	
	else
		if d.effectiveAddress then
			write16(d.effectiveAddress, bit.bor(op("replicatedStorageh", read(d.effectiveAddress), 1), 0x80), 16)
		else
			rwrite(d.regDest, bit.bor(op("replicatedStorageh", rread(d.regDest), 1), 0x80), 16)
		end
	end

	incIP(d.length)
end

functions["D2"] = function (addr)	-- _ROT r/m8, CL
	local d = decode(addr)
	local operation = regCodes[d.modrm.reg]

	if operation == 0 then
		if d.effectiveAddress then
			write(d.effectiveAddress, op("rol", read(d.effectiveAddress), rread("CL")))
		else
			rwrite(d.regDest, op("rol", rread(d.regDest), rread("CL")))
		end
	elseif operation == 1 then
		if d.effectiveAddress then
			write(d.effectiveAddress, op("ror", read(d.effectiveAddress), rread("CL")))
		else
			rwrite(d.regDest, op("ror", rread(d.regDest), rread("CL")))
		end
	elseif operation == 2 then
		if d.effectiveAddress then
			write(d.effectiveAddress, op("rcl", read(d.effectiveAddress), rread("CL")))
		else
			rwrite(d.regDest, op("rcl", rread(d.regDest), rread("CL")))
		end
	elseif operation == 3 then
		if d.effectiveAddress then
			write(d.effectiveAddress, op("rcr", read(d.effectiveAddress), rread("CL")))
		else
			rwrite(d.regDest, op("rcr", rread(d.regDest), rread("CL")))
		end
	elseif operation == 4 then
		if d.effectiveAddress then
			write(d.effectiveAddress, op("lsh", read(d.effectiveAddress), rread("CL")))
		else
			rwrite(d.regDest, op("lsh", rread(d.regDest), rread("CL")))
		end
	elseif operation == 5 then
		if d.effectiveAddress then
			write(d.effectiveAddress, op("replicatedStorageh", read(d.effectiveAddress), rread("CL")))
		else
			rwrite(d.regDest, op("replicatedStorageh", rread(d.regDest), rread("CL")))
		end
	elseif operation == 6 then
		if d.effectiveAddress then
			write(d.effectiveAddress, op("lsh", read(d.effectiveAddress), rread("CL")))
		else
			rwrite(d.regDest, op("lsh", rread(d.regDest), rread("CL")))
		end	
	else
		if d.effectiveAddress then
			write(d.effectiveAddress, bit.bor(op("replicatedStorageh", rread(d.regDest), rread("CL")), 0x80))
		else
			rwrite(d.regDest, bit.bor(op("replicatedStorageh", rread(d.regDest), rread("CL")), 0x80))
		end
	end

	incIP(d.length)
end

functions["D3"] = function (addr)	-- _ROT r/m16, CL
	local d = decode(addr)
	local operation = regCodes[d.modrm.reg]

	if operation == 0 then
		if d.effectiveAddress then
			write16(d.effectiveAddress, op("rol", read16(d.effectiveAddress), rread("CL")), 16)
		else
			rwrite(d.regDest, op("rol", rread(d.regDest), rread("CL")), 16)
		end
	elseif operation == 1 then
		if d.effectiveAddress then
			write16(d.effectiveAddress, op("ror", read16(d.effectiveAddress), rread("CL")), 16)
		else
			rwrite(d.regDest, op("ror", rread(d.regDest), rread("CL")), 16)
		end
	elseif operation == 2 then
		if d.effectiveAddress then
			write16(d.effectiveAddress, op("rcl", read16(d.effectiveAddress), rread("CL")), 16)
		else
			rwrite(d.regDest, op("rcl", rread(d.regDest), rread("CL")), 16)
		end
	elseif operation == 3 then
		if d.effectiveAddress then
			write16(d.effectiveAddress, op("rcr", read16(d.effectiveAddress), rread("CL")), 16)
		else
			rwrite(d.regDest, op("rcr", rread(d.regDest), rread("CL")), 16)
		end
	elseif operation == 4 then
		if d.effectiveAddress then
			write16(d.effectiveAddress, op("lsh", read16(d.effectiveAddress), rread("CL")), 16)
		else
			rwrite(d.regDest, op("lsh", rread(d.regDest), rread("CL")), 16)
		end
	elseif operation == 5 then
		if d.effectiveAddress then
			write16(d.effectiveAddress, op("replicatedStorageh", read16(d.effectiveAddress), rread("CL")), 16)
		else
			rwrite(d.regDest, op("replicatedStorageh", rread(d.regDest), rread("CL")), 16)
		end
	elseif operation == 6 then
		if d.effectiveAddress then
			write16(d.effectiveAddress, op("lsh", read16(d.effectiveAddress), rread("CL")), 16)
		else
			rwrite(d.regDest, op("lsh", rread(d.regDest), rread("CL")), 16)
		end	
	else
		if d.effectiveAddress then
			write16(d.effectiveAddress, bit.bor(op("replicatedStorageh", read(d.effectiveAddress), rread("CL")), 0x80), 16)
		else
			rwrite(d.regDest, bit.bor(op("replicatedStorageh", rread(d.regDest), rread("CL")), 0x80), 16)
		end
	end

	incIP(d.length)
end

functions["D4"] = function(addr)	-- AAM d8
	local base = math.max(1, read(addr + 1))
	local al = rread("AL")
	rwrite("AH", math.floor(al / base))
	rwrite("AL", al % base)
	al = al % base
	rwrite("ZF", al == 0 and 1 or 0)
	rwrite("SF", bit.band(al, 0x80) and 1 or 0)
	local p = utils.decimalToBinary(al, 8)
	rwrite("PF", (p:len() - p:gsub("1",""):len()) % 2 == 0 and 1 or 0)
	incIP(2)
end

functions["D5"] = function(addr)	-- AAD d8
	local base = read(addr + 1)
	local ah, al = rread("AH"), rread("AL")
	al = (ah * base + al) % 256
	rwrite("AL", al)
	rwrite("AH", 0)
	rwrite("ZF", al == 0 and 1 or 0)
	rwrite("SF", bit.band(al, 0x80) and 1 or 0)
	local p = utils.decimalToBinary(al, 8)
	rwrite("PF", (p:len() - p:gsub("1",""):len()) % 2 == 0 and 1 or 0)
	incIP(2)
end

functions["D6"] = function(addr)	-- *SALC
	rwrite("AL", rread("CF") == 1 and 0xFF or 0)
	incIP(1)
end

functions["D7"] = function(addr)	-- XLAT
	rwrite("AL", read(rread("BX") + rread("AL")))
	incIP(1)
end

functions["D8"] = function(addr)	-- ESC (PASS)
	incIP(1)
end

functions["D9"] = function(addr)	-- ESC (PASS)
	incIP(1)
end

functions["DA"] = function(addr)	-- ESC (PASS)
	incIP(1)
end

functions["DB"] = function(addr)	-- ESC (PASS)
	incIP(1)
end

functions["DC"] = function(addr)	-- ESC (PASS)
	incIP(1)
end

functions["DD"] = function(addr)	-- ESC (PASS)
	incIP(1)
end

functions["DE"] = function(addr)	-- ESC (PASS)
	incIP(1)
end

functions["DF"] = function(addr)	-- ESC (PASS)
	incIP(1)
end

-- Ex

functions["E0"] = function(addr)	-- LOOPNZ/NE rel8
	rwrite("CX", rread("CX") - 1)
	if rread("ZF") == 0 and rread("CX") ~= 0 then
		incIP(2 + utils.toSigned8(read(addr + 1))) 
	else
		incIP(2)
	end
end

functions["E1"] = function(addr)	-- LOOPZ/E rel8
	rwrite("CX", rread("CX") - 1)
	if rread("ZF") == 1 and rread("CX") ~= 0 then
		incIP(2 + utils.toSigned8(read(addr + 1))) 
	else
		incIP(2)
	end
end

functions["E2"] = function(addr)	-- LOOP rel8
	rwrite("CX", rread("CX") - 1)
	if rread("CX") ~= 0 then
		incIP(2 + utils.toSigned8(read(addr + 1))) 
	else
		print(string.format("EXPECT %X", rread("IP") + 2))
		incIP(2)
		print(string.format("BYTE %X", read(rread("IP"))))
		print(string.format("RES %X", rread("IP")))
	end
end

functions["E3"] = function(addr)	-- JCXZ rel8
	if rread("CX") == 0 then
		incIP(2 + utils.toSigned8(read(addr + 1))) 
	else
		incIP(2)
	end
end

functions["E4"] = function(addr)	-- IN AL, [d8]	
	rwrite("AL", io.read(addr + 1))
	incIP(2)
end

functions["E5"] = function(addr)	-- IN AL, [d8]	
	rwrite("AX", io.read(addr) + bit.lshift(io.read(addr + 1), 8))
	incIP(2)
end

functions["E6"] = function(addr)	-- OUT [d8], AL
	io.write(read(addr + 1), rread("AL"))
	ioUpdate:FireAllClients(read(addr + 1), rread("AL"))
	incIP(2)
end

functions["E7"] = function(addr) 	-- OUT [d8], AX
	io.write(read(addr + 1), rread("AL"))
	ioUpdate:FireAllClients(read(addr + 1), rread("AL"))
	io.write(read(addr + 2), rread("AH"))
	ioUpdate:FireAllClients(read(addr + 2), rread("AH"))
	incIP(2)
end

functions["E8"] = function(addr)    -- CALL rel16
	local displacement = read16(addr + 1)
	displacement = displacement - (displacement >= 0x8000 and 0x10000 or 0)
	local returnIP = addr + 3
	rwrite("SP", rread("SP") - 2)
	write16(rread("SP") + rread("SS") * 16, returnIP)
	rwrite("IP", returnIP + displacement)
end

functions["E9"] = function(addr)    -- JMP rel16
	local displacement = read16(addr + 1)
	displacement = displacement - (displacement >= 0x8000 and 0x10000 or 0)
	rwrite("IP", displacement)
end

functions["EA"] = function(addr)    -- JMP seg:a16
	rwrite("CS", read16(addr + 1))
	rwrite("IP", read16(addr + 3))
end

functions["EB"] = function(addr)    -- JMP rel8
	rwrite("IP", rread("IP") + utils.toSigned8(read(addr + 1)))
end

functions["EC"] = function(addr)    -- IN AL, DX
	rwrite("AL", io.read(rread("DX")))
	incIP(1)
end

functions["ED"] = function(addr)    -- IN AX, DX
	rwrite("AL", io.read(rread("DX")))
	rwrite("AX", io.read(rread("DX")) + 1)
	incIP(1)
end

functions["EE"] = function(addr)    -- OUT DX, AL
	io.write(rread("DX"), rread("AL"))
	ioUpdate:FireAllClients(rread("DX"), rread("AL"))
	incIP(1)
end

functions["EF"] = function(addr)    -- OUT DX, AX
	io.write(rread("DX"), rread("AL"))
	ioUpdate:FireAllClients(read(addr + 1), rread("AL"))
	io.write(rread("DX") + 1, rread("AH"))
	ioUpdate:FireAllClients(read(addr + 2), rread("AH"))
	incIP(1)
end

-- Fx

functions["F0"] = function(addr)    -- LOCK
	-- PASS
end

functions["F1"] = function(addr)    -- PASS
	incIP(1)
end

functions["F2"] = function(addr)    -- REPNE/REPNZ
	-- PASS
end

functions["F3"] = function(addr)    -- REP/REPE/REPZ
	-- PASS
end

functions["F4"] = function (addr)	-- HLT
	rwrite("halt", true)
	incIP(1)
end

functions["F5"] = function (addr)	-- CMC
	rwrite("CF", 1 - rread("CF"))
	incIP(1)
end

functions["F6"] = function(addr)	-- _ALU2 r/m8, d8
	local d = decode(addr)
	local modrm = d.modrm
	local operation = modrm.reg
	local operand, result, ax, dx, quotient, remainder

	if d.effectiveAddress then
		operand = read(d.effectiveAddress)
	else
		operand = rread(d.regDest)
	end

	if operation == 0 then 
		local imm8 = read(addr + d.length - 1)
		result = bit.band(operand, imm8)
		rwrite("CF", 0)
		rwrite("OF", 0)
		rwrite("SF", bit.band(result, 0x80) ~= 0 and 1 or 0)
		rwrite("ZF", result == 0 and 1 or 0)
		rwrite("PF", parity(result))
	elseif operation == 2 then 
		result = bit.bnot(operand) % 256
		if d.effectiveAddress then
			write(d.effectiveAddress, result)
		else
			rwrite(d.regDest, result)
		end
	elseif operation == 3 then 
		result = op("sub", 0, operand)
		if d.effectiveAddress then
			write(d.effectiveAddress, result)
		else
			rwrite(d.regDest, result)
		end

	elseif operation == 4 then 
		local al = rread("AL")  
		result = al * operand
		rwrite("AX", result % 65536)
		rwrite("CF", result > 0xFF and 1 or 0)
		rwrite("OF", rread("CF"))
	elseif operation == 5 then 
		local alSigned = utils.toSigned8(rread("AL"))
		local opSigned = utils.toSigned8(operand)
		result = alSigned * opSigned
		rwrite("AX", result % 65536)
		local ah = bit.rshift(result, 8) % 256
		local sign_bit = bit.band(result % 256, 0x80) ~= 0
		rwrite("CF", (sign_bit and ah ~= 0xFF) or (not sign_bit and ah ~= 0x00) and 1 or 0)
		rwrite("OF", rread("CF"))
	elseif operation == 6 then 
		if operand == 0 then 
			local vectorAddr = 0
			local flagsValue = 0x0
			flagsValue = bit.bor(flagsValue, bit.lshift(rread("CF") and 1 or 0, 0))   
			flagsValue = bit.bor(flagsValue, bit.lshift(rread("PF") and 1 or 0, 2))   
			flagsValue = bit.bor(flagsValue, bit.lshift(rread("AF") and 1 or 0, 4))   
			flagsValue = bit.bor(flagsValue, bit.lshift(rread("ZF") and 1 or 0, 6))   
			flagsValue = bit.bor(flagsValue, bit.lshift(rread("SF") and 1 or 0, 7))   
			flagsValue = bit.bor(flagsValue, bit.lshift(rread("TF") and 1 or 0, 8))   
			flagsValue = bit.bor(flagsValue, bit.lshift(rread("IF") and 1 or 0, 9))   
			flagsValue = bit.bor(flagsValue, bit.lshift(rread("DF") and 1 or 0, 10))  
			flagsValue = bit.bor(flagsValue, bit.lshift(rread("OF") and 1 or 0, 11))  
			local sp = rread("SP")
			local ss = rread("SS")
			sp -= 2
			write16(ss * 16 + sp, flagsValue)  
			sp -= 2
			write16(ss * 16 + sp, rread("CS")) 
			sp -= 2
			write16(ss * 16 + sp, rread("IP")) 
			rwrite("SP", sp)
			local newIP = read16(vectorAddr)
			local newCS = read16(vectorAddr + 2)
			rwrite("CS", newCS)
			rwrite("IP", newIP)
			rwrite("IF", 0)
			rwrite("TF", 0)
		end
		ax = rread("AX")
		quotient = math.floor(ax / operand)
		remainder = ax % operand
		rwrite("AL", quotient)
		rwrite("AH", remainder)
	elseif operation == 7 then 
		local axSigned = utils.toSigned16(rread("AX"))
		local opSigned = utils.toSigned8(operand)
		if opSigned == 0 then 
			local vectorAddr = 0
			local flagsValue = 0x0
			flagsValue = bit.bor(flagsValue, bit.lshift(rread("CF") and 1 or 0, 0))   
			flagsValue = bit.bor(flagsValue, bit.lshift(rread("PF") and 1 or 0, 2))   
			flagsValue = bit.bor(flagsValue, bit.lshift(rread("AF") and 1 or 0, 4))   
			flagsValue = bit.bor(flagsValue, bit.lshift(rread("ZF") and 1 or 0, 6))   
			flagsValue = bit.bor(flagsValue, bit.lshift(rread("SF") and 1 or 0, 7))   
			flagsValue = bit.bor(flagsValue, bit.lshift(rread("TF") and 1 or 0, 8))   
			flagsValue = bit.bor(flagsValue, bit.lshift(rread("IF") and 1 or 0, 9))   
			flagsValue = bit.bor(flagsValue, bit.lshift(rread("DF") and 1 or 0, 10))  
			flagsValue = bit.bor(flagsValue, bit.lshift(rread("OF") and 1 or 0, 11))  
			local sp = rread("SP")
			local ss = rread("SS")
			sp -= 2
			write16(ss * 16 + sp, flagsValue)  
			sp -= 2
			write16(ss * 16 + sp, rread("CS")) 
			sp -= 2
			write16(ss * 16 + sp, rread("IP")) 
			rwrite("SP", sp)
			local newIP = read16(vectorAddr)
			local newCS = read16(vectorAddr + 2)
			rwrite("CS", newCS)
			rwrite("IP", newIP)
			rwrite("IF", 0)
			rwrite("TF", 0)	
		end
		quotient = math.floor(axSigned / opSigned)
		remainder = axSigned % opSigned
		rwrite("AL", quotient % 256)
		rwrite("AH", remainder % 256)
	else
		error(string.format("Unsupported operation at %X", addr))
	end
	incIP(d.length)
end

functions["F7"] = function(addr)	-- _ALU2 r/m16, d16
	local d = decode(addr)
	local modrm = d.modrm
	local operation = regCodes.upper[modrm.reg]
	local operand, result, ax, dx, quotient, remainder

	if d.effectiveAddress then
		operand = read16(d.effectiveAddress)
	else
		operand = rread(d.regDest)
	end

	if operation == 0 then 
		local imm16 = utils.littleEndianRead16(addr + d.length - 1)
		result = bit.band(operand, imm16)
		rwrite("CF", 0)
		rwrite("OF", 0)
		rwrite("SF", bit.band(result, 0x8000) ~= 0 and 1 or 0)
		rwrite("ZF", result == 0 and 1 or 0)
		rwrite("PF", parity(result % 256))
	elseif operation == 2 then 
		result = bit.bnot(operand) % 65536
		if d.effectiveAddress then
			utils.littleEndianWrite16(d.effectiveAddress, result)
		else
			rwrite(d.regDest, result)
		end
	elseif operation == 3 then 
		result = op("sub", 0, operand, 16)
		if d.effectiveAddress then
			utils.littleEndianWrite16(d.effectiveAddress, result)
		else
			rwrite(d.regDest, result)
		end
	elseif operation == 4 then 
		ax = rread("AX")
		result = ax * operand
		rwrite("AX", result % 65536)
		rwrite("DX", bit.rshift(result, 16) % 65536)
		rwrite("CF", result > 0xFFFF and 1 or 0)
		rwrite("OF", rread("CF"))
	elseif operation == 5 then 
		local axSigned = utils.toSigned16(rread("AX"))
		local opSigned = utils.toSigned16(operand)
		result = axSigned * opSigned
		local low = result % 65536
		local high = bit.rshift(result, 16) % 65536
		rwrite("AX", low)
		rwrite("DX", high)
		rwrite("CF", (high ~= 0 and high ~= 0xFFFF) and 1 or 0)
		rwrite("OF", rread("CF"))
	elseif operation == 6 then 
		if operand == 0 then 
			local vectorAddr = 0
			local flagsValue = 0x0
			flagsValue = bit.bor(flagsValue, bit.lshift(rread("CF") and 1 or 0, 0))   
			flagsValue = bit.bor(flagsValue, bit.lshift(rread("PF") and 1 or 0, 2))   
			flagsValue = bit.bor(flagsValue, bit.lshift(rread("AF") and 1 or 0, 4))   
			flagsValue = bit.bor(flagsValue, bit.lshift(rread("ZF") and 1 or 0, 6))   
			flagsValue = bit.bor(flagsValue, bit.lshift(rread("SF") and 1 or 0, 7))   
			flagsValue = bit.bor(flagsValue, bit.lshift(rread("TF") and 1 or 0, 8))   
			flagsValue = bit.bor(flagsValue, bit.lshift(rread("IF") and 1 or 0, 9))   
			flagsValue = bit.bor(flagsValue, bit.lshift(rread("DF") and 1 or 0, 10))  
			flagsValue = bit.bor(flagsValue, bit.lshift(rread("OF") and 1 or 0, 11))  
			local sp = rread("SP")
			local ss = rread("SS")
			sp -= 2
			write16(ss * 16 + sp, flagsValue)  
			sp -= 2
			write16(ss * 16 + sp, rread("CS")) 
			sp -= 2
			write16(ss * 16 + sp, rread("IP")) 
			rwrite("SP", sp)
			local newIP = read16(vectorAddr)
			local newCS = read16(vectorAddr + 2)
			rwrite("CS", newCS)
			rwrite("IP", newIP)
			rwrite("IF", 0)
			rwrite("TF", 0)	
		end
		local dividend = rread("DX") * 65536 + rread("AX")
		quotient = math.floor(dividend / operand)
		remainder = dividend % operand
		rwrite("AX", quotient % 65536)
		rwrite("DX", remainder % 65536)
	elseif operation == 7 then 
		local dividend = utils.toSigned32(rread("DX") * 65536 + rread("AX"))
		local opSigned = utils.toSigned16(operand)
		if opSigned == 0 then 
			local vectorAddr = 0
			local flagsValue = 0x0
			flagsValue = bit.bor(flagsValue, bit.lshift(rread("CF") and 1 or 0, 0))   
			flagsValue = bit.bor(flagsValue, bit.lshift(rread("PF") and 1 or 0, 2))   
			flagsValue = bit.bor(flagsValue, bit.lshift(rread("AF") and 1 or 0, 4))   
			flagsValue = bit.bor(flagsValue, bit.lshift(rread("ZF") and 1 or 0, 6))   
			flagsValue = bit.bor(flagsValue, bit.lshift(rread("SF") and 1 or 0, 7))   
			flagsValue = bit.bor(flagsValue, bit.lshift(rread("TF") and 1 or 0, 8))   
			flagsValue = bit.bor(flagsValue, bit.lshift(rread("IF") and 1 or 0, 9))   
			flagsValue = bit.bor(flagsValue, bit.lshift(rread("DF") and 1 or 0, 10))  
			flagsValue = bit.bor(flagsValue, bit.lshift(rread("OF") and 1 or 0, 11))  
			local sp = rread("SP")
			local ss = rread("SS")
			sp -= 2
			write16(ss * 16 + sp, flagsValue)  
			sp -= 2
			write16(ss * 16 + sp, rread("CS")) 
			sp -= 2
			write16(ss * 16 + sp, rread("IP")) 
			rwrite("SP", sp)
			local newIP = read16(vectorAddr)
			local newCS = read16(vectorAddr + 2)
			rwrite("CS", newCS)
			rwrite("IP", newIP)
			rwrite("IF", 0)
			rwrite("TF", 0)	
		end
		quotient = math.floor(dividend / opSigned)
		remainder = dividend % opSigned
		rwrite("AX", quotient % 65536)
		rwrite("DX", remainder % 65536)
	else
		error(string.format("Unsupported operation at %X", addr))
	end
	incIP(d.length)
end

functions["F8"] = function(addr)	-- CLC
	rwrite("CF", 0)
	incIP(1)
end

functions["F9"] = function(addr)	-- STC
	rwrite("CF", 0)
	incIP(1)
end

functions["FA"] = function(addr)	-- CLI
	rwrite("IF", 0)
	incIP(1)
end

functions["FB"] = function(addr)	-- STI
	rwrite("IF", 1)
	incIP(1)
end

functions["FC"] = function(addr)	-- CLD
	rwrite("DF", 0)
	incIP(1)
end

functions["FD"] = function(addr)	-- STD
	rwrite("DF", 1)
	incIP(1)
end

functions["FE"] = function(addr)	-- _MISC r/m8
	local d = decode(addr)
	local operation = regCodes.lower[d.modrm.reg]

	if operation == 0 then 
		if d.effectiveAddress then
			local value = read(d.effectiveAddress)
			local result = op("inc", value, 1, 8)
			write(d.effectiveAddress, result)
		else
			local value = rread(d.regDest)
			local result = op("inc", value, 1, 8)
			rwrite(d.regDest, result)
		end
		incIP(d.length)
	elseif operation == 1 then 
		if d.effectiveAddress then
			local value = read(d.effectiveAddress)
			local result = op("dec", value, 1, 8)
			write(d.effectiveAddress, result)
		else
			local value = rread(d.regDest)
			local result = op("dec", value, 1, 8)
			rwrite(d.regDest, result)
		end
		incIP(d.length)
	else
		error(string.format("Unsupported operation at %X", addr))
	end
end

functions["FF"] = function(addr)	-- _MISC r/m16
	local d = decode(addr)
	local operation = regCodes[d.modrm.reg]

	if operation == 0 then 
		if d.effectiveAddress then
			local value = read16(d.effectiveAddress)
			local result = op("inc", value, 1, 16)
			write16(d.effectiveAddress, result)
		else
			local value = rread(d.regDest)
			local result = op("inc", value, 1, 16)
			rwrite(d.regDest, result)
		end
		incIP(d.length)
	elseif operation == 1 then 
		if d.effectiveAddress then
			local value = read16(d.effectiveAddress)
			local result = op("dec", value, 1, 16)
			write16(d.effectiveAddress, result)
		else
			local value = rread(d.regDest)
			local result = op("dec", value, 1, 16)
			rwrite(d.regDest, result)
		end
		incIP(d.length)
	elseif operation == 2 then 
		local returnIP = addr + d.length
		rwrite("SP", rread("SP") - 2)
		write16(rread("SP") + rread("SS") * 16, returnIP)
		if d.effectiveAddress then
			rwrite("IP", read16(d.effectiveAddress))
		else
			rwrite("IP", rread(d.regDest))
		end
	elseif operation == 3 then 
		local returnIP = addr + d.length
		local returnCS = rread("CS")
		rwrite("SP", rread("SP") - 4)
		write16(rread("SP") + rread("SS") * 16, returnIP)
		write16(rread("SP") + rread("SS") * 16 + 2, returnCS)
		rwrite("IP", read16(d.effectiveAddress))
		rwrite("CS", read16(d.effectiveAddress + 2))
	elseif operation == 4 then 
		if d.effectiveAddress then
			rwrite("IP", read16(d.effectiveAddress))
		else
			rwrite("IP", rread(d.regDest))
		end
	elseif operation == 5 then 
		rwrite("IP", read16(d.effectiveAddress))
		rwrite("CS", read16(d.effectiveAddress + 2))
	elseif operation == 6 then 
		local value
		if d.effectiveAddress then
			value = read16(d.effectiveAddress)
		else
			value = rread(d.regDest)
		end
		rwrite("SP", rread("SP") - 2)
		write16(rread("SP") + rread("SS") * 16, value)
		incIP(d.length)
	else
		error(string.format("Unsupported operation at %X", addr))
	end
end

return functions
