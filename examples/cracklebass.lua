-- saveid: crackle
d=[[
080808000A0800000000000000000000
00000010000000000001000200000000
00020008000000000003000800000800
00000000000000000000000000000000
00000000000000000000000000000000
00000100010001FFFFFFFFFFFFFFFFFF
FFFFFF02020204FFFFFFFFFFFFFFFFFF
FF01000100010001FFFFFFFFFFFFFFFF
FF0303FF03030303FFFFFFFFFFFFFFFF
FFFFFFFF0F0FFFFFFFFFFFFFFFFFFFFF
00FF000C0FFF0007FFFFFFFFFFFFFFFF
00FF000C0F000007FFFFFFFFFFFFFFFF
00FF070C0CFF0F0CFFFFFFFFFFFFFFFF
00FF00FF00FF0000FFFFFFFFFFFFFFFF
00FFFFFF00FF0C00FFFFFFFFFFFFFFFF
FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
0000050700000507FFFFFFFFFFFFFFFF
]]
d=d:gsub("%s+","")
for i=0,415 do
 v=tonumber(d:sub(i*2+1,i*2+2),16)
 poke(0x14004+i,v)
end
function TIC()
 cls()
 print("Song loaded :)",9,9,time())
end