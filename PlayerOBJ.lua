playerOBJ = {};
playerOBJ.__index = playerOBJ;

function playerOBJ:new(o)
    o=o  or {};
    setmetatable(o,self);
    self.__index = self;
    self.need=0;
    self.greed=0;
    self.disenchant=0;
    self.pass=0;
    self.total=0;
    self.need_ratio=0.0;
    self.name = "";
    return o;
end

function playerOBJ:setname(newname)
    self.name=newname
end
function playerOBJ:update_NeedRatio()
    self.need_ratio =  NLA_round(self.need / self.total, -4) * 100;
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