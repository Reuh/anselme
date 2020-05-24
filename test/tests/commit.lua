local _={}
_[17]={}
_[16]={}
_[15]={}
_[14]={}
_[13]={data="parallel: 2",tags=_[17]}
_[12]={data="after: 2",tags=_[16]}
_[11]={data="parallel: 5",tags=_[15]}
_[10]={data="before: 2",tags=_[14]}
_[9]={_[13]}
_[8]={_[12]}
_[7]={_[11]}
_[6]={_[10]}
_[5]={"return"}
_[4]={"text",_[9]}
_[3]={"text",_[8]}
_[2]={"text",_[7]}
_[1]={"text",_[6]}
return {_[1],_[2],_[3],_[4],_[5]}
--[[
{ "text", { {
      data = "before: 2",
      tags = {}
    } } }
{ "text", { {
      data = "parallel: 5",
      tags = {}
    } } }
{ "text", { {
      data = "after: 2",
      tags = {}
    } } }
{ "text", { {
      data = "parallel: 2",
      tags = {}
    } } }
{ "return" }
]]--