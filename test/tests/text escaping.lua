local _={}
_[25]={}
_[24]={}
_[23]={}
_[22]={}
_[21]={}
_[20]={}
_[19]={tags=_[25],text="generic symbol \194\163"}
_[18]={tags=_[24],text="sub [text]"}
_[17]={tags=_[23],text="decorators # tag ~ condition $ fn"}
_[16]={tags=_[22],text="other codes \n \\ \9"}
_[15]={tags=_[21],text="quote \""}
_[14]={tags=_[20],text="expression {a}"}
_[13]={_[19]}
_[12]={_[18]}
_[11]={_[17]}
_[10]={_[16]}
_[9]={_[15]}
_[8]={_[14]}
_[7]={"return"}
_[6]={"text",_[13]}
_[5]={"text",_[12]}
_[4]={"text",_[11]}
_[3]={"text",_[10]}
_[2]={"text",_[9]}
_[1]={"text",_[8]}
return {_[1],_[2],_[3],_[4],_[5],_[6],_[7]}
--[[
{ "text", { {
      tags = {},
      text = "expression {a}"
    } } }
{ "text", { {
      tags = {},
      text = 'quote "'
    } } }
{ "text", { {
      tags = {},
      text = "other codes \n \\ \t"
    } } }
{ "text", { {
      tags = {},
      text = "decorators # tag ~ condition $ fn"
    } } }
{ "text", { {
      tags = {},
      text = "sub [text]"
    } } }
{ "text", { {
      tags = {},
      text = "generic symbol £"
    } } }
{ "return" }
]]--