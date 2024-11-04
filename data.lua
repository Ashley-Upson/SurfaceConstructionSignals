data:extend({
    -- Define a virtual signal for each planet's missing materials
    {
        type = "virtual-signal",
        name = "planet_missing_materials_signal",
        icon = "__core__/graphics/icons/alerts/no-building-material-icon.png",
        icon_size = 64,
        subgroup = "virtual-signal",
        order = "z[planet-missing-materials]"
    }
})
