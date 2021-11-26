local _={}
_[8]={}
_[7]={}
_[6]={tags=_[8],text="ho"}
_[5]={tags=_[7],text="ah"}
_[4]={_[5],_[6]}
_[3]={"return"}
_[2]={"text",_[4]}
_[1]={"wait",5}
return {_[1],_[2],_[3]}
--[[
{ "wait", 5 }
{ "text", { {
      tags = {},
      text = "ah"
    }, {
      tags = {},
      text = "ho"
    } } }
{ "return" }
]]--