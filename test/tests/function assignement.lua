local _={}
_[23]={}
_[22]={}
_[21]={}
_[20]={}
_[19]={}
_[18]={tags=_[23],text="3"}
_[17]={tags=_[22],text="ok"}
_[16]={tags=_[22],text="v2="}
_[15]={tags=_[21],text="50"}
_[14]={tags=_[20],text="50"}
_[13]={tags=_[20],text="v="}
_[12]={tags=_[19],text="5"}
_[11]={_[18]}
_[10]={_[16],_[17]}
_[9]={_[15]}
_[8]={_[13],_[14]}
_[7]={_[12]}
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
      text = "5"
    } } }
{ "text", { {
      tags = <1>{},
      text = "v="
    }, {
      tags = <table 1>,
      text = "50"
    } } }
{ "text", { {
      tags = {},
      text = "50"
    } } }
{ "text", { {
      tags = <1>{},
      text = "v2="
    }, {
      tags = <table 1>,
      text = "ok"
    } } }
{ "text", { {
      tags = {},
      text = "3"
    } } }
{ "return" }
]]--