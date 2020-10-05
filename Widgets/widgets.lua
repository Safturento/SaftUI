local st = select(2, ...)
local Widgets = st:NewModule('Widgets')
st.Widgets = Widgets

function Widgets:OnEnable()
    --local testCheckbox = Widgets:CheckBox('test', UIParent, 'Test label')
    --testCheckbox:SetPoint('Center')

    --local testEditBox = Widgets:EditBox('testEditBox', UIParent, 3)
    --testEditBox:SetSize(200, 50)
    --testEditBox:SetPoint('CENTER')
end

function ShowColorPicker(r, g, b, a, changedCallback)
     ColorPickerFrame:SetColorRGB(r,g,b);
     ColorPickerFrame.hasOpacity, ColorPickerFrame.opacity = (a ~= nil), a;
     ColorPickerFrame.previousValues = {r,g,b,a};
     ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc =
      changedCallback, changedCallback, changedCallback;
     ColorPickerFrame:Hide(); -- Need to run the OnShow handler.
     ColorPickerFrame:Show()
end

WidgetPoolMixin = CreateFromMixins(ObjectPoolMixin)

function WidgetPoolMixin:Acquire(...)
     local numInactiveObjects = #self.inactiveObjects;
     local createdNewObject = false
     local object
     if numInactiveObjects > 0 then
          object = self.inactiveObjects[numInactiveObjects];
          self.activeObjects[object] = true;
          self.numActiveObjects = self.numActiveObjects + 1;
          self.inactiveObjects[numInactiveObjects] = nil;
     else
          object = self.creationFunc(self);
          if self.resetterFunc then
               self.resetterFunc(self, object);
          end
          self.activeObjects[object] = true;
          self.numActiveObjects = self.numActiveObjects + 1;
          createdNewObject = true
     end

     if self.acquireFunc then
          self.acquireFunc(self, object, ...)
     end

     return object, createdNewObject;
end

function WidgetPoolMixin:OnLoad(creationFunc, acquireFunc, resetterFunc)
     self.creationFunc = creationFunc;
     self.resetterFunc = resetterFunc;
     self.acquireFunc = acquireFunc;

     self.activeObjects = {};
     self.inactiveObjects = {};

     self.numActiveObjects = 0;
end

function CreateWidgetPool(creationFunc, acquireFunc, resetterFunc)
     local objectPool = CreateFromMixins(WidgetPoolMixin);
     objectPool:OnLoad(creationFunc, acquireFunc, resetterFunc);
     return objectPool;
end