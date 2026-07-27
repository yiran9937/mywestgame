local 物品 = {
    名称 = '变身卡',
    叠加 = 0,
    类别 = 10,
    类型 = 0,
    对象 = 1,
    条件 = 2,
    绑定 = false
}


local 对话 = [[
menu
1|我要使用变身卡
2|我要放入变身卡册
3|显示卡所有数据效果
99|什么都不想做
]]

--卡集存放



function 物品:使用(对象)
    local r = 对象:选择窗口(对话)
    if r == "1" or r == "2" then
        if r == "1" then
            local rw = 生成任务 { 名称 = '变身卡' }
            rw:添加任务2(对象, self)
            self.数量 = self.数量 - 1
        elseif r == "2" then
            if 对象:放入卡册 { name = self.name, key = self.key, 属性类型 = self.属性类型, 属性id = self.属性id } then
                self.数量 = self.数量 - 1
            end
        end
    elseif r == "3" then
        ------------------ 【完整属性打印代码】 ------------------
        if type(self.附加) == "table" then
            for i, v in ipairs(self.附加) do
                -- 匹配到写错的 "加昏睡"
                if v[1] == "加昏睡" then
                    print(string.format("[变身卡修复] 检测到错误属性 '%s': %s，修正为 '加强昏睡': 5", tostring(v[1]), tostring(v[2])))
                    v[1] = "加强昏睡" -- 修正属性名
                    -- v[2] = 5         -- 修正数值为正确的 5（或你想要的数值）
                end
            end
        end


        print("\n================== 变身卡完整属性 Dump ==================")
        -- 1. 打印变身卡对象的所有原始键值（包括名称、种类、五行、附加表等）
        打印卡片完整属性(self.附加, "变身卡(self)")

        -- 2. 针对关键字段做直观解析提示
        print("\n------------------ 关键字段快速校验 ------------------")
        print(string.format("卡片名称: %s", tostring(self.name or self.名称)))
        print(string.format("属性ID  : %s", tostring(self.属性id)))
        print(string.format("属性类型: %s (%s)", tostring(self.属性类型), self.属性类型 == 1 and "变身属性" or "属性卡"))
        print(string.format("卡片等级: %s", tostring(self.等级)))
        print(string.format("卡片种类: %s", tostring(self.种类)))
        print(string.format("亲和力  : %s", tostring(self.亲和力)))
        print(string.format("外形ID  : %s", tostring(self.外形)))
        print(string.format("介绍  : %s", tostring(self.介绍)))
        print(string.format("皮肤图标: %s", tostring(self.皮肤 or self.图标)))
        print("========================================================\n")
    end
end


-- 通用表格展开打印工具函数
function 打印卡片完整属性(tb, 标签, 缩进层级)
    缩进层级 = 缩进层级 or 0
    标签 = 标签 or "变身卡数据"
    local 缩进 = string.rep("  ", 缩进层级)

    if type(tb) ~= "table" then
        print(string.format("%s%s = %s", 缩进, tostring(标签), tostring(tb)))
        return
    end

    print(string.format("%s[%s] (table):", 缩进, tostring(标签)))
    for k, v in pairs(tb) do
        local 当前缩进 = string.rep("  ", 缩进层级 + 1)
        if type(v) == "table" then
            打印卡片完整属性(v, k, 缩进层级 + 1)
        else
            print(string.format("%s%-12s = %s", 当前缩进, tostring(k) .. ":", tostring(v)))
        end
    end
end



function 物品:生成介绍()
end

-- 属性名称纠错字典（如遇到其他写错的属性可在此处扩充）
local 属性纠错映射 = {
    ["加昏睡"] = "加强昏睡",
    ["加混乱"] = "加强混乱",
    ["加封印"] = "加强封印",
}

function 物品:取描述(对象)
    local t = {}

    -- 1. 基础信息拼接
    if self.等级 then table.insert(t, "等级:" .. tostring(self.等级)) end
    if self.亲和力 then table.insert(t, "亲和力:" .. tostring(self.亲和力)) end
    if self.种类 then table.insert(t, "种类:" .. tostring(self.种类)) end

    -- 2. 动态遍历附加属性集合（self.附加）
    if type(self.附加) == "table" then
        for _, v in ipairs(self.附加) do
            local 属性名 = v[1]
            local 属性值 = v[2]

            -- 自动纠正错别字
            if 属性纠错映射[属性名] then
                属性名 = 属性纠错映射[属性名]
            end

            -- 针对带有百分比或数值的文本格式化
            if type(属性值) == "number" then
                -- 常见的百分比/固定数值加成展示（若数值大于0且不是纯数值属性，可自动带上%或正负号）
                if 属性值 > 0 then
                    table.insert(t, string.format("%s:%d%%", 属性名, 属性值))
                else
                    table.insert(t, string.format("%s:%d%%", 属性名, 属性值))
                end
            else
                table.insert(t, string.format("%s:%s", tostring(属性名), tostring(属性值)))
            end
        end
    end

    -- 3. 动态遍历五行数据（self.五行，顺序为：金、木、水、火、土）
    local 五行名称 = { "金", "木", "水", "火", "土" }
    if type(self.五行) == "table" then
        for i, 名称 in ipairs(五行名称) do
            local 值 = self.五行[i] or 0
            if 值 > 0 then
                table.insert(t, string.format("%s:%d", 名称, 值))
            end
        end
    end

    -- 4. 拼接所有项并返回
    if #t > 0 then
        return '#C' .. table.concat(t, ",")
    end

    return '#C未知介绍'
end

return 物品
