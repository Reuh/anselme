local _={}
_[13]={}
_[12]={}
_[11]={}
_[10]={tags=_[13],text="12"}
_[9]={tags=_[12],text="12"}
_[8]={tags=_[11],text="&function reference dot operator function.f.a"}
_[7]={_[10]}
_[6]={_[9]}
_[5]={_[8]}
_[4]={"return"}
_[3]={"text",_[7]}
_[2]={"text",_[6]}
_[1]={"text",_[5]}
return {_[1],_[2],_[3],_[4]}
--[[
{ "text", { {
      tags = {},
      text = "&function reference dot operator function.f.a"
    } } }
{ "text", { {
      tags = {},
      text = "12"
    } } }
{ "text", { {
      tags = {},
      text = "12"
    } } }
{ "return" }
]]--