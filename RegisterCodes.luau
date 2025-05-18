local module = {}

module.upper = {
	AX = 0x0, -- 000
	CX = 0x1, -- 001
	DX = 0x2, -- 010
	BX = 0x3, -- 011
	SP = 0x4, -- 100
	BP = 0x5, -- 101
	SI = 0x6, -- 110
	DI = 0x7, -- 111
	[0x0] = "AX", -- reverse lookup
	[0x1] = "CX", -- reverse lookup
	[0x2] = "DX", -- reverse lookup
	[0x3] = "BX", -- reverse lookup
	[0x4] = "SP", -- reverse lookup
	[0x5] = "BP", -- reverse lookup
	[0x6] = "SI", -- reverse lookup
	[0x7] = "DI", -- reverse lookup
}

module.lower = {
	AL = 0x0, -- 000
	CL = 0x1, -- 001
	DL = 0x2, -- 010
	BL = 0x3, -- 011
	AH = 0x4, -- 100
	CH = 0x5, -- 101
	DH = 0x6, -- 110
	BH = 0x7, -- 111
	[0x0] = "AL", -- reverse lookup
	[0x1] = "CL", -- reverse lookup
	[0x2] = "DL", -- reverse lookup
	[0x3] = "BL", -- reverse lookup
	[0x4] = "AH", -- reverse lookup
	[0x5] = "CH", -- reverse lookup
	[0x6] = "DH", -- reverse lookup
	[0x7] = "BH", -- reverse lookup
}


return module
