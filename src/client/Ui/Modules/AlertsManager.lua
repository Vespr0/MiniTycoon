local AlertsManager = {}

local AlertComponent = require(script.Parent.Components.AlertComponent)

-- Private storage for all alerts
local alerts = {}
local alertParents = {} -- Track parent elements for each alert

function AlertsManager.RegisterAlert(alertId, parentElement)
 	-- Register an alert with its parent element
	if not alertId or not parentElement then
		warn("AlertsManager: Missing required parameters for RegisterAlert")
		return
	end

	alertParents[alertId] = parentElement
end

function AlertsManager.UnregisterAlert(alertId)
 	-- Remove an alert registration and clean up
	if alerts[alertId] then
		alerts[alertId]:destroy()
		alerts[alertId] = nil
	end

	alertParents[alertId] = nil
end

function AlertsManager.SwitchAlert(alertId, isVisible)
	-- Switch an alert on or off
	local parentElement = alertParents[alertId]
	if not parentElement then
		warn("AlertsManager: Alert not registered:", alertId)
		return
	end

	if isVisible then
		-- Create alert if it doesn't exist
		if not alerts[alertId] then
			alerts[alertId] = AlertComponent.new()
			alerts[alertId]:setup()
		end
		-- Show the alert
		alerts[alertId]:show(parentElement)
	elseif alerts[alertId] then
		-- Hide the alert
		alerts[alertId]:hide()
	end
end

-- function AlertsManager.IsAlertVisible(alertId)
-- 	-- Check if a specific alert is visible
-- 	local alert = alerts[alertId]
-- 	return alert and alert.isVisible or false
-- end

return AlertsManager
