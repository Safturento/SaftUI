local st = SaftUI

local function OpenRetailDropdown(self)
    MenuUtil.CreateCheckboxContextMenu(self, self.isChecked, self.setChecked, unpack(self.entries))
    self:Show()
end


function st:CreateCheckboxDropdown(name, parent, entries, isChecked, setChecked)
    local dropdown = CreateFrame("DropdownButton", name, parent or UIParent)
    dropdown.entries = {}
    for key, entry in pairs(entries) do
        tinsert(dropdown.entries, { entry.text, key })
    end

    dropdown.Open = OpenRetailDropdown
    dropdown.isChecked = isChecked
    dropdown.setChecked = setChecked

    return dropdown
end