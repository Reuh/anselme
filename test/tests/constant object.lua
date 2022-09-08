local _={}
_[5]={}
_[4]={tags=_[5],text="12"}
_[3]={_[4]}
_[2]={"error","can't change the value of an attribute of a constant object; in Lua function \"_._\"; at test/tests/constant object.ans:8"}
_[1]={"text",_[3]}
return {_[1],_[2]}
--[[
{ "text", { {
      tags = {},
      text = "12"
    } } }
{ "error", "can't change the value of an attribute of a constant object; in Lua function \"_._\"; at test/tests/constant object.ans:8" }
]]--