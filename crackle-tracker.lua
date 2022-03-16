-- title:  Crackle tracker
-- author: pestis / bC!
-- desc:   a tracker for tiny intros
-- script: lua
-- saveid: crackle

ords={}
pats={}
inst={}
ilab={"Oct","Reps","Wave","Pitch","Fill","Mute"}
imin={0,0,0,0,0}
imax={8,2,2,8,7,1}
song={}
smin={1,0,1,0}
smax={16,6,16,7}
slab={"OrdLen","OrdSpd","PatLen","PatSpd"}
savebtn={}
expbtn={}
newbtn={}
play=false
taborder={inst,ords,pats,song}
focus=nil
dialog=nil
t=0

function TIC()
 cls()
 if dialog~=nil then
  dialog()
  return
 end

 if play then
  sound()
 end

 local dur=peek(0x14004)*ptic()/60
 print("Song duration: "..math.floor(dur+.5).."s",42,130,15,1,1,1)
 bpm=30*60/(16-peek(0x14007))
 print("BPM: "..math.floor(bpm+.5),130,130,15,1,1,1)

 print("Cracle 0.1\nTracker",0,0,15,1,1,1)
 iconbtn(newbtn,1,0,14,new,"New")
 iconbtn(savebtn,3,0,30,save,"Save")
 iconbtn(expbtn,5,0,46,export,"Export")

 label(slab,42,102,24,2)
 editor(song,66,101,1,4,0,1,smin,smax)


 print("Instrs",46,0,15,1,1,5)
 label(ilab,21,16,24,2)
 editor(inst,45,15,4,6,1,8,0,imax)
    hextitle(46,8,4)


 print("Order",84,0,15,1,1,1)
 editor(ords, 83,15, 5,peek(0x14004),5,16,0,15)
    spr(0,112,7,0)
    hextitle(84,8,4)

 print("Patterns",129,0,15,1,1,1)
 editor(pats,128,15,16,peek(0x14006),10,16,0,35)
 hextitle(129,8,16)

 if keyp(49) then
  found=0
  for i,v in ipairs(taborder) do
   if v==focus then
    found=i
    break
   end
  end
  if found~=nil then
   if key(64) then
    found=found-2
   end
   focus=taborder[found%#taborder+1]
  end
 end
 if keyp(48) then
  play=not play
  if focus==ords then
   t=ords.y*ptic()
  end
 end
end

---------------------
-- Sound
---------------------

function ptic()
 return 2^(5-peek(0x14005))*
            (16-peek(0x14007))*
            peek(0x14006)
end

function sound()
 local ptic=ptic()
 local stic=ptic*peek(0x14004)
 pat=t//ptic
 for i=0,4 do
  rect(83+i*7,pat*7+15,7,7,2+i)
 end
    t=(t+1)%stic
end

---------------------
-- Saving & Exporting
---------------------

function clear()
 for i=0,511 do
  poke(0x14004+i,0)
 end
 poke(0x14004,8)
 poke(0x14005,2)
 poke(0x14006,8)
end

function new()
 yesbtn={}
 nobtn={}
 dialog=function()
  rect(20,20,200,96,15)
  label("Warning: Clear song data?",20,50,200,1,12)
  button(yesbtn,70,80,40,10,"Yes",function()
   clear()
   dialog=nil
  end)
  button(nobtn,130,80,40,10,"No",function()
   dialog=nil
  end)
 end
end

function save()
 local s="\n-- saveid: crackle\n"
 s=s.."d=\n"
    for i=0,12 do
        s=s..'"'
     for j=0,31 do
         local v=peek(0x14004+i*32+j)
         s=s..string.char(v+35)
        end
        s=s..'"'
        if i<15 then
        s=s..'..'
  end
        s=s..'\n'
 end
 s=s..[[
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

function label(s,x,y,w,a,c)
 if c==nil then
  c=15
 end
 if type(s)=="table" then
  for i=1,#s do
   label(s[i],x,y+(i-1)*7,w,a)
  end
  return
 end
 local m=print(s,0,-99,15,1,1,1)
 local k=x+(w-m)*a/2
 print(s,k,y,c,1,1,1)
end

function iconbtn(s,i,x,y,cb,tip)
  mx,my,l=mouse()
  if mx>=x and my>=y and mx<x+16 and my<y+16 then
   if not s.l and l then
    cb()
   end
   rect(x,y,16,16,15)
   s.t = (s.t or 0) + 1
   if s.t == 40 then
    s.x,s.y = mx, my
   end
  else
   s.t = 0
  end
  spr(i,x,y,0,1,0,0,2,2)
  if tip and s.t >= 40 then
   local w = print(tip,1e3,0)
   rect(s.x,s.y,w+2,8,13)
   print(tip,s.x+1,s.y+1,0)
  end
  s.l=l
end

function button(s,x,y,w,h,t,cb)
 rect(x,y,w,h,13)
 rect(x+1,y+1,w-1,h-1,15)
 rect(x+1,y+1,w-2,h-2,14)
 local m=print(t,0,-99)
 local a=x+(w-m)/2
 print(t,a+1,y+2+1,0)
 print(t,a,y+2,12)
 mx,my,l=mouse()
 if mx>=x and my>=y and
    mx<x+w and my<y+h and
    not s.l and l then
  cb()
 end
 s.l=l
end

function hextitle(x,y,n)
 for i=0,n-1 do
  local c
  if i<10 then
   c=i
  else
   c=string.char(65+i-10)
  end
  print(c,x+7*i,y,1,1,1)
 end
end

function editor(s,x,y,w,h,ad,st,mi,ma)
 pw,ph=w*7,h*7
 s.x=s.x or 0
 s.y=s.y or 0
 ad=ad*16+0x14004
 if focus==s then
  if keyp(60) then
   s.x=s.x-1
  end
  if keyp(61) then
   s.x=s.x+1
  end
  if keyp(58) then
   s.y=s.y-1
  end
  if keyp(59) then
   s.y=s.y+1
  end
  if keyp(52) then
   poke(ad+s.x*st+s.y,0)
  end
  for i=0,9 do
   if keyp(27+i) then
    poke(ad+s.x*st+s.y,i)
   end
  end
  for i=1,26 do
   if keyp(i) then
    poke(ad+s.x*st+s.y,i+9)
   end
  end
  c=13
  rect(x+s.x*7,y+s.y*7,7,7,9)
  poke(16320+9*3,math.sin(time()/199)^2*128)
 else
  c=14
 end
 s.x=s.x>0 and s.x or 0
 s.y=s.y>0 and s.y or 0
 s.x=s.x<w-1 and s.x or w-1
 s.y=s.y<h-1 and s.y or h-1
 mx,my,lb,mb,rb,sx,sy=mouse()
 if lb and
    mx>x and my>y and
    mx-x<pw and my-y<ph then
  focus=s
  s.x=(mx-x)//7
  s.y=(my-y)//7
 end
 for i=0,w-1 do
  for j=0,h-1 do
   local a=ad+i*st+j
   v=peek(a)
   if type(mi)=="table" then
    v=v<mi[j+1] and mi[j+1] or v
   else
    v=v<mi and mi or v
   end
   if type(ma)=="table" then
    v=v>ma[j+1] and ma[j+1] or v
   else
    v=v>ma and ma or v
   end
   poke(a,v)
   if v>=10 then
    v=string.char(65+v-10)
   end
   print(v,i*7+x+1,j*7+y+1,c,1)
  end
 end
end
-- <TILES>
-- 000:0001100000010100000100000111000011110000011000000000000000000000
-- 001:0000000000000000000ddddd000deeee000deeee000deeee000deeee000deeee
-- 002:0000000000000000dd000000ddd00000dddd0000ddddd000eeeed000eeeed000
-- 003:0000000000000000000ddddd00deeddd00deeddd00deeddd00deeeee00deeeee
-- 004:0000000000000000ddddd000dedeed00dedeed00dddeed00eeeeed00eeeeed00
-- 005:0000000000000000000ddddd00deeeee00deeeee00deeeee00deeeff00deeefd
-- 006:0000000000000000ddddd000eeeeed00eeeeff00eeeefd00fffffdd0dddddddd
-- 017:000deeee000deeee000deeee000deeee000deeee000ddddd0000000000000000
-- 018:eeeed000eeeed000eeeed000eeeed000eeeed000ddddd0000000000000000000
-- 019:00dedddd00dedddd00dedddd00dedddd000ddddd000000000000000000000000
-- 020:dddded00dddded00dddded00dddded00ddddd000000000000000000000000000
-- 021:00deeeff00deeeee00deeeee00deeeee000ddddd000000000000000000000000
-- 022:fffffdd0eeeefd00eeeeff00eeeeed00ddddd000000000000000000000000000
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

