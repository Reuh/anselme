local _={}
_[8]={}
_[7]={}
_[6]={text="[1, [2, 3]]",tags=_[8]}
_[5]={text="[1,[2,3]]: ",tags=_[7]}
_[4]={_[5],_[6]}
_[3]={"return"}
_[2]={"text",_[4]}
_[1]={"error","abort; in Lua function \"error\"; at test/tests/merge nested mutable error.ans:16"}
return {_[1],_[2],_[3]}
--[[
{ "error", 'abort; in Lua function "error"; at test/tests/merge nested mutable error.ans:16' }
{ "text", { {
      tags = {},
      text = "[1,[2,3] ]: "
    }, {
      tags = {},
      text = "[1, [2, 3] ]"
    } } }
{ "return" }
]]--