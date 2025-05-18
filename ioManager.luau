local module = {}
local ports = {}
local ioSize = 0xFFFF

module.read = function(port)
	return ports[bit32.band(port, ioSize) + 1] or 0
end

module.write = function(port, Val)
	ports[bit32.band(port, ioSize) + 1] = bit32.band(Val, 0xFF)
	print(string.format("Writing to port 0x%X with value 0x%X", port, Val))
end

return module

