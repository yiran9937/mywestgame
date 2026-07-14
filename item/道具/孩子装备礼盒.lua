-- @Author              : GGELUA
-- @Last Modified by    : baidwwy
-- @Date                : 2025-06-17 15:00:21
-- @Last Modified time  : 2025-06-18 00:26:20
local 物品 = {
    名称 = '孩子装备礼盒',
    叠加 = 999,
    类别 = 10,
    类型 = 0,
    对象 = 1,
    条件 = 2,
    绑定 = false,
    装备类型 = nil, -- 新增默认值
    参数 = nil, -- 新增默认值
    装备名称 = nil, -- 新增默认值
}

function 物品:初始化(装备类型, 参数)
    -- self.装备类型 = 装备类型
    -- self.参数 = 参数 or 1
    if not self.参数 then
        self.参数 = 1
    end
    if not self.装备类型 then
        self.装备类型 = "帽子"
        self.装备名称 = 帽子[self.参数]
    end
end

local 帽子 = { "布帽", "方巾", "纶巾", "书生巾", "天师法冠" }
local 头簪 = { "银簪", "玉钗", "珍珠头钗", "凤钗", "织女花环" }

local 道袍 = { "粗布衣", "麻衣", "丝绸外衣", "书生服", "八卦道袍" }
local 裙子 = { "粗布裙", "麻裙", "轻纱小裙", "丝绸长裙", "织女彩裙" }

local 鞋子_男 = { "草鞋", "布鞋", "马靴", "书生履", "天师履" }
local 鞋子_女 = { "草鞋", "布鞋", "绣花鞋", "云靴", "织女彩鞋" }

local 古筝 = { "木筝", "宝螺筝", "楠木花卉筝", "红木山水画筝", "骨雕飞天筝" }
local 长剑 = { "木剑", "竹剑", "青铜剑", "越女剑", "龙泉剑" }
local 书籍 = { "庄子", "孟子", "论语", "道德经", "周易" }
local 扇子 = { "翎毛扇", "白羽扇", "鹅毛扇", "鹤羽扇", "麈尾扇" }



function 物品:使用(对象)
    --  local 几率 = math.random(100)
    -- local 装备名称 = ""
    -- if not self.参数 then
    --     self.参数 = 1
    -- end
    -- print("装备类型=", self.装备类型, "参数=", self.参数)
    if not self.装备类型 then
        self.装备名称 = "粗布衣"
    elseif self.装备类型 == "帽子" then
        self.装备名称 = 帽子[self.参数]
    elseif self.装备类型 == "头簪" then
        self.装备名称 = 头簪[self.参数]
    elseif self.装备类型 == "道袍" then
        self.装备名称 = 道袍[self.参数]
    elseif self.装备类型 == "裙子" then
        self.装备名称 = 裙子[self.参数]
    elseif self.装备类型 == "鞋子_男" then
        self.装备名称 = 鞋子_男[self.参数]
        -- print(鞋子_男[self.参数])
    elseif self.装备类型 == "鞋子_女" then
        self.装备名称 = 鞋子_女[self.参数]
    elseif self.装备类型 == "古筝" then
        self.装备名称 = 古筝[self.参数]
    elseif self.装备类型 == "长剑" then
        self.装备名称 = 长剑[self.参数]
    elseif self.装备类型 == "书籍" then
        self.装备名称 = 书籍[self.参数]
    elseif self.装备类型 == "扇子" then
        self.装备名称 = 扇子[self.参数]
    end
    -- print("装备名称=", 装备名称, ";")
    local r = 生成装备_孩子 { 名称 = 装备名称 }

    if r then
        if 对象:添加物品({ r }) then
            self.数量 = self.数量 - 1
            -- print("获取物品成功！")
        end
    end
end

function 物品:取描述()
    return "#Y恭喜获得" .. self.参数 .. "级孩子装备#R" .. self.装备名称 .. "#Y!"
end

return 物品
