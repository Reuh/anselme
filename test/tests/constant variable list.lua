local _={}
_[5]={}
_[4]={tags=_[5],text="[3]"}
_[3]={_[4]}
_[2]={"error","can't insert values into a constant list; in Lua function \"insert\"; at test/tests/constant variable list.ans:5"}
_[1]={"text",_[3]}
return {_[1],_[2]}
--[[
{ "text", { {
      tags = {},
      text = "[3]"
    } } }
{ "error", "can't insert values into a constant list; in Lua function \"insert\"; at test/tests/constant variable list.ans:5" }
]]--