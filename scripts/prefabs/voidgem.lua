require "prefabutil"

    local assets =
    {
        Asset("ANIM", "anim/voidgem_build.zip"),
        Asset("ATLAS", "images/inventoryimages/voidgem_normal.xml"),
        Asset("IMAGE", "images/inventoryimages/voidgem_normal.tex"),
        Asset("ATLAS", "images/inventoryimages/voidgem_refined.xml"),
        Asset("IMAGE", "images/inventoryimages/voidgem_refined.tex"),
        Asset("ATLAS", "images/inventoryimages/voidgem_purified.xml"),
        Asset("IMAGE", "images/inventoryimages/voidgem_purified.tex"),
        Asset("ANIM", "anim/ui_voidgem_3x3.zip"),
        Asset("ANIM", "anim/voidgem_range.zip")
    }

local function buildvoidgem(type)

    local ignore_list = {
        "INLIMBO",
        "voidresist", 
        "chester_eyebone",
        "fossil_piece",
        "icepack",
        "krampus_sack",
        "piggyback",
        "candybag",
        "backpack",
        "ancient_key",
        "cavein_boulder",
        "sculpture_rooknose",
        "sculpture_knighthead",
        "sculpture_bishophead",
        "chesspiece_pipe_marble",
        "chesspiece_pipe_stone",
        "chesspiece_hornucopia_marble",
        "chesspiece_hornucopia_stone",
        "chesspiece_rook_marble",
        "chesspiece_rook_stone",
        "chesspiece_knight_marble",
        "chesspiece_knight_stone",
        "chesspiece_bishop_marble",
        "chesspiece_bishop_stone",
        "chesspiece_formal_marble",
        "chesspiece_formal_stone",
        "chesspiece_muse_marble",
        "chesspiece_muse_stone",
        "chesspiece_pawn_marble",
        "chesspiece_pawn_stone",
        "chesspiece_deerclops_marble",
        "chesspiece_deerclops_stone",
        "chesspiece_bearger_marble",
        "chesspiece_bearger_stone",
        "chesspiece_moosegoose_marble",
        "chesspiece_moosegoose_stone",
        "chesspiece_dragonfly_marble",
        "chesspiece_dragonfly_stone"
    }

    local function IsItemInFilter(inst, item)
        if inst.components.container ~= nil then
            for _,i in pairs(inst.components.container:ReferenceAllItems()) do
                if i.prefab == item.prefab then
                    return true
                end
            end
        end
        return false
    end

    local function TryToInsertItem(inst, parent_storage, item)
        -- Handle player inventories
        if parent_storage.components.inventory ~= nil then
            local inv = parent_storage.components.inventory
            local backpack = inv:GetOverflowContainer()
            local slot_num, storage = inv:GetNextAvailableSlot(item)
            if slot_num then
                inv.inst:PushEvent("gotnewitem", {item = item, slot = slot_num})
            
                local leftovers = nil
                if backpack ~= nil and backpack == storage then
                    local itemInSlot = backpack:GetItemInSlot(slot_num) 
                    if itemInSlot then
                        leftovers = itemInSlot.components.stackable:Put(item, nil)
                    end
                elseif storage == inv.equipslots then
                    if inv.equipslots[slot] then
                        leftovers = inv.equipslots[slot].components.stackable:Put(item, nil)
                    end
                else
                    if inv.itemslots[slot_num] ~= nil then
                        if inv.itemslots[slot_num].components.stackable:IsFull() then
                            leftovers = item
                        else 
                            leftovers = inv.itemslots[slot_num].components.stackable:Put(item, nil)
                        end
                    else
                        item.components.inventoryitem:OnPutInInventory(inv.inst)
                        inv.itemslots[slot_num] = item
                        inv.inst:PushEvent("itemget", {item = item, slot = slot_num, src_pos = nil})
                    end

                    if item.components.equippable then
                        item.components.equippable:ToPocket()
                    end
                end

                if leftovers then
                    if not TryToInsertItem(inst, parent_storage, leftovers) and inv.ignorefull then
                        return false
                    end
                end
                return true
            elseif backpack ~= nil and TryToInsertItem(inst, backpack.inst, item) then
                return true
            end

            if inv.ignorefull then
                return false
            end
            return false
        -- Handle containers
        elseif parent_storage.components.container ~= nil then
            local con = parent_storage.components.container
            if item == nil then
                return false
            elseif item.components.inventoryitem ~= nil and con:CanTakeItemInSlot(item) then
                if item.components.stackable ~= nil and con.acceptsstacks then
                    for k = 1, con.numslots do
                        local other_item = con.slots[k]
                        if other_item and other_item.prefab == item.prefab and not other_item.components.stackable:IsFull() then
                            if con.inst.components.inventoryitem ~= nil and con.inst.components.inventoryitem.owner ~= nil then
                                con.inst.components.inventoryitem.owner:PushEvent("gotnewitem", { item = item, slot = k })
                            end

                            item = other_item.components.stackable:Put(item, nil)
                            if item == nil then
                                return true
                            end
                        end
                    end
                end

                local in_slot = nil
                if con.numslots > 0 then
                    for k = 1, con.numslots do
                        if not con.slots[k] then
                            in_slot = k
                            break
                        end
                    end
                end

                if in_slot then
                    if not con.acceptsstacks and item.components.stackable and item.components.stackable:StackSize() > 1 then
                        item = item.components.stackable:Get()
                        con.slots[in_slot] = item
                        item.components.inventoryitem:OnPutInInventory(con.inst)
                        con.inst:PushEvent("itemget", { slot = in_slot, item = item, src_pos = nil })
                        return false
                    end

                    con.slots[in_slot] = item
                    item.components.inventoryitem:OnPutInInventory(con.inst)
                    con.inst:PushEvent("itemget", { slot = in_slot, item = item, src_pos = nil })

                    if not con.ignoresound and con.inst.components.inventoryitem ~= nil and con.inst.components.inventoryitem.owner ~= nil then
                        con.inst.components.inventoryitem.owner:PushEvent("gotnewitem", { item = item, slot = in_slot })
                    end
                    return true
                end
            end
        end
    end

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank("voidgem")
        inst.AnimState:SetBuild("voidgem_build")
        inst.AnimState:PlayAnimation("idle_"..type, true)

        inst:AddTag("molebait")
        inst:AddTag("voidresist")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.atlasname = "images/inventoryimages/voidgem_"..type..".xml"

        local fog = nil
        
        inst.components.inventoryitem:SetOnPutInInventoryFn(function(_, owner)
            if owner:HasTag("voidresist") then
                owner.components.container:DropItem(inst)
            end
        end)

        if type == "purified" or type == "refined" then
            inst:AddComponent("container")
            local widget_name = "voidgem_"..type
            inst.components.container:WidgetSetup(widget_name)

            local normal_item_check = inst.components.container.CanTakeItemInSlot
            function inst.components.container.CanTakeItemInSlot(slot, item, ...)
                return normal_item_check(slot, item) and not item:HasTag("voidresist")
            end
        end

        inst:AddComponent("inspectable")
        inst:AddComponent("tradable")
        MakeHauntableLaunchAndSmash(inst)

        local x, y, z = 0, -50, 0
        local current_owner = nil
        local fog_hidden = false
        local fog_hidden

        inst:DoPeriodicTask(1, function()
            x, y, z = inst.Transform:GetWorldPosition()

            -- Check who owns the gem at the moment
            current_owner = inst.components.inventoryitem:GetGrandOwner()

            -- It may be that a backpack contains the gem
            if current_owner == nil then
                local backpack = inst.components.inventoryitem.owner
                if backpack ~= nil and backpack:HasTag("backpack") then
                    current_owner = backpack
                end
            end

            -- Spawn fog if not present yet.
            if fog == nil then
                fog = SpawnPrefab("voidgem_range_"..type)
            end

            -- If we have an owner, we can use the parent function
            if current_owner ~= nil then
                fog.entity:SetParent(current_owner.entity)
            -- Otherwise we need to manually place the fog under the gem
            else
                fog.entity:SetParent(inst.entity)
            end

            -- Set the fog to be hidden if no items in container
            local is_empty = inst.components.container and inst.components.container:NumItems() == 0
            if is_empty and not fog_hidden then
                fog_hidden = true
                fog.AnimState:PlayAnimation("_")
            elseif not is_empty and fog_hidden then
                fog_hidden = false
                fog.AnimState:PlayAnimation("idle_"..type, true)
            end
            
            -- Collect all entities around the gem
            local stuff = TheSim:FindEntities(x, y, z, 6.3, {"_inventoryitem"}, ignore_list, nil)
            
            -- Handles if we show a shadow above the player (default: no)
            local do_in_puff = false

            -- Iterate over all entities
            for key, entity in pairs(stuff) do
                -- If this gem destorys things...
                if type == "normal" or (type == "refined" and IsItemInFilter(inst, entity)) then
                    local shadow = SpawnPrefab("sanity_lower")
                    shadow.Transform:SetPosition(entity.Transform:GetWorldPosition())
                    shadow.Transform:SetScale(.5,.5,.5)
                    SpawnPrefab("sand_puff").Transform:SetPosition(entity.Transform:GetWorldPosition())
                    entity:Remove()
                    -- If a player holds the gem, this will drain some sanity
                    if current_owner ~= nil and current_owner.player_classified ~= nil then
                        current_owner.components.sanity:DoDelta(-0.2)
                    end
                -- If this gem collects things...
                elseif type == "purified" and IsItemInFilter(inst, entity) and current_owner ~= nil then
                    -- If inserting an item was successful, do some animations
                    if TryToInsertItem(inst, current_owner, entity) then
                        do_in_puff = true
                        local shadow = SpawnPrefab("sanity_lower")
                        shadow.Transform:SetPosition(entity.Transform:GetWorldPosition())
                        shadow.Transform:SetScale(.5,.5,.5)
                        SpawnPrefab("sand_puff").Transform:SetPosition(entity.Transform:GetWorldPosition())
                        -- If a player holds the gem, this will drain some sanity
                        if current_owner.player_classified ~= nil then
                            current_owner.components.sanity:DoDelta(-1.5)
                        end
                    end
                end
            end
            -- This gets called when the purified gem collected some entities
            if do_in_puff then
                local shadow_in = SpawnPrefab("sanity_raise")
                shadow_in.entity:SetParent(current_owner.entity)
            end
        end)
        return inst
    end
    return Prefab("voidgem_"..type, fn, assets)
end

local function build_voidgem_range(type)

    local PLACER_SCALE = 2.2

    local range_assets = {
        Asset("ANIM", "anim/voidgem_range.zip")
    }

    local function fn_range()
        local inst = CreateEntity() 
        inst:AddTag("FX")
        inst:AddTag("placer")
        inst:AddTag("NOCLICK")

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        inst.persists = false

        inst.AnimState:SetBank("voidgem_range")
        inst.AnimState:SetBuild("voidgem_range")
        inst.AnimState:PlayAnimation("idle_"..type, true)
        inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
        inst.AnimState:SetLayer(LAYER_BACKGROUND)
        inst.AnimState:SetSortOrder(1)
        inst.Transform:SetScale(PLACER_SCALE, PLACER_SCALE, PLACER_SCALE)
        return inst
    end

    return Prefab("voidgem_range_"..type, fn_range, range_assets)
end

STRINGS.NAMES.VOIDGEM_NORMAL = "Rough Void Gem"
STRINGS.RECIPE_DESC.VOIDGEM_NORMAL = "I feel empty."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.VOIDGEM_NORMAL = "Is this all there is? Nothing?"

STRINGS.NAMES.VOIDGEM_REFINED = "Refined Void Gem"
STRINGS.RECIPE_DESC.VOIDGEM_REFINED = "Controlled destruction."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.VOIDGEM_REFINED = "I can see a faint glow inside."

STRINGS.NAMES.VOIDGEM_PURIFIED = "Purified Void Gem"
STRINGS.RECIPE_DESC.VOIDGEM_PURIFIED = "Order and Chaos"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.VOIDGEM_PURIFIED = "Balance."

return build_voidgem_range("normal"),
       build_voidgem_range("refined"),
       build_voidgem_range("purified"),
       buildvoidgem("normal"),
       buildvoidgem("refined"),
       buildvoidgem("purified")