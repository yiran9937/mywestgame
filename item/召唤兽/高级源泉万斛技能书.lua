-- @Author              : GGELUA
-- @Last Modified by    : baidwwy
-- @Date                : 2025-04-25 15:17:47
-- @Last Modified time  : 2025-04-25 15:59:12
local 物品 = {
    名称 = '高级源泉万斛技能书',
	叠加 = 99,
    类别 = 8,
    类型 = 0,
    对象 = 2,
    条件 = 2,
	召唤兽 = '适用于全部召唤兽',
	技能 = '高级源泉万斛',
    绑定 = false
}

function 物品:初始化(t)
end

function 物品:使用(对象)
    local t,d = 对象:添加领悟技能(self.技能,"高级源泉万斛")
    if d then
        self.数量 = self.数量 - 1
        对象:提示窗口(t)
    -- else
    --     return t
    end
    -- if 对象:添加后天技能(self.技能) then
    --     对象:提示窗口("#Y恭喜你，召唤兽已成功领悟%s！", self.技能)
    --     self.数量 = self.数量 - 1
    -- end
end

function 物品:取描述()
    if self.技能 then
        return string.format("#Y召唤兽：%s\n#Y技能：%s", self.召唤兽, self.技能)
    end
end

return 物品