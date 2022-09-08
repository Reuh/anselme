local _={}
_[5]={}
_[4]={tags=_[5],text="3"}
_[3]={_[4]}
_[2]={"error","can't change the value of a constant \"constant variable.a\"; while assigning value to variable \"constant variable.a\"; at test/tests/constant variable.ans:5"}
_[1]={"text",_[3]}
return {_[1],_[2]}
--[[
{ "text", { {
      tags = {},
      text = "3"
    } } }
{ "error", "can't change the value of a constant \"constant variable.a\"; while assigning value to variable \"constant variable.a\"; at test/tests/constant variable.ans:5" }
]]--