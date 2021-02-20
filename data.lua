data:extend{
    {
        type = "recipe",
        name = "fac-stats",
        enabled = "false",
        ingredients = {
            {"electronic-circuit", 5},
            {"copper-cable", 5},
        },
        result = "fac-stats",
    },
    {
        type = "item",
        name = "fac-stats",
        icon = "__fac-stats__/graphics/icons/gauge.png",
        icon_size = 32,
        subgroup = "circuit-network",
        order = "d[other]-c[fac-stats]",
        place_result = "fac-stats",
        stack_size = 10
    },
    {
        type = "technology",
        name = "fac-stats",
        icon_size = 128,
        icon = "__fac-stats__/graphics/fac-stats-tech.png",
        effects = {
            {
                type = "unlock-recipe",
                recipe = "fac-stats"
            }
        },
        prerequisites = {"circuit-network"},
        unit = {
            count = 100,
            ingredients = {
                {"automation-science-pack", 1},
                {"logistic-science-pack", 1}
            },
            time = 15
        },
        order = "a-d-e"
    }
}

local PREFIX = "__fac-stats__/graphics/"

local filenames = {
    gauge = {im = PREFIX .. "blue.png",   hr = PREFIX .. "hr-blue.png"},
    rate =  {im = PREFIX .. "yellow.png", hr = PREFIX .. "hr-yellow.png"},
}

local function change_filenames(entity, new_names)
    local dirs = {"north", "east", "south", "west"}
    for _, dir in ipairs(dirs) do
        local sprite = entity.sprites[dir]
        sprite.layers[1].filename = new_names.im
        sprite.layers[1].hr_version.filename = new_names.hr
    end
end

local time_series_entity = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])

time_series_entity.name = "fac-stats"
time_series_entity.icon = "__base__/graphics/icons/centrifuge.png"
time_series_entity.minable.result = "fac-stats"
time_series_entity.item_slot_count = 0

change_filenames(time_series_entity, filenames.gauge)
data:extend{time_series_entity}
