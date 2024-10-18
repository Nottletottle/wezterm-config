-- WezTerm Configuration
local wezterm = require('wezterm')
local act = wezterm.action
local config = wezterm.config_builder()

-- Color configuration
local colors = {
    bg = {
        primary = "#282a36",
        secondary = "#44475a",
        dark = "#21222c",
        solidblack = "#000000",
        tabpanel = "#333333"
    },
    fg = {
        primary = "#f8f8f2",
        secondary = "#6272a4",
        accent = "#bd93f9",
    },
    status = {
        bg1 = "#bd93f9",  -- Purple
        bg2 = "#ff79c6",  -- Pink
        bg3 = "#8be9fd",  -- Cyan
        bg4 = "#50fa7b",  -- Green (for battery)
        fg = "#282a36",   -- Dark background for text
    },
    battery = {
        critical = "#ff5555",  -- Red
        low = "#ffb86c",       -- Orange
        normal = "#50fa7b",    -- Green 50fa7b
        charging = "#f1fa8c",  -- Yellow
    },
    arrow = {
        left = utf8.char(0xe0b2),
        right = utf8.char(0xe0b0),
    },
}

local window_config = {
    -- Background image configuration
    background = {
        image_path = os.getenv("HOME") .. "/images/background.jpg",
        overlay_path = os.getenv("HOME") .. "/images/overlay.jpeg",
        opacity_full = 1.0,
        opacity_transparent = 0.50,
        overlay_opacity_full = 0.90,
        overlay_opacity_transparent = 0.75,
        is_transparent = true,
    }
}

-- Basic appearance configuration
local function setup_appearance(config)
    config.color_scheme = "Dracula"
    config.font = wezterm.font("JetBrains Mono")
    config.font_size = 14
    config.window_decorations = "RESIZE"
    config.initial_rows = 30
    config.initial_cols = 120

    --Background image configuration
    config.background = {
        -- This is the deepest/back-most layer. It will be rendered first
        {
            source = {
            File = window_config.background.image_path,
            },
            opacity = window_config.background.opacity_full,
            height = cover,
            width = cover,
            hsb = dimmer,
            attachment = fixed,
        },
        -- Subsequent layers are rendered over the top of each other
        {
            source = {
            File = window_config.background.overlay_path,
            },
            opacity = 0.90,
            height = cover,
            width = cover,
            hsb = dimmer,
            attachment = fixed,
        },
    }

    config.window_padding = {
        left = 40,
        top = 20,
    }
    
    -- Tab bar configuration
    config.hide_tab_bar_if_only_one_tab = false
    config.tab_bar_at_bottom = true
    config.use_fancy_tab_bar = false
    config.tab_and_split_indices_are_zero_based = true
    
    return config
end

-- Keybinding configuration
local function setup_keybindings(config)
    config.leader = { 
        key = "q", 
        mods = "ALT", 
        timeout_milliseconds = 2000 
    }
    
    local keys = {
        -- Tab management
        { mods = "LEADER", key = "c", action = act.SpawnTab("CurrentPaneDomain") },
        { mods = "LEADER", key = "x", action = act.CloseCurrentPane({ confirm = true }) },
        { mods = "LEADER", key = "b", action = act.ActivateTabRelative(-1) },
        { mods = "LEADER", key = "n", action = act.ActivateTabRelative(1) },
        
        -- Split management
        { mods = "LEADER", key = "]", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
        { mods = "LEADER", key = "-", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
        
        -- Navigation
        { mods = "LEADER", key = "h", action = act.ActivatePaneDirection("Left") },
        { mods = "LEADER", key = "j", action = act.ActivatePaneDirection("Down") },
        { mods = "LEADER", key = "k", action = act.ActivatePaneDirection("Up") },
        { mods = "LEADER", key = "l", action = act.ActivatePaneDirection("Right") },
        
        -- Resize
        { mods = "LEADER", key = "LeftArrow", action = act.AdjustPaneSize({ "Left", 5 }) },
        { mods = "LEADER", key = "RightArrow", action = act.AdjustPaneSize({ "Right", 5 }) },
        { mods = "LEADER", key = "DownArrow", action = act.AdjustPaneSize({ "Down", 5 }) },
        { mods = "LEADER", key = "UpArrow", action = act.AdjustPaneSize({ "Up", 5 }) },
        
        -- Fullscreen
        { mods = "LEADER", key = "f", action = act.ToggleFullScreen },

        -- Opacity toggle (Alt + O)
        {
            key = "o",
            mods = "ALT",
            action = wezterm.action_callback(function(window, pane)
                window_config.background.is_transparent = not window_config.background.is_transparent
                local new_opacity, new_overlay_opacity = window_config.background.is_transparent and 
                    window_config.background.opacity_transparent, window_config.background.overlay_opacity_transparent or 
                    window_config.background.opacity_full, window_config.background.overlay_opacity_full
                
                window:set_config_overrides({
                    background = {
                        {
                            source = {
                            File = window_config.background.image_path,
                            },
                            opacity = new_opacity,
                            height = cover,
                            width = cover,
                            hsb = dimmer,
                            attachment = fixed,
                        },
                        -- Subsequent layers are rendered over the top of each other
                        {
                            source = {
                            File = window_config.background.overlay_path,
                            },
                            opacity = new_overlay_opacity,
                            height = cover,
                            width = cover,
                            hsb = dimmer,
                            attachment = fixed,
                        },
                    }
                })
            end)
        }, 
    }

    
    
    -- Add number-based tab switching
    for i = 0, 9 do
        table.insert(keys, {
            key = tostring(i),
            mods = "LEADER",
            action = act.ActivateTab(i),
        })
    end
    
    config.keys = keys
    return config
end

-- Status bar utilities
local function format_path(path)
    local max_length = 35
    local max_last_dir_length = 10
    local shortened_last_dir_length = 7
    
    if #path <= max_length then return path end
    
    local components = {}
    for dir in path:gmatch("[^/]+") do
        table.insert(components, dir)
    end
    
    local last_dir = components[#components]
    if #last_dir > max_last_dir_length then
        last_dir = last_dir:sub(1, shortened_last_dir_length) .. "..."
    end
    
    local shortened = {}
    for i = 1, #components - 1 do
        table.insert(shortened, #components[i] > 2 and (components[i]:sub(1, 4) .. ".") or components[i])
    end
    table.insert(shortened, last_dir)
    
    local result = table.concat(shortened, "/")
    if #result > max_length then
        result = "..." .. result:sub(-max_length + 3)
    end
    
    if path:sub(1, 1) == "/" and path ~= "~" then
        result = "/" .. result
    end
    
    return result
end


-- Battery status utilities
local function get_battery_status()
    -- Get battery info from wezterm API
    local battery = wezterm.battery_info()
    if not battery then return nil end
    
    local first_battery = battery[1]
    if not first_battery then return nil end
    
    -- Select appropriate battery symbol based on state and percentage
    local state = first_battery.state
    local percentage = first_battery.state_of_charge * 100
    
    local symbols = {
        -- Different battery levels
        full = '🌕',
        threequarters = '🌖',
        half = '🌗',
        quarter = '🍕',
        empty = '🌑',
        charging = '⚡',
    }
    
    local symbol
    local color
    
    if state == "Charging" then
        symbol = symbols.charging
        color = colors.battery.charging
    else
        if percentage >= 80 then
            symbol = symbols.full
            color = colors.battery.normal
        elseif percentage >= 60 then
            symbol = symbols.threequarters
            color = colors.battery.normal
        elseif percentage >= 40 then
            symbol = symbols.half
            color = colors.battery.normal
        elseif percentage >= 20 then
            symbol = symbols.quarter
            color = colors.battery.low
        else
            symbol = symbols.empty
            color = colors.battery.critical
        end
    end
    
    return {
        symbol = symbol,
        percentage = math.floor(percentage),
        color = color,
    }
end

-- Status bar setup
wezterm.on("update-right-status", function(window, _)
    local SOLID_LEFT_ARROW = ""
    local ARROW_FOREGROUND = { Foreground = { Color = colors.bg.solidblack } }
    local prefix = "" 

    if window:leader_is_active() then
        prefix = " " .. "🪄✨"
        SOLID_LEFT_ARROW = colors.arrow.left
    end

    if window:mux_window():active_tab():tab_id() ~= 0 then
        ARROW_FOREGROUND = { Foreground = { Color = colors.bg.tabpanel } }
    end
    window:set_left_status(wezterm.format {
        { Background = { Color = colors.status.bg1 } },
        { Text = prefix },
        ARROW_FOREGROUND,
        { Text = SOLID_LEFT_ARROW }
    })
    
    -- Right status
    local pane = window:mux_window():active_tab():active_pane()
    local cwd = pane:get_current_working_dir().file_path:gsub("^" .. os.getenv("HOME"), "~")
    cwd = format_path(cwd)
    
    local date = wezterm.strftime('%b %d, %a')
    local time = wezterm.strftime('%H:%M')
    
    local elements = {
        { Foreground = { Color = colors.status.bg1 } },
        { Text = colors.arrow.left },
        { Foreground = { Color = colors.status.fg } },
        { Background = { Color = colors.status.bg1 } },
        { Text = ' ' .. cwd .. ' ' },
        { Foreground = { Color = colors.status.bg2 } },
        { Text = colors.arrow.left },
        { Foreground = { Color = colors.status.fg } },
        { Background = { Color = colors.status.bg2 } },
        { Text = ' ' .. date .. ' ' },
        { Foreground = { Color = colors.status.bg3 } },
        { Text = colors.arrow.left },
        { Foreground = { Color = colors.status.fg } },
        { Background = { Color = colors.status.bg3 } },
        { Text = ' ' .. time .. ' ' },
    }

    -- Add battery status if available
    local battery = get_battery_status()
    if battery then
        table.insert(elements, { Foreground = { Color = battery.color } })
        table.insert(elements, { Text = colors.arrow.left })
        table.insert(elements, { Foreground = { Color = colors.status.fg } })
        table.insert(elements, { Background = { Color = battery.color } })
        table.insert(elements, { Text = string.format(' %s %d%% ', battery.symbol, battery.percentage) })
    end
    
    window:set_right_status(wezterm.format(elements))
end)

-- Initialize configuration
config = setup_appearance(config)
config = setup_keybindings(config)

return config
