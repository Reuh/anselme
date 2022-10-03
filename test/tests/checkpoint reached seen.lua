local _={}
_[29]={}
_[28]={}
_[27]={}
_[26]={}
_[25]={}
_[24]={}
_[23]={}
_[22]={}
_[21]={}
_[20]={text="1",tags=_[29]}
_[19]={text="Reached: ",tags=_[28]}
_[18]={text="1",tags=_[27]}
_[17]={text="Seen: ",tags=_[26]}
_[16]={text="seen!",tags=_[25]}
_[15]={text="1",tags=_[24]}
_[14]={text="Reached: ",tags=_[23]}
_[13]={text="0",tags=_[22]}
_[12]={text="Seen: ",tags=_[21]}
_[11]={_[19],_[20]}
_[10]={_[17],_[18]}
_[9]={_[16]}
_[8]={_[14],_[15]}
_[7]={_[12],_[13]}
_[6]={"return"}
_[5]={"text",_[11]}
_[4]={"text",_[10]}
_[3]={"text",_[9]}
_[2]={"text",_[8]}
_[1]={"text",_[7]}
return {_[1],_[2],_[3],_[4],_[5],_[6]}
--[[
{ "text", { {
      tags = {},
      text = "Seen: "
    }, {
      tags = {},
      text = "0"
    } } }
{ "text", { {
      tags = {},
      text = "Reached: "
    }, {
      tags = {},
      text = "1"
    } } }
{ "text", { {
      tags = {},
      text = "seen!"
    } } }
{ "text", { {
      tags = {},
      text = "Seen: "
    }, {
      tags = {},
      text = "1"
    } } }
{ "text", { {
      tags = {},
      text = "Reached: "
    }, {
      tags = {},
      text = "1"
    } } }
{ "return" }
]]--