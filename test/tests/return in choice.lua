local _={}
_[13]={}
_[12]={}
_[11]={tags=_[12],text="a"}
_[10]={tags=_[13],text="Yes."}
_[9]={tags=_[12],text="x"}
_[8]={_[11]}
_[7]={_[10]}
_[6]={_[9]}
_[5]={_[8]}
_[4]={"return"}
_[3]={"text",_[7]}
_[2]={"text",_[6]}
_[1]={"choice",_[5]}
return {_[1],_[2],_[3],_[4]}
--[[
{ "choice", { { {
        tags = {},
        text = "a"
      } } } }
{ "text", { {
      tags = {},
      text = "x"
    } } }
{ "text", { {
      tags = {},
      text = "Yes."
    } } }
{ "return" }
]]--