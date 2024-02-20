script_name = "GlobalRotation"
script_description = "Rotate selected lines over a certain origin"
script_author = "Ghegghe"
script_version = "1.0.0"
script_namespace = "ghe.GlobalRotation"

local math = require("math")

function progress(message)
    if aegisub.progress.is_cancelled() then
        aegisub.cancel()
    end
    aegisub.progress.title(message)
end

function error(message, cancel)
    aegisub.dialog.display(
        {
            {class = "label", label = message}
        },
        {"OK"},
        {close = "OK"}
    )
    if cancel then
        aegisub.cancel()
    end
end

function round(n, dec)
    dec = dec or 0
    return math.floor(n * 10 ^ dec + 0.5) / 10 ^ dec
end

function addtag(tag, text)
    return text:gsub("^({\\[^}]-)}", "%1" .. tag .. "}")
end

function main(subs, sel)
    -- build GUI
    local groupcopyGUI = {
        {
            x = 0,
            y = 0,
            class = "label",
            label = "Origin X"
        },
        {
            x = 0,
            y = 1,
            class = "floatedit",
            name = "orgX"
        },
        {
            x = 0,
            y = 2,
            class = "label",
            label = "Origin Y"
        },
        {
            x = 0,
            y = 3,
            class = "floatedit",
            name = "orgY"
        },
        {
            x = 1,
            y = 0,
            class = "label",
            label = "Rotation"
        },
        {
            x = 1,
            y = 1,
            class = "floatedit",
            name = "frz"
        }
    }
    local press, values =
        aegisub.dialog.display(groupcopyGUI, {"Rotate", "Rotate each", "Cancel"}, {ok = "Rotate", close = "Cancel"})

    for i = 1, #subs do
        if subs[i].class == "dialogue" then
            line0 = i - 1
            break
        end
    end

    if press == "Cancel" then
        -- exit
        aegisub.cancel()
    else
        progress("Rotating lines...")
        for i = 1, #sel, 1 do
            local line = subs[sel[i]]
            local x, y = line.text:match("\\pos%(([%d.-]+),([%d.-]+)%)")
            local angle = values.frz

            if not x then
                aegisub.log("Missing pos on line: " .. sel[i] - line0 .. "\n", false)
            elseif line.text:match("\\move") then
                aegisub.log("Move not supported, line: " .. sel[i] - line0 .. "\n", false)
            else
                if press == "Rotate each" then
                    angle = i * values.frz
                end

                local radians = math.rad(angle)
                x2 = (x - values.orgX) * math.cos(radians) - (y - values.orgY) * math.sin(radians) + values.orgX
                y2 = (x - values.orgX) * math.sin(radians) + (y - values.orgY) * math.cos(radians) + values.orgY
                line.text =
                    line.text:gsub(
                    "\\pos%(([%d.-]+),([%d.-]+)%)",
                    "\\pos(" .. round(x2, 2) .. "," .. round(y2, 2) .. ")"
                )
                line.text =
                    line.text:gsub(
                    "\\frz%(([%d.-]+),([%d.-]+)%)",
                    "\\pos(" .. round(x2, 2) .. "," .. round(y2, 2) .. ")"
                )

                local z = line.text:match("\\frz([%d.-]+)")
                if z then
                    z = (z - angle) % 360
                    if z < 0 then
                        z = 360 + z
                    end
                    line.text = line.text:gsub("\\frz([%d.-]+)", "\\frz" .. round(z, 3) .. "")
                else
                    z = (0 - angle) % 360
                    if z < 0 then
                        z = 360 + z
                    end
                    line.text = addtag("\\frz" .. round(z, 3), line.text)
                end

                subs[sel[i]] = line
            end
        end
    end
end

aegisub.register_macro(script_name, script_description, main)
