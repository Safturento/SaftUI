local st = SaftUI

--[[
    options: {
        buttonWidth: number
        buttonHeight: number
        buttonSpacing: number
        theme, background: strings, the look a click gives the buttons (or
            template, an old template name, from a caller not yet moved to themes)
        growthDirection: 'UP' | 'DOWN' | 'LEFT' | 'RIGHT'
        items = [
            {
                label: string
                onClick: function(self, button, down)
            }
        ]
    }
]]--
function st:CreateRadioGroup(name, parent, options)
    -- The group has no backdrop of its own; its buttons have theirs.
    local radioGroup = st:CreateFrame('frame', name, parent)

	radioGroup:SetHeight(options.buttonHeight + options.buttonSpacing * 2)
	radioGroup:SetWidth(options.buttonWidth * 3 + options.buttonSpacing * 5)

    radioGroup.buttons = {}

    local prev
    for i, item in pairs(options.items) do
        local button = st:CreateButton(name..'Button'..i, parent, item.label)
        button:SetSize(options.buttonWidth, options.buttonHeight)
        button.config = item --store button config for use in callbacks
        button:SetScript('OnClick', function(self, mouseButton, down)
            for _, _button in pairs(radioGroup.buttons) do
				if options.theme then
					st:SetBackdrop(_button, options.theme, options.background, 'small')
				else
					st:SetBackdrop(_button, options.template)
				end
			end
			self.backdrop:SetBackdropBorderColor(st.config.profile.colors.button.blue:GetRGB())

            -- global click handler
            if options.onClick then
                options.onClick(self, mouseButton, down)
            end

            -- per item click handler
            if item.onClick then
                item.onClick(self, mouseButton, down)
            end
        end)

        -- TODO: Implement all growth directions
        if prev then
			button:SetPoint('TOPLEFT', prev, 'TOPRIGHT', options.buttonSpacing, 0)
		else
			button:SetPoint('TOPLEFT', radioGroup, 'TOPLEFT', options.buttonSpacing, -options.buttonSpacing)
		end
		prev = button

        if options.postCreate then
            options.postCreate(button)
        end

		tinsert(radioGroup.buttons, button)
    end

    return radioGroup
end