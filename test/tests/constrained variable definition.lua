local _={}
_[5]={}
_[4]={text="5::kg",tags=_[5]}
_[3]={_[4]}
_[2]={"error","constraint check failed; while assigning value to variable \"constrained variable definition.not weigh\"; at test/tests/constrained variable definition.ans:7"}
_[1]={"text",_[3]}
return {_[1],_[2]}
--[[
{ "text", { {
      tags = {},
      text = "5::kg"
    } } }
{ "error", 'constraint check failed; while assigning value to variable "constrained variable definition.not weigh"; at test/tests/constrained variable definition.ans:7' }
]]--