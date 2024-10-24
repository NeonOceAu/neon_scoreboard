local Framework = nil

-- Detect the framework (ESX or QBCore)
if Config.Framework == 'ESX' then
    -- Use the new ESX shared object export
    Framework = exports['es_extended']:getSharedObject()

elseif Config.Framework == 'QB' then
    -- Initialize QBCore shared object
    Framework = exports['qb-core']:GetCoreObject()
end

lib.callback.register('neon_scoreboard:scoreboard', function(source)
    local TotalPlayers = 0
    local Players = {}
    local jobCounts = {}

    -- Initialize job counts for each job in the config
    for job, jobData in pairs(Config.OptionsTitles.jobs) do
        jobCounts[job] = 0
    end

    local players = nil
    if Config.Framework == 'ESX' then
        -- ESX-specific code to get players
        players = Framework.GetPlayers()
    elseif Config.Framework == 'QB' then
        -- QBCore-specific code to get players
        players = Framework.Functions.GetQBPlayers()
    end

    if not players then
        print("Error: Failed to retrieve players from the framework.")
        return nil
    end

    -- Iterate through players to calculate job counts
    for _, playerId in pairs(players) do
        local playerData = nil

        if Config.Framework == 'ESX' then
            -- Get ESX player data
            playerData = Framework.GetPlayerFromId(playerId)
        elseif Config.Framework == 'QB' then
            -- Get QBCore player data
            playerData = Framework.Functions.GetPlayer(playerId)
        end

        if playerData and playerData.job then
            -- Increment job counts based on the job name
            for job, jobData in pairs(Config.OptionsTitles.jobs) do
                if playerData.job.name == jobData.jobName then
                    jobCounts[job] = jobCounts[job] + 1
                end
            end
        end

        -- Increment the total player count
        TotalPlayers = TotalPlayers + 1
    end

    -- Set player counts for each job
    for job, jobData in pairs(Config.OptionsTitles.jobs) do
        Players[jobData.index] = jobCounts[job] or 0
    end
    Players[Config.OptionsTitles.totalPlayers.index] = TotalPlayers

    -- Robberies status
    local robberiesStatus = {}
    for _, robbery in pairs(Config.Robberies) do
        if jobCounts['police'] >= robbery.requiredCops then
            table.insert(robberiesStatus, { title = robbery.title, status = '✅' })
        else
            table.insert(robberiesStatus, { title = robbery.title, status = '❌' })
        end
    end

    -- Return the data for the scoreboard
    return { players = Players, robberies = robberiesStatus }
end)
