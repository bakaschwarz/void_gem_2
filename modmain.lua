local RECIPETABS = GLOBAL.RECIPETABS
local Vector3 = GLOBAL.Vector3
local TECH = GLOBAL.TECH
local require = GLOBAL.require
containers = require "containers"

Assets =
{
    Asset("ATLAS", "images/inventoryimages/voidgem_normal.xml"),
    Asset("IMAGE", "images/inventoryimages/voidgem_normal.tex"),
    Asset("ATLAS", "images/inventoryimages/voidgem_refined.xml"),
    Asset("IMAGE", "images/inventoryimages/voidgem_refined.tex"),
    Asset("ATLAS", "images/inventoryimages/voidgem_purified.xml"),
    Asset("IMAGE", "images/inventoryimages/voidgem_purified.tex"),
    Asset("ANIM", "anim/ui_voidgem_3x3.zip"),
}

PrefabFiles = 
{
    "voidgem",
}

local params = {}

local old_widgetsetup = containers.widgetsetup
containers.widgetsetup = function(container, prefab)
    local t = params[prefab or container.inst.prefab]
    if t ~= nil then
        for k, v in pairs(t) do
            container[k] = v
        end
    container:SetNumSlots(container.widget.slotpos ~= nil and #container.widget.slotpos or 0)
    else
        old_widgetsetup(container, prefab)
    end
end

local function makeVoidGem()
    container = {
        widget =
        {
            slotpos = {},
            animbank = "ui_voidgem_3x3",
            animbuild = "ui_voidgem_3x3",
            pos = Vector3(0, 200, 0),
            side_align_tip = 160,
        },
        acceptsstacks = false,
        type = "chest",
    }

    for y = 2, 0, -1 do
        for x = 0, 2 do
            table.insert(container.widget.slotpos, Vector3(80 * x - 80 * 2 + 80, 80 * y - 80 * 2 + 80, 0))
        end
    end

    return container
end

params.voidgem_refined = makeVoidGem()
params.voidgem_purified = makeVoidGem()

for k, v in pairs(params) do
    containers.MAXITEMSLOTS = math.max(containers.MAXITEMSLOTS, v.widget.slotpos ~= nil and #v.widget.slotpos or 0)
end

AddRecipe("voidgem_normal", {Ingredient("purplegem", 1), Ingredient("nightmarefuel", 8)}, RECIPETABS.MAGIC, TECH.MAGIC_THREE, nil, nil, nil, nil, nil, "images/inventoryimages/voidgem_normal.xml")
AddRecipe("voidgem_refined", {Ingredient("voidgem_normal", 1, "images/inventoryimages/voidgem_normal.xml", "voidgem_normal.tex"), Ingredient("thulecite_pieces", 20)}, RECIPETABS.ANCIENT, TECH.ANCIENT_TWO, nil, nil, nil, nil, nil, "images/inventoryimages/voidgem_refined.xml")
AddRecipe("voidgem_purified", {Ingredient("voidgem_normal", 1, "images/inventoryimages/voidgem_normal.xml", "voidgem_normal.tex"), Ingredient("opalpreciousgem", 1)}, RECIPETABS.ANCIENT, TECH.ANCIENT_FOUR, nil, nil, nil, nil, nil, "images/inventoryimages/voidgem_purified.xml")