-- saveid: crackle
d=
"+#'##$%#)#######################"..
"##$####$###############$########"..
"&#(###+###########%###+#####+###"..
"################################"..
"################################"..
"2222&#&#&#&#&#&#2222222222222222"..
"%#%#%#%#%#%#%#222222222222222222"..
"22$#$#$#22$#$#222222222222222222"..
"22######22######2222222222222222"..
"2#2#2#2#'#'#'#2#2222222222222222"..
"##22222222##22####222222222222##"..
"2222##222222##222222##222222####"..
"##2222##2222/#222222222222222222"..
"##22*#/#22*#/#22##222222##*#/#*#"..
"'#*#%###'#*#%#'#'#*#%###'#*#%#'#"..
"22222222222222222222222222222222"..
"22222222222222222222222222222222"..
"22222222222222222222222222222222"..
"22222222222222222222222222222222"..
"22222222222222222222222222222222"..
"22222222222222222222222222222222"..
"22222222222222222222222222222222"..
"22222222222222222222222222222222"..
"22222222222222222222222222222222"..
"22222222222222222222222222222222"..
"'#'#'#'#'#'#%#'#'#'#'#'#'#'#%#'#"..
"################################"..
"################################"..
"################################"..
"################################"..
"################################"..
"################################"
for i=0,511 do
 v=string.byte(
  string.sub(d,i*2+1,i*2+1)
 )-35+(string.byte(
  string.sub(d,i*2+2,i*2+2)
 )-35)*16
 poke(0x14004+i,v)
end
function TIC()
 cls()
 print("Song loaded :)",9,9,time())
end