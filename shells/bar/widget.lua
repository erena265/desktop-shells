local astal = require("astal")
local Widget = require("astal.gtk3.widget")
local Variable = astal.Variable
local GLib = astal.require("GLib")
local bind = astal.bind
local Mpris = astal.require("AstalMpris")
local Battery = astal.require("AstalBattery")
local Wp = astal.require("AstalWp")
local Network = astal.require("AstalNetwork")
local Tray = astal.require("AstalTray")
local Hyprland = astal.require("AstalHyprland")
local map = require("lib").map

local function SysTray()
    local tray = Tray.get_default()

    return Widget.Box({
        class_name = "SysTray",
        bind(tray, "items"):as(function(items)
            return map(items, function(item)
                return Widget.MenuButton({
                    tooltip_markup = bind(item, "tooltip_markup"),
                    use_popover = false,
                    menu_model = bind(item, "menu-model"),
                    action_group = bind(item, "action-group"):as(
                        function(ag) return { "dbusmenu", ag } end
                    ),
                    Widget.Icon({
                        gicon = bind(item, "gicon"),
                    }),
                })
            end)
        end),
    })
end

local function FocusedClient()
    local hypr = Hyprland.get_default()
    local focused = bind(hypr, "focused-client")

    return Widget.Box({
        class_name = "Focused",
        visible = focused,
        focused:as(
            function(client)
                return client
                    and Widget.Label({
                        label = bind(client, "title"):as(tostring),
                    })
            end
        ),
    })
end

local function Wifi()
    local network = Network.get_default()
    local wifi = bind(network, "wifi")

    return Widget.Box({
        visible = wifi:as(function(v) return v ~= nil end),
        wifi:as(
            function(w)
                return Widget.Icon({
                    tooltip_text = bind(w, "ssid"):as(tostring),
                    class_name = "Wifi",
                    icon = bind(w, "icon-name"),
                })
            end
        ),
    })
end

local function AudioSlider()
    local speaker = Wp.get_default().audio.default_speaker

    return Widget.Box({
        class_name = "AudioSlider",
        css = "min-width: 140px;",
        Widget.Icon({
            icon = bind(speaker, "volume-icon"),
        }),
        Widget.Slider({
            hexpand = true,
            on_dragged = function(self) speaker.volume = self.value end,
            value = bind(speaker, "volume"),
        }),
    })
end

local function BatteryLevel()
    local bat = Battery.get_default()

    if not bat.is_present then
        return nil
    end

    return Widget.Box({
        class_name = "Battery",
        visible = bind(bat, "is-present"),
        Widget.Icon({
            icon = bind(bat, "battery-icon-name"),
        }),
        Widget.Label({
            label = bind(bat, "percentage"):as(
                function(p) return tostring(math.floor(p * 100)) .. " %" end
            ),
        }),
    })
end

local function Media()
    local player = Mpris.Player.new("spotify")

    return Widget.Box({
        class_name = "Media",
        visible = bind(player, "available"),
        Widget.Box({
            class_name = "Cover",
            valign = "CENTER",
            css = bind(player, "cover-art"):as(
                function(cover)
                    return "background-image: url('" .. (cover or "") .. "');"
                end
            ),
        }),
        Widget.Label({
            label = bind(player, "metadata"):as(
                function()
                    return (player.title or "")
                        .. " - "
                        .. (player.artist or "")
                end
            ),
        }),
    })
end

local function Workspaces()
    local hypr = Hyprland.get_default()

    return Widget.Box({
        class_name = "Workspaces",
        bind(hypr, "workspaces"):as(function(wss)
            table.sort(wss, function(a, b) return a.id < b.id end)

            return map(wss, function(ws)
                if not (ws.id >= -99 and ws.id <= -2) then -- filter out special workspaces
                    return Widget.Button({
                        class_name = bind(hypr, "focused-workspace"):as(
                            function(fw) return fw == ws and "focused" or "" end
                        ),
                        on_clicked = function() ws:focus() end,
                        label = bind(ws, "id"):as(
                            function(v)
                                return type(v) == "number"
                                    and string.format("%.0f", v)
                                    or v
                            end
                        ),
                    })
                end
            end)
        end),
    })
end

local function Time(format)
    local time = Variable(""):poll(
        1000,
        function() return GLib.DateTime.new_now_local():format(format) end
    )

    return Widget.Label({
        class_name = "Time",
        on_destroy = function() time:drop() end,
        label = time(),
    })
end

---@class GdkMonitor
---@field get_geometry fun(): Geometry
---@field get_model fun(): string
---@field get_scale_factor fun(): number
---@field get_refresh_rate fun(): number
---@field is_primary fun(): boolean

---@class Geometry
---@field width number
---@field height number
---@field x number
---@field y number

---@class WindowAnchor
---@field LEFT number
---@field RIGHT number
---@field TOP number
---@field BOTTOM number

---@param gdkmonitor GdkMonitor
---@return number anchor
local function GetAnchor(gdkmonitor)
    ---@class WindowAnchor
    local anchor = astal.require("Astal").WindowAnchor
    local geometry = gdkmonitor:get_geometry()

    print(string.format("gdkmonitor:get_model():  %s", gdkmonitor:get_model()))
    print(string.format("gdkmonitor:get_geometry(): width = %d, height = %d, x = %d, y = %d", geometry.width,
        geometry.height, geometry.x, geometry.y))
    print(string.format("gdkmonitor:get_scale_factor(): %d", gdkmonitor:get_scale_factor()))
    print(string.format("gdkmonitor:get_refresh_rate(): %d", gdkmonitor:get_refresh_rate()))
    print(string.format("gdkmonitor:is_primary(): %s", gdkmonitor:is_primary()))
    print("---")

    if geometry.width > geometry.height then
        return anchor.LEFT + anchor.BOTTOM + anchor.TOP
    else
        return anchor.TOP + anchor.LEFT + anchor.RIGHT
    end
end

return function(gdkmonitor)
    return Widget.Window({
        class_name = "Bar",
        gdkmonitor = gdkmonitor,
        anchor = GetAnchor(gdkmonitor),
        exclusivity = "EXCLUSIVE",
        Widget.CenterBox({
            vertical = true,
            Widget.Box({
                halign = "START",
                Workspaces(),
                FocusedClient(),
            }),
            Widget.Box({
                Media(),
            }),
            Widget.Box({
                halign = "END",
                SysTray(),
                Wifi(),
                AudioSlider(),
                BatteryLevel(),
                Time("%H:%M - %A %e."),
            }),
        }),
    })
end
