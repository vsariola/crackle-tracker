-- title:  Crackle tracker
-- author: pestis / bC!
-- desc:   a tracker for tiny intros
-- script: lua
-- saveid: crackle

-- song memory map
ORDLEN_ADDR = 0x14004
PATREPS_ADDR = 0x14005
PATLEN_ADDR = 0x14006
TEMPO_ADDR = 0x14007
SONGST_ADDR = 0x14008
KEYDUR_ADDR = 0x14009
-- intrument 0 memory map, instr 1 at +8 addresses
WAVE_ADDR = 0x14014
OCTAVE_ADDR = 0x14015
SEMITN_ADDR = 0x14016
NOTEDUR_ADDR = 0x14017
FILL_ADDR = 0x14018
MUTE_ADDR = 0x14019
SLIDE_ADDR = 0x1401A
-- chn 0 orderlist start address, chn 1 starts at +16
ORDER_ADDR = 0x14054
-- pattern 0 start address, pattern 1 starts at +16
PATS_ADDR = 0x140A4
MEMUSED = PATS_ADDR + 16 * 16 - 0x14004 -- total bytes that need to be saved

-- labels and maximum & minimum values for editors
INSTR_LABELS = {
  "Wave",
  "Octave",
  "Semitn",
  "NoteDur",
  "Fill",
  "Mute",
  "Slide"
}
INSTR_MIN = { 0, 0, 0, 1, 0, 0, 0 }
INSTR_MAX = { 3, 7, 11, 16, 7, 1, 16 }
SONG_LABELS = {
  "OrdLen",
  "PatReps",
  "PatLen",
  "Tempo",
  "Semitn",
  "KeyDur"
}
SONG_MIN = { 1, 0, 1, 0, 0, 1 }
SONG_MAX = { 16, 16, 16, 7, 11, 16 }

-- states for the table editors (cursor x,y within the editor etc.)
orderState = {}
patsState = {}
instrState = {}
songState = {}
-- states for the buttons
saveBtn = {}
expBtn = {}
newBtn = {}
rewindBtn = {}
playBtn = {}
stopBtn = {}

playing = false
tabOrder = { instrState, orderState, patsState, songState }
focus = nil
dialog = nil
tooltip = {}
t = 0

function TIC()
  cls()
  if dialog ~= nil then
    return dialog()
  end

  if playing then
    sound()
  end

  local durSec = songTicks() / 60
  local durMin = math.floor(durSec / 60)
  durSec = math.floor(durSec - durMin * 60)
  local durStr = (durMin > 0 and (durMin .. "min ") or "") .. durSec .. "s"
  print("Song duration: " .. durStr, 0, 130, 15, 1, 1, 1)
  print("BPM: " .. math.floor(bpm() + .5), 130, 130, 15, 1, 1, 1)

  print("Crackle\nTracker", 0, 0, 15, 1, 1, 1)
  print("v0.1", 225, 131, 15, 1, 1, 1)
  iconbtn(newBtn, 1, 0, 14, new, "New")
  iconbtn(saveBtn, 3, 0, 30, save, "Save")
  iconbtn(expBtn, 5, 0, 46, export, "Export")

  iconbtn(rewindBtn, 48, 29, 69, rewind, "Play from start", 1)
  iconbtn(playBtn, 49, 37, 69, play, "Play (space)", 1)
  iconbtn(stopBtn, 50, 45, 69, stop, "Stop (space)", 1)
  rect(10, 77, 41, 1, 1)

  print("Song", 10, 70, 15, 1, 1, 5)
  label(SONG_LABELS, 21, 80, 24, 2)
  editor(songState, 45, 79, 1, 6, 0, 1, SONG_MIN, SONG_MAX)

  print("Instrs", 46, 0, 15, 1, 1, 5)
  label(INSTR_LABELS, 21, 16, 24, 2)
  editor(instrState, 45, 15, 4, 7, 1, 8, INSTR_MIN, INSTR_MAX, true)
  hextitle(46, 8, 4)

  print("Order", 84, 0, 15, 1, 1, 1)
  editor(orderState, 83, 15, 5, peek(ORDLEN_ADDR), 5, 16, -1, 15, true)
  spr(0, 112, 7, 0)
  hextitle(84, 8, 4)

  print("Patterns", 129, 0, 15, 1, 1, 1)
  editor(patsState, 128, 15, 16, peek(PATLEN_ADDR), 10, 16, -1, 35, true)
  hextitle(129, 8, 16)

  if tooltip.src then
    label(tooltip.txt, tooltip.x, tooltip.y, nil, 2, 0, 13)
  end

  -- if Tab pressed
  if keyp(49) then
    found = find(tabOrder, focus) or 0
    -- Shift+Tab cycles backwards
    if key(64) then
      found = found - 2
    end
    focus = tabOrder[found % #tabOrder + 1]
  end
  -- if Space pressed
  if keyp(48) then
    if playing then
      stop()
    else
      play()
    end
  end
end

---------------------
-- Sound
---------------------
function rewind()
  t = 0
  playing = true
end

function play()
  playing = true
  if focus == orderState then
    t = orderState.y * patTicks()
  end
end

function stop()
  playing = false
end

function songTicks()
  return peek(ORDLEN_ADDR) * patTicks()
end

function patTicks()
  return peek(PATREPS_ADDR) * (16 - peek(TEMPO_ADDR)) * peek(PATLEN_ADDR)
end

function bpm()
  return 30 * 60 / (16 - peek(TEMPO_ADDR))
end

function sound()
  local ptic = patTicks()
  local stic = ptic * peek(ORDLEN_ADDR)
  local noteticks = (16 - peek(TEMPO_ADDR))
  pat = t // ptic
  for i = 0, 4 do
    rect(83 + i * 7, pat * 7 + 15, 7, 7, 2 + i)
  end
  local keypat = peek(ORDER_ADDR + 64 + pat)
  local key = 0
  if keypat < 255 then
    local row = t / peek(KEYDUR_ADDR) // noteticks % peek(PATLEN_ADDR)
    key = peek(PATS_ADDR + keypat * 16 + row)
    rect(128 + keypat * 7, row * 7 + 15, 7, 7, 6)
  end
  for i = 0, 3 do
    poke(0x100E4 + 66 * i, i * 16)
    local mute = peek(MUTE_ADDR + i * 8)
    if mute > 0 then
      goto continue
    end
    local wave = peek(WAVE_ADDR + i * 8)
    local notepos = t * peek(NOTEDUR_ADDR + i * 8) // 8
    local row = notepos // noteticks % peek(PATLEN_ADDR)
    local col = peek(ORDER_ADDR + i * 16 + pat)
    if col < 255 then
      local filldiv = ((peek(PATREPS_ADDR) - peek(FILL_ADDR + i * 8)) * (16 - peek(TEMPO_ADDR)) * peek(PATLEN_ADDR))
      if filldiv > 0 then col = col + t % ptic // filldiv end
      local note = peek(PATS_ADDR + col * 16 + row)
      local env = -notepos % noteticks
      if note == 255 then
        env = 0
      end
      local oct = peek(OCTAVE_ADDR + i * 8)
      local st = peek(SEMITN_ADDR + i * 8)
      rect(128 + col * 7, row * 7 + 15, 7, 7, 2 + i)
      note = note - peek(SLIDE_ADDR + i * 8) * (notepos % noteticks) + key
      sfx(wave, oct * 12 + st + note + peek(SONGST_ADDR) ~ 0, 3, i, env)
    end
    ::continue::
  end

  t = (t + 1)
  if t >= stic then
    t = 0
    playing = false
  end
end

---------------------
-- Saving & Exporting
---------------------

function clear()
  memset(0x14004, 0, 1024)
  memset(PATS_ADDR, 255, 16 * 16)
  memset(ORDER_ADDR, 255, 5 * 16)
  poke(ORDER_ADDR, 0)
  poke(PATS_ADDR, 0)
  for i = 0, 3 do
    poke(NOTEDUR_ADDR + i * 8, 8)
  end
  poke(ORDLEN_ADDR, 8)
  poke(PATREPS_ADDR, 8)
  poke(PATLEN_ADDR, 8)
  poke(KEYDUR_ADDR, 8)
end

function new()
  local yesbtn = {}
  local nobtn = {}
  dialog = function()
    rect(20, 20, 200, 96, 15)
    label("Warning: Clear song data?", 20, 50, 200, 1, 12)
    button(yesbtn, 70, 80, 40, 10, "Yes",
      function() clear() dialog = nil end)
    button(nobtn, 130, 80, 40, 10, "No",
      function() dialog = nil end)
  end
end

function save()
  local tmpl = [=[

-- saveid: crackle
d=[[
${dataStr}]]
d=d:gsub("%s+","")
for i=0,${memUsedMinus1} do
 v=tonumber(d:sub(i*2+1,i*2+2),16)
 poke(0x14004+i,v)
end
function TIC()
 cls()
 print("Song loaded :)",9,9,time())
end
]=]
  local dataStr = ""
  for i = 0, MEMUSED - 1 do
    local v = peek(0x14004 + i)
    dataStr = dataStr .. string.format("%02X", v)
    if (i + 1) % 16 == 0 then dataStr = dataStr .. "\n" end
  end
  trace(interp(tmpl, { dataStr = dataStr, memUsedMinus1 = MEMUSED - 1 }))
  exit()
end

function interp(s, tab)
  return (s:gsub(
    "($%b{})",
    function(w)
    return tab[w:sub(3, -2)] or w
  end
  ))
end

function find(arr, value)
  for i, v in ipairs(arr) do
    if v == value then
      return i, v
    end
  end
  return nil, nil
end

function constant(arr)
  if #arr < 2 then
    return true
  end
  for i = 2, #arr do
    if arr[i] ~= arr[i - 1] then
      return false
    end
  end
  return true
end

function export()
  local tmpl = [[
-- exported from crackle tracker
d={
${data}
}

t=0

function TIC()
 for k=0,3 do
  p=t//${partLen} -- orderlist pos${waveSetCode}
  e=t*d[k+${noteDurInd}]//8 -- envelope pos
  -- n is note (semitones), 0=no note
  n=d[
      ${patLen}*d[${ordLen}*k+p+${ordInd}]+${patInd} -- patstart
      +e//${envSteps}%${patLen} -- patrow${fillCode}
     ] or 0 -- can sometimes be removed
  -- save envelopes for syncs
  -- d[0] = chn 0, d[-1] = chn 1...
  -- % ensures if n=0|pat=0 then env=0
  d[-k]=-e%${envSteps}%(16*n*d[${ordLen}*k+p+${ordInd}]+1)
  sfx(
   k, -- channel k uses wave k
   ${songPitch} -- global pitch:
    +12*d[k+${octInd}] -- octave
    +d[k+${stInd}] -- semitones
    +n -- note
    -e%${envSteps}*d[k+${slideInd}] -- pitch drop
    +(
      0<d[${ordLen}*4+p+${ordInd}] -- key active?
      and d[
            ${patLen}*d[${ordLen}*4+p+${ordInd}] -- key pat
            +${patInd}+t//${keyEnvDur}%${patLen} -- key row
           ]
      or 1
     ) -- key change
    ~0, -- convert to int
   2,
   k,
   d[-k] -- stored envelope
  )
 end
 t=t+1,t<${songTicks} or exit()
end
]]
  local waves = { peek(WAVE_ADDR), peek(WAVE_ADDR + 8), peek(WAVE_ADDR + 16), peek(WAVE_ADDR + 24) }
  local waveSetCode = ""
  if constant(waves) then
    if waves[1] > 0 then
      waveSetCode = "\n  poke(65764+k*66," .. waves[1] .. ")"
    end
  else
    for k = 0, 3 do
      if waves[k + 1] > 0 then
        waveSetCode = waveSetCode .. string.format("\n  poke(%d,%d) -- set chn %d wave", 65764 + k * 66, waves[k + 1] * 16, k)
      end
    end
  end
  local fills = { peek(FILL_ADDR), peek(FILL_ADDR + 8), peek(FILL_ADDR + 16), peek(FILL_ADDR + 24) }
  local fillCode = ""
  if constant(fills) then
    if fills[1] > 0 then
      local filldiv = ((peek(PATREPS_ADDR) - fills[1]) * (16 - peek(TEMPO_ADDR)) * peek(PATLEN_ADDR))
      fillCode = string.format("\n      +t%%%d//%d*%d --fills", patTicks(), filldiv, peek(PATLEN_ADDR))
    end
    fills = {}
  else
    fillCode = string.format("\n      +t%%%d//%d//(%d-d[k+${fillInd}])*%d --fills", patTicks(), (16 - peek(TEMPO_ADDR)) * peek(PATLEN_ADDR), peek(PATREPS_ADDR), peek(PATLEN_ADDR))
  end
  local patUsed = {}
  for k = 0, 4 do
    localfillpats = 0
    if k < 4 then
      local filldiv = ((peek(PATREPS_ADDR) - peek(FILL_ADDR + k * 8)) * (16 - peek(TEMPO_ADDR)) * peek(PATLEN_ADDR))
      fillpats = (patTicks() - 1) // filldiv
    end
    for i = 0, peek(ORDLEN_ADDR) - 1 do
      local p = peek(ORDER_ADDR + k * 16 + i)
      if p ~= 255 then
        for j = 0, fillpats do
          patUsed[p + j] = true
        end
      end
    end
  end
  local patList = {}
  local newIndex = {}
  local runningIndex = 1
  for k = 0, 15 do
    if patUsed[k] then
      for i = 0, peek(PATLEN_ADDR) - 1 do
        table.insert(patList, (peek(PATS_ADDR + k * 16 + i) + 1) % 256)
      end
      newIndex[k] = runningIndex
      runningIndex = runningIndex + 1
    end
  end
  local ordList = {}
  for k = 0, 4 do
    for i = 0, peek(ORDLEN_ADDR) - 1 do
      local pat = peek(ORDER_ADDR + k * 16 + i)
      if pat == 255 then
        table.insert(ordList, 0)
      else
        table.insert(ordList, newIndex[pat])
      end
    end
  end
  local octaves = {}
  for k = 0, 3 do
    table.insert(octaves, peek(OCTAVE_ADDR + k * 8))
  end
  local semitones = {}
  for k = 0, 3 do
    table.insert(semitones, peek(SEMITN_ADDR + k * 8))
  end
  local slides = {}
  for k = 0, 3 do
    table.insert(slides, peek(SLIDE_ADDR + k * 8))
  end
  local notespeeds = { peek(NOTEDUR_ADDR), peek(NOTEDUR_ADDR + 8), peek(NOTEDUR_ADDR + 16), peek(NOTEDUR_ADDR + 24) }
  data, inds = superArray(notespeeds, ordList, patList, octaves, slides, fills, semitones)
  local dataStr = " "
  for index, value in ipairs(data) do
    dataStr = dataStr .. string.format("%2d", value) .. ","
    if index % 10 == 0 then dataStr = dataStr .. "\n " end
  end
  local code = interp(tmpl, {
    partLen = patTicks(),
    waveSetCode = waveSetCode,
    data = dataStr,
    noteDurInd = inds[1],
    patLen = peek(PATLEN_ADDR),
    patInd = inds[3] - peek(PATLEN_ADDR),
    envSteps = (16 - peek(TEMPO_ADDR)),
    ordLen = peek(ORDLEN_ADDR),
    ordInd = inds[2],
    songTicks = patTicks() * peek(ORDLEN_ADDR) - 1,
    songPitch = peek(SONGST_ADDR) - 2,
    octInd = inds[4],
    stInd = inds[7],
    slideInd = inds[5],
    keyEnvDur = peek(KEYDUR_ADDR) * (16 - peek(TEMPO_ADDR)),
    fillCode = interp(fillCode, { fillInd = inds[6] }),
  })
  trace("\n" .. code)
  exit()
end

function compare(a1, a2, s1, s2, l)
  for i = 0, l - 1 do
    if a1[s1 + i] ~= a2[s2 + i] then
      return false
    end
  end
  return true
end

function overlap(a1, a2)
  local max = 0
  local t1 = 0
  local t2 = #a1
  for i = 2 - #a2, #a1 do
    local l = math.max(1, i)
    local r = math.min(i + #a2 - 1, #a1)
    local w = r - l + 1
    local s = 1 + l - i
    if max < w and compare(a1, a2, l, s, w) then
      max = w
      t1 = s
      t2 = l
    end
  end
  ret = {}
  table.move(a1, 1, #a1, t1, ret)
  table.move(a2, 1, #a2, t2, ret)
  return max, ret, t1, t2
end

function superArray(...)
  local arrs = { ... }
  local inds = {}
  for i = 1, #arrs do
    inds[i] = {}
    inds[i][i] = 1
  end
  local len = #arrs
  while len > 1 do
    local max = 0
    local mi, mj, ms
    for i = 1, len do
      for j = i + 1, len do
        m, s, t1, t2 = overlap(arrs[i], arrs[j])
        if max < m then
          max = m
          ms, mi, mj, mt1, mt2 = s, i, j, t1, t2
        end
      end
    end
    if max == 0 then
      -- no overlap, just join the last element with first
      arrs[1] = { table.unpack(arrs[1]) }
      local l = #(arrs[1])
      table.move(arrs[len], 1, #(arrs[len]), l + 1, arrs[1])
      for i, v in pairs(inds[len]) do
        inds[1][i] = v + l
      end
    else
      -- move mi+mj to mi, and last to where mj was
      arrs[mi] = ms
      for i, v in pairs(inds[mi]) do
        inds[mi][i] = v + mt1 - 1
      end
      for i, v in pairs(inds[mj]) do
        inds[mi][i] = v + mt2 - 1
      end
      arrs[mj] = arrs[len]
      inds[mj] = inds[len]
    end
    len = len - 1
  end
  return arrs[1], inds[1]
end

---------------
-- GUI elements
---------------

function label(s, x, y, w, a, c, b)
  if c == nil then
    c = 15
  end
  if type(s) == "table" then
    for i = 1, #s do
      label(s[i], x, y + (i - 1) * 7, w, a)
    end
    return
  end
  local m = print(s, 0, -99, 15, 1, 1, 1)
  w = w or (m + 1)
  if b then
    rect(x, y - 1, w, 7, b)
  end
  local k = x + (w - m) * a / 2
  print(s, k, y, c, 1, 1, 1)
end

function iconbtn(s, i, x, y, cb, tip, w)
  w = w or 2
  mx, my, l = mouse()
  if mx >= x and my >= y and mx < x + 8 * w and my < y + 8 * w then
    if not s.l and l and cb then
      cb()
    end
    for i = 0, 15 do
      poke4(0x3FF0 * 2 + i, i - 1)
    end
    s.t = (s.t or 0) + 1
    if s.t == 40 then
      tooltip.src = s
      tooltip.txt = tip
      tooltip.x = mx
      tooltip.y = my + 5
    end
  else
    s.t = 0
    if tooltip.src == s then
      tooltip.src = nil
    end
  end
  spr(i, x, y, 1, 1, 0, 0, w, w)
  for i = 0, 15 do
    poke4(0x3FF0 * 2 + i, i)
  end
  s.l = l
end

function button(s, x, y, w, h, t, cb)
  local mx, my, l = mouse()
  local highlight = 0
  if mx >= x and my >= y and mx < x + w and my < y + h then
    if not s.l and l and cb then
      cb()
    end
    highlight = -1
  end
  rect(x, y, w, h, 13 + highlight)
  rect(x + 1, y + 1, w - 1, h - 1, highlight)
  rect(x + 1, y + 1, w - 2, h - 2, 14 + highlight)
  local m = print(t, 0, -99)
  local a = x + (w - m) / 2
  print(t, a + 1, y + 2 + 1, 0)
  print(t, a, y + 2, 12)
  s.l = l
end

function hextitle(x, y, n)
  for i = 0, n - 1 do
    local c
    if i < 10 then
      c = i
    else
      c = string.char(65 + i - 10)
    end
    print(c, x + 7 * i, y, 1, 1, 1)
  end
end

function editor(s, x, y, w, h, ad, st, mi, ma, hex)
  pw, ph = w * 7, h * 7
  s.x = s.x or 0
  s.y = s.y or 0
  ad = ad * 16 + 0x14004
  if focus == s then
    local m = ad + s.x * st + s.y
    if keyp(54) then
      poke(m, peek(m) + 1)
    end
    if keyp(55) then
      poke(m, peek(m) - 1)
    end
    if keyp(52) then
      poke(m, 255)
    end
    if keyp(60) then
      s.x = s.x - 1
    end
    if keyp(61) then
      s.x = s.x + 1
    end
    if keyp(58) then
      s.y = s.y - 1
    end
    if keyp(59) then
      s.y = s.y + 1
    end
    for i = 0, 9 do
      if keyp(27 + i) then
        poke(ad + s.x * st + s.y, i)
      end
    end
    for i = 1, 26 do
      if keyp(i) then
        poke(ad + s.x * st + s.y, i + 9)
      end
    end
    c = 13
    poke(16320 + 9 * 3, math.sin(time() / 199) ^ 2 * 128)
  else
    c = 14
  end
  s.x = s.x > 0 and s.x or 0
  s.y = s.y > 0 and s.y or 0
  s.x = s.x < w - 1 and s.x or w - 1
  s.y = s.y < h - 1 and s.y or h - 1
  if focus == s then
    rect(x + s.x * 7, y + s.y * 7, 7, 7, 9)
  end
  mx, my, lb, mb, rb, sx, sy = mouse()
  if lb and mx > x and my > y and mx - x < pw and my - y < ph then
    focus = s
    s.x = (mx - x) // 7
    s.y = (my - y) // 7
  end
  for i = 0, w - 1 do
    for j = 0, h - 1 do
      local a = ad + i * st + j
      v = peek(a)
      v = (v + 128) % 256 - 128 -- treat these as signed 8-bit values
      if type(mi) == "table" then
        v = v < mi[j + 1] and mi[j + 1] or v
      else
        v = v < mi and mi or v
      end
      if type(ma) == "table" then
        v = v > ma[j + 1] and ma[j + 1] or v
      else
        v = v > ma and ma or v
      end
      poke(a, v)
      if hex and v >= 10 then
        v = string.char(65 + v - 10)
      end
      if v == -1 then
        v = "-"
      end
      print(v, i * 7 + x + 1, j * 7 + y + 1, c, 1)
    end
  end
end

-- <TILES>
-- 000:0001100000010100000100000111000011110000011000000000000000000000
-- 001:1111111111111111111eeeee111effff111effff111effff111effff111effff
-- 002:1111111111111111ee111111eee11111eeee1111eeeee111ffffe011ffffe011
-- 003:1111111111111111111eeeee11effeee11effeee11effeee11efffff11efffff
-- 004:1111111111111111eeeee111efeffe11efeffe01eeeffe01fffffe01fffffe01
-- 005:1111111111111111111eeeee111effff111effff111effff111effff111effee
-- 006:1111111111111111eeeee111ffffe011fffff011ffffe011ffffee11eeeeeee1
-- 017:111effff111effff111effff111effff111effff111eeeee1111000011111111
-- 018:ffffe011ffffe011ffffe011ffffe011ffffe011eeeee0110000001111111111
-- 019:11efeeee11efeeee11efeeee11efeeee111eeeee111100001111111111111111
-- 020:eeeefe01eeeefe01eeeefe01eeeefe01eeeee011000001111111111111111111
-- 021:111effff111effff111effff111effff111eeeee111100001111111111111111
-- 022:ffffee00ffffe001fffff011ffffe011eeeee011000000111111111111111111
-- 032:1111111111e1e11111e0e011111e10111ee1ee111ee0ee011100100111111111
-- 033:111111111eeee1111effe0111efeee111eeefe01110eee011111000111111111
-- 034:1111111111eee1111efffe111eeeee011eefee011eeeee011100000111111111
-- 035:11111111111ee11111ee01111eeeee1111ee0001111ee1111111001111111111
-- 036:1111111111ee1111111ee1111eeeee11110ee00111ee00111110011111111111
-- 048:11111111111e1e1111e10e011eeee10111e00e11111e1e011111010111111111
-- 049:111111111e1111111eee11111eeeee111eee00011e0001111101111111111111
-- 050:111111111eeeee111efffe011efffe011efffe011eeeee011100000111111111
-- </TILES>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304000000000
-- </SFX>

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>
