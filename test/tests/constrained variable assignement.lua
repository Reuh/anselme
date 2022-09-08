local _={}
_[9]={}
_[8]={}
_[7]={text="12::kg",tags=_[9]}
_[6]={text="5::kg",tags=_[8]}
_[5]={_[7]}
_[4]={_[6]}
_[3]={"error","constraint check failed; while assigning value to variable \"constrained variable assignement.weigh\"; at test/tests/constrained variable assignement.ans:9"}
_[2]={"text",_[5]}
_[1]={"text",_[4]}
return {_[1],_[2],_[3]}
--[[
{ "text", { {
      tags = {},
      text = "5::kg"
    } } }
{ "text", { {
      tags = {},
      text = "12::kg"
    } } }
{ "error", 'constraint check failed; while assigning value to variable "constrained variable assignement.weigh"; at test/tests/constrained variable assignement.ans:9' }
]]--