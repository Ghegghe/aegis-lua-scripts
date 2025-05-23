script_name        = "Whispers"
script_description = "Get audio transcription"
script_author      = "Ghegghe"
script_version     = "0.1.1"
script_namespace   = "ghe.Whispers"

local DependencyControl = require("l0.DependencyControl")
local version = DependencyControl{
    feed = "https://raw.githubusercontent.com/Ghegghe/aegis-lua-scripts/main/DependencyControl.json",
	{
		"json"
	}
}

local json = require("json")
local pathsep = package.config:sub(1,1)
local is_windows = (pathsep == "\\")

local python_cmd = is_windows and "python" or "python3"
local ass_whispers_cmd = python_cmd .. " -m ass_whispers"
local ass_whispers_compatible_version = "0.1.5"

local timestamp_file_name = ".timestamps.json"
local config_file_name = "ghe.Whispers.json"

local default_config = {
	model = "large-v2",
	device = "cuda",
	compute_type = "float32",
	language = "ja",
	temperature = 0.4,
	best_of = 8,
	beam_size = 10,
	patience = 2,
	repetition_penalty = 1.4,
	condition_on_previous_text = false,
	no_speech_threshold = 0.275,
	log_prob_threshold = -1,
	compression_ratio_threshold = 1.75,
	word_timestamps = true,
	vad_filter = true,
	-- vad_method = "pyannote_v3",
	-- sentence = true,
	-- standard_asia = true,
}

local function get_python_version()
    local handle = io.popen(python_cmd .. " --version 2>&1")
    local result = handle:read("*a")
    handle:close()

    local major, minor, patch = result:match("Python (%d+)%.(%d+)%.?(%d*)")
    if major and minor then
        return tonumber(major), tonumber(minor), tonumber(patch) or 0
    else
        return nil
    end
end

local function get_ass_whispers_version()
    local handle = io.popen(ass_whispers_cmd .. " --version 2>&1")
    local result = handle:read("*a"):gsub("\n", "")
    handle:close()
	if not result:match("^%d+%.%d+%.%d+$") then
		return nil
	end
    return result
end

local function validate_ass_whispers_version(ass_whispers_version)
	local major1, minor1, patch1 = ass_whispers_version:match("(%d+)%.(%d+)%.(%d+)")
	local major2, minor2, patch2 = ass_whispers_compatible_version:match("(%d+)%.(%d+)%.(%d+)")
	return not (major1 < major2 or minor1 < minor2 or patch1 < patch2)
end

local function install_ass_whispers()
	local install_cmd = string.format('%s -m pip install ass-whispers==%s', python_cmd, ass_whispers_compatible_version)
	os.execute(install_cmd)
end

local function run_detached_script(script)
	if is_windows then
		local cmd = string.format('start cmd /k "%s"', script)
		os.execute(cmd)
		return
	else
		local sysname = io.popen('uname 2>/dev/null'):read('*l') or ''

		if sysname == 'Linux' then
			local handle = io.popen('which gnome-terminal')
			local gnome_terminal = handle:read('*l')
			handle:close()
	
			if gnome_terminal and gnome_terminal ~= '' then
				os.execute(string.format('gnome-terminal -- bash -c "%s; exec bash"', script))
			else
				handle = io.popen('which xterm')
				local xterm = handle:read('*l')
				handle:close()
				if xterm and xterm ~= '' then
					os.execute(string.format('xterm -hold -e "%s"', script))
				else
					print('Errore: nessun terminale grafico disponibile (gnome-terminal o xterm)')
				end
			end
		elseif sysname == 'Darwin' then
			local apple_script = string.format([[
				tell application "Terminal"
					do script "%s; exec bash"
					activate
				end tell
			]], script)
			local escaped_script = apple_script:gsub('\n', ' '):gsub('"', '\\"')
			os.execute(string.format('osascript -e "%s"', escaped_script))
		end
	end
end

local function read_json(path)
	local file = io.open(path, "r")
	local obj
    if file ~= nil then
		obj = json.decode(file:read("*a"))
		file:close()
		return obj
	end
	return nil
end

local function write_json(path, obj)
	local file = io.open(path, "w")
	if not file then
		return false
	end
	file:write(json.encode(obj))
	file:close()
	return true
end

local function load_config()
	local config_json = read_json(aegisub.decode_path("?user/config/" .. config_file_name))
	local config = default_config
    if config_json ~= nil then
		for k, v in pairs(config_json) do
			config[k] = v
		end
	else
		write_json(aegisub.decode_path("?user/config/" .. config_file_name), config)
	end
	return config
end

function whisper(subs, sel)
	-- check python version
	local python_major, python_minor = get_python_version()
	if not python_major then
		aegisub.cancel("Python not found.\n")
		return
	elseif not (python_major > 3 or (python_major == 3 and python_minor >= 9)) then
		aegisub.cancel("Python version 3.9 or greater is required.\n")
		return
	end
	
	-- check ass-whispers
	local ass_whispers_version = get_ass_whispers_version()
	if not ass_whispers_version or not validate_ass_whispers_version(ass_whispers_version) then
		if not ass_whispers_version then
			aegisub.debug.out("Ass-whispers not found. Installation in progress...\n")
		else
			aegisub.debug.out("Ass-whispers version " .. ass_whispers_version .. " is not compatible whith this version of the script. Installation of " .. ass_whispers_compatible_version .. " in progress...\n")
		end
		install_ass_whispers()
		if validate_ass_whispers_version(get_ass_whispers_version()) then
			aegisub.debug.out("Installation completed.\n")
		else
			aegisub.cancel("Installation of ass-whispers failed.\n")
			return
		end
	end

	-- setup variables and create temp folder
	local config = load_config()
	local audio_file = aegisub.project_properties().audio_file
	local sub_folder = aegisub.decode_path("?script")
	local timestamp_file = sub_folder .. pathsep .. timestamp_file_name
	
	if not audio_file then
		aegisub.cancel("Audio file not found")
		return
	end
	if not sub_folder then
		aegisub.cancel("Subtitle folder not found")
		return
	end

	-- save timestamps
	local file = io.open(timestamp_file, "w")
	if not file then
		aegisub.cancel("Unable to save timestamps into file.\n")
	end

	file:write("[\n")
	for index, i in ipairs(sel) do
        local line = subs[i]
		local start_time = line.start_time
		local end_time = line.end_time

		local line = string.format("  {\"start_time\": %d, \"end_time\": %d}", start_time, end_time)
		if index < #sel then
			line = line .. ","
		end
		file:write(line .. "\n")
    end
	file:write("]\n")
	file:close()

	-- call python for transcription
	local cmd = ass_whispers_cmd .. " " .. string.format("%q", audio_file) .. " " .. string.format("%q", timestamp_file)
	for k, v in pairs(config) do
		if type(v) == "boolean" and v then
			cmd = cmd .. " --" .. k
		elseif type(v) == "number" then
			cmd = cmd .. " --" .. k .. " " .. tostring(v)
		elseif type(v) == "string" and v ~= "" then
			cmd = cmd .. " --" .. k .. " " .. v
		end
	end
	run_detached_script(cmd)
	
    aegisub.set_undo_point(script_name)
end

function whispers_config()
	local config = load_config()

	local whisper_config_gui = {
		{class="label", label="Whisper Model Settings", x=0, y=0, width=2},
	
		{class="label", label="Model:", x=0, y=1},
		{class="edit", name="model", value=config.model, x=1, y=1},
	
		{class="label", label="Device:", x=0, y=2},
		{class="dropdown", name="device", items={"cpu", "cuda", "auto"}, value=config.device, x=1, y=2},
	
		{class="label", label="Compute Type:", x=0, y=3},
		{class="edit", name="compute_type", value=config.compute_type, x=1, y=3},
	
		{class="label", label="Language (optional):", x=0, y=4},
		{class="edit", name="language", value=config.language, x=1, y=4},
	
		{class="label", label="Temperature:", x=0, y=5},
		{class="edit", name="temperature", value=config.temperature, x=1, y=5},
	
		{class="label", label="Best Of:", x=0, y=6},
		{class="intedit", name="best_of", value=config.best_of, x=1, y=6},
	
		{class="label", label="Beam Size:", x=0, y=7},
		{class="intedit", name="beam_size", value=config.beam_size, x=1, y=7},
	
		{class="label", label="Patience:", x=0, y=8},
		{class="floatedit", name="patience", value=config.patience, x=1, y=8},
	
		{class="label", label="Repetition Penalty:", x=0, y=9},
		{class="floatedit", name="repetition_penalty", value=config.repetition_penalty, x=1, y=9},
	
		{class="checkbox", name="condition_on_previous_text", label="Condition on previous text", value=config.condition_on_previous_text, x=0, y=10, width=2},
		{class="checkbox", name="word_timestamps", label="Word timestamps", value=config.word_timestamps, x=0, y=11, width=2},
		{class="checkbox", name="vad_filter", label="VAD filter", value=config.vad_filter, x=0, y=12, width=2},
	
		{class="label", label="No speech threshold (optional):", x=0, y=13},
		{class="edit", name="no_speech_threshold", value=config.no_speech_threshold, x=1, y=13},
	
		{class="label", label="Log prob threshold (optional):", x=0, y=14},
		{class="edit", name="log_prob_threshold", value=config.log_prob_threshold, x=1, y=14},
	
		{class="label", label="Compression ratio threshold (optional):", x=0, y=15},
		{class="edit", name="compression_ratio_threshold", value=config.compression_ratio_threshold, x=1, y=15},
	}
	
	local buttons = {"OK", "Cancel"}
	
	local pressed, input = aegisub.dialog.display(whisper_config_gui, buttons)
	
	if pressed == "OK" then
		if input.model then
			config.model = input.model
		end
		if input.device then
			config.device = input.device
		end
		if input.compute_type then
			config.compute_type = input.compute_type
		end
		if input.temperature then
			config.temperature = input.temperature
		end
		if input.best_of then
			config.best_of = input.best_of
		end
		if input.beam_size then
			config.beam_size = input.beam_size
		end
		if input.patience then
			config.patience = input.patience
		end
		if input.repetition_penalty then
			config.repetition_penalty = input.repetition_penalty
		end
		if input.condition_on_previous_text then
			config.condition_on_previous_text = input.condition_on_previous_text
		end
		if input.word_timestamps then
			config.word_timestamps = input.word_timestamps
		end
		if input.vad_filter then
			config.vad_filter = input.vad_filter
		end

		if not write_json(aegisub.decode_path("?user/config/" .. config_file_name), config) then
			aegisub.cancel("Unable to open file for writing: " .. aegisub.decode_path("?user/config/" .. config_file_name))
		end
	end
end

version:registerMacros{
    {"Whispers", "Transcribe selected lines", whisper},
    {"Whispers config", "Open configuration file", whispers_config}
}