local ADDON_NAME, st = ...
local UF = st:GetModule('Unitframes')

local function Construct(self)
	local health = CreateFrame('StatusBar', nil, self)
	health.config = self.config.health

	self.Health = health
end

local function Update(self)
	self.Health:SetStatusBarTexture(st.BLANK_TEX)

	self.Health.Smooth = true
	self.Health.colorTapping		= self.Health.config.colorTapping
	self.Health.colorDisconnected	= self.Health.config.colorDisconnected
	self.Health.colorHealth			= self.Health.config.colorHealth
	self.Health.colorClass			= self.Health.config.colorClass
	self.Health.colorClassNPC		= self.Health.config.colorClassNPC
	self.Health.colorClassPet		= self.Health.config.colorClassPet
	self.Health.colorReaction		= self.Health.config.colorReaction
	self.Health.colorSmooth			= self.Health.config.colorSmooth
	self.Health.colorCustom			= self.Health.config.colorCustom
	self.Health.customColor 		= self.Health.config.customColor
end

UF.elements.Health = {
	name = 'Health',
	Construct = Construct,
	Update = Update
}