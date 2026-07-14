-- @Author              : GGELUA
-- @Last Modified by    : baidwwy
-- @Date                : 2025-05-07 10:23:16
-- @Last Modified time  : 2025-05-07 10:29:11
--[[
Author: error: error: git config user.name & please set dead value or install git && error: git config user.email & please set dead value or install git & please set dead value or install git
Date: 2025-03-09 20:44:36
LastEditors: error: error: git config user.name & please set dead value or install git && error: git config user.email & please set dead value or install git & please set dead value or install git
LastEditTime: 2025-03-09 20:48:14
FilePath: \服务端1\scripts\npc\长安\召唤兽展示.lua
Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
--]]
local NPC = {}
local 对话 = [[
踩着七彩祥云的盖世英雄是你吗？
menu
1|我只是路过看看
]]

function NPC:NPC对话(玩家, i)
    return 对话
end

function NPC:NPC菜单(玩家, i)
    if i == '1' then
    elseif i == '2' then
    elseif i == '3' then
    elseif i == '4' then
    end
end

return NPC
