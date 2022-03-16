-- title:  Crackle tracker
-- author: pestis / bC!
-- desc:   a tracker for tiny intros
-- script: lua
-- saveid: crackle
TEMPO_ADDR = 0x14007
SONGST_ADDR = 0x14008
ORDLEN_ADDR = 0x14004
PATREP_ADDR = 0x14005
PATLEN_ADDR = 0x14006
NOTEDUR_ADDR = 0x14017

ords = {}
pats = {}
inst = {}
ilab = {
 "Wave",
 "Octave",
 "Semitn",
 "NoteDur",
 "Fill",
 "Mute"
}
imin = {0, 0, 0, 1, 0, 0}
imax = {3, 7, 11, 16, 7, 1}
song = {}
smin = {1, 0, 1, 0, 0}
smax = {16, 16, 16, 7, 11}
slab = {
 "OrdLen",
 "PatReps",
 "PatLen",
 "Tempo",
 "Semitn"
}
savebtn = {}
expbtn = {}
newbtn = {}
cutbtn = {}
copybtn = {}
pastebtn = {}
undobtn = {}
redobtn = {}
rewindbtn = {}
playbtn = {}
stopbtn = {}
playing = false
taborder = {inst, ords, pats, song}
focus = nil
dialog = nil
t = 0

function TIC()
 cls()
 if dialog ~= nil then
  dialog()
  return
 end

 if playing then
  sound()
 end

 local dur = peek(ORDLEN_ADDR) * ptic() / 60
 local dur_min = math.floor(dur / 60)
 local dur_s = math.floor(dur - dur_min * 60)
 local dur_str = (dur_min > 0 and (dur_min .. "min ") or "") .. dur_s .. "s"
 print("Song duration: " .. dur_str, 0, 130, 15, 1, 1, 1)
 bpm = 30 * 60 / (16 - peek(TEMPO_ADDR))
 print("BPM: " .. math.floor(bpm + .5), 130, 130, 15, 1, 1, 1)

 print("Crackle\nTracker", 0, 0, 15, 1, 1, 1)
 print("v0.1", 225, 131, 15, 1, 1, 1)
 iconbtn(newbtn, 1, 0, 14, new, "New")
 iconbtn(savebtn, 3, 0, 30, save, "Save")
 iconbtn(expbtn, 5, 0, 46, export, "Export")

 iconbtn(cutbtn, 32, 201, 0, cut, "Cut (ctrl+x)", 1)
 iconbtn(copybtn, 33, 209, 0, cut, "Copy (ctrl+c)", 1)
 iconbtn(pastebtn, 34, 217, 0, cut, "Paste (ctrl+p)", 1)
 iconbtn(undobtn, 35, 225, 0, cut, "Undo (ctrl+z)", 1)
 iconbtn(redobtn, 36, 233, 0, cut, "Redo (ctrl+y)", 1)

 iconbtn(rewindbtn, 48, 29, 77, rewind, "Play from start", 1)
 iconbtn(playbtn, 49, 37, 77, play, "Play (space)", 1)
 iconbtn(stopbtn, 50, 45, 77, stop, "Stop (space)", 1)
 rect(10, 85, 41, 1, 1)

 print("Song", 10, 78, 15, 1, 1, 5)
 label(slab, 21, 88, 24, 2)
 editor(song, 45, 87, 1, 5, 0, 1, smin, smax)

 print("Instrs", 46, 0, 15, 1, 1, 5)
 label(ilab, 21, 16, 24, 2)
 editor(inst, 45, 15, 4, 6, 1, 8, imin, imax, true)
 hextitle(46, 8, 4)

 print("Order", 84, 0, 15, 1, 1, 1)
 editor(ords, 83, 15, 5, peek(ORDLEN_ADDR), 5, 16, 0, 15, true)
 spr(0, 112, 7, 0)
 hextitle(84, 8, 4)

 print("Patterns", 129, 0, 15, 1, 1, 1)
 editor(pats, 128, 15, 16, peek(PATLEN_ADDR), 10, 16, 0, 35, true)
 hextitle(129, 8, 16)

 if keyp(49) then
  found = 0
  for i, v in ipairs(taborder) do
   if v == focus then
    found = i
    break
   end
  end
  if found ~= nil then
   if key(64) then
    found = found - 2
   end
   focus = taborder[found % #taborder + 1]
  end
 end
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
 if focus == ords then
  t = ords.y * ptic()
 end
end

function stop()
 playing = false
end

function ptic()
 return peek(PATREP_ADDR) * (16 - peek(TEMPO_ADDR)) * peek(PATLEN_ADDR)
end

function sound()
 local ptic = ptic()
 local stic = ptic * peek(ORDLEN_ADDR)
 pat = t // ptic
 for i = 0, 4 do
  rect(83 + i * 7, pat * 7 + 15, 7, 7, 2 + i)
 end
 for i = 0, 3 do
  k = t * peek(NOTEDUR_ADDR + i * 8) / 8 // (16 - peek(TEMPO_ADDR)) % peek(PATLEN_ADDR)
  rect(128 + i * 7, k * 7 + 15, 7, 7, 2 + i)
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
 for i = 0, 511 do
  poke(0x14004 + i, 0)
 end
 for i = 0, 3 do
  poke(NOTEDUR_ADDR + i * 8, 8)
 end
 poke(ORDLEN_ADDR, 8)
 poke(PATREP_ADDR, 8)
 poke(PATLEN_ADDR, 8)
end

function new()
 yesbtn = {}
 nobtn = {}
 dialog = function()
  rect(20, 20, 200, 96, 15)
  label("Warning: Clear song data?", 20, 50, 200, 1, 12)
  button(
   yesbtn,
   70,
   80,
   40,
   10,
   "Yes",
   function()
    clear()
    dialog = nil
   end
  )
  button(
   nobtn,
   130,
   80,
   40,
   10,
   "No",
   function()
    dialog = nil
   end
  )
 end
end

function save()
 local s = "\n-- saveid: crackle\n"
 s = s .. "d=\n"
 for i = 0, 12 do
  s = s .. '"'
  for j = 0, 31 do
   local v = peek(0x14004 + i * 32 + j)
   s = s .. string.char(v + 35)
  end
  s = s .. '"'
  if i < 15 then
   s = s .. ".."
  end
  s = s .. "\n"
 end
 s =
  s ..
  [[
for i=0,511 do
 v=string.byte(
  string.sub(d,i+1,i+1)
 )-35
 poke(0x14004+i,v)
end
function TIC()
 cls()
 print("Song loaded :)",9,9,time())
end
]]
 trace(s)
 exit()
end

function export()
 trace("\nExport does not work yet :(")
 exit()
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
  if not s.l and l then
   cb()
  end
  for i = 0, 15 do
   poke4(0x3FF0 * 2 + i, i - 1)
  end
  s.t = (s.t or 0) + 1
  if s.t == 40 then
   s.x, s.y = mx, my + 5
  end
 else
  s.t = 0
 end
 spr(i, x, y, 1, 1, 0, 0, w, w)
 for i = 0, 15 do
  poke4(0x3FF0 * 2 + i, i)
 end
 if tip and s.t >= 40 then
  label(tip, s.x, s.y, nil, 2, 0, 13)
 -- local w = print(tip,1e3,0)
 -- rect(s.x,s.y,w+2,8,13)
 -- print(tip,s.x+1,s.y+1,0)
 end
 s.l = l
end

function button(s, x, y, w, h, t, cb)
 rect(x, y, w, h, 13)
 rect(x + 1, y + 1, w - 1, h - 1, 0)
 rect(x + 1, y + 1, w - 2, h - 2, 14)
 local m = print(t, 0, -99)
 local a = x + (w - m) / 2
 print(t, a + 1, y + 2 + 1, 0)
 print(t, a, y + 2, 12)
 mx, my, l = mouse()
 if mx >= x and my >= y and mx < x + w and my < y + h and not s.l and l then
  cb()
 end
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
  if keyp(55) and peek(m) > 0 then
   poke(m, peek(m) - 1)
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
  if keyp(52) then
   poke(ad + s.x * st + s.y, 0)
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
  rect(x + s.x * 7, y + s.y * 7, 7, 7, 9)
  poke(16320 + 9 * 3, math.sin(time() / 199) ^ 2 * 128)
 else
  c = 14
 end
 s.x = s.x > 0 and s.x or 0
 s.y = s.y > 0 and s.y or 0
 s.x = s.x < w - 1 and s.x or w - 1
 s.y = s.y < h - 1 and s.y or h - 1
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

