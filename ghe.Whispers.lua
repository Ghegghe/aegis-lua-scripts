--[[
Script: Whispers
Descrizione: Estrae un clip audio con FFmpeg, lo passa a Whisper e salva la trascrizione nella linea.
Autore: Ghegghe
Versione: 1.0.0
Namespace: ghe.Whispers
]]

script_name        = "Whispers"
script_description = "Get audio transcription"
script_author      = "Ghegghe"
script_version     = "1.0.0"
script_namespace   = "ghe.Whispers"

local pathsep = package.config:sub(1,1)

-- -- whisper string
local whisper_string = "faster-whisper-xxl.exe -m large-v2 -d cuda --compute_type \"float32\" --task transcribe --language ja --temperature 0.4 --best_of 8 --beam_size 10 --patience 2 --repetition_penalty 1.4 --condition_on_previous_text False --no_speech_threshold 0.275 --logprob_threshold -1 --compression_ratio_threshold 1.75 --word_timestamp True --vad_filter True --vad_method pyannote_v3 --sentence --standard_asia"

function whisper(subs, sel)
	local audio_file = aegisub.project_properties().audio_file
	local sub_folder = aegisub.decode_path("?script")
	
	if not audio_file or not sub_folder then
		aegisub.cancel("Audio file or subtitle folder not found")
		return
	end

    for _, i in ipairs(sel) do
        local line = subs[i]

		-- calculate start and end time in seconds
		local start_time = line.start_time / 1000
		local end_time = line.end_time   / 1000

		-- extract clip with FFmpeg without re-encoding
		local clip = string.format("clip_%d.wav", i)
		local ffcmd = string.format(
			'ffmpeg -y -i "%s" -map 0:a:0 -ss %.3f -to %.3f -acodec pcm_s16le -ar 44100 -ac 2 "%s" 2>&1',
			audio_file, start_time, end_time, sub_folder .. pathsep .. clip
		)
		local handle = io.popen(ffcmd)
		local result = handle:read("*a")
		handle:close()

		-- -- call Whisper on the clip and capture output
		local cmd = string.format('%s "%s"', whisper_string, sub_folder .. pathsep .. clip)
		local handle = io.popen(cmd)
		local result = handle:read("*a")
		handle:close()

		-- clean up the output from new lines
		for line in result:gmatch("[^\r\n]+") do
			if line:match("^%[.+%]") then
				aegisub.debug.out(line)
			end
		end

		-- update the line text
		-- line.text = result
		-- subs[i] = line

		-- remove the temporary file
		os.remove(sub_folder .. pathsep .. clip)
    end
    aegisub.set_undo_point(script_name)
end

aegisub.register_macro(script_name, script_description, whisper)
