local module = {}
local replicatedStorage = game:GetService("ReplicatedStorage")

local ram = require(replicatedStorage.CPU.RAM)
local write, read = ram.write, ram.read
local properties = require(replicatedStorage.CPU.Properties)
local regNumbering = require(replicatedStorage.CPU.RegisterCodes)
local registers = require(replicatedStorage.CPU.Registers)
local regr, regw = registers.read, registers.write
local bit = bit32

local egaColors = {
	[0] = Color3.fromRGB(0, 0, 0),        -- Black
	[1] = Color3.fromRGB(170, 0, 0),      -- Dark Red
	[2] = Color3.fromRGB(0, 170, 0),      -- Dark Green
	[3] = Color3.fromRGB(170, 170, 0),    -- Yellow
	[4] = Color3.fromRGB(0, 0, 170),      -- Dark Blue
	[5] = Color3.fromRGB(170, 0, 170),    -- Purple
	[6] = Color3.fromRGB(0, 170, 170),    -- Cyan
	[7] = Color3.fromRGB(170, 170, 170),  -- Light Gray
	[8] = Color3.fromRGB(85, 85, 85),     -- Dark Gray
	[9] = Color3.fromRGB(255, 85, 85),    -- Light Red
	[10] = Color3.fromRGB(85, 255, 85),   -- Light Green
	[11] = Color3.fromRGB(255, 255, 85),  -- Light Yellow
	[12] = Color3.fromRGB(85, 85, 255),   -- Light Blue
	[13] = Color3.fromRGB(255, 85, 255),  -- Light Purple
	[14] = Color3.fromRGB(85, 255, 255),  -- Light Cyan
	[15] = Color3.fromRGB(255, 255, 255), -- White
}

module.littleEndianRead16 = function(addr)
	return read(addr) + bit.lshift(read(addr + 1), 8)
end

module.toSigned8 = function(value)
	if value >= 0x80 then
		return value - 0x100
	else
		return value
	end
end

module.littleEndianWrite16 = function(addr, value)
	write(addr, value % 256)
	write(addr + 1, bit.rshift(value, 8))
end

module.decodeInstruction = function(baseAddress, preferedSegment)
	preferedSegment = preferedSegment or "DS"
	
	local address = baseAddress
	local cyclesRequired = 0
	local linearAddress = nil
	local prefix = { segment = nil, rep = nil, length = 0 }

	while true do
		local prefixByte = read(address)
		if prefixByte == 0x2E then
			prefix.segment = "CS"
			prefix.length = prefix.length + 1
			cyclesRequired += properties["2E"].cycles
		elseif prefixByte == 0x3E then
			prefix.segment = "DS"
			prefix.length = prefix.length + 1
			cyclesRequired += properties["3E"].cycles
		elseif prefixByte == 0x26 then
			prefix.segment = "ES"
			prefix.length = prefix.length + 1
			cyclesRequired += properties["26"].cycles
		elseif prefixByte == 0x36 then
			prefix.segment = "SS"
			prefix.length = prefix.length + 1
			cyclesRequired += properties["36"].cycles
		elseif prefixByte == 0xF2 then
			prefix.rep = "REPNE"
			prefix.length = prefix.length + 1
			cyclesRequired += properties["F2"].cycles
		elseif prefixByte == 0xF3 then
			prefix.rep = "REPE"
			prefix.length = prefix.length + 1
			cyclesRequired += properties["F3"].cycles
		elseif prefixByte == 0xF0 then
			prefix.locked = true
			prefix.length = prefix.length + 1
			cyclesRequired += properties["F0"].cycles
		else
			break
		end
		address = address + 1
	end

	local opcodeByte = read(address)
	
	address = address + 1
	
	local length = prefix.length + 1
	local opcodeKey = string.format("%02X", opcodeByte)
	local prop = properties[opcodeKey]
	local mod, reg, rm, displacement, effectiveAddress, segment, baseRegistersUsed
	
	displacement = 0
	baseRegistersUsed = {}

	if prop and prop.modrm then
		local modrmByte = read(address)
		address = address + 1
		length = length + 1
		cyclesRequired += 2

		mod = bit.rshift(modrmByte, 6)
		local regField = bit.band(bit.rshift(modrmByte, 3), 7)
		local rmField = bit.band(modrmByte, 7)
		local regTable = (prop.size == 8) and regNumbering.lower or regNumbering.upper
		reg = regTable[regField]

		if mod == 3 then
			rm = regTable[rmField]
		else
			if rmField == 0 then baseRegistersUsed = {"BX", "SI"}
			elseif rmField == 1 then baseRegistersUsed = {"BX", "DI"}
			elseif rmField == 2 then baseRegistersUsed = {"BP", "SI"}
			elseif rmField == 3 then baseRegistersUsed = {"BP", "DI"}
			elseif rmField == 4 then baseRegistersUsed = {"SI"}
			elseif rmField == 5 then baseRegistersUsed = {"DI"}
			elseif rmField == 6 then
				if mod == 0 then baseRegistersUsed = {} else baseRegistersUsed = {"BP"} end
			elseif rmField == 7 then baseRegistersUsed = {"BX"} end

			effectiveAddress = 0
			for _, regName in ipairs(baseRegistersUsed) do effectiveAddress += regr(regName) end

			if mod == 1 then
				displacement = read(address)
				if displacement >= 0x80 then displacement -= 0x100 end
				address += 1
				length += 1
			elseif mod == 2 or (mod == 0 and rmField == 6) then
				displacement = module.littleEndianRead16(address)
				address += 2
				length += 2
			end

			effectiveAddress = bit.band(effectiveAddress + displacement, 0xFFFF)

			local hasBP = false
			for _, r in ipairs(baseRegistersUsed) do if r == "BP" then hasBP = true break end end

			local penalty = 0
			if mod == 0 then
				penalty = (rmField == 6) and 6 or 5
				if hasBP then penalty += 1 end
			elseif mod == 1 then
				penalty = 6
				if hasBP then penalty += 1 end
			elseif mod == 2 then
				penalty = 7
				if hasBP then penalty += 1 end
			end
			cyclesRequired += penalty
		end

		segment = prefix.segment or ((#baseRegistersUsed > 0 and (baseRegistersUsed[1] == "BP" or (baseRegistersUsed[1] == "BX" and baseRegistersUsed[2] == "BP"))) and "SS" or "DS")
	else
		effectiveAddress = module.littleEndianRead16(address)
		address += 2
		length += 2
		segment = prefix.segment or preferedSegment
	end

	if effectiveAddress and segment then
		linearAddress = bit.band(bit.lshift(regr(segment), 4) + effectiveAddress, 0xFFFFF)
	end

	cyclesRequired += prop.cycles

	if prop.size == 0 then
		return { 
			opcode = opcodeKey, 
			length = length - 2,
			segment = segment,
			cycles = cyclesRequired, 
			rep = prefix.rep
		}
	else
		return {
			opcode = opcodeKey,
			length = length,
			operandSize = prop.size or 0,
			effectiveAddress = linearAddress,
			segment = segment,
			registersUsed = baseRegistersUsed,
			displacement = displacement,
			rep = prefix.rep,
			regSource = reg,
			regDest = rm,
			cycles = cyclesRequired,
			modrm = mod and { mod = mod, reg = reg, rm = (mod == 3) and rm or nil } or nil
		}
	end
end

module.dumpFlags = function()
	print("FLAG DUMP:")
	print("CF", regr("CF"))
	print("ZF", regr("ZF"))
	print("SF", regr("SF"))
	print("PF", regr("PF"))
	print("TF", regr("TF"))
	print("IF", regr("IF"))
	print("DF", regr("DF"))
	print("OF", regr("OF"))
	print("AF", regr("AF"))
	print()
end

module.dumpRegs = function()
	print("REG DUMP:")
	print("AX", regr("AX"))
	print("BX", regr("BX"))
	print("CX", regr("CX"))
	print("DX", regr("DX"))
	print("SP", regr("SP"))
	print("BP", regr("BP"))
	print("SI", regr("SI"))
	print("DI", regr("DI"))
	print("CS", regr("CS"))
	print("SS", regr("SS"))
	print("DS", regr("DS"))
	print("ES", regr("ES"))
	print("IP", regr("IP"))
	print()
end

module.decimalToBinary = function(value, width)
	local binary = ""
	for i = 1, width do
		local bitValue = value % 2
		binary = tostring(bitValue) .. binary
		value = math.floor(value / 2)
	end
	return binary
end

module.calculateWithFlags = function(op, a, b, width)
	width = width or 8
	local mask = 2^width - 1
	local signed_mask = 2^(width-1)
	local signed_min = -signed_mask
	local signed_max = signed_mask - 1
	local res

	local function parity(val)
		local byte = bit.band(val, 0xFF)
		local bits = 0
		for i=0,7 do
			bits = bits + bit.band(bit.rshift(byte, i), 1)
		end
		return (bits % 2 == 0) and 1 or 0
	end

	local function sign_extend(val, bits)
		local shift = 32 - bits
		return bit.arshift(bit.lshift(val, shift), shift)
	end

	if op == "add" then
		res = a + b
		regw("CF", (res > mask) and 1 or 0)
		regw("OF", (bit.band(a, signed_mask) == bit.band(b, signed_mask)) and 
			(bit.band(res, signed_mask) ~= bit.band(a, signed_mask)) and 1 or 0)
		regw("SF", bit.band(res, signed_mask) ~= 0 and 1 or 0)
		regw("ZF", (bit.band(res, mask) == 0) and 1 or 0)
		regw("AF", (bit.band(a, 0xF) + bit.band(b, 0xF) > 0xF) and 1 or 0)
		regw("PF", parity(res))
		return bit.band(res, mask)

	elseif op == "sub" then
		res = a - b
		regw("CF", (a < b) and 1 or 0)
		regw("OF", (bit.band(a, signed_mask) ~= bit.band(b, signed_mask)) and 
			(bit.band(res, signed_mask) ~= bit.band(a, signed_mask)) and 1 or 0)
		regw("SF", bit.band(res, signed_mask) ~= 0 and 1 or 0)
		regw("ZF", (bit.band(res, mask) == 0) and 1 or 0)
		regw("AF", (bit.band(a, 0xF) < bit.band(b, 0xF)) and 1 or 0)
		regw("PF", parity(res))
		return bit.band(res, mask)

	elseif op == "adc" then
		local cf = regr("CF")
		res = a + b + cf
		regw("CF", (res > mask) and 1 or 0)
		regw("OF", (bit.band(a, signed_mask) == bit.band(b, signed_mask)) and 
			(bit.band(res, signed_mask) ~= bit.band(a, signed_mask)) and 1 or 0)
		regw("SF", bit.band(res, signed_mask) ~= 0 and 1 or 0)
		regw("ZF", (bit.band(res, mask) == 0) and 1 or 0)
		regw("AF", (bit.band(a, 0xF) + bit.band(b, 0xF) + cf > 0xF) and 1 or 0)
		regw("PF", parity(res))
		return bit.band(res, mask)

	elseif op == "sbb" then
		local cf = regr("CF")
		res = a - b - cf
		regw("CF", (a < (b + cf)) and 1 or 0)
		regw("OF", (bit.band(a, signed_mask) ~= bit.band(b + cf, signed_mask)) and 
			(bit.band(res, signed_mask) ~= bit.band(a, signed_mask)) and 1 or 0)
		regw("SF", bit.band(res, signed_mask) ~= 0 and 1 or 0)
		regw("ZF", (bit.band(res, mask) == 0) and 1 or 0)
		regw("AF", (bit.band(a, 0xF) < bit.band(b + cf, 0xF)) and 1 or 0)
		regw("PF", parity(res))
		return bit.band(res, mask)

	elseif op == "inc" then
		res = a + 1
		regw("OF", (a == signed_max) and 1 or 0)  
		regw("SF", bit.band(res, signed_mask) ~= 0 and 1 or 0)
		regw("ZF", (bit.band(res, mask) == 0) and 1 or 0)
		regw("AF", (bit.band(a, 0xF) + 1 > 0xF) and 1 or 0)
		regw("PF", parity(res))
		return bit.band(res, mask)

	elseif op == "dec" then
		res = a - 1
		regw("OF", (a == signed_min) and 1 or 0)  
		regw("SF", bit.band(res, signed_mask) ~= 0 and 1 or 0)
		regw("ZF", (bit.band(res, mask) == 0) and 1 or 0)
		regw("AF", (bit.band(a, 0xF) < 1) and 1 or 0)
		regw("PF", parity(res))
		return bit.band(res, mask)

	elseif op == "mul" then
		res = a * b
		regw("CF", (res > mask) and 1 or 0)
		regw("OF", regr("CF"))  
		return bit.band(res, mask)

	elseif op == "imul" then
		res = a * b
		local low = bit.band(res, mask)
		local high = bit.rshift(res, width)
		local sign_ext = sign_extend(low, width)
		local overflow = (high ~= sign_ext) and 1 or 0
		regw("CF", overflow)
		regw("OF", overflow)
		return bit.band(res, mask)

	elseif op == "div" then
		res = math.floor(a / b)
		local overflow = (res > mask) and 1 or 0
		regw("CF", overflow)
		regw("OF", 0)  
		regw("SF", bit.band(res, signed_mask) ~= 0 and 1 or 0)
		regw("ZF", (res == 0) and 1 or 0)
		regw("PF", parity(res))
		return bit.band(res, mask)

	elseif op == "neg" then
		res = -a
		regw("CF", (a ~= 0) and 1 or 0)  
		regw("OF", (a == signed_min) and 1 or 0)  
		regw("SF", bit.band(res, signed_mask) ~= 0 and 1 or 0)
		regw("ZF", (res == 0) and 1 or 0)
		regw("AF", (bit.band(a, 0xF) ~= 0) and 1 or 0)
		regw("PF", parity(res))
		return bit.band(res, mask)

	elseif op == "lsh" then
		local c = b % (width + 1)
		res = bit.lshift(a, c)
		regw("CF", c > 0 and bit.band(bit.rshift(a, width - c), 1) or regr("CF"))
		regw("OF", (c == 1) and bit.bxor(bit.band(res, signed_mask), regr("CF")) or 0)
		regw("SF", bit.band(res, signed_mask) ~= 0 and 1 or 0)
		regw("ZF", (bit.band(res, mask) == 0) and 1 or 0)
		regw("PF", parity(res))
		return bit.band(res, mask)

	elseif op == "rsh" then
		local c = b % (width + 1)
		res = bit.rshift(a, c)
		regw("CF", c > 0 and bit.band(bit.rshift(a, c - 1), 1) or regr("CF"))
		regw("OF", 0)
		regw("SF", bit.band(res, signed_mask) ~= 0 and 1 or 0)
		regw("ZF", (bit.band(res, mask) == 0) and 1 or 0)
		regw("PF", parity(res))
		return bit.band(res, mask)

	elseif op == "rcl" then
		local count = b % (width + 1)
		local res = a
		local cf = regr("CF")
		for _ = 1, count do
			local new_cf = bit.band(bit.rshift(res, width - 1), 1)
			res = bit.band(bit.lshift(res, 1) + cf, mask)
			cf = new_cf
		end
		regw("CF", cf)
		regw("OF", (count == 1) and bit.bxor(bit.band(res, signed_mask), cf) or 0)
		return res

	elseif op == "rcr" then
		local count = b % (width + 1)
		local res = a
		local cf = regr("CF")
		for _ = 1, count do
			local new_cf = bit.band(res, 1)
			res = bit.bor(bit.rshift(res, 1), bit.lshift(cf, width - 1))
			cf = new_cf
		end
		regw("CF", cf)
		regw("OF", (count == 1) and bit.bxor(bit.band(res, signed_mask), bit.band(a, signed_mask)) or 0)
		return res

	elseif op == "ror" then
		local c = b % width
		res = bit.rrotate(a, c)
		regw("CF", bit.band(res, 1))  
		regw("OF", (c == 1) and bit.bxor(bit.band(res, signed_mask), bit.band(a, signed_mask)) ~= 0 and 1 or 0)
		return bit.band(res, mask)

	elseif op == "rol" then
		local c = b % width
		res = bit.lrotate(a, c)
		regw("CF", bit.band(bit.rshift(res, width - 1), 1))  
		regw("OF", (c == 1) and bit.bxor(bit.band(res, signed_mask), bit.band(a, signed_mask)) ~= 0 and 1 or 0)
		return bit.band(res, mask)

	elseif op == "and" then
		res = bit.band(a, b)
		regw("CF", 0)
		regw("OF", 0)
		regw("SF", bit.band(res, signed_mask) ~= 0 and 1 or 0)
		regw("ZF", (res == 0) and 1 or 0)
		regw("PF", parity(res))
		return res

	elseif op == "xor" then
		res = bit.bxor(a, b)
		regw("CF", 0)
		regw("OF", 0)
		regw("SF", bit.band(res, signed_mask) ~= 0 and 1 or 0)
		regw("ZF", (res == 0) and 1 or 0)
		regw("PF", parity(res))
		return res

	elseif op == "or" then
		res = bit.bor(a, b)
		regw("CF", 0)
		regw("OF", 0)
		regw("SF", bit.band(res, signed_mask) ~= 0 and 1 or 0)
		regw("ZF", (res == 0) and 1 or 0)
		regw("PF", parity(res))
		return res

	elseif op == "not" then
		res = bit.bnot(a)  
		return bit.band(res, mask)

	else
		error("Unsupported operation: " .. op)
	end
end

module.bitToColor = function(number)
	return egaColors[number]
end

module.readEGA = function(...)
	
end

module.loadIntoMem = function (data, offset)
	local t = string.split(data, " ")
	offset = offset or 0
	for i, v in ipairs(t) do							
		write(offset + (i - 1), tonumber("0x" .. v))
	end
end

return module

