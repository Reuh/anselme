local _={}
_[8]={}
_[7]={}
_[6]={data="ho",tags=_[8]}
_[5]={data="ah",tags=_[7]}
_[4]={_[5],_[6]}
_[3]={"return"}
_[2]={"text",_[4]}
_[1]={"wait",5}
return {_[1],_[2],_[3]}
--[[
{ "wait", 5 }
{ "text", { {
      data = "ah",
      tags = {}
    }, {
      data = "ho",
      tags = {}
    } } }
{ "return" }
]]--