local _={}
_[21]={}
_[20]={}
_[19]={}
_[18]={}
_[17]={}
_[16]={text="sub [text]",tags=_[21]}
_[15]={text="decorators # tag ~ condition $ fn",tags=_[20]}
_[14]={text="other codes \n \\ \9",tags=_[19]}
_[13]={text="quote \"",tags=_[18]}
_[12]={text="expression {a}",tags=_[17]}
_[11]={_[16]}
_[10]={_[15]}
_[9]={_[14]}
_[8]={_[13]}
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
{ "return" }
]]--