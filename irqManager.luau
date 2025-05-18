local rs = game:GetService("ReplicatedStorage")  

local event = {}
local rwrite, rread = require(rs.CPU.Registers).write, require(rs.CPU.Registers).read
local bit = bit32
local utils = require(rs.CPU.Utilities)
local read16, write16 = utils.littleEndianRead16, utils.littleEndianWrite16

event.OnServerInvoke = function (base, level)
	local vectorAddr = base + level * 4
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
	rwrite("halt", false)
end

return event
