local _={}
_[7]={}
_[6]={tags=_[7],text="2"}
_[5]={tags=_[7],text="before: "}
_[4]={_[5],_[6]}
_[3]={"return",""}
_[2]={"wait",0}
_[1]={"text",_[4]}
return {_[1],_[2],_[3]}
--[[
{ "text", { {
      tags = <1>{},
      text = "before: "
    }, {
      tags = <table 1>,
      text = "2"
    } } }
{ "wait", 0 }
{ "return", "" }
]]--