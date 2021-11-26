local _={}
_[13]={}
_[12]={}
_[11]={tags=_[13],text="ye"}
_[10]={tags=_[13],text=" = "}
_[9]={tags=_[13],text="ye"}
_[8]={tags=_[12],text="ok"}
_[7]={tags=_[12],text=" = "}
_[6]={tags=_[12],text="ok"}
_[5]={_[9],_[10],_[11]}
_[4]={_[6],_[7],_[8]}
_[3]={"return"}
_[2]={"text",_[5]}
_[1]={"text",_[4]}
return {_[1],_[2],_[3]}
--[[
{ "text", { {
      tags = <1>{},
      text = "ok"
    }, {
      tags = <table 1>,
      text = " = "
    }, {
      tags = <table 1>,
      text = "ok"
    } } }
{ "text", { {
      tags = <1>{},
      text = "ye"
    }, {
      tags = <table 1>,
      text = " = "
    }, {
      tags = <table 1>,
      text = "ye"
    } } }
{ "return" }
]]--