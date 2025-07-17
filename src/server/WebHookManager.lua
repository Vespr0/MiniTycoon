local HttpService = game:GetService("HttpService")

local WebHookManager = {}

-- Set your proxy endpoint here

local PROXY_URL = "https://webhook.lewisakura.moe/api/webhook"
local DISCORD_WEBHOOK_URL = "https://discord.com/api/webhooks/your_webhook_here" -- Set your Discord webhook here

-- Send a message to a Discord webhook via the proxy
-- @param webhookUrl (string): The Discord webhook URL
-- @param payload (table): The JSON payload to send (e.g., {content = "Hello World"})

-- Send a message to the Discord webhook via the proxy
-- @param payload (table): The JSON payload to send (e.g., {content = "Hello World"})
function WebHookManager.Send(payload)
    assert(type(payload) == "table", "payload must be a table")

    local data = {
        url = DISCORD_WEBHOOK_URL,
        body = payload
    }

    local success, response = pcall(function()
        return HttpService:PostAsync(
            PROXY_URL,
            HttpService:JSONEncode(data),
            Enum.HttpContentType.ApplicationJson
        )
    end)

    if not success then
        warn("[WebHookManager] Failed to send webhook:", response)
        return false, response
    end

    return true, response
end

return WebHookManager