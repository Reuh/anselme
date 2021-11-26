local _={}
_[18]={}
_[17]={}
_[16]={}
_[15]={}
_[14]={tags=_[18],text="neol"}
_[13]={tags=_[15],text="oh"}
_[12]={tags=_[17],text="neol"}
_[11]={tags=_[16],text="ho"}
_[10]={tags=_[15],text="ok"}
_[9]={_[14]}
_[8]={_[13]}
_[7]={_[12]}
_[6]={_[11]}
_[5]={_[10]}
_[4]={_[6],_[7],_[8],_[9]}
_[3]={"return"}
_[2]={"text",_[5]}
_[1]={"choice",_[4]}
return {_[1],_[2],_[3]}
--[[
{ "choice", { { {
        tags = {},
        text = "ho"
      } }, { {
        tags = {},
        text = "neol"
      } }, { {
        tags = {},
        text = "oh"
      } }, { {
        tags = {},
        text = "neol"
      } } } }
{ "text", { {
      tags = {},
      text = "ok"
    } } }
{ "return" }
]]--