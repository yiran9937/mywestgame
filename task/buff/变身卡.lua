local 任务 = {
    名称 = '变身卡',
    --图标 = 1,
    是否BUFF = true
}

function 任务:任务初始化(玩家, ...)
end

function 任务:任务上线(玩家)
    if self.时间 <= os.time() then
        self:清除变身(玩家)
    end
end

function 任务:添加任务(玩家)
    local r = 玩家:取任务("变身卡")
    if r then
        r:清除变身(玩家)
    end
    self.时间 = os.time() + 60 * 60 * 30 * 24
    self.原形 = 玩家.外形
    self.是否变身 = true
    玩家:添加任务(self)
    玩家:刷新外形()
    return true
end

function 任务:任务战斗开始(对象, 玩家) -- 对象是战斗对象数据
    if not 玩家 or not self.附加 then
        return
    end

    local 种族差 = 0
    local 总亲和 = self.亲和力 or 0 -- 初始值包含玩家自己的亲和力
    local 重复差 = 0
    local 亲和力数值 = self.亲和力 or 0
    local 自身亲和力 = 亲和力数值 * 5
    local bskxz = 1

    if 玩家.是否组队 then
        for _, value in 玩家:遍历队伍() do
            -- 【核心修复】：排除玩家自己，只比对队友！
            if value ~= 玩家 then
                local r = value:取任务("变身卡")
                if r then
                    if r.种类 ~= self.种类 then
                        种族差 = 种族差 + 5
                    end
                    if r.亲和力 then
                        总亲和 = 总亲和 + r.亲和力
                    end
                    if r.属性id == self.属性id and r.外形 == self.外形 then
                        重复差 = 重复差 + 18
                    end
                else
                    种族差 = 种族差 + 5
                end
            end
        end

        bskxz = math.floor((214 - 种族差 - 重复差 - math.abs(总亲和 - 自身亲和力) * 2)) * 0.01
        if bskxz < 1 then
            bskxz = 1
        end
    end

    -- 结算五行
    if self.五行 then
        for i, v in ipairs { "金", "木", "水", "火", "土" } do
            对象[v] = (玩家[v] or 0) + (self.五行[i] or 0)
        end
    end

    -- 结算附加属性（已修改：全属性享受 bskxz 放大加成）
    if self.附加 then
        for _, v in ipairs(self.附加) do
            local 属性名 = v[1]
            local 基础值 = v[2] or 0

            if 属性名 == "气血" then
                local n = math.floor(基础值 * bskxz) * 0.01
                local 增加量 = math.floor((对象.最大气血 or 0) * n)
                对象.最大气血 = (对象.最大气血 or 0) + 增加量
                对象.气血 = (对象.气血 or 0) + 增加量

            elseif 属性名 == "法力" then
                local n = math.floor(基础值 * bskxz) * 0.01
                local 增加量 = math.floor((对象.最大魔法 or 0) * n)
                对象.最大魔法 = (对象.最大魔法 or 0) + 增加量
                对象.魔法 = (对象.魔法 or 0) + 增加量

            elseif 属性名 == "速度" then
                if 对象.速度 then
                    local n = math.floor(基础值 * bskxz) * 0.01
                    对象.速度 = 对象.速度 + math.floor(对象.速度 * n)
                end

            elseif 属性名 == "力量" then
                if 对象.攻击 then
                    local n = math.floor(基础值 * bskxz) * 0.01
                    对象.攻击 = 对象.攻击 + math.floor(对象.攻击 * n)
                end

            elseif 属性名 == "物理" then
                if 对象.攻击 then
                    -- 【修改点 1】：物理攻击力增加值乘以组队系数
                    local 实际加成 = math.floor(基础值 * bskxz)
                    对象.攻击 = 对象.攻击 + 实际加成
                end

            else
                -- 【修改点 2】：强法（如加强混乱）、抗性、忽视等所有其他属性，统统乘以组队系数 bskxz
                local 实际加成 = 基础值 * bskxz
                local 旧值 = 对象[属性名] or 0
                对象[属性名] = 旧值 + 实际加成

                -- 调试日志（可按需保留或删除）
                --print(string.format("[全属性加成] %s: 原基础=%d, 组队系数=%.2f, 实战最终附加=%d", tostring(属性名), 基础值, bskxz, 实际加成))
            end
        end
    end
end

function 任务:添加时长(玩家, n)
    self.时间 = self.时间 + n * 60 * 60 * 24 * 30
end

function 任务:添加任务2(玩家, t)
    local r = 玩家:取任务("变身卡")
    if r then
        if t.外形 == r.外形 and t.属性id == r.属性id and r.是否变身 == (t.属性类型 == 1) then
            r:添加时长(玩家, 6)
            return
        else
            r:清除变身(玩家)
        end
    end
    self.时间 = os.time() + 60 * 60 * 24 * 30
    self.原形 = 玩家.外形
    self.是否变身 = t.属性类型 == 1
    self.等级 = t.等级
    self.种类 = t.种类
    self.亲和力 = t.亲和力
    self.五行 = t.五行
    self.附加 = t.附加
    self.外形 = t.外形
    self.图标 = t.皮肤
    self.属性id = t.属性id
    玩家:添加任务(self)
    玩家:刷新外形()
    return true
end

function 任务:清除变身(玩家)
    self:删除()
    玩家:刷新外形()
end

function 任务:任务更新(sec, 玩家)
    --print(self.时间)
    if self.时间 <= sec then
        self:清除变身(玩家)
    end
end

function 任务:任务取详情(玩家)
    return '剩余变身时间: #G' .. tostring((self.时间 - os.time()) // 60)
end

return 任务
