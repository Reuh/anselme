local _={}
_[12]={}
_[11]={}
_[10]={}
_[9]={data="no",tags=_[12]}
_[8]={data="in interrupt: 5",tags=_[11]}
_[7]={data="before: 2",tags=_[10]}
_[6]={_[8],_[9]}
_[5]={_[7]}
_[4]={"return"}
_[3]={"text",_[6]}
_[2]={"wait",0}
_[1]={"text",_[5]}
return {_[1],_[2],_[3],_[4]}
--[[
{ "text", { {
      data = "before: 2",
      tags = {}
    } } }
{ "wait", 0 }
{ "text", { {
      data = "in interrupt: 5",
      tags = {}
    }, {
      data = "no",
      tags = {}
    } } }
{ "return" }
]]--