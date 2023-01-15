local _, ns = ...
local oUF = ns.oUF or oUF

function toTime(sec)
	local day, hour, minute = 86400, 3600, 60
	if sec >= day then
		return format("%dd", ceil(sec / day))
	elseif sec >= hour then
		return format("%dh", ceil(sec / hour))
	elseif sec >= minute then
		return format("%dm", ceil(sec / minute))
	elseif sec >= minute / 12 then
		return floor(sec)
	end
	return format("%.1f", sec)
end

local function Update(self, event)
    local element = self.Widget
    local widgetSetId = UnitWidgetSet(self.unit)

    element:SetShown(widgetSetId ~= nil)

    if not widgetSetId then return end

    local widgets = C_UIWidgetManager.GetAllWidgetsBySetID(widgetSetId)
    local widgetID = widgets[1].widgetID

    local widgetType = widgets[1].widgetType
    local widgetTypeInfo = UIWidgetManager:GetWidgetTypeInfo(widgetType)

    tableprint(C_UIWidgetManager.GetUnitPowerBarWidgetVisualizationInfo(widgetID))

    local widgetInfo = widgetTypeInfo.visInfoDataFunction(widgetID);
    --local widgetsOnlyMode = UnitNameplateShowsWidgetsOnly(self.unit)

    local min, max, current = widgetInfo.barMin, widgetInfo.barMax, widgetInfo.barValue
    local text = widgetInfo.text

    if widgetInfo.hasTimer then
        text = ('%s %s'):format(text, toTime(current))
    end

    element:SetMinMaxValues(min, max)
    element:SetValue(current)
    element.text:SetText(text)

    --tableprint(widgetInfo)

end

local function Path(self, ...)
    return (self.Widget.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate')
end

local function Enable(self)
    local element = self.Widget
    if element then
        element.__owner = self
        element.ForceUpdate = ForceUpdate

        return true
    end
end

local function Disable(self)
    local element = self.Widget
    if element then
        element:Hide()
    end
end

oUF:AddElement('Widget', Path, Enable, Disable)