local _={}
_[17]={}
_[16]={}
_[15]={}
_[14]={}
_[13]={}
_[12]={text="2",tags=_[17]}
_[11]={text="2",tags=_[16]}
_[10]={text="1",tags=_[15]}
_[9]={text="2",tags=_[14]}
_[8]={text="1",tags=_[13]}
_[7]={_[12]}
_[6]={_[10],_[11]}
_[5]={_[8],_[9]}
_[4]={"return"}
_[3]={"text",_[7]}
_[2]={"text",_[6]}
_[1]={"text",_[5]}
return {_[1],_[2],_[3],_[4]}
--[[
{ "text", { {
      tags = {},
      text = "1"
    }, {
      tags = {},
      text = "2"
    } } }
{ "text", { {
      tags = {},
      text = "1"
    }, {
      tags = {},
      text = "2"
    } } }
{ "text", { {
      tags = {},
      text = "2"
    } } }
{ "return" }
]]--