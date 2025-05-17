local st = SaftUI

--[[
    options: {
        buttonWidth: number
        buttonHeight: number
        buttonSpacing: number
        template: string
        growthDirection: 'UP' | 'DOWN' | 'LEFT' | 'RIGHT'
        items = [
            {
                label: string
                onClick: function(self, button, down)
            }
        ]
    }
]]--
local function createButton(buttonName, buttons, label, onClick)
    local button = st:CreateButton(buttonName,
            selector, buttonName, self.config.template)

    button:SetSize(buttonWidth, buttonHeight)

    button:SetScript('OnClick', function(self)
        for _,button in pairs(buttons) do
            st:SetBackdrop(button, self.config.template)
        end
        self.backdrop:SetBackdropBorderColor(unpack(st.config.profile.colors.button.blue))
        BankFrame_ShowPanel(bankFrameName)
    end)

    return button
end

function st:CreateRadioGroup(name, parent, options)
    local radioGroup = st:CreateFrame('frame', name, parent)
    st:SetBackdrop(radioGroup, self.config.template)

	radioGroup:SetHeight(options.buttonHeight + options.buttonSpacing * 2)
	radioGroup:SetWidth(options.buttonWidth * 3 + options.buttonSpacing * 5)

    radioGroup.buttons = {}

    local prev
    for i, item in pairs(options.items) do
        local button = st:CreateButton(name..'Button'..i, parent, item.label, self.config.template)
        button:SetSize(options.buttonWidth, options.buttonHeight)
        button.config = item --store button config for use in callbacks
        button:SetScript('OnClick', function(self, mouseButton, down)
            for _, _button in pairs(radioGroup.buttons) do
				st:SetBackdrop(_button, options.template)
			end
			self.backdrop:SetBackdropBorderColor(unpack(st.config.profile.colors.button.blue))

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