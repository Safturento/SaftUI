local st = SaftUI

local function OpenRetailDropdown(self)
    MenuUtil.CreateCheckboxContextMenu(self, self.isChecked, self.setChecked, unpack(self.entries))
    self:Show()
end

local function OpenEasyMenu(self)
    EasyMenu(self.entries, self, self:GetParent())
end

function st:CreateCheckboxDropdown(name, parent, entries, isChecked, setChecked)
    local dropdown
    if st.retail then
        dropdown = CreateFrame("DropdownButton", name, parent or UIParent)
        dropdown.entries = {}
        for key, entry in pairs(entries) do
            tinsert(dropdown.entries, { entry.text, key })
        end

        dropdown.Open = OpenRetailDropdown
        dropdown.isChecked = isChecked
        dropdown.setChecked = setChecked

    else
        dropdown = CreateFrame("Frame", name, parent or UIParent, "UIDropDownMenuTemplate")
        dropdown.entries = {}
        dropdown.Open = OpenEasyMenu
        for key, entry in pairs(entries) do
            tinsert(dropdown.entries, {
                isNotRadio = true,
                keepShownOnClick = true,
                text = entry.text,
                func = function() setChecked(key) end,
                checked = function() return isChecked(key) end,
            })
        end
    end

    return dropdown
end