--pull constants for type of rolls
local LOOT_ROLL_TYPE_NEED = LOOT_ROLL_TYPE_NEED; -- Constants.lua:304-307
local LOOT_ROLL_TYPE_GREED = LOOT_ROLL_TYPE_GREED; -- Constants.lua:304-307
local LOOT_ROLL_TYPE_DISENCHANT = LOOT_ROLL_TYPE_DISENCHANT; -- Constants.lua:304-307
local LOOT_ROLL_TYPE_PASS = LOOT_ROLL_TYPE_PASS; -- Constants.lua:304-307

player_roll_names = {};
NLA_Players = {};

playerOBJ = {};
playerOBJ.__index = playerOBJ;
function playerOBJ:new (o, name)
    o=o  or {};
    setmetatable(o,self);
    self.__index = self;
    self.need=0;
    self.greed=0;
    self.disenchant=0;
    self.pass=0;
    self.total=0;
    self.need_ratio=0.0;
    self.name = name;
    return o;
end
function playerOBJ:update_NeedRatio()
    self.need_ratio = self.need / self.total;
    self.need_ratio = NLA_round(self.need_ratio, -4) * 100;
end
function playerOBJ:needed()
    self.need = self.need + 1;
    self.total = self.total + 1;
    self:update_NeedRatio();
end
function playerOBJ:greeded()
    self.greed = self.greed + 1;
    self.total = self.total + 1;
    if NLA_Config.Debug == true then
        self:update_NeedRatio()
    end
end
function playerOBJ:disenchanted()
    self.disenchant = self.disenchant + 1;
    self.total = self.total + 1;
    if NLA_Config.Debug == true then
        self:update_NeedRatio()
    end
end
function playerOBJ:passed()
    self.pass = self.pass + 1;
    self.total = self.total + 1;
    if NLA_Config.Debug == true then
        self:update_NeedRatio()
    end
end

function NLA_round(num,precision)
    local exp = precision and 10^precision or 1;
    return math.floor(num / exp + 0.5) * exp;
end
function NLA_CheckAlert(player)
    if player.need_ratio > NLA_Config.MaxNeedRatio then
        if NLA_Config.Debug == true then
            print("Passed ratio check for " .. player.name ..".")
        end
        if (not(NLA_Config.MinTotal_Enabled) or (player.total >= NLA_Config.MinTotal))then
            if NLA_Config.Debug == true then
                print("Passed min total check for " .. player.name ..".")
            end
            if (not(NLA_Config.MinNeed_Enabled) or (player.need >= NLA_Config.MinNeed) ) then
                if NLA_Config.Debug == true then
                    print("Passed min need check for " .. player.name ..".")
                end
                NLA_Alert(player);
            end    
        end
    end
end
function NLA_Alert(player)
    --only implementing print for now....
    print(player.name .. " is over max need ratio of (" .. NLA_Conifg.MaxNeedRatio ..") -> " .. player.need .. "/" .. player.total .."=" .. player.need_ratio .. ".")
end
function NLA_reset()
    player_roll_names = {};
    NLA_Players = {};
end

--[[

--Setup a lookup table for converting the number returned, to a text value
local LOOT_ROLL_TYPES = { -- array over roll type and frame that goes with it
	[LOOT_ROLL_TYPE_PASS] = "Pass",
	[LOOT_ROLL_TYPE_NEED] = "Need",
	[LOOT_ROLL_TYPE_GREED] = "Greed",
	[LOOT_ROLL_TYPE_DISENCHANT] = "Disenchant",
};

--]]

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
    local temp;

    --setup own local variables
    local roll_id, item_link, max_rolls, is_Master; 
    local player_name, roll_type_number, roll_type, roll_number, is_me;
    local _
    --get item link and if master looter.
    roll_id, item_link, max_rolls, _, _, is_Master  = C_LootHistory.GetItem(item_idx);
    --rollID_num, itemLink_str, numPlayers_num, isDone_bool, winnerIdx_num, isMasterLoot_bool


    --if master loot, don't track, as master looter should hopefully be paying attention
    if is_Master == true then return end

    --get roll details
    player_name, _, roll_type_number, roll_number, _, is_me = C_LootHistory.GetPlayerInfo(item_idx, player_idx)
    --name_str, class_str, rollType_num, roll_num, isWinner_bool, isMe_bool

    --don't track details on yourself
    if (is_me == true) then 
        return 
    end

    --check if you've already got a roll for player
    if (player_roll_names[roll_id] == nil) then
        player_roll_names[roll_id] = player_name
    elseif (string.find(player_roll_names[roll_id],player_name,1,true) == nil) then
        player_roll_names[roll_id] = player_roll_names[roll_id] .. player_name
    else
        return
    end
--[[
    --lookup table
    roll_type = LOOT_ROLL_TYPES[roll_type_number]
--]]

    --
    if NLA_Players[player_name] == nil then
        NLA_Players[player_name] = playerOBJ:new(nil,player_name);
    end
    temp = NLA_Players[player_name];
    if roll_type_number == LOOT_ROLL_TYPE_NEED then
        temp:needed();
        --NLA_CheckAlert(temp);
    elseif roll_type_number == LOOT_ROLL_TYPE_GREED then
        temp:greeded()
    elseif roll_type_number == LOOT_ROLL_TYPE_DISENCHANT then
        temp:disenchanted()
    elseif roll_type_number == LOOT_ROLL_TYPE_PASS then
        temp:passed()
    else
        if NLA_Config.Debug == true then
            print("Missed loot roll type?! " .. roll_type_number)
        end
    end
    NLA_Players[player_name] = temp;
    
    if NLA_Config.Debug == true then
        print("Player " .. temp.name .. " details: " .. temp.need .. "/" .. temp.total .." = " .. temp.need_ratio .. ".")        
    end

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
    end
    
    --versioning of defaults (allows for new defaults)
    if NLA_Config.Version == nil or NLA_Config.Version < NLA_Config_Default.Version then
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
        print("NLA: Debug mode on.");
        NLA_Config["Debug"] = true;
    elseif msg == "nodebug" then
        print("NLA: Debug mod off.");
        NLA_Config["Debug"] = false;
    end
end
