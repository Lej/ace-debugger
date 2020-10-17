local AceDebugger = LibStub("AceAddon-3.0"):NewAddon("AceDebugger", "AceConsole-3.0", "AceHook-3.0")
local AceGUI = LibStub("AceGUI-3.0")

local gui = nil

function AceDebugger:OnInitialize()
  self.gui = self:CreateGui()
  self:RegisterChatCommand("ad", "ChatCommand")
end

function AceDebugger:ChatCommand(command)

  local parts = {}
  for part in string.gmatch(command, "%S+") do
    parts[#parts + 1] = part
  end

  if parts[1] == "hook" and type(parts[2]) == "string" then
    self:ChatCommandHook(parts[2])
  elseif parts[1] == "unhook" then
    self:ChatCommandUnhook()
  elseif parts[1] == "list" then
    self:ChatCommandList()
  elseif parts[1] == "show" then
    self.gui:Show()
  elseif parts[1] == "hide" then
    self.gui:Hide()
  else
    self:Print("/ad list")
    self:Print("  List addons registered in AceAddon-3.0")
    self:Print("/ad hook <addon>")
    self:Print("  Hook all functions of <addon> and start logging")
    self:Print("/ad hook <addon>")
    self:Print("  Unhook all hooked functions")
    self:Print("/ad show")
    self:Print("  Show GUI")
    self:Print("/ad hide")
    self:Print("  Hide GUI")
  end

end

function AceDebugger:CreateGui()

    local frame = AceGUI:Create("Frame")
    frame:Hide()
    frame:SetTitle("AceDebugger")
    frame:SetLayout("Fill")
    frame.statustext:Hide()
    frame.statustext:GetParent():Hide()

    local editbox = AceGUI:Create("MultiLineEditBox")
    editbox.editBox:SetMaxBytes(0)
    editbox:SetMaxLetters(0)
    editbox:SetLabel("")
    editbox:DisableButton(true)

    frame:AddChild(editbox)
    frame.editbox = editbox

    return frame
end

function AceDebugger:Log(line)
  local editbox = self.gui.editbox
  --[[
  self:Print("MAX BYTES")
  self:Print(editbox.editBox:GetMaxBytes())
  self:Print("MAX LETTERS")
  self:Print(editbox.editBox:GetMaxLetters())
  --]]
  local text = editbox:GetText()
  local newText = text .. line .. "\n"
  editbox:SetText(newText)
end

function AceDebugger:ChatCommandList()
  local names = {}
  for name, addon in LibStub("AceAddon-3.0"):IterateAddons() do
    names[#names+1] = name
  end
  table.sort(names)
  for _, name in pairs(names) do
    self:Print(name)
  end
end

function AceDebugger:ChatCommandHook(addonName)
  self:Print("Hooking " .. addonName)
  local addon = LibStub("AceAddon-3.0"):GetAddon(addonName, true)
  local type = type(addon);
  if (type ~= "table") then
    self:Print("Table expected. Got " .. type .. ".")
    return
  end
  local dump = self:Dump(addonName, addon)
  self:Log(dump)
end

function AceDebugger:ChatCommandUnhook()
  self:Print("Unhooking")
  self:UnhookAll()
end

function AceDebugger:Dump(key, value)
	t = {}
	t[#t+1] = "\n"
	t[#t+1] = key
	t[#t+1] = "#1 = {\n"
	self:DumpRecursive(value, 1, { value }, t)
	t[#t+1] = "}\n"
	return table.concat(t, "")
end

function AceDebugger:DumpRecursive(value, level, visited, t)

	for k, v in pairs(value) do
    local ks = tostring(k)
    local vs = tostring(v)
		local vType = type(v)
		if vType == "boolean" or vType == "number" or vType == "string" then
		  t[#t+1] = string.rep(' ', level)
			t[#t+1] = ks
			t[#t+1] = " = "
			t[#t+1] = vs
			t[#t+1] = "\n"
		elseif vType == "table" then

      local visitedRef = 0
      for i, maybeVisited in ipairs(visited) do
        if v == maybeVisited then
          visitedRef = i
          break
        end
      end

      if visitedRef == 0 then
        visited[#visited+1] = v
        t[#t+1] = string.rep(' ', level)
        t[#t+1] = ks
        t[#t+1] = "#"
        t[#t+1] = tostring(#visited)
        t[#t+1] = " = {\n"
        self:DumpRecursive(v, level + 1, visited, t)
        t[#t+1] = string.rep(' ', level)
        t[#t+1] = "}\n"
      else
        t[#t+1] = string.rep(' ', level)
        t[#t+1] = ks
        t[#t+1] = " = #"
        t[#t+1] = tostring(visitedRef)
        t[#t+1] = "\n"
      end

		elseif vType == "function" then
      if (v == self.Print) then
        self:Print("Skipping " .. ks)
      else
        if (self:IsHooked(value, k)) then
          self:Print("Already hooked " .. ks)
        elseif (type(k) == "string") then
          self:Print("Hooking " .. ks)
          self:Hook(value, k, function() self:Print(k .. "()") end, true)
        else
          self:Print("Failed to hook " .. ks)
        end
      end
			t[#t+1] = string.rep(' ', level)
			t[#t+1] = ks
			t[#t+1] = " = function(...)\n"
	  else
		  t[#t+1] = string.rep(' ', level)
		  t[#t+1] = ks
			t[#t+1] = " = <"
			t[#t+1] = vType
			t[#t+1] = ">\n"
		end
	end

	return t
end

