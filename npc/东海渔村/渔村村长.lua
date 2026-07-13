local NPC = {}
local 对话 = [[
我们村人少，需要不少的人手，不会亏了你的好处的。
menu
1|帮忙找个人,100两银子
2|打海盗，120两银子
3|我还有其他事情，就不帮忙了
]]

function NPC:NPC对话(玩家, i)
    return 对话
end

function NPC:NPC菜单(玩家, i)
    if i == '1' then
        if 玩家.等级 < 4 then
            return
        end
        return self:领取海岛寻人任务(玩家)
    elseif i == '2' then
        if 玩家.等级 < 4 then
            return
        end
        return self:领取打海盗任务(玩家)
    end
end

function NPC:领取海岛寻人任务(玩家)
    local t = {}
    for _, v in 玩家:遍历队伍() do
        if v:取任务('海岛寻人') then
            table.insert(t, v.名称)
        end
    end

    if #t > 0 then
        return '#R' .. table.concat(t, '、 ') .. '已有此任务,无法重复领取'
    end

    local r = 生成任务 { 名称 = '海岛寻人' }

    if r and r:生成怪物(玩家) then
        local ff = string.format('最近发现#G%s#W有海盗出没，请到渔村外帮我把#G#u%s#W#u找回来。', r.位置, r.怪名)
        for _, v in 玩家:遍历队伍() do
            v:最后对话(ff, self.外形)
        end
    end
end

function NPC:领取打海盗任务(玩家)
    local t = {}
    for _, v in 玩家:遍历队伍() do
        if v:取任务('打海盗') then
            table.insert(t, v.名称)
        end
    end
    if #t > 0 then
        return '#R' .. table.concat(t, '、 ') .. '已有此任务,无法重复领取'
    end

    local r = 生成任务 { 名称 = '打海盗' }

    if r and r:生成怪物(玩家) then
        local ff = string.format('最近发现#G%s#W有海盗出没，请到渔村外击退#G#u%s#W#u。', r.位置, r.怪名)
        for _, v in 玩家:遍历队伍() do
            v:最后对话(ff, self.外形)
        end
    end
end

return NPC
