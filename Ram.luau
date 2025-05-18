local module = {}
local addrs = {}
local ramSize = 0xFFFFF

module.read = function(addr)
	return addrs[bit32.band(addr, ramSize) + 1] or 0
end

module.write = function(addr, Val)
	addrs[bit32.band(addr, ramSize) + 1] = bit32.band(Val, 0xFF)
end

return module
