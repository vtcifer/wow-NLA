function NLA_round(num,precision)
    local exp = precision and 10^precision or 1;
    return math.floor(num / exp + 0.5) * exp;
end

function NLA_CheckAlert(player)
    if player.need_ratio > NLA_Config.MaxNeedRatio then
        if NLA_Config.Debug == true then
            print("Passed ratio check for " .. player.name ..".")
        end
        if ( not(NLA_Config.MinTotal_Enabled) or (player.total >= NLA_Config.MinTotal) )then
            if NLA_Config.Debug == true then
                print("Passed min total check for " .. player.name ..".")
            end
            if ( not(NLA_Config.MinNeed_Enabled) or (player.need >= NLA_Config.MinNeed) ) then
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
    print(player.name .. " is over max need ratio of (" .. NLA_Config.MaxNeedRatio ..") -> " .. player.need .. "/" .. player.total .."=" .. player.need_ratio .. ".")
end

function NLA_reset()
    player_roll_names = {};
    NLA_Players = {};
end