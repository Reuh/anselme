local _={}
_[17]={}
_[16]={}
_[15]={}
_[14]={}
_[13]={tags=_[17],text="decorators # tag ~ condition $ fn"}
_[12]={tags=_[16],text="other codes \n \\ \9"}
_[11]={tags=_[15],text="quote \""}
_[10]={tags=_[14],text="expression {a}"}
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
{ "return" }
]]--