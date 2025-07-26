local Selectors = {}
Selectors.__index = Selectors

-- Unified section handler: supports {open,close} modules or plain functions

-- Modules
local Ui = require(script.Parent.Parent.Parent.UiUtility)
local Tween = require(script.Parent.Tween)

function Selectors.new(buttonsFrame: Frame, selections, sections, buttonSelectedColor, buttonUnselectedColor)
	local self = setmetatable({}, Selectors)

	self.selections = selections
	self.currentSelection = selections[1]

	self.buttons = {}
	self.frames = {}

	-- Use provided colors or default to Ui constants
	self.buttonSelectedColor = buttonSelectedColor or Ui.BUTTON_SELECTED_COLOR
	self.buttonUnselectedColor = buttonUnselectedColor or Ui.BUTTON_UNSELECTED_COLOR

	for _, name in selections do
		self.buttons[name] = buttonsFrame:WaitForChild(name)
	end

	self.sections = sections -- can be {open,close} modules or functions

	self:connectInputs()

	return self
end

function Selectors:connectInputs()
	for _, button in self.buttons do
		button.MouseButton1Click:Connect(function()
			Ui.PlaySound("Click")
			self:switch(button.Name)
		end)
	end
end

function Selectors:switch(name)
	self.currentSelection = name

	for _, button in self.buttons do
		local isSelectedType = button.Name == self.currentSelection
		Tween.Color(button, isSelectedType and self.buttonSelectedColor or self.buttonUnselectedColor)

		local sectionName = button.Name
		local section = self.sections and self.sections[sectionName]

		if isSelectedType then
			if type(section) == "table" and section.Open then
				section.Open()
			elseif type(section) == "function" then
				section()
			elseif self.frames[sectionName] then
				self.frames[sectionName].Visible = true
				warn(`No module/function for "{sectionName}" section.`)
			end
		else
			if type(section) == "table" and section.Close then
				section.Close()
			elseif self.frames[sectionName] then
				self.frames[sectionName].Visible = false
				warn(`No module/function for "{sectionName}" section.`)
			end
		end
	end
end

return Selectors
