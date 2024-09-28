local mod = SexyCooldown:NewModule("Buffs and Debuffs", "AceEvent-3.0", "AceBucket-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("SexyCooldown")

  -- Roll The Bones
local SPELL_ALIASES = {
  SPELL_199603 = "193316",
  SPELL_199600 = "193316",
  SPELL_193356 = "193316",
  SPELL_193357 = "193316",
  SPELL_193358 = "193316",
  SPELL_193359 = "193316"
}

local COLLAPSE_SPELLS = {
  SPELL_199603 = "193316",
  SPELL_199600 = "193316",
  SPELL_193356 = "193316",
  SPELL_193357 = "193316",
  SPELL_193358 = "193316",
  SPELL_193359 = "193316"
}

function mod:OnInitialize()
  SexyCooldown.RegisterFilter(self, "BUFFS_ON_ME",
    L["All buffs on me"],
    L["Show the duration of buffs on me on this bar"])
  SexyCooldown.RegisterFilter(self, "DEBUFFS_ON_ME",
    L["All debuffs on me"],
    L["Show the duration of my debuffs on me on this bar"])

  SexyCooldown.RegisterFilter(self, "MY_BUFFS_ON_ME",
    L["My buffs on me"],
    L["Show the duration of my buffs on me on this bar"])
  SexyCooldown.RegisterFilter(self, "MY_DEBUFFS_ON_ME",
    L["My debuffs on me"],
    L["Show the duration of debuffs on me on this bar"])

  SexyCooldown.RegisterFilter(self, "MY_FOCUS_BUFFS",
    L["My focus buffs"],
    L["Show the duration of my buffs on my focus on this bar"])
  SexyCooldown.RegisterFilter(self, "MY_FOCUS_DEBUFFS",
    L["My focus debuffs"],
    L["Show the duration of my debuffs on my focus on this bar"])

  SexyCooldown.RegisterFilter(self, "MY_TARGET_BUFFS",
    L["My target buffs"],
    L["Show the duration of my buffs on my target on this bar"])
  SexyCooldown.RegisterFilter(self, "MY_DEBUFFS",
    L["My target debuffs"],
    L["Show the duration of my debuffs on my target on this bar"])

  SexyCooldown.RegisterFilter(self, "ALL_TARGET_BUFFS",
    L["All target buffs"],
    L["Show the duration of all buffs on my target on this bar"])
  SexyCooldown.RegisterFilter(self, "ALL_TARGET_DEBUFFS",
    L["All target debuffs"],
    L["Show the duration of all debuffs on my target on this bar"])
end

function mod:OnEnable()
  self:RegisterBucketEvent("UNIT_AURA", 0.1, "UNIT_AURA")
  self:RegisterEvent("PLAYER_TARGET_CHANGED", "Refresh")
  self:RegisterEvent("PLAYER_FOCUS_CHANGED", "Refresh")
  self:Refresh()
end

function mod:Refresh()
  self:UpdateUnit("player")
  self:UpdateUnit("target")
  self:UpdateUnit("focus")
end

local function showBuffHyperlink(frame, unit, id, filter)
  GameTooltip:SetUnitAura(unit, id, filter)
end

function mod:UNIT_AURA(units)
  for unit in pairs(units) do
    self:UpdateUnit(unit)
  end
end

do
  local tmp = {}
  local existingBuffs = {}

  local function getuid(unit, uidstr, name, icon)
    return unit .. ":" .. uidstr .. ":" .. name .. ":" .. icon
  end

  local function check(unit, uidstr, filter, func, funcFilter, filterSource)
    if not SexyCooldown:IsFilterRegistered(filter) then return end

    local buffs = existingBuffs[unit]
    local name, rank, icon, count, debuffType, duration, expirationTime, source, index, id
    index = 1

    for i = 1, 10 do
      auraData = C_UnitAuras.GetBuffDataByIndex("player",i)
      if auraData.duration > 0 then
        print(auraData.name , auraData.duration)
      end
    end
    --[[ for key, value in pairs(auraData) do
      print("Key:", key, "Value:", value)
    end ]]

    while true do
      --name, icon, count, debuffType, duration, expirationTime, source, _, _, id = func(unit, index)
      
      local auraData = func(unit, index)      

       -- if not auraData.name then
        if not auraData then
          print("----------------break ")
          break
        end

        print(index , " - " ,auraData.name, " ", auraData.icon , " ", auraData.duration)

        local altID = SPELL_ALIASES["SPELL_" .. (auraData.id or "none")]
        
        -- Handle Roll The Bones
        if auraData.altID then
          count = 0
          name, rank, icon, _ = GetSpellInfo(auraData.altID)
          for i = 1, 128 do
            local auraData = func(unit, i)
            if not auraData.name then break end
            if COLLAPSE_SPELLS["SPELL_" .. (auraData.auraID or "none")] == altID then
              count = count + 1
            end
          end
        end

        local filterValid = filterSource == nil or filterSource and source and UnitIsUnit(filterSource, auraData.source)

        if auraData.duration > 0 and filterValid then
          local uid = getuid(unit, uidstr, name, icon)

          SexyCooldown:AddItem(uid, name, icon, expirationTime - duration, duration, count, filter, showBuffHyperlink, unit, index, funcFilter)
          buffs[uid] = true
          tmp[uid] = nil
        end
        index = index + 1

    end
  end

  function mod:UpdateUnit(unit)
    if unit ~= "player" and unit ~= "target" and unit ~= "focus" then return end

    wipe(tmp)
    existingBuffs[unit] = existingBuffs[unit] or {}
    local buffs = existingBuffs[unit]
    for k, v in pairs(buffs) do
      tmp[k] = v
    end
    wipe(buffs)

    --[[ OLD
    local name, rank, icon, count, debuffType, duration, expirationTime, source, index
    if unit == "player" then
      check(unit, "buff", "BUFFS_ON_ME", UnitBuff, "HELPFUL")
      check(unit, "debuff", "DEBUFFS_ON_ME", UnitDebuff, "HARMFUL")

      check(unit, "buff", "MY_BUFFS_ON_ME", UnitBuff, "HELPFUL", "player")
      check(unit, "debuff", "MY_DEBUFFS_ON_ME", UnitDebuff, "HARMFUL", "player")
    elseif unit == "target" then
      check(unit, "buff", "ALL_TARGET_BUFFS", UnitBuff, "HELPFUL")
      check(unit, "debuff", "ALL_TARGET_DEBUFFS", UnitDebuff, "HARMFUL")

      check(unit, "buff", "MY_TARGET_BUFFS", UnitBuff, "HELPFUL", "player")
      check(unit, "debuff", "MY_DEBUFFS", UnitDebuff, "HARMFUL", "player")
    elseif unit == "focus" then
      check(unit, "buff", "MY_FOCUS_BUFFS", UnitBuff, "HELPFUL", "player")
      check(unit, "debuff", "MY_FOCUS_DEBUFFS", UnitDebuff, "HARMFUL", "player")
    end
    ]]

    local name, rank, icon, count, debuffType, duration, expirationTime, source, index
    if unit == "player" then
      check(unit, "buff", "BUFFS_ON_ME", C_UnitAuras.GetBuffDataByIndex , "HELPFUL")
      check(unit, "debuff", "DEBUFFS_ON_ME", C_UnitAuras.GetDebuffDataByIndex, "HARMFUL")

      check(unit, "buff", "MY_BUFFS_ON_ME", C_UnitAuras.GetBuffDataByIndex , "HELPFUL", "player")
      check(unit, "debuff", "MY_DEBUFFS_ON_ME", C_UnitAuras.GetDebuffDataByIndex, "HARMFUL", "player")
    elseif unit == "target" then
      check(unit, "buff", "ALL_TARGET_BUFFS", C_UnitAuras.GetBuffDataByIndex , "HELPFUL")
      check(unit, "debuff", "ALL_TARGET_DEBUFFS", C_UnitAuras.GetDebuffDataByIndex, "HARMFUL")

      check(unit, "buff", "MY_TARGET_BUFFS", C_UnitAuras.GetBuffDataByIndex , "HELPFUL", "player")
      check(unit, "debuff", "MY_DEBUFFS", C_UnitAuras.GetDebuffDataByIndex, "HARMFUL", "player")
    elseif unit == "focus" then
      check(unit, "buff", "MY_FOCUS_BUFFS", C_UnitAuras.GetBuffDataByIndex , "HELPFUL", "player")
      check(unit, "debuff", "MY_FOCUS_DEBUFFS", C_UnitAuras.GetDebuffDataByIndex, "HARMFUL", "player")
    end

    for k, v in pairs(tmp) do
      SexyCooldown:RemoveItem(k)
    end
  end
end
