local 法术 = {
    类别 = '门派',
    类型 = 1,
    对象 = 2,
    条件 = 37,
    名称 = '啮骨抽髓',
    id = 1903,
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
    -- 1. 计算【真正的总回血池】
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

    -- 如果一滴血都没吸到，直接结束
    if 总回血池 <= 0 then
        self.吸血值 = {}
        return
    end

    -- 💡 【修复死锁1】：单次回复限额绝对不能为 0！最少为 1
    local 原始总血池 = 总回血池
    local 单次回复限额 = math.max(1, math.floor(原始总血池 * 0.3))

    -- ========================================================
    -- 2. 搜集我方需要回血的目标
    -- ========================================================
    local list = {}
    for _, v in 攻击方:遍历我方() do
        if not v:取BUFF('封印') then
            if v.是否死亡 then
                if v.是否玩家 then table.insert(list, v) end
            else
                table.insert(list, v)
            end
        end
    end

    -- ========================================================
    -- 3. 严格多条件分级排序
    -- ========================================================
    table.sort(list, function(a, b)
        if a.是否死亡 ~= b.是否死亡 then return a.是否死亡 end
        if a.是否死亡 and b.是否死亡 then
            if a.最大气血 ~= b.最大气血 then return a.最大气血 < b.最大气血 end
            return false
        end
        local a_残血 = a.气血 < a.最大气血
        local b_残血 = b.气血 < b.最大气血
        if a_残血 ~= b_残血 then return a_残血 end
        if a_残血 and b_残血 then
            local a_损失比 = 1 - (a.气血 / a.最大气血)
            local b_损失比 = 1 - (b.get_hp or b.最大气血) -- 兼容防错
            if a.最大气血 > 0 then a_损失比 = 1 - (a.气血 / a.最大气血) end
            if b.最大气血 > 0 then b_损失比 = 1 - (b.气血 / b.最大气血) end
            if math.abs(a_损失比 - b_损失比) > 0.0001 then
                return a_损失比 > b_损失比
            end
        end
        return a.最大气血 < b.最大气血
    end)

    -- ========================================================
    -- 4. 【模拟分发（带安全计数器，绝对防卡死）】
    -- ========================================================
    local 最大回回人数 = 5 
    while #list > 最大回回人数 do
        table.remove(list)
    end

    local heal_map = {}
    local 安全计数器 = 0 -- 💡 【修复死锁2】：强制兜底，运行超过200轮无条件终止，防止引擎挂起

    while 总回血池 > 0 and 安全计数器 < 200 do
        安全计数器 = 安全计数器 + 1
        local 本轮有任何加血行为 = false

        for _, v in ipairs(list) do
            if 总回血池 <= 0 then break end

            local 已记账血量 = heal_map[v] or 0
            local 虚拟当前气血 = v.气血 + 已记账血量
            local 需要血量 = v.最大气血 - 虚拟当前气血
            
            if v.是否死亡 then
                需要血量 = v.最大气血 - 已记账血量
            end

            if 需要血量 > 0 or (v.是否死亡 and 已记账血量 == 0) then
                local 实际想加 = math.min(需要血量, 单次回复限额)
                local 实际加血 = math.min(总回血池, 实际想加)
                
                if 实际加血 <= 0 and v.是否死亡 and 已记账血量 == 0 then 
                    实际加血 = 1 
                end 

                if 实际加血 > 0 then
                    heal_map[v] = (heal_map[v] or 0) + 实际加血
                    总回血池 = 总回血池 - 实际加血
                    本轮有任何加血行为 = true
                end
            end
        end

        -- 如果一整圈扫描下来，没有任何一个人能吃得下血（全员虚拟满血，或血池有碎屑分不出去）
        if not 本轮有任何加血行为 then
            -- 💡 【修复死锁3】：如果还有剩余碎屑血池（比如剩1点血），但大家都满血不要了，直接把碎屑塞给队列第一人，清空血池退出
            if 总回血池 > 0 and list[1] then
                heal_map[list[1]] = (heal_map[list[1]] or 0) + 总回血池
                总回血池 = 0
            end
            break
        end
    end

    -- ========================================================
    -- 5. 【合并结算】
    -- ========================================================
    for target, 总增加值 in pairs(heal_map) do
        if 总增加值 > 0 then
            target:增加气血(总增加值)
        end
    end

    self.吸血值 = {}
end

function 法术:法术取伤害(攻击方, 挨打方)
    local 伤害 = 0
    local 等级 = 攻击方.等级 + 1
    伤害 = 37.144 * 等级 + 攻击方.加强三尸虫
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
        return 4
    elseif self.熟练度 >= 5200 then
        return 3
    else
        return 2
    end
end

function 法术:法术取目标数()
    return self:取目标数(), function(a, b)
            return a.速度 > b.速度
        end
end

function 法术:法术取消耗()
    return { 消耗MP = math.floor(self.熟练度 * 0.168) }
end

function 法术:法术取描述()
    return string.format('放出大量的尸虫攻击敌方多个目标，啮其骨髓，蚀其心志。可将伤害的一定百分比化为己方所用，目标人数#R%s#G人。'
        , self:法术取目标数())
end

return 法术
