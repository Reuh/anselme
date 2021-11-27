local _={}
_[7]={}
_[6]={}
_[5]={text="ok bis",tags=_[7]}
_[4]={text="ok ",tags=_[6]}
_[3]={_[4],_[5]}
_[2]={"return"}
_[1]={"text",_[3]}
return {_[1],_[2]}
--[[
{ "text", { {
      tags = {},
      text = "ok "
    }, {
      tags = {},
      text = "ok bis"
    } } }
{ "return" }
]]--