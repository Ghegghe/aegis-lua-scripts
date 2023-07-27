script_name="GroupCopy"
script_description="Copy start tags from 1 to n lines and from n to n lines"
script_author="Ghegghe"
script_version="0.3.0"
script_namespace="ghe.GroupCopy"

function table.shallowCopy(table)
	local newTable = {}
	for key, value in pairs(table) do
		newTable[ key ] = value
	end
	return newTable
end

function progress(message) 
	if aegisub.progress.is_cancelled() then 
		aegisub.cancel()
	end 
	aegisub.progress.title(message) 
end

function error(message, cancel) 
	aegisub.dialog.display({
		{class="label",label=message}
	},
	{"OK"},
	{close='OK'}) 
	if cancel then 
		aegisub.cancel()
	end 
end

-- returns an object with the "type" of the tag and his "value"
function getTypeAndValue(tag)
	local tags ={
		{name="blur", tag="\\blur"},
		{name="scale_x", tag="\\fscx"},
		{name="scale_y", tag="\\fscy"},
		{name="spacing", tag="\\fsp"},
		{name="alpha", tag="\\alpha"},
		{name="move", tag="\\move"},
		{name="fade", tag="\\fade"},
		{name="clip", tag="\\clip"},
		{name="iclip", tag="\\iclip"},
		{name="outline_x", tag="\\xbord"},
		{name="outline_y", tag="\\ybord"},
		{name="outline", tag="\\bord"},
		{name="shadow_x", tag="\\xshad"},
		{name="shadow_y", tag="\\yshad"},
		{name="shadow", tag="\\shad"},

		-- three character tags
		{name="position", tag="\\pos"},
		{name="origin", tag="\\org"},
		{name="fade_simple", tag="\\fad"},
		{name="angle", tag="\\frz"},
		{name="angle_x", tag="\\frx"},
		{name="angle_y", tag="\\fry"},
		{name="shear_x", tag="\\fax"},
		{name="shear_y", tag="\\fay"},
		{name="baseline_offset", tag="\\pbo"},

		-- two character tags
		{name="fontsize", tag="\\fs"},
		{name="align", tag="\\an"},
		{name="color1", tag="\\1c"},
		{name="color2", tag="\\2c"},
		{name="color3", tag="\\3c"},
		{name="color4", tag="\\4c"},
		{name="alpha1", tag="\\1a"},
		{name="alpha2", tag="\\2a"},
		{name="alpha3", tag="\\3a"},
		{name="alpha4", tag="\\4a"},
		{name="blur_edges", tag="\\be"},
		{name="k_sweep", tag="\\kf"},
		{name="k_bord", tag="\\ko"},
		{name="fontname", tag="\\fn"},

		-- one character tags
		{name="color", tag="\\c"},
		{name="drawing", tag="\\p"},
		{name="transform", tag="\\t"},
		{name="wrapstyle", tag="\\q"},
		{name="italic", tag="\\i"},
		{name="underline", tag="\\u"},
		{name="strikeout", tag="\\s"},
		{name="bold", tag="\\b"},
		{name="k_fill", tag="\\k"},
		{name="reset", tag="\\r"},
	}
	for key, value in ipairs(tags) do
		if tag:match("^" .. value.tag) then
			return {type=value.tag, value=tag:gsub(value.tag, "")}
		end
	end
	return nil
end

function getStartTags(stags)
	local tagObj = {}

	local iStags = 1
	local char = stags:sub(iStags, iStags)
	
	if char == "{" then
		-- if stag present
		-- jump to next char = \
		iStags = iStags + 1
		char = stags:sub(iStags, iStags)
		repeat
			-- copy the single tag
			local tag = ""
			local parenthesis = 0
			repeat
				tag = tag .. char
				if char == '(' then
					parenthesis = parenthesis + 1
				elseif char == ')' then
					parenthesis = parenthesis - 1
				end
				iStags = iStags + 1
				char = stags:sub(iStags, iStags)
			until parenthesis <= 0 and char == "\\" or char == "}"
			table.insert(tagObj, getTypeAndValue(tag))
		until char == "}"
		return tagObj
	else
		return nil
	end
end

-- groupcopy
function groupCopy(subs, sel)
	progress("GroupCopying, fetch groups...")

	-- create an array of selected lines
	local lines = {}
	for i = 1, #sel do
		lines[ i ] = subs[ sel[ i ] ]
	end

	-- get to copy lines from first group
	local iLine = 1
	local groupToGroupCount = 0
	while iLine <= #sel and (not( lines[ iLine ].comment and lines[ iLine ].text:match("--end"))) do
		iLine = iLine + 1
		-- check in case of multiple commented lines
		if iLine <= #sel and lines[ iLine ].comment and iLine > 1 and not lines[ iLine - 1 ].comment then 
			groupToGroupCount = groupToGroupCount + 1
		end
	end
	local toCopyLinesLength = iLine - 1
	iLine = iLine + 1

	-- build GUI
	local groupcopyGUI={
		{x = 0, y = 0, 
		class = "label", label="Ready to copy? lines to be copied from detected: " .. toCopyLinesLength},
		{x = 0, y = 1, 
		class = "checkbox", name = "overwrite", value = true, 
		label = "Overwrite tags", hint = "Overwrite identical tags"},
		{x = 0, y = 2, 
		class = "checkbox", name = "keepInline", value = true,
		label = "Keep inline", hint = "Keeps inline tags in the lines where tags will be copied"},
		{x = 0, y = 3, 
		class = "checkbox", name = "keep", value = true,
		label = "Keep old tags", hint = "Doesn't remove the start tags which doesn't match with new tags"},
		{x = 0, y = 4, 
		class = "checkbox", name = "transformToEndOfLine", value = true,
		label = "Transform at end of line", hint = "Copy transform tags at the end of the line"},
		{x = 0, y = 5, 
		class = "checkbox", name = "groupToGroup",
		label = "Copt tags from n to n", hint = "Copy tags from n line to n line, * x groups"},
	}
	if iLine > #sel then
		table.insert(groupcopyGUI, 
		{x = 0, y = 5, 
		class = "label", label = "It's recommended to read the flight manual first"})
	end
	local press, checkboxes = aegisub.dialog.display(
		groupcopyGUI, 
		{"Make me fly", "Bring me back to school", "Not today"},
		{ok = 'Make me fly', close = 'Not today'})

	if press == "Not today" then 
		-- exit
		aegisub.cancel()
	elseif press == "Bring me back to school" then 
		help()
	elseif iLine > #sel then
		error("Incorrectly formatted lines, it's recommended to read the flight manual first", true)
	else
		-- groupcopy
		local iToCopyLines = 1

		-- for all lines
		while iLine <= #sel and iToCopyLines <= toCopyLinesLength do
			progress("Groupcopying lines " .. iToCopyLines .. " / " .. toCopyLinesLength)

			-- find next group
			if lines[ iLine ].comment then
				-- jump to next to copy into group
				while iLine <= #sel and lines[ iLine ].comment do
					iLine = iLine + 1
				end
				-- jump to next to copy from group
				if checkboxes.groupToGroup then
					while iToCopyLines <= toCopyLinesLength and not lines[ iToCopyLines ].comment do
						iToCopyLines = iToCopyLines + 1
					end
					while iToCopyLines <= toCopyLinesLength and lines[ iToCopyLines ].comment do
						iToCopyLines = iToCopyLines + 1
					end
				end
			end
			
			if lines[ iToCopyLines ].comment then
				-- jump to next to copy from group
				while iToCopyLines <= toCopyLinesLength and lines[ iToCopyLines ].comment do
					iToCopyLines = iToCopyLines + 1
				end
				-- jump to next to copy into group
				while iLine <= #sel and not lines[ iLine ].comment do
					iLine = iLine + 1
				end
				while iLine <= #sel and lines[ iLine ].comment do
					iLine = iLine + 1
				end
			end
			
			if iLine <= #sel and iToCopyLines <= toCopyLinesLength then
				-- fetch stags
				-- [type, value]
				local toCopyTags = getStartTags(lines[ iToCopyLines ].text)
				
				-- copying tags
				while iLine <= #sel and not lines[ iLine ].comment do
					local newTags = table.shallowCopy(toCopyTags)
					local oldTags = getStartTags(lines[ iLine ].text)

					if checkboxes.keep and oldTags ~= nil then
						-- join tags
						for _, newTag in ipairs(newTags) do
							local isPresent = false
							for oldKey, oldTag in ipairs(oldTags)do
								-- replace tag if is the same
								-- transform check
								if oldTag.type == newTag.type and 
									(oldTag.type ~= "\\t" or
									(oldTag.type == "\\t" and oldTag.value == newTag.value)) then
									isPresent = true
									-- overwrite
									if checkboxes.overwrite then
										oldTags[ oldKey ].value = newTag.value
									end
								end
							end

							-- add the new tag 
							-- new tags are added after old tags by default
							if not isPresent then
								table.insert(oldTags, newTag)
							end
						end
						-- switch reference
						newTags = oldTags
					end

					-- move transforms into a new object
					local newTransforms = {}
					if checkboxes.transformToEndOfLine then
						for key = #newTags, 1, -1 do
							if newTags[ key ].type == "\\t" then
								table.insert(newTransforms, newTags[ key ])
								table.remove(newTags, key)
							end
						end
					end
					
					-- clear the line
					if checkboxes.keepInline then
						lines[ iLine ].text = lines[ iLine ].text:gsub("^{.-}", "")
					else
						lines[ iLine ].text = lines[ iLine ].text:gsub("{.-}", "")
					end

					-- copy tags
					local tags = ""
					for _, value in ipairs(newTags) do
						tags = tags .. value.type .. value.value
					end
					for key = #newTransforms, 1, -1 do
						tags = tags .. newTransforms[ key ].type .. newTransforms[ key ].value
					end
					lines[ iLine ].text = "{" .. tags .. "}" .. lines[ iLine ].text
					subs[ sel[ iLine ] ] = lines[ iLine ]
					
					iLine = iLine + 1

					-- exit for groutToGroup case
					if checkboxes.groupToGroup then
						break
					end
				end
				-- repeat with next group
				iToCopyLines = iToCopyLines + 1
			end
		end

		-- check if all lines were copied
		if iLine < #sel then
			-- more groups then copy lines
			error("There were more groups then \"to copy\" lines.\nHowever, all the " .. toCopyLinesLength .. " \"to copy\" lines were copied in the first groups")
		elseif iToCopyLines <= toCopyLinesLength then
			-- more copy lines then groups
			error("There were more \"to copy\" lines then groups.\nHowever, the first " .. iToCopyLines .. " were copied anyway")
		end

		progress("Groupcopy complete.")
	end
end

groupHelp=[[
Groupcopy
It allows you to copy all the start tag from N to N lines.
You can also check if you want to overwrite existent tags, keep inline and/or old start tags from lines on which tags will be copied.
By default, new tags will be added to the end of the old tags.
If you check the "Transform at the end of line" option, all the transforms will be moved to the end.

For make this script works, you must select all the lines from which tags will be copied, and the lines on which tags will be copied, separated at least by one commented line.
To separate the lines "to be copied from" and the lines "to be copied to", put a commented line wich only contains "--end".

This script can:
  - copy start tags from 1 to n lines * x

Example:
{\b1} (copy from)
{\fad(300,400)} (copy from)
commented lines (separator) text = ""--end
(first group of lines (1), \b will be copied here)
(first group of lines (2), \b will be copied here)
commented lines (separator)
(second group of lines (1), \fad(300,400) will be copied here)
(second group of lines (2), \fad(300,400) will be copied here)
(second group of lines (3), \fad(300,400) will be copied here)

 - copy start tags from n to n lines * x

Example:
{\b1} (copy from)
{\i1} (copy from)
commented lines (separator)
{\u1} (copy from)
{s1} (copy from)
commented lines (separator) text = ""--end
(first group of lines (1-1), \b1 will be copied here)
(first group of lines (1-2), \i1 will be copied here)
commented lines (separator)
(second group of lines (2-1), \u1 will be copied here)
(second group of lines (1-1), \s1 will be copied here)

Obviously, you can copy more than one tag for group.
Having said that, have fun.
]]

function help()
	selection = aegisub.dialog.display({
		{ width=38, height=10, class="textbox", value = groupHelp},
		{ x=39, height=10, class="label", label="GroupCopy\nversion "..script_version}
	},
	{"Close"}, 
	{close='Close'})
end

aegisub.register_macro(script_name, script_description, groupCopy)