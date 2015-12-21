--pull constants for type of rolls
local LOOT_ROLL_TYPE_NEED = LOOT_ROLL_TYPE_NEED; -- Constants.lua:304-307
local LOOT_ROLL_TYPE_GREED = LOOT_ROLL_TYPE_GREED; -- Constants.lua:304-307
local LOOT_ROLL_TYPE_DISENCHANT = LOOT_ROLL_TYPE_DISENCHANT; -- Constants.lua:304-307
local LOOT_ROLL_TYPE_PASS = LOOT_ROLL_TYPE_PASS; -- Constants.lua:304-307

playerOBJ = {};
playerOBJ.__index = playerOBJ;
function playerOBJ:new (o, name)
    o=o  or {};
    setmetatable(o,self);
    self.__index = self
    self.need=0;
    self.greed=0;
    self.disenchant=0;
    self.pass=0;
    self.total=0;
    self.need_ratio=0.0;
    self.name = name;
    return o
end
function playerOBJ:update_NeedRatio()
    self.need_ratio = self.need / self.total
    self.need_ratio = NLA_round(self.need_ratio, -4) * 100
    return self.need_ratio
end
function playerOBJ:needed()
    self.need = self.need + 1;
    self.total = self.total + 1;
    return self:update_NeedRatio();
end
function playerOBJ:greeded()
    self.need = self.greed + 1;
    self.total = self.total + 1;
end
function playerOBJ:disenchanted()
    self.need = self.disenchant + 1;
    self.total = self.total + 1;
end
function playerOBJ:passed()
    self.need = self.need + 1;
    self.total = self.total + 1;
end

function NLA_round(num,precision)
    local exp = precision and 10^precision or 1
    return math.floor(num / exp + 0.5) * exp    
end

local player_roll_names = {};
local NLA_Players = {};

--Setup a lookup table for converting the number returned, to a text value
local LOOT_ROLL_TYPES = { -- array over roll type and frame that goes with it
	[LOOT_ROLL_TYPE_PASS] = "Pass",
	[LOOT_ROLL_TYPE_NEED] = "Need",
	[LOOT_ROLL_TYPE_GREED] = "Greed",
	[LOOT_ROLL_TYPE_DISENCHANT] = "Disenchant",
};


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
        
	--lookup table
	roll_type = LOOT_ROLL_TYPES[roll_type_number]
        
        if NLA_Players[player_name] == nil then
            NLA_Players[player_name] = playerOBJ:new(nil,player_name);
        else 
            temp = NLA_Players[player_name];
        end
        
        if roll_type == "Need" then
            print("Player " .. player_name .. " new need ratio: " .. temp:needed())
        elseif roll_type == "Greed" then
            temp:greeded()
        elseif roll_type == "Disenchant" then
            temp:disenchanted()
        elseif roll_type == "Passed" then
            temp:passed()
        end
        
        NLA_Players[player_name] = temp;
end

_NLA_frame:SetScript("OnEvent", function(self, event, ...)
    events[event](self, ...);
end);

--register for the loot events
for event, v in pairs(events) do 
    _NLA_frame:RegisterEvent(event);
end
