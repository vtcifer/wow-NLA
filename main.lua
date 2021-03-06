--pull constants for type of rolls
local LOOT_ROLL_TYPE_NEED = LOOT_ROLL_TYPE_NEED; -- Constants.lua:304-307
local LOOT_ROLL_TYPE_GREED = LOOT_ROLL_TYPE_GREED; -- Constants.lua:304-307
local LOOT_ROLL_TYPE_DISENCHANT = LOOT_ROLL_TYPE_DISENCHANT; -- Constants.lua:304-307
local LOOT_ROLL_TYPE_PASS = LOOT_ROLL_TYPE_PASS; -- Constants.lua:304-307

--Setup a lookup table for converting the number returned, to a text value
local LOOT_ROLL_TYPES = { -- array over roll type and frame that goes with it
	[LOOT_ROLL_TYPE_PASS] = "Pass",
	[LOOT_ROLL_TYPE_NEED] = "Need",
	[LOOT_ROLL_TYPE_GREED] = "Greed",
	[LOOT_ROLL_TYPE_DISENCHANT] = "Disenchant",
};

player_roll_names = {};
NLA_Players = {};

local _NLA_frame = CreateFrame("Frame")
local events = {}

function events:LOOT_HISTORY_ROLL_CHANGED(...)
    --code for handling what happens when loot roll history changed fires
	--Two variables passed by the event:
		--item_idx:
			--first var passed
			--index (int) in the loot history window (top->down 1->...
		--player_idx:
			--second var passed
			--integer representing the player that the event occurs for	
    local item_idx, player_idx = ...;

    --setup own local variables
    local roll_id, item_link, max_rolls, is_Master; 
    local player_name, roll_type_number, roll_type, roll_number, is_me
    --These variables aren't used right now
    local rolls_finished, winner_id, player_class, is_winner;
    
    --get item link and if master looter.
    roll_id, item_link, max_rolls, rolls_finished, winner_id, is_Master  = C_LootHistory.GetItem(item_idx);
    --rollID_num, itemLink_str, numPlayers_num, isDone_bool, winnerIdx_num, isMasterLoot_bool

    --if master loot, don't track, as master looter should hopefully be paying attention
    if is_Master == true then return end

    --get roll details
    player_name, player_class, roll_type_number, roll_number, is_winner, is_me = C_LootHistory.GetPlayerInfo(item_idx, player_idx)
    --name_str, class_str, rollType_num, roll_num, isWinner_bool, isMe_bool

    --don't track details on yourself
    if (is_me == true) then 
        return 
    end

    --check if you've already got a roll for player
    if (player_roll_names[roll_id] == nil) then
--[[
        if NLA_Config.Debug == true then
            print("First roll for Item: ".. item_link .. ". Creating entry in  player roll names.")
        end
--]]
        player_roll_names[roll_id] = player_name
    elseif (string.find(player_roll_names[roll_id],player_name,1,true) == nil) then
--[[
        if NLA_Config.Debug == true then
            print("Adding roll entry in player_roll_names for " .. item_link ..".")
        end
--]]
        player_roll_names[roll_id] = player_roll_names[roll_id] .. player_name
    else
        return
    end
    
    --lookup table
    roll_type = LOOT_ROLL_TYPES[roll_type_number]    
    
--[[
    if NLA_Config.Debug == true then
        print("Player " .. player_name .. " rolled " .. roll_type .. " on " .. item_link .. ".")        
    end
--]]

    if NLA_Players[player_name] == nil then
        NLA_Players[player_name] = playerOBJ:new();
        NLA_Players[player_name]:setname(player_name);
--[[
        if NLA_Config.Debug == true then
            print("Initial roll for player " .. NLA_Players[player_name].name .. ". Created, entry in NLA_Players.")
        end
--]]
    end

--[[
    if NLA_Config.Debug == true then
        print("Before update of NLA_Players table.  Name is:" .. NLA_Players[player_name].name .. ".")
    end
--]]
    if roll_type_number == LOOT_ROLL_TYPE_NEED then
        NLA_Players[player_name]:needed();
        NLA_CheckAlert(NLA_Players[player_name]);
    elseif roll_type_number == LOOT_ROLL_TYPE_GREED then
        NLA_Players[player_name]:greeded()
    elseif roll_type_number == LOOT_ROLL_TYPE_DISENCHANT then
        NLA_Players[player_name]:disenchanted()
    elseif roll_type_number == LOOT_ROLL_TYPE_PASS then
        NLA_Players[player_name]:passed()
    else
        if NLA_Config.Debug == true then
            print("Missed loot roll type?! " .. roll_type_number)
        end
    end
    
--[[
    if NLA_Config.Debug == true then
        print("After update of NLA_Players table.  Name is:" ..NLA_Players[player_name].name .. ".")
    end
--]]

--[[
    if NLA_Config.Debug == true then
        print("Player " .. NLA_Players[player_name].name .. " details: " .. NLA_Players[player_name].need .. "/" .. NLA_Players[player_name].total .." = " .. NLA_Players[player_name].need_ratio .. ".")        
    end
--]]

end
function events:ADDON_LOADED(...)
    local addon_name = ...;
    
    --don't care if event fires for another addon
    if addon_name ~= "NLA" then
        return
    end
    
    --likely first time addon is firing.  Set Defaults.
    if NLA_Config == nil then
        print("No NLA settings, loading from default.")
        NLA_Config = NLA_Config_Default;
        return
    --versioning of defaults (allows for new defaults)
    elseif NLA_Config.Version == nil or NLA_Config.Version < NLA_Config_Default.Version then
        for index,value in ipairs(NLA_Config_Default) do
            if NLA_Config[index] == nil then
                NLA_Config[index] = value
            end
        end
        NLA_Config.Version = NLA_Config_Default.Version
    end
end
function events:PLAYER_LOGOUT(...)
    --Reset debug to false (debug should be temporary)
    NLA_Config["Debug"] = false;
end

--Call event handers, when registered events fire
_NLA_frame:SetScript("OnEvent", function(self, event, ...)
    events[event](self, ...);
end);

--register for the loot events
for event, v in pairs(events) do 
    _NLA_frame:RegisterEvent(event);
end

SLASH_NLA1 = '/nla';
function SlashCmdList.NLA(msg, editbox)
    if msg == "reset" then
        print("NLA: Resetting loot tracking.");
        NLA_reset();
    elseif msg == "debug" then
        NLA_Config["Debug"] = not NLA_Config["Debug"]
        print("NLA: Debug mode toggled.  New Value: " .. tostring(NLA_Config["Debug"]))
    elseif msg == "debugon" then
        NLA_Config["Debug"] = false;
        print("NLA: Debug mode off.");
    elseif msg == "debugoff" then
        NLA_Config["Debug"] = true;
        print("NLA: Debug mode on.");
    end
end
