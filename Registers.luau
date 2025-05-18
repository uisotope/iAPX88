local replicatedStorage = game:GetService("ReplicatedStorage")
local properties = require(replicatedStorage.CPU.Properties)

local m = {}
local mod = {}

local halt = false
local waiting = false

local registerHierarchy = {
	AX = { parts = { AH = 8, AL = 0 } },
	BX = { parts = { BH = 8, BL = 0 } },
	CX = { parts = { CH = 8, CL = 0 } },
	DX = { parts = { DH = 8, DL = 0 } },
	AH = { parent = 'AX', shift = 8 },
	AL = { parent = 'AX', shift = 0 },
	BH = { parent = 'BX', shift = 8 },
	BL = { parent = 'BX', shift = 0 },
	CH = { parent = 'CX', shift = 8 },
	CL = { parent = 'CX', shift = 0 },
	DH = { parent = 'DX', shift = 8 },
	DL = { parent = 'DX', shift = 0 },
}

-- GENERIC PURPOSE REGISTERS
m.AX = 0x0
m.BX = 0x0
m.CX = 0x0
m.DX = 0x0
-- AX
m.AH = 0x0
m.AL = 0x0
-- BX
m.BH = 0x0
m.BL = 0x0
-- CX
m.CH = 0x0
m.CL = 0x0
-- DX
m.DH = 0x0
m.DL = 0x0    
-- POINTER/INDEX REGISTERS
m.SP = 0xFFFF
m.BP = 0x0
m.SI = 0x0
m.DI = 0x0
-- SEGMENT REGISTERS
m.CS = 0xF000
m.SS = 0x0
m.DS = 0x0
m.ES = 0x0
-- FLAGS
m.CF = 0x0
m.PF = 0x0
m.AF = 0x0
m.ZF = 0x0
m.SF = 0x0
m.TF = 0x0
m.IF = 0x0
m.DF = 0x0
m.OF = 0x0
-- ADDITIONAL
m.IP = 0xE000

mod.read = function(reg)
	if m[reg] then
		return m[reg]
	elseif reg == "halt" then
		return halt
	elseif reg == "test#" then
		return waiting
	else
		warn(debug.traceback())
		error("Attempt to read from " .. reg)
	end
end

mod.write = function(reg, val)
	if m[reg] then
		local regsize = properties[reg].size
		local maskedVal
		if regsize == 8 then
			maskedVal = bit32.band(val, 0xFF)
		elseif regsize == 16 then
			maskedVal = bit32.band(val, 0xFFFF)
		elseif regsize == 1 then
			maskedVal = (val ~= 0) and 1 or 0
		else
			maskedVal = val
		end
		m[reg] = maskedVal
		local partInfo = registerHierarchy[reg]
		if partInfo and partInfo.parent then
			local parent = partInfo.parent
			local parentParts = registerHierarchy[parent].parts
			local parentVal = 0
			for part, shift in pairs(parentParts) do
				parentVal = bit32.bor(parentVal, bit32.lshift(m[part] or 0, shift))
			end
			parentVal = bit32.band(parentVal, 0xFFFF)
			m[parent] = parentVal
		end

		local parentParts = registerHierarchy[reg] and registerHierarchy[reg].parts
		if parentParts then
			local parentVal = m[reg]
			for part, shift in pairs(parentParts) do
				local partVal = bit32.rshift(bit32.band(parentVal, 0xFFFF), shift)
				partVal = bit32.band(partVal, 0xFF) 
				m[part] = partVal
			end
		end
	elseif reg == "halt" then
		halt = val
	elseif reg == "test#" then
		waiting = val
	else
		warn(debug.traceback())
		error("Attempt to write to " .. reg)
	end
end

return mod
