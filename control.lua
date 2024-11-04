-- Table to store missing materials for each surface
local surface_materials = {}

-- Function to categorize surfaces into planets and stations
local function categorize_surfaces()
    local planets = {}
    local stations = {}

    for _, surface in pairs(game.surfaces) do
        -- Identify station surfaces by checking for "station" in the name
        if surface.name:find("station") then
            stations[surface.name] = surface
        -- Identify planet surfaces by checking for "planet" in the name
        elseif surface.name:find("planet") then
            planets[surface.name] = surface
        end
    end

    return planets, stations
end

-- Function to build circuit signal parameters based on missing materials
local function build_signal_parameters(missing_materials, surface_name)
    local signals = {}
    local index = 1
    for material, count in pairs(missing_materials) do
        table.insert(signals, {
            signal = {type = "virtual", name = surface_name .. "-missing-" .. material},
            count = count,
            index = index
        })
        index = index + 1
    end
    return signals
end

-- Function to update missing materials for planets and stations
local function update_missing_materials_signals()
    -- Get categorized lists of planets and stations
    local planets, stations = categorize_surfaces()

    -- Function to process each surface type
    local function process_surface(surface, type)
        local missing_materials = {}

        -- Retrieve alerts for missing construction materials on this surface
        local alerts = surface.get_alerts{type = defines.alert_type.no_material_for_construction}

        -- Compile a list of missing materials
        for _, alert in pairs(alerts) do
            if alert.entity then
                local material_name = alert.entity.name
                missing_materials[material_name] = (missing_materials[material_name] or 0) + 1
            end
        end

        -- Store missing materials in the global state for this surface
        surface_materials[surface.name] = missing_materials

        -- Send the signals to the circuit network
        for _, entity in pairs(surface.find_entities_filtered({name = "constant-combinator"})) do
            if entity and entity.valid then
                entity.get_control_behavior().parameters = build_signal_parameters(missing_materials, surface.name)
            end
        end
    end

    -- Update missing materials for each planet and station
    for _, planet_surface in pairs(planets) do
        process_surface(planet_surface, "planet")
    end
    for _, station_surface in pairs(stations) do
        process_surface(station_surface, "station")
    end
end

-- Initialization for new game or mod addition to existing game
local function initialize_mod()
    update_missing_materials_signals()
    -- Schedule updates every 5 seconds
    script.on_nth_tick(300, update_missing_materials_signals)
end

-- Register on_init for new game
script.on_init(initialize_mod)

-- Register on_configuration_changed for mod addition to existing save
script.on_configuration_changed(function(event)
    if event.mod_changes and event.mod_changes["SurfaceConstructionSignals"] then
        initialize_mod()
    end
end)

-- Debug command to log materials (optional)
commands.add_command("log_materials", "Log missing materials per surface", function()
    for surface, materials in pairs(surface_materials) do
        local material_list = {}
        for mat, count in pairs(materials) do
            table.insert(material_list, mat .. " (" .. count .. ")")
        end
        game.print("Surface " .. surface .. " is missing materials: " .. table.concat(material_list, ", "))
    end
end)

