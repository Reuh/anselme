local _={}
_[13]={1}
_[12]={}
_[11]={}
_[10]={}
_[9]={tags=_[13],text="Tagged text"}
_[8]={tags=_[12],text="b: "}
_[7]={tags=_[11],text="Some text."}
_[6]={tags=_[10],text="a: "}
_[5]={_[8],_[9]}
_[4]={_[6],_[7]}
_[3]={"return"}
_[2]={"text",_[5]}
_[1]={"text",_[4]}
return {_[1],_[2],_[3]}
--[[
{ "text", { {
      tags = {},
      text = "a: "
    }, {
      tags = {},
      text = "Some text."
    } } }
{ "text", { {
      tags = {},
      text = "b: "
    }, {
      tags = { 1 },
      text = "Tagged text"
    } } }
{ "return" }
]]--