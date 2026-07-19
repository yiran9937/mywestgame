local 法术 = {
    类别 = '门派',
    类型 = 1,
    对象 = 2,
    条件 = 37,
    名称 = '吸星大法',
    id = 1905,
}

function 法术:法术施放(攻击方, 目标)
    local 消耗mp = self:法术取消耗().消耗MP
    if 攻击方:取魔法() < 消耗mp then
        攻击方:提示("#R魔法不足，无法释放！")
        return false
    end
    self.xh = 消耗mp
    self.吸血值 = {}
    for i, v in ipairs(目标) do
        攻击方.伤害 = self:法术取伤害(攻击方, v)
        v:被法术攻击(攻击方, self)
        self.吸血值[i] = 攻击方.伤害
    end
    if 攻击方.是否玩家 then
        self.熟练度 = self.熟练度 < self.熟练度上限 and self.熟练度 + 1 or self.熟练度上限
    end
end

function 法术:法术施放后(攻击方, 目标)
    if self.xh then
        攻击方:减少魔法(self.xh)
        self.xh = false
    end

    -- ========================================================
    -- 1. 计算总回血池
    -- ========================================================
    local 总回血池 = 0
    if self.吸血值 then
        local 加强程度 = 攻击方.加强三尸虫回血程度 or 0
        for _, 伤害 in ipairs(self.吸血值) do
            if 伤害 and 伤害 > 0 then
                local 转换回血 = math.floor(伤害 * 2 * (1 + 加强程度 * 0.01))
                总回血池 = 总回血池 + 转换回血
            end
        end
    end

    if 总回血池 <= 0 then
        self.吸血值 = {}
        return
    end

    local 原始总血池 = 总回血池
    local 单次回复限额 = math.max(1, math.floor(原始总血池 * 0.3))

    -- ========================================================
    -- 2. 搜集并标准化数据 + 位置标识与进入时气血+百分比打印
    -- ========================================================
    local list = {}
    local player_idx = 0 
    local pet_idx = 5    
    local debug_enter_str = "进入回血方法时气血 -> "

    for _, v in 攻击方:遍历我方() do
        if not v:取BUFF('封印') then
            local 当前气血 = tonumber(v.气血) or (v.取气血 and v:取气血()) or (v.get_hp and v:get_hp()) or 0
            local 最大气血 = tonumber(v.最大气血) or (v.取最大气血 and v:取最大气血()) or (v.get_max_hp and v:get_max_hp()) or 1
            
            local 是否死亡 = false
            if v.是否死亡 == true or (v.is_dead and v:is_dead()) or 当前气血 <= 0 then
                是否死亡 = true
            end

            local 位置标识 = 0
            if v.是否玩家 then
                位置标识 = player_idx
                player_idx = math.min(4, player_idx + 1) 
            else
                位置标识 = pet_idx
                pet_idx = math.min(9, pet_idx + 1)
            end

            local 血量百分比 = math.floor((当前气血 / 最大气血) * 100)
            debug_enter_str = debug_enter_str .. 位置标识 .. ":" .. 当前气血 .. "(" .. 血量百分比 .. "%), "

            if not 是否死亡 or (是否死亡 and v.是否玩家) then
                table.insert(list, {
                    raw = v, 
                    位置标识 = 位置标识, 
                    是否死亡 = 是否死亡,
                    是否玩家 = v.是否玩家,
                    气血 = 当前气血,
                    最大气血 = 最大气血,
                    损失比 = 1 - (当前气血 / 最大气血)
                })
            end
        end
    end
    print(string.sub(debug_enter_str, 1, -3))

    -- ========================================================
    -- 3. 严格的多条件分级排序
    -- ========================================================
    table.sort(list, function(a, b)
        if a.是否死亡 ~= b.是否死亡 then return a.是否死亡 end
        if a.是否死亡 and b.是否死亡 then
            -- 💡 修复此处变量名笔误 a.max_health -> a.最大气血
            if a.最大气血 ~= b.最大气血 then return a.最大气血 < b.最大气血 end
            return false
        end
        local a_残血 = a.气血 < a.最大气血
        local b_残血 = b.气血 < b.最大气血 
        if a_残血 ~= b_残血 then return a_残血 end
        if a_残血 and b_残血 then
            if math.abs(a.损失比 - b.损失比) > 0.0001 then
                return a.损失比 > b.损失比
            end
        end
        return a.最大气血 < b.最大气血
    end)

    -- ========================================================
    -- 4. 模拟分发（限制5人）
    -- ========================================================
    local 最大回血人数 = 5 
    while #list > 最大回血人数 do
        table.remove(list)
    end

    local heal_map = {}
    local 安全计数器 = 0

    while 总回血池 > 0 and 安全计数器 < 200 do
        安全计数器 = 安全计数器 + 1
        local 本轮有任何加血行为 = false

        for _, info in ipairs(list) do
            if 总回血池 <= 0 then break end

            local v = info.raw
            local 已记账血量 = heal_map[v] or 0
            local 虚拟当前气血 = info.气血 + 已记账血量
            local 需要血量 = info.最大气血 - 虚拟当前气血
            
            if info.是否死亡 then
                -- 💡 修复此处变量名写错的致命隐患：need_hp -> 需要血量
                需要血量 = info.最大气血 - 已记账血量
            end

            if 需要血量 > 0 or (info.是否死亡 and 已记账血量 == 0) then
                -- 💡 修复此处 math.min 内传入的变量名：need_hp -> 需要血量
                local 实际想加 = math.min(需要血量, 单次回复限额)
                local 实际加血 = math.min(总回血池, 实际想加)
                
                if 实际加血 <= 0 and info.是否死亡 and 已记账血量 == 0 then 
                    实际加血 = 1 
                end 

                if 实际加血 > 0 then
                    heal_map[v] = (heal_map[v] or 0) + 实际加血
                    总回血池 = 总回血池 - 实际加血
                    本轮有任何加血行为 = true
                end
            end
        end

        if not 本轮有任何加血行为 then
            if 总回血池 > 0 and list[1] then
                local top_v = list[1].raw
                heal_map[top_v] = (heal_map[top_v] or 0) + 总回血池
                总回血池 = 0
            end
            break
        end
    end

    -- ========================================================
    -- 5. 合并结算 + 包含总回血池的加血结果打印
    -- ========================================================
    local debug_result_str = "计算完成后加血量(总回血池:" .. 原始总血池 .. ") -> "
    
    player_idx = 0
    pet_idx = 5
    for _, v in 攻击方:遍历我方() do
        if not v:取BUFF('封印') then
            local 位置标识 = v.是否玩家 and player_idx or pet_idx
            if v.是否玩家 then player_idx = math.min(4, player_idx + 1) else pet_idx = math.min(9, pet_idx + 1) end
            
            local 增加值 = heal_map[v] or 0
            debug_result_str = debug_result_str .. 位置标识 .. ":" .. 增加值 .. ", "
            
            if 增加值 > 0 then
                v:增加气血(增加值)
            end
        end
    end
    print(string.sub(debug_result_str, 1, -3))

    self.吸血值 = {}
end

function 法术:法术取伤害(攻击方, 挨打方)
    local 伤害 = 0
    local 等级 = 攻击方.等级 + 1
    伤害 = 69.65 * 等级 + 攻击方.加强三尸虫
    伤害 = 强克伤害加成(攻击方, 挨打方, 伤害)
    伤害 = 取鬼法伤害(攻击方, 挨打方, 伤害)
    if math.random(100) < 攻击方.三尸虫狂暴几率 then
        伤害 = 伤害 * (1.5 + 攻击方.三尸虫狂暴程度 * 0.01)
        挨打方.伤害类型 = "狂暴"
    end
    伤害 = 伤害 - 挨打方.抗三尸虫
    if 伤害 <= 0 then
        伤害 = 1
    end
    return math.floor(伤害)
end

function 法术:取目标数()
    if self.熟练度 >= 6800 then
        return 5
    elseif self.熟练度 >= 5200 then
        return 4
    else
        return 3
    end
end

function 法术:法术取目标数()
    return self:取目标数(), function(a, b)
        return a.速度 > b.速度
    end
end

function 法术:法术取消耗()
    return { 消耗MP = math.floor(self.熟练度 * 0.707) }
end

function 法术:法术取描述()
    return string.format('放出千千万万的尸蛊之虫，蚕食对方多个单位的生命，并化为己用。可将伤害的一定百分比化为己方所用，目标人数#R%s#G人。'
    , self:法术取目标数())
end

return 法术
