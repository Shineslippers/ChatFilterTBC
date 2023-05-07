-- List of gold spam keywords
local keywords = { "%$", "buy", "bonus", "cheap", "code", "coupon", "customer", "deal", "deliver", "delivery", "discount", "express", "fast", "free", "gift", "gold",
				   "iphone", "low", "lowest", "order", "price", "promotion", "safe", "sale", "save", "service", "win", "www", "%.com", "%.net", "%.org" }

-- Keyword threshold to trigger the filter
local threshold = 4

-- Saved variables
-- local ChatFilter_filterGold = false
ChatFilter_filterCustom = false
ChatFilter_filterIcons = false
ChatFilter_filterDuplicates = false
ChatFilter_verbose = false

-- Other variables
ChatFilter_alternativekeywords = {}
local messageLog = {}
local lastMessage = 0
local prevMessage

local function insensitivePattern(pattern)

  -- find an optional '%' (group 1) followed by any character (group 2)
  local p = pattern:gsub("(%%?)(.)", function(percent, letter)

    if percent ~= "" or not letter:match("%a") then
      -- if the '%' matched, or `letter` is not a letter, return "as is"
      return percent .. letter
    else
      -- else, return a case-insensitive character class of the matched letter
      return string.format("[%s%s]", letter:lower(), letter:upper())
    end

  end)

  return p
end

-- ChatFilter_AddLog() - Add a message to the log
function ChatFilter_AddLog(msg)
	-- Display a message if verbose is enabled (throttle it to 1 notification every 10 seconds)
	if ChatFilter_verbose and lastMessage + 10 <= GetTime() then
		print("|cff00ff00Chat Filter:|r Filtered a message") 
		lastMessage = GetTime()
	end
	
	-- Only add the message if it isn't already in the log
	-- local message = format("[%s]: %s", msg)
	if not tContains(messageLog, msg) then
		table.insert(messageLog, msg)
	end
	
	-- Remove old messages if the log has more than 10 messages
	if #messageLog > 10 then
		table.remove(messageLog, 0)
	end
end

-- ChatFilter_DisplayLog() - Display the last 10 filtered messages
function ChatFilter_DisplayLog()
	if #messageLog == 0 then
		print("|cff00ff00Chat Filter:|r The message log is empty")
	else
		print("|cff00ff00Chat Filter:|r Displaying the last", #messageLog, "messages")
		for k,v in pairs(messageLog) do
			print(v)
		end
	end
end

-- ChatFilter() - Used to filter chat messages
function ChatFilter_MainFunction(self, ...)
	
	-- Manual filter
	if ChatFilter_filterCustom then
		-- Search the message for specific keywords
		for k,v in pairs(ChatFilter_alternativekeywords) do 
			if string.find(self, insensitivePattern(v)) ~= nil then
				ChatFilter_AddLog(self)
				return true
			end
		end
	end

	-- Duplicate filter
	if ChatFilter_filterDuplicates then
		if prevMessage == self then
			return true
		end
		prevMessage = self
	end
--[[	-- Gold spam filter
	if ChatFilter_filterGold then
		local temp = strlower(self)
		local count = 0
		
		-- Search the message for specific keywords
		for i = 1, #keywords do
			if temp:find(keywords[i]) then
				count = count + 1
			end
		end

		-- Check if the message is over the keyword threshold
		if count >= threshold then
			ChatFilter_AddLog(self)
			return true
		end
	end]]
	-- Raid icon filter
	if ChatFilter_filterIcons then
		local term;
		for tag in string.gmatch(self, "%b{}") do
			term = strlower(string.gsub(tag, "[{}]", ""))
			if ICON_TAG_LIST[term] and ICON_LIST[ICON_TAG_LIST[term]] then
				self = gsub(self, tag, "")
			end
		end
		return false, self
	end

	return false
end

-- Chat filter event hooks
ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", ChatFilter_MainFunction)
ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", ChatFilter_MainFunction)
ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", ChatFilter_MainFunction)
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", ChatFilter_MainFunction)
ChatFrame_AddMessageEventFilter("CHAT_MSG_EMOTE", ChatFilter_MainFunction)
ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", ChatFilter_MainFunction)

-- Slash command handler
SLASH_CHATFILTER1, SLASH_CHATFILTER2 = "/chatfilter", "/cf"
SlashCmdList["CHATFILTER"] = function(msg)

--[[	if msg:lower() == "gold" then
		ChatFilter_filterGold = not ChatFilter_filterGold
		print(ChatFilter_filterGold and "|cff00ff00Gold|r filter enabled" or "|cff00ff00Gold|r filter disabled")]]	
	if msg:lower() == "custom" then
		ChatFilter_filterCustom = not ChatFilter_filterCustom
		print(ChatFilter_filterCustom and "|cff00ff00Custom|r filter enabled" or "|cff00ff00Custom|r filter disabled")
	elseif string.match(msg:lower(), "add (.+)") ~= nil then
		local addthisfilter = msg:gsub("add ", ""):gsub("[%W]", "%%%1")
		table.insert(ChatFilter_alternativekeywords, addthisfilter)
		print("|cff00ff00Chat Filter:|r added |cffffa500"..addthisfilter:gsub("%%", "").."|r to list")
	elseif string.match(msg:lower(), "remove (.+)") ~= nil then
		local removethisfilter = msg:gsub("remove ", "")
		if string.match(removethisfilter, "(%d+)") ~= nil then 
			removethisfilter = tonumber(removethisfilter)
			local getNumber = 0
			for k,v in pairs(ChatFilter_alternativekeywords) do 
				getNumber = getNumber + 1
			end
			if getNumber >= removethisfilter then
				print("|cff00ff00Chat Filter:|r removed |cffffa500"..ChatFilter_alternativekeywords[removethisfilter]:gsub("%%", "").."|r from list")
				table.remove(ChatFilter_alternativekeywords, removethisfilter)
			else
				print("|cff00ff00Chat Filter:|r there is no such number as |cffffa500"..removethisfilter.."|r in custom list. Check out /cf list again")
			end
			return
		else
			for k,v in pairs(ChatFilter_alternativekeywords) do
				if insensitivePattern(v:gsub("%%", "")) == insensitivePattern(removethisfilter) then
					print("|cff00ff00Chat Filter:|r removed |cffffa500"..removethisfilter.."|r from list")
					table.remove(ChatFilter_alternativekeywords, k)
					return
				end
			end
			print("|cff00ff00Chat Filter:|r there is no such filter as |cffffa500"..removethisfilter.."|r in list. Check out /cf list again")
		end
	elseif msg:lower() == "list" then
		print("|cff00ff00Chat Filter:|r List of added word(s) to filter")
		print("--------------------------------------------------------")
		for k,v in pairs(ChatFilter_alternativekeywords) do
			print("["..k.."]"..v:gsub("%%", ""))
		end
		print("--------------------------------------------------------")
	elseif msg:lower() == "icon" or msg:lower() == "icons" then
		ChatFilter_filterIcons = not ChatFilter_filterIcons
		print(ChatFilter_filterIcons and "|cff00ff00Icons|r filter enabled" or "|cff00ff00Icons|r filter disabled")
	elseif msg:lower() == "dup" or msg:lower() == "duplicates" then
		ChatFilter_filterDuplicates = not ChatFilter_filterDuplicates
		print(ChatFilter_filterDuplicates and "|cff00ff00Duplicates|r filter enabled" or "|cff00ff00Duplicates|r filter disabled")
	elseif msg:lower() == "verbose" then
		ChatFilter_verbose = not ChatFilter_verbose
		if ChatFilter_verbose then
			print("|cff00ff00Chat Filter:|r Showing a notification whenever a message is filtered")
		else
			print("|cff00ff00Chat Filter:|r Silently filtering gold spam messages")
		end
		print(ChatFilter_verbose and "Showing a notification whenever a message is filtered" or "Silently filtering gold spam messages")
	elseif msg:lower() == "log" then
		ChatFilter_DisplayLog()	
	else
		print("|cff00ff00Chat Filter|r list of commands:")
--		print("-------------------------")
--		print(ChatFilter_filterGold and "|cff00ff00[Enabled]|r Gold spammers filter" or "|cff800000[Disabled]|r Gold spammers filter")
--		print("Gold: gold spammer filter")
--		print("-- /cf gold")
		print("-------------------------")
		print(ChatFilter_filterCustom and "|cff00ff00[Enabled]|r Custom filter. To add word(s) use different command" or "|cff800000[Disabled]|r Custom filter. To add word(s) use different command")
		print("-- /cf custom")
		print("-------------------------")
		print("Add word(s) to custom filter")
		print("-- /cf add word(s)")
		print("-------------------------")
		print("Remove word(s) from custom filter. Use /cf showfilters to get IDs ")
		print("-- /cf remove word(s)")		
		print("-------------------------")
		print("Show active custom list")
		print("-- /cf list")		
		print("-------------------------")		
		print(ChatFilter_filterIcons and "|cff00ff00[Enabled]|r Raid icons filter" or "|cff800000[Disabled]|r Raid icons filter")
		print("-- /cf icons")
		print("-------------------------")
		print(ChatFilter_filterDuplicates and "|cff00ff00[Enabled]|r Duplicate messages filter" or "|cff800000[Disabled]|r Duplicate messages filter")
		print("-- /cf duplicates")
		print("-------------------------")
		print(ChatFilter_verbose and "|cff00ff00[Enabled]|r Notifications of addon when something filtered" or "|cff800000[Disabled]|r Notifications of addon when something filtered")
		print("-- /cf verbose")
		print("-------------------------")
		print("Log: last 10 filtered messages")
		print("-- /cf log")
		print("-------------------------")
	end
end