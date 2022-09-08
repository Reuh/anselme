local _={}
_[17]={}
_[16]={}
_[15]={}
_[14]={}
_[13]={}
_[12]={text="[1, 2, 3]",tags=_[17]}
_[11]={text="[1, 2]",tags=_[16]}
_[10]={text="-----",tags=_[15]}
_[9]={text="[1, 2, 3]",tags=_[14]}
_[8]={text="[1, 2, 3]",tags=_[13]}
_[7]={_[11],_[12]}
_[6]={_[10]}
_[5]={_[8],_[9]}
_[4]={"error","can't remove values from a constant list; in Lua function \"remove\"; at test/tests/constant values variable.ans:15"}
_[3]={"text",_[7]}
_[2]={"text",_[6]}
_[1]={"text",_[5]}
return {_[1],_[2],_[3],_[4]}
--[[
{ "text", { {
      tags = {},
      text = "[1, 2, 3]"
    }, {
      tags = {},
      text = "[1, 2, 3]"
    } } }
{ "text", { {
      tags = {},
      text = "-----"
    } } }
{ "text", { {
      tags = {},
      text = "[1, 2]"
    }, {
      tags = {},
      text = "[1, 2, 3]"
    } } }
{ "error", "can't remove values from a constant list; in Lua function \"remove\"; at test/tests/constant values variable.ans:15" }
]]--