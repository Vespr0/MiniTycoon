local Selectors = {}
Selectors.__index = Selectors

-- Modules
local Ui = require(script.Parent.Parent.Parent.UiUtility)
local Tween = require(script.Parent.Tween)

function Selectors.new(mainFrame: Frame,selections,sectionModules)
	local self = setmetatable({}, Selectors)
	
	self.MainFrame = mainFrame
	self.origin = mainFrame.Position
	self.selections = selections
	self.currentSelection = selections[1]
	
	self.buttonsFrame = mainFrame:WaitForChild("SectionSelectors")
	self.buttons = {}
	self.frames = {}
	
	for _,name in selections do
		self.buttons[name] = self.buttonsFrame:WaitForChild(name)
		self.frames[name] = mainFrame:WaitForChild(name.."Frame")
	end
	
	self.modules = sectionModules
	
	self:connectInputs()
	
	return self
end

function Selectors:connectInputs()
	for _,button in self.buttons do
		button.MouseButton1Click:Connect(function()
			Ui.PlaySound("Click")
			self:switch(button.Name)
		end)
	end
end

function Selectors:switch(name)
	self.currentSelection = name
	
	for _,button in self.buttons do
		local isSelectedType = button.Name == self.currentSelection
		Tween.Color(button,isSelectedType and Ui.BUTTON_SELECTED_COLOR or Ui.BUTTON_UNSELECTED_COLOR)

		local name = button.Name
		
		if isSelectedType then
			if self.modules[name] then
				self.modules[name].Open()
			else
				self.frames[name].Visible = true
				warn(`No module for "{name}" section.`)
			end
		else
			print(name,false)
			if self.modules[name] then
				self.modules[name].Close() -- TODO: this gets fired even when the module is already closed and may cause unintuitive behaivor.
			else
				self.frames[name].Visible = false
				warn(`No module for "{name}" section.`)
			end
		end
	end
end

return Selectors
