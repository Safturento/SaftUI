local ADDON_NAME, st = ...
local SK = st:GetModule('Skinning')

SK.AddonSkins.AddonSkins = function()
	local AS = unpack(AddOnSkins)

	function AS:UpdateMedia()
		AS.Blank = st.BLANK_TEX
		AS.NormTex = st.BLANK_TEX
		AS.Font = select(1, st:GetFont(SK.config.font):GetFont())
		AS.BackdropColor = st.config.profile.templates[SK.config.template].backdropcolor
		AS.BorderColor = st.config.profile.templates[SK.config.template].bordercolor
		AS.Template = SK.config.template
	end 
	
	function AS:SetTemplate(frame, template, texture)
		st:SetTemplate(frame, 'thicktransparent')

		if template == 'NoBackdrop' then
			AS:SetBackdropColor(frame, 0, 0, 0, 0)
		end

		if template == 'NoBorder' then
			AS:SetBackdropBorderColor(frame, 0, 0, 0, 0)
		end
	end
end