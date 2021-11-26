local _={}
_[12]={}
_[11]={}
_[10]={tags=_[12],text="5"}
_[9]={tags=_[12],text="in interrupt: "}
_[8]={tags=_[11],text="2"}
_[7]={tags=_[11],text="before: "}
_[6]={_[9],_[10]}
_[5]={_[7],_[8]}
_[4]={"return"}
_[3]={"text",_[6]}
_[2]={"wait",0}
_[1]={"text",_[5]}
return {_[1],_[2],_[3],_[4]}
--[[
{ "text", { {
      tags = <1>{},
      text = "before: "
    }, {
      tags = <table 1>,
      text = "2"
    } } }
{ "wait", 0 }
{ "text", { {
      tags = <1>{},
      text = "in interrupt: "
    }, {
      tags = <table 1>,
      text = "5"
    } } }
{ "return" }
]]--