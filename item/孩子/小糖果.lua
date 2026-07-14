local 物品 = {
    名称 = '小糖果',
    叠加 = 999,
    孩子是否可用 = true,
    绑定 = false
}

-- 对象 是 孩子.接口
function 物品:使用(对象)
    if 对象:添加亲密孝心('小糖果') then
        self.数量 = self.数量 - 1
    end
end

return 物品
