local _={}
_[15]={}
_[14]={}
_[13]={}
_[12]={}
_[11]={}
_[10]={tags=_[15],data="ok"}
_[9]={tags=_[14],data="neol"}
_[8]={tags=_[13],data="oh"}
_[7]={tags=_[12],data="neol"}
_[6]={tags=_[11],data="ho"}
_[5]={_[10]}
_[4]={_[6],_[7],_[8],_[9]}
_[3]={"return"}
_[2]={"text",_[5]}
_[1]={"choice",_[4]}
return {_[1],_[2],_[3]}
--[[
{ "choice", { {
      data = "ho",
      tags = {}
    }, {
      data = "neol",
      tags = {}
    }, {
      data = "oh",
      tags = {}
    }, {
      data = "neol",
      tags = {}
    } } }
{ "text", { {
      data = "ok",
      tags = {}
    } } }
{ "return" }
]]--