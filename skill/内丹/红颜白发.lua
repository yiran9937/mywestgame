local 法术 = {
    类别 = '内丹',
    类型 = 2,
    对象 = 0,
    条件 = 0,
    名称 = '红颜白发',
    种族 = 2
}
local BUFF
function 法术:法术施放(攻击方, 目标)

end

function 法术:公式(召唤)
    -- 1. 安全获取召唤兽/单位的最大法力上限
    local 最大魔法 = 召唤.最大魔法 or 0

    -- 2. 计算最大魔法带来的加成项 (参考祝融取火/开天辟地指数公式)
    local 法力加成 = 0.000001 * math.pow(最大魔法, 1.57)

    -- 3. 将法力加成注入基础公式
    local ndjl =
    math.floor(
        (math.pow(召唤.等级 * self.等级 * 0.04, 1 / 2) * (1 + 0.25 * self.转生) +
            (math.pow(召唤.亲密, 1 / 6) * 内丹系数调整(召唤.转生, self.转生) * self.等级) / 50 +
            法力加成) *
        1000
    ) * 0.000005;

    -- 4. 狂暴程度自动按 1.2 倍随 MP 加成一起提升
    local ndcd = ndjl * 1.2
    ndjl = math.ceil(ndjl * 10000) / 100
    ndcd = math.ceil(ndcd * 10000) / 100
    return ndjl, ndcd
end

function 法术:法术取描述(召唤)
    local ndjl, ndcd = self:公式(召唤)
    return string.format("此技能在使用仙法攻击的时候额外有#R%.2f%%#W几率出现狂暴，狂暴程度增加#R%.2f%%#W。",
        ndjl, ndcd)
end

local _jl = {
    '水系狂暴几率',
    '火系狂暴几率',
    '雷系狂暴几率',
    '风系狂暴几率',
}

local _cd = {
    '水系狂暴程度',
    '火系狂暴程度',
    '雷系狂暴程度',
    '风系狂暴程度',
}

function 法术:计算(召唤)
    local ndjl, ndcd = self:公式(召唤)
    local list = {}
    for _, v in pairs(_jl) do
        list[v] = ndjl
    end
    for _, v in pairs(_cd) do
        list[v] = ndcd
    end
    return list
end

local _bid = { 1301, 1302, 1303, 1314, 1318 }
function 法术:切换内丹BUFF(召唤)
    BUFF.id = _bid[self.转生 + 1]
    召唤:添加BUFF(BUFF)
end

BUFF = {
    法术 = '红颜白发',
    名称 = '内丹特效',
    id = 1301
}
法术.BUFF = BUFF

function BUFF:BUFF添加前(buff)
    if buff.名称 == '内丹特效' then
        self:删除()
    end
end

return 法术