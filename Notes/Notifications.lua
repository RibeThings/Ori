---- IT REQUIRES 30LOG LIBRARY!!!
assert(class, "Please include 30log library")

---- 'new' function
local new = function(InstanceClass, InstanceParent, ...)
	-- Check if the arguments are correct
	local InstanceClassType = type(InstanceClass)
	local InstanceParentType = typeof(InstanceParent)
	assert(InstanceClassType == "nil" or InstanceClassType == "string", "Expected string at argument #1, got " .. InstanceClassType)
	assert(InstanceParentType == "nil" or InstanceParentType == "Instance", "Expected Instance at argument #2, got " .. InstanceParentType)

	-- Create instance
	local ReturnedInstance
	local SUCCESS, RETURN = pcall(function()
		ReturnedInstance = Instance.new(InstanceClass)
	end)
	if not SUCCESS then
		error(InstanceClass .. " is not a valid ClassName: " .. debug.traceback())
		return nil
	end
	ReturnedInstance.Parent = InstanceParent

	-- Change properties of the Instance
	local ArgumentProperties = {...}
	local SetProperties = {}

	for ArgumentIndex, Argument in ipairs(ArgumentProperties) do
		-- Check if 'Argument' is a table
		local ArgumentType = type(Argument)
		assert(ArgumentType == "table", "Expected table at argument #" .. tostring(ArgumentIndex + 2) .. ", got " .. ArgumentType)
		--
		for PropertyName, Property in pairs(Argument) do
			SetProperties[PropertyName] = Property
		end
	end

	for PropertyName, Property in pairs(SetProperties) do
		local SUCCESS, RETURN = pcall(function()
			ReturnedInstance[PropertyName] = Property
		end)

		if not SUCCESS then
			error("Error trying to set property '" .. PropertyName .. "' to Instance " .. InstanceClass .. " (Property type is " .. type(PropertyValue) .. ") ")
		end
	end

	return ReturnedInstance
end
----

---- Notifications system
NotificationHeight = 40

NotificationNormal = Color3.fromRGB(47, 47, 47)
NotificationError = Color3.fromRGB(200, 47, 47)
NotificationTitleHeight = 15
NotificationGreen = Color3.fromRGB(48, 220, 48)
NotificationRed = Color3.fromRGB(220, 48, 48)

Notification = class("Notification", {
	parent = nil, -- : UIInstance

	frame = nil,
	bg = nil,
	framecorner = nil,
	colorbar = nil,
	text = nil,
	duration = 0,

	fadeTime = 0,
	fadeInTweens = {},
	fadeOutTweens = {},
	fadeOutTime = 0,
	visible = false,
})

function Notification:createTweens()
	local ts = game:GetService("TweenService")

	self.fadeTime = 0.2
	local animInfo = TweenInfo.new(self.fadeTime, Enum.EasingStyle.Sine, Enum.EasingDirection.In)

		-- Create fade out tweens
	table.insert(self.fadeOutTweens, ts:Create(self.frame, animInfo, {BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 20)}))
	table.insert(self.fadeOutTweens, ts:Create(self.text, animInfo, {TextTransparency = 1}))
	table.insert(self.fadeOutTweens, ts:Create(self.colorbar, animInfo, {BackgroundTransparency = 1}))
	
		-- Create fade in tweens
	table.insert(self.fadeInTweens, ts:Create(self.frame, animInfo, {BackgroundTransparency = 0, Position = UDim2.fromOffset(0, 0)}))
	table.insert(self.fadeInTweens, ts:Create(self.text, animInfo, {TextTransparency = 0}))
	table.insert(self.fadeInTweens, ts:Create(self.colorbar, animInfo, {BackgroundTransparency = 0}))
	
		--
	self.fadeOutTime = self.duration + self.fadeTime
end

function Notification:reset()
	-- Resets notification for a fade in
	self.frame.BackgroundTransparency = 1
	self.frame.Position = UDim2.fromOffset(0, 20)
	
	self.text.TextTransparency = 1
	
	self.colorbar.BackgroundTransparency = 12
	
	self.visible = false
end

function Notification:fadeOut()
	-- Fades out notif
	self.visible = false
	for i, v in ipairs(self.fadeOutTweens) do
		v:Play()
	end
end

function Notification:fadeIn()
	-- Fades in notif (:reset() should be called first)
	self.visible = true
	for i, v in ipairs(self.fadeInTweens) do
		v:Play()
	end
end

function Notification:setRadius(num)
	self.framecorner.CornerRadius = UDim.new(0, num)
end

function Notification:setColor(color)
	-- Changes notif colorbar color
	self.colorbar.BackgroundColor3 = color
end

function Notification:changeTheme(bgColor, textColor)
	-- Changes bgColor and textColor
	self.frame.BackgroundColor3 = bgColor
	self.text.TextColor3 = textColor
end

function Notification:setHeight(num)
	-- Changes notif height
	self.bg.Size = UDim2.new(1, 0, 0, num or NotificationHeight)
end

function Notification:init(parent, color, text, height, bgcolor, textcolor)
	self.parent = parent

	-- Create bg
	self.bg = new("Frame", self.parent, {
		BackgroundTransparency = 1,
		ClipsDescendants = true
	})
	self:setHeight(height)

	-- Create frame
	self.frame = new("Frame", self.bg, {
		Size = UDim2.new(1, 0, 1, 0),
		BorderSizePixel = 0,
		BackgroundColor3 = bgcolor,
	})
	-- Add corner
	self.framecorner = new("UICorner", self.frame, {
		CornerRadius = UDim.new()
	})

	-- Create colorbar
	self.colorbar = new("Frame", self.frame, {
		Position = UDim2.fromScale(0, 1), AnchorPoint = Vector2.new(0, 1),
		Size = UDim2.new(1, 0, 0, 4),
		BorderSizePixel = 0,
	})
	self:setColor(color)

	-- Create text
	self.text = new("TextLabel", self.frame, {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		TextColor3 = textcolor,
		Text = text,
	})
	
	-- Create tweens
	self:reset()
	self:createTweens()
	self:fadeIn()
end
-- Notification Holder
NotificationHolder = class("NotificationHolder", {
	parent = nil,

	notifications = {},
	aliveNotifications = 0,

	frame = nil,
	framelayout = nil,
	
	lastNotifRounded = false,
	
	notifsBGColor = nil,
	notifsTextColor = nil,
})

function NotificationHolder:init(parent, data)
	-- data should look like
	--[[
	{
	  pos = UDim2.new(0, 5, 1, -60), -- pos of the notifs holder
	  anchorPoint = Vector2.new(0, 1), -- anchor point of the notifs holder
	  width = 200, -- width of notifications
	  spacing = 3, -- space between notifs
	  rounded = true, -- if last notification should be rounded
	  bgColor = Color3.fromRGB(47, 47, 47), -- background color of notifs
	  textColor = Color3.fromRGB(255, 255, 255), -- text color of notifs
	}
	]]--
	self.parent = parent
	self.lastNotifRounded = data.rounded
	self.notifsBGColor = data.bgColor
	self.notifsTextColor = data.textColor
	
	-- Create frame
	self.frame = new("Frame", self.parent, {
		BackgroundTransparency = 1,
		Position = data.pos,
		AnchorPoint = data.anchorPoint,
		Size = UDim2.fromOffset(data.width),
	})
	-- Add layout
	self.framelayout = new("UIListLayout", self.frame, {
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, data.spacing)
	})
end

function NotificationHolder:notificate(data)
	-- data should look like
	--[[
	{
	  text = "Hello world", -- notification text
	  color = Color3.fromRGB(0, 0, 0), -- notification color
	  duration = 3, -- notification duration
	  height = 100, -- notification height (optional)
	}
	]]--
	
	-- Create notif
	local notifId = self.aliveNotifications + 1
	self.aliveNotifications = notifId
	
	local notif = Notification(self.frame, data.color, data.text, data.height, self.notifsBGColor, self.notifsTextColor)
	table.insert(self.notifications, notif)
	
	-- Round if its last
	if notifId == 1 and self.lastNotifRounded then
		notif:setRadius(4)
	end
	
	-- Fade in
	notif:fadeIn()
	
	coroutine.wrap(function(self, duration, notif, id)
		-- Made so it disappears after data.duration seconds
		wait(duration)
		
		notif:fadeOut() -- Make notif fade out
		self.aliveNotifications = self.aliveNotifications - 1
		
		wait(notif.fadeTime)
		
		local nextNotif = self.notifications[id + 1] -- Get the notif below this one
		
		if nextNotif and self.lastNotifRounded then -- Make so notif below this one gets round
			nextNotif:setRadius(4)
		end
		
			-- Destroy notif
		if self.aliveNotifications == 0 then
			for i, v in ipairs(self.notifications) do
				v.bg:Destroy()
				self.notifications[i] = nil
			end
		end
		
	end)(self, data.duration, notif, notifId)
	
	return notif
end

function NotificationHolder:changeTheme(bgColor, textColor)
	self.notifsBGColor = data.bgColor
	self.notifsTextColor = data.textColor
	
	-- Change every notif theme
	for i, v in ipairs(self.aliveNotifications) do
		v:changeTheme(self.notifsBGColor, self.notifsTextColor)
	end
end

--[[
-- Create the NotificationHolder for notifications, this is needed
-- The NotificationHolder (obviously) handles every notifications and creates them

local holder = NotificationHolder(GUI, {
	pos = UDim2.new(0, 5, 1, -60), -- pos of the notifs holder
	anchorPoint = Vector2.new(0, 1), -- anchor point of the notifs holder
	width = 200, -- width of notifications
	spacing = 3, -- space between notifs
	rounded = true, -- if last notification should be rounded
	bgColor = Color3.fromRGB(47, 47, 47), -- background color of notifs
	textColor = Color3.fromRGB(255, 255, 255), -- text color of notifs
})

-- Notificate something
holder:notificate({
	text = "Hello world", -- notification text
	color = Color3.fromRGB(0, 0, 0), -- notification color
	duration = 3, -- notification duration
	height = 100, -- notification height (optional)
})

-- Lets notificate more!
wait(4)

for i = 1, 5 do
	-- Create 5 notifications
	
	holder:notificate({
		text = "Notification #" .. i,
		color = NotificationGreen,
		duration = 3,
	})
	wait(0.1)
end
]]

--[[
You can use NotificationGreen & NotificationRed for your notif color btw
]]
