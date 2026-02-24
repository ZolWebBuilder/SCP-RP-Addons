-- Ts so Coded Core

local mapping_array = {
    {["Trial Moderator"] = "TMod", ["default"] = "Staff Member"},
    {["Moderator"] = "Mod", ["default"] = "Staff Member"},
    {["Senior Moderator"] = "SMod", ["default"] = "Staff Administrator"},
    {["Head Moderator"] = "HMod", ["default"] = "Super Administrator"}
}

---------------------------------------------------
-- VARIABLES
---------------------------------------------------

local awaiting = false
local awaiting_table = {}

-- cache username -> api rank
local awaited_2 = {}

-- prevents duplicate commands
local granted = {}

-- the api itself
-- you'll need to make one yourself
-- get the source code at (placeholder)
local staff_api = "https://api-zol.vercel.app/api/staff/return"

---------------------------------------------------
-- FUNCTIONS
---------------------------------------------------

function log(str)
    -- just for logging
    -- [CORE LOGGER] example
    print("[CORE LOGGER] "..str)
end

function check(...)
    -- http request to the api
    -- json decode it to be usable
    local data =
        jsonDecode(
        http(
            staff_api, -- staff api
            "post", -- method
            {["Content-Type"] = "application/json"}, -- headers
            jsonEncode( -- body encoding to be the correct api body
                {
                    users = {...} --treats this as "users":["...","..."]
                }
            )
        ).Body -- body of api, [{"user":"example","is":"Moderator"}{...},...]
    )
    -- return the json decoded data
    -- log("Check API valid")
    return data
end

function getMapping(apiRank)
    -- if nil were sent here, it means the user has no rank
    if not apiRank then
        -- send back nil, this user will not be modded
        -- log("Nil = normal, falling back")
        return nil
    end

    for _, map in ipairs(mapping_array) do
        -- scanner to detect rank
        -- if the api rank is in the mapping array, return their rank
        if map[apiRank] then
            -- returns the map value
            -- log("Successfully scanned")
            return map
        end
    end

    -- by default, return nil
    -- log("Returned nil as a safety measure")
    return nil
end

function await_plrs()
    -- already waiting?
    if awaiting then
        -- log("Batch awaiting already initialized, falling back")
        -- already waiting
        return
    end

    -- awaiting started
    -- set awaiting to true to prevent batch re-init
    awaiting = true
    log("Detected a player, initializing")

    task.spawn(
        function()
            -- wait after first player joins
            -- log("Started new batch")
            task.wait(5)

            -- if no one is waiting... why are we calling func
            -- safety check to not clog api
            if #awaiting_table == 0 then
                -- reset variable
                awaiting = false
                -- pause the entire thing
                -- log("As a safety, the code has been stopped since there's no users awaiting")
                return
            end

            ------------------------------------------------
            -- api contact
            -- contact to the api we had
            -- yes the api is required
            ------------------------------------------------

            -- contact api
            -- log("API contacted")
            local awaited = check(table.unpack(awaiting_table))

            ------------------------------------------------
            -- processing results from the api
            -- we use for loop to go through everyone
            -- cache the result and scan player's ranks
            -- if player has no rank, fallback
            -- if they do have one, continue
            ------------------------------------------------

            for _, v in ipairs(awaited) do
                -- break down users for each check
                -- take both response
                local username = v.user -- user from api
                local apiRank = v.is -- rank from api || nil = no rank

                -- cache result
                -- not much to see
                awaited_2[username] = apiRank

                -- gate 1, normal player filter
                -- if nil, skip as normal players
                if not apiRank then
                    -- normal players
                    log(username .. " isn't any rank/normal players")
                    continue
                end

                -- if they do have rank, get the mapping
                -- log("Grabbing map")
                local map = getMapping(apiRank)

                -- if not map then log("Somehow it failed") countinue end
                if not map then
                    continue
                end

                -- prevent duplicate command spam
                -- will not fire the command again
                if granted[username] then
                    continue
                end

                -- mark as granted, they won't be given perks another time
                -- log(username .. " is added to granted user")
                granted[username] = true

                --------------------------------------------
                -- mod granting
                -- we run the command to give proper ranks
                --------------------------------------------

                -- get their respective mod rank
                local modRank = map[apiRank]
                -- log(modRank .. " is " .. username .. "'s rank")

                if modRank then
                    -- the true logic granting the mod
                    runCommand(":mod " .. username .. " " .. modRank)
                    -- log it
                    log("Granted " .. username .. "'s mod as \"" .. modRank .. "\"")
                end

                --------------------------------------------
                -- team command
                -- only if default exists
                -- if it doesn't, fallback
                --------------------------------------------

                -- attempt to get their team
                -- nil = no default team
                local defaultTeam = map["default"]

                if defaultTeam ~= nil then
                    -- if there is one
                    -- set their team
                    runCommand(":team " .. username .. " " .. defaultTeam)
                    -- log it
                    log("Set " .. username .. "'s team to \"" .. defaultTeam .. "\"")
                end
            end

            ------------------------------------------------
            -- final clearing
            -- we clear the table data, then change awaiting to false
            -- not a lot here
            ------------------------------------------------

            -- table clearing for the next batch
            table.clear(awaiting_table)
            -- log("Batch table cleared")

            -- awaiting next batch
            awaiting = false
            -- log("awaiting is set to false")
        end
    )
end

---------------------------------------------------
-- EVENT LISTENER
---------------------------------------------------

--[[
Testing fire
table.insert(awaiting_table, "AlternativelyZolars")
table.insert(awaiting_table, "JonathanOOMF")
table.insert(awaiting_table, "FinallyDefined")
table.insert(awaiting_table, "ARandomTMod")
await_plrs()
]]--

event( -- listener
    "joined", -- event type, joined specifically
    function(data) -- execute the code on join
        local username = data.Value -- username obviously

        -- already cached?
        if awaited_2[username] then
            -- log(username .. " already cached")
            -- already cached
            return
        end

        -- avoid duplicate queue entries
        if not table.find(awaiting_table, username) then
            table.insert(awaiting_table, username)
            log("Added " .. username)
        end

        await_plrs()
    end
)
