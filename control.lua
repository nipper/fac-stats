local Entity = require('__stdlib__/stdlib/entity/entity')
local ENTITY_NAMES = {["fac-stats"] = true, ["fac-stats-rate"] = true}

local function new_registry_entry(entity)

    return {type = "gauge", entity = entity}
end

local function new_registry_entry_counter(entity)
    local entry = new_registry_entry(entity)
    entry.type = "rate"
    entry.counters = {}
    entry.counter_index = 0
    -- 10s moving average.
    entry.counter_length = 600
    return entry
end

local TYPE_MAP = {virtual = "virtual-signal"}

script.on_init(function()
    global.registry = {}
    global.gui = {}


end)

local statistics = {
    "item_production_statistics", "fluid_production_statistics",
    "kill_count_statistics", "entity_build_count_statistics"
}

local function log_data(tick, line, file_prefix)

    game.write_file(
        settings.global["folder-name"].value .. "/" .. settings.global['game-name'].value .. "/" ..
            file_prefix .. "_" .. tick .. ".csv", line .. "\n", false)
end

local function merge_global_line(tick, name, force_name, stat_name, prod_type,
                                 item, amount)
    line =
         name .. "," .. tick .. "," .. force_name .. "," .. stat_name .. "," ..
            prod_type .. "," .. item .. "," .. amount
    return line
end

local function merge_line_combinator(tick, game_name, entity_id, stat_title,
                                     signal_type, signal_name, amount)
    local line = game_name .. "," .. tick .. "," .. entity_id .. "," ..
                     stat_title .. "," .. signal_type .. "," .. signal_name ..
                     "," .. amount
    return line
end

local function write_global_data(event)

    data_to_write = "game_name,tick,force,stat,type,item,amount\n"
    game_name = settings.global["game-name"].value

    for k, force in pairs(game.forces) do
        for _, statName in pairs(statistics) do
            for item, amount in pairs(force[statName].input_counts) do
                data_to_write = data_to_write ..
                                    merge_global_line(game.tick, game_name,
                                                      force.name, statName,
                                                      "input", item, amount) ..
                                    "\n"
            end

            for item, amount in pairs(force[statName].output_counts) do
                data_to_write = data_to_write ..
                                    merge_global_line(game.tick, game_name,
                                                      force.name, statName,
                                                      "output", item, amount) ..
                                    "\n"
            end
        end
    end
    log_data(game.tick, data_to_write,
             "global_data" .. "-" .. settings.global['game-name'].value)

end

local function write_combinator_data(event)

    local data_to_write = "game_name,tick,entity_id,stat,signal_type,signal_name,value\n"
    for entity_number, entry in pairs(global.registry) do
        local entity = entry.entity

        if not entity.valid then goto wc_skip_to_next end

        local data = Entity.get_data(entity)

        if data == nil then goto wc_skip_to_next end

        local entity_enabled = data["fac_stats_entity_enabled"] or false

        if not entity_enabled then goto wc_skip_to_next end

        local stat_title = data["stat_title"]
        local signals = entity.get_merged_signals()

        if signals then
            for _, signal in ipairs(signals) do

                local signal_type = TYPE_MAP[signal.signal.type] or
                                        signal.signal.type

                data_to_write = data_to_write ..
                                    merge_line_combinator(game.tick,
                                                          settings.global["game-name"]
                                                              .value,
                                                          entity_number,
                                                          stat_title,
                                                          signal_type,
                                                          signal.signal.name,
                                                          signal.count) .. "\n"
            end
        end

        ::wc_skip_to_next::
    end
    log_data(game.tick, data_to_write,
             "combinator_data" .. "-" .. settings.global['game-name'].value)

end

local function on_tick(event)

    if settings.global["fac-stats-write-global-data"].value then
        write_global_data(event)
    end

    if settings.global['write-combinators'].value then
        write_combinator_data(event)
    end

end

script.on_nth_tick(60, on_tick)

local function on_place_entity(event)
    local entity = event.created_entity
    if not entity.valid or not ENTITY_NAMES[entity.name] then return end
    Entity.set_data(entity, {stat_title = entity.unit_number})
    Entity.set_data(entity, {fac_stats_entity_enabled = false})

    entity.get_control_behavior().enabled = false
    local entry
    if entity.name == "fac-stats" then
        entry = new_registry_entry(entity)
    else
        entry = new_registry_entry_counter(entity)
    end
    global.registry[entity.unit_number] = entry
end

local function on_remove_entity(event)
    local entity = event.entity
    if not entity.valid or not ENTITY_NAMES[entity.name] then return end

    global.registry[entity.unit_number] = nil
end

script.on_event(defines.events.on_built_entity, on_place_entity)
script.on_event(defines.events.on_robot_built_entity, on_place_entity)

script.on_event(defines.events.on_pre_player_mined_item, on_remove_entity)
script.on_event(defines.events.on_robot_pre_mined, on_remove_entity)
script.on_event(defines.events.on_entity_died, on_remove_entity)

script.on_nth_tick(60, on_tick)

script.on_event(defines.events.on_gui_opened, function(event)
    local entity = event.entity
    if event.gui_type ~= defines.gui_type.entity or not entity or
        not ENTITY_NAMES[entity.name] then return end

    local entry = global.registry[entity.unit_number]
    local player = game.players[event.player_index]

    local caption
    if entry.type == "rate" then
        caption = {"entity-name.fac-stats-rate"}
    else
        caption = {"entity-name.fac-stats"}
    end
    local frame = player.gui.center.add {
        type = "frame",
        name = "fac_stats",
        caption = caption,
        direction = "vertical"
    }

    local interval_index = 1
    local gui = {
        element = frame,
        entry = entry,
        interval_index = interval_index
    }

    local data = Entity.get_data(entity)

    local text = data["stat_title"] or "none"
    local entity_enabled = data["fac_stats_entity_enabled"] or false

    local text_label = frame.add({
        type = "checkbox",
        name = "entity-enabled",
        state = entity_enabled,
        caption = "Enable Combinator"

    })

    local text_input = frame.add {
        type = "textfield",
        name = "entity-title",
        caption = "Name",
        text = text
    }

    player.opened = frame

    global.gui[player.index] = gui

end)

script.on_event(defines.events.on_gui_closed, function(event)
    local frame = event.element
    if event.gui_type ~= defines.gui_type.custom or not frame or not frame.valid or
        frame.name ~= "fac_stats" then return end
    local player = game.players[event.player_index]
    local gui = global.gui[player.index]
    local entry = gui.entry
    local title_text = ""
    local checkbox_state = true
    for _, item in pairs(gui.element.children) do

        if item.name == 'entity-title' then title_text = item.text end
        if item.name == 'entity-enabled' then checkbox_state = item.state end
    end

    Entity.set_data(entry.entity, {
        fac_stats_entity_enabled = checkbox_state,
        stat_title = title_text
    })

    global.gui[player.index] = nil
    frame.destroy()
end)
