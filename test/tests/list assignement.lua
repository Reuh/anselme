local _={}
_[37]={}
_[36]={}
_[35]={}
_[34]={}
_[33]={}
_[32]={}
_[31]={}
_[30]={}
_[29]={}
_[28]={tags=_[37],text="[3, 12, 99]"}
_[27]={tags=_[36],text="99"}
_[26]={tags=_[35],text="[3, 12]"}
_[25]={tags=_[34],text="12"}
_[24]={tags=_[33],text="[3, 5]"}
_[23]={tags=_[32],text="5"}
_[22]={tags=_[31],text="[3, 2]"}
_[21]={tags=_[30],text="3"}
_[20]={tags=_[29],text="[1, 2]"}
_[19]={_[28]}
_[18]={_[27]}
_[17]={_[26]}
_[16]={_[25]}
_[15]={_[24]}
_[14]={_[23]}
_[13]={_[22]}
_[12]={_[21]}
_[11]={_[20]}
_[10]={"error","list assignment index out of bounds; in Lua function \"()\"; at test/tests/list assignement.ans:21"}
_[9]={"text",_[19]}
_[8]={"text",_[18]}
_[7]={"text",_[17]}
_[6]={"text",_[16]}
_[5]={"text",_[15]}
_[4]={"text",_[14]}
_[3]={"text",_[13]}
_[2]={"text",_[12]}
_[1]={"text",_[11]}
return {_[1],_[2],_[3],_[4],_[5],_[6],_[7],_[8],_[9],_[10]}
--[[
{ "text", { {
      tags = {},
      text = "[1, 2]"
    } } }
{ "text", { {
      tags = {},
      text = "3"
    } } }
{ "text", { {
      tags = {},
      text = "[3, 2]"
    } } }
{ "text", { {
      tags = {},
      text = "5"
    } } }
{ "text", { {
      tags = {},
      text = "[3, 5]"
    } } }
{ "text", { {
      tags = {},
      text = "12"
    } } }
{ "text", { {
      tags = {},
      text = "[3, 12]"
    } } }
{ "text", { {
      tags = {},
      text = "99"
    } } }
{ "text", { {
      tags = {},
      text = "[3, 12, 99]"
    } } }
{ "error", 'list assignment index out of bounds; in Lua function "()"; at test/tests/list assignement.ans:21' }
]]--