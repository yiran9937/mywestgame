local _地图 = { 1213 }
local _模型 = { 2044, 2045 }
local 任务 = {
    名称 = '打海盗',
    类型 = '新手任务'
}

function 任务:任务初始化()
end

function 任务:任务取详情(玩家)
    if self.NPC then
        -- #G#u#[%s|%s|%s|$%s#]#u
        return string.format('#Y任务目的:#r#W去#Y%s#W击退#G#u#[%s|%s|%s|$%s#]#u#W(剩余%d分钟)', self.位置,
            self.MAP, self.x, self.y,
            self.怪名,
            (self.时间 - os.time()) // 60)
    end
    return string.format('由于行动迟缓，#Y%s#W已经逃之夭夭了。\n', self.怪名)
end

function 任务:任务取消(玩家)
    local map = 玩家:取地图(self.MAP)
    if map then
        local NPC = map:取NPC(self.NPC)
        if NPC then
            NPC.人数 = NPC.人数 - 1
            if NPC.人数 <= 0 then
                map:删除NPC(self.NPC)
                self:删除()
            end
        end
    end
end

function 任务:任务上线(玩家)
    local map = 玩家:取地图(self.MAP)
    if map then
        local NPC = map:取NPC(self.NPC)
        if not NPC then
            self:删除()
        end
    end
end

function 任务:任务下线(玩家)
    local map = 玩家:取地图(self.MAP)
    if map then
        local NPC = map:取NPC(self.NPC)
        if NPC then
            map:删除NPC(self.NPC)
        end
    end
end

function 任务:任务更新(sec, 玩家)
    if sec > self.时间 then
        local map = 玩家:取地图(self.MAP)
        if map then
            local NPC = map:取NPC(self.NPC)
            if NPC then
                map:删除NPC(self.NPC)
            end
            self:删除()
        end
    end
end

function 任务:生成怪物(玩家)
    local map = 玩家:取随机地图(_地图)
    if not map then
        return
    end
    self.怪名 = _随机名称(3)
    local X, Y = map:取随机坐标() --真坐标
    if not X then
        return
    end
    self.位置 = string.format('%s(%d,%d)', map.名称, X, Y)
    self.队伍 = {}
    for k, v in 玩家:遍历队伍() do
        table.insert(self.队伍, v.nid)
        v:添加任务(self)
    end
    self.时间 = os.time() + 600
    self.NPC =
        map:添加NPC {
            队伍 = self.队伍,
            人数 = #self.队伍,
            名称 = self.怪名,
            外形 = _模型[math.random(#_模型)],
            脚本 = 'scripts/task/新手任务/打海盗.lua',
            时间 = self.时间,
            任务类型 = "打海盗",
            X = X,
            Y = Y,
            来源 = self
        }

    self.MAP = map.id
    self.x = X
    self.y = Y
    return true
end

function 任务:完成(玩家)
    local r = 玩家:取任务('打海盗')
    if r.NPC == self.NPC then
        if 玩家:判断等级是否低于(30, 0) then
            self:掉落包(玩家)
        end
        self:删除()
    end
end

local _掉落 = {
    { 几率 = 70, 名称 = '金针', 数量 = 1 },
    { 几率 = 70, 名称 = '八角莲叶', 数量 = 1 },

}
function 任务:掉落包(玩家)
    local 银子 = 120
    local 经验 = 玩家.等级 * 723
    玩家:添加师贡(银子)
    玩家:添加任务经验(经验, "打海盗")
    for i, v in ipairs(_掉落) do
        if math.random(100) <= v.几率 then
            local r = 生成物品 { 名称 = v.名称, 数量 = v.数量, 参数 = v.参数 }
            if r then
                玩家:添加物品({ r })
                if v.广播 then
                    玩家:发送系统(v.广播, 玩家.名称, r.nid, r.名称)
                end
                break
            end
        end
    end
end

--=========================NPC======================================
local 对话 = [[最近发现珊瑚海岛上有海盗出没，你还尽快回村吧#22。]]

function 任务:NPC对话(玩家, NPC)
    local r = 玩家:取任务('打海盗')
    if NPC.任务类型 == "打海盗" and r then
        if r.NPC == NPC.nid then
            local s = 玩家:进入战斗('scripts/task/新手任务/打海盗.lua', self)
            if s then
                玩家:最后对话(对话, self.外形)
                self:删除()
            end
            return s and 对话
        else
            return '我认识你么？#24'
        end
    end
end

function 任务:NPC菜单(玩家, i)
end

local _怪物 = {
    { 名称 = "海盗", 外形 = 2044, 气血 = 465, 魔法 = 1, 攻击 = 59, 速度 = 1 },
    { 名称 = "海盗", 外形 = 2045, 气血 = 465, 魔法 = 1, 攻击 = 59, 速度 = 1 }
}
--=========================战斗======================================
function 任务:战斗初始化(玩家, NPC)
    self.NPC_nid = NPC.nid
    for i = 1, 1 do
        local r = 生成战斗怪物(_怪物[math.random(#_怪物)])
        self:加入敌方(i, r)
    end
end

function 任务:战斗回合开始(dt)

end

function 任务:战斗结束(s)
    if s then
        for k, v in self:遍历我方() do
            if v.是否玩家 then
                local r = v.对象.接口:取任务("打海盗")
                if r and r.NPC == self.NPC_nid then
                    r:完成(v.对象.接口)
                end
            end
        end
    end
end

return 任务
