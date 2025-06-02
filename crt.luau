local replicatedStorage = game:GetService("ReplicatedStorage")
local registers = require(replicatedStorage.CPU.Registers)
local io = require(replicatedStorage.CPU.IOManager)
local runService = game:GetService("RunService")
local as = game:GetService("AssetService")
local ram = require(replicatedStorage.CPU.RAM)
local charSet = require(replicatedStorage.DisplayModules.charSet)
local cursorContainer = replicatedStorage.DisplayModules.Cursor

local ioUpdate = replicatedStorage.Remote.ioUpdate

local awaiting = false
local x0C = false	-- Start Address High Byte
local x0D = false	-- Start Address Low Byte
local x0A = false	-- Cursor start
local x0B = false	-- Cursor end
local x0E = false	-- Location high
local x0F = false	-- Location low

local access = 0x0
local linearAddress = 0x0
local cursorAddress = 0x0
local screenPaused = false
local temp = 0x0
local frameSkip = false

local mode = false	-- False for text
local color = false	-- False for greyscale
local intense = false
local res = false	-- False for low
local enabled = false
local strongColor = false	-- False for weaker
local cursorBlink = true
local cursorUpper = 2
local cursorLower = 0
local cursorEnabled = true

local displayHigh = as:CreateEditableImage({Size = Vector2.new(640, 200)})
local displayLow = as:CreateEditableImage({Size = Vector2.new(320, 200)})
local cursor = as:CreateEditableImage({Size = Vector2.new(100, 310)})

local function readBit(int, n)
	return bit32.band(bit32.rshift(int, n), 1)
end

local function getRGBIColor(index)
	local i = bit32.band(index, 0x8) ~= 0 and 0xAA or 0x55
	local r = bit32.band(index, 0x4) ~= 0 and i or 0
	local g = bit32.band(index, 0x2) ~= 0 and i or 0
	local b = bit32.band(index, 0x1) ~= 0 and i or 0
	
	return Color3.fromRGB(r, g, b)
end

ioUpdate.OnClientEvent:Connect(function(address, new)
	if address == 0x3D4 then
		local op = new

		if op == 0x0C then
			x0C = true
			awaiting = true
			return
		end

		if op == 0x0D then
			x0D = true
			awaiting = true
			return	
		end

		if op == 0x0A then
			x0A = true
			awaiting = true
			return
		end

		if op == 0x0B then
			x0B = true
			awaiting = true
			return
		end

		if op == 0x0E then
			x0E = true
			awaiting = true
			return
		end

		if op == 0x0F then
			x0F = true
			awaiting = true
			return	
		end
		return
	end
	
	if address == 0x3D5 then
		if not awaiting then return false end

		if x0C then
			local data = new
			linearAddress = bit32.band(linearAddress, 0x00FF)
			linearAddress = bit32.bor(linearAddress, bit32.lshift(data, 8))
			x0C = false
			awaiting = false
			return
		end

		if x0D then
			local data = io.read(0x3D5)
			linearAddress = bit32.band(linearAddress, 0xFF00)
			linearAddress = bit32.bor(linearAddress, data)
			x0D = false
			awaiting = false
			return
		end

		if x0A then
			local data = io.read(0x3D5)
			cursorBlink = readBit(data, 6) == 1
			cursorEnabled = readBit(data, 5) == 0
			cursorUpper = bit32.band(data, 0x1F)
			x0A = false
			awaiting = false
			return
		end

		if x0B then
			cursorLower = bit32.band(io.read(0x3D5), 0x1F)
			x0B = false
			awaiting = false
		end
		return
	end
	
	if address == 0x3D8 then
		local byte = new

		mode = (readBit(byte, 1) == 1)
		res = (readBit(byte, 4) == 1)
		color = (readBit(byte, 2) == 1)
		enabled = (readBit(byte, 3) == 1)
		blinkingEnabled = (readBit(byte, 5) == 1)
		
	end
end)

cursorContainer.Parent = script.Parent.Back

runService.Stepped:Connect(function()
	if not enabled then return false end
	if frameSkip then frameSkip = false return end
	frameSkip = true
	if not mode and res then	-- Text 80x25
		local container = script.Parent.Back
		container.textModeBig.Visible = true
		container.textModeSmall.Visible = false
		container.graphicsModeBig.Visible = false
		local temp = 753664
		local accessAddress = linearAddress + temp
		temp = 1
		local dataChunk = replicatedStorage.Remote.ChunkRequest:InvokeServer(accessAddress, 4000)

		for y = 1, 25 do
			for x = 1, 80 do
				local char = container.textModeBig[x .. " " .. y]
				local charCode = dataChunk[linearAddress + temp]
				char.Text = charSet[charCode] or "?"
				temp += 1
				local attr = dataChunk[temp] or 0
				temp += 1
				local fgIndex = bit32.band(attr, 0x0F)
				local bgIndex = bit32.rshift(bit32.band(attr, 0x70), 4)
				local blinkAttr = bit32.band(attr, 0x80) ~= 0
				local show = true

				if blinkingEnabled and blinkAttr then
					show = math.floor(tick() * 2) % 2 == 0
				end

				char.TextColor3 = show and getRGBIColor(fgIndex) or getRGBIColor(bgIndex)
				char.BackgroundColor3 = getRGBIColor(bgIndex)
			end
		end
		if math.floor(tick() * 2) % 2 == 0 then

			cursorContainer.Visible = cursorEnabled

			local cursorLower = math.max(cursorLower, 1)
			local cursorUpper = math.max(cursorUpper, 0)

			local charCell = container.textModeBig[(cursorAddress % 80 + 1) .. " " .. (math.floor(cursorAddress / 80) + 1)]

			cursor:DrawRectangle(Vector2.new(0, 0), Vector2.new(100, 310), charCell.BackgroundColor3, 0, Enum.ImageCombineType.Overwrite)
			cursor:DrawRectangle(Vector2.new(0, cursorUpper * 10), Vector2.new(100, math.max(cursorLower * 10, 1)), charCell.TextColor3, 0, Enum.ImageCombineType.Overwrite)


			cursorContainer.ImageContent = Content.fromObject(cursor)
			cursorContainer.Position = UDim2.new(0, charCell.AbsolutePosition.X - cursorContainer.Parent.AbsolutePosition.X, 0, charCell.AbsolutePosition.Y - cursorContainer.Parent.AbsolutePosition.Y)
			cursorContainer.Size = UDim2.new(0, charCell.AbsoluteSize.X, 0, charCell.AbsoluteSize.Y)
		
		else
			cursorContainer.Visible = false
		end	
	end
	if not mode and not res then	-- Text 40x25
		local container = script.Parent.Back
		container.textModeBig.Visible = false
		container.textModeSmall.Visible = true
		container.graphicsModeBig.Visible = false
		local temp = 753664
		local accessAddress = linearAddress + temp
		temp = 1
		local dataChunk = replicatedStorage.Remote.ChunkRequest:InvokeServer(accessAddress, 2000)

		for y = 1, 25 do
			for x = 1, 40 do
				local char = container.textModeSmall[x .. " " .. y]
				local charCode = dataChunk[linearAddress + temp]
				char.Text = charSet[charCode] or "?"
				temp += 1
				local attr = dataChunk[temp] or 0
				temp += 1
				local fgIndex = bit32.band(attr, 0x0F)
				local bgIndex = bit32.rshift(bit32.band(attr, 0x70), 4)
				local blinkAttr = bit32.band(attr, 0x80) ~= 0
				local show = true

				if blinkingEnabled and blinkAttr then
					show = math.floor(tick() * 2) % 2 == 0
				end

				char.TextColor3 = show and getRGBIColor(fgIndex) or getRGBIColor(bgIndex)
				char.BackgroundColor3 = getRGBIColor(bgIndex)
			end
		end
		if math.floor(tick() * 2) % 2 == 0 then

			cursorContainer.Visible = cursorEnabled

			local cursorLower = math.max(cursorLower, 1)
			local cursorUpper = math.max(cursorUpper, 0)

			local charCell = container.textModeSmall[(cursorAddress % 40 + 1) .. " " .. (math.floor(cursorAddress / 40) + 1)]

			cursor:DrawRectangle(Vector2.new(0, 0), Vector2.new(100, 310), charCell.BackgroundColor3, 0, Enum.ImageCombineType.Overwrite)
			cursor:DrawRectangle(Vector2.new(0, cursorUpper * 10), Vector2.new(100, math.max(cursorLower * 10, 1)), charCell.TextColor3, 0, Enum.ImageCombineType.Overwrite)


			cursorContainer.ImageContent = Content.fromObject(cursor)
			cursorContainer.Position = UDim2.new(0, charCell.AbsolutePosition.X - cursorContainer.Parent.AbsolutePosition.X, 0, charCell.AbsolutePosition.Y - cursorContainer.Parent.AbsolutePosition.Y)
			cursorContainer.Size = UDim2.new(0, charCell.AbsoluteSize.X, 0, charCell.AbsoluteSize.Y)

		else
			cursorContainer.Visible = false
		end	
	end
end)
