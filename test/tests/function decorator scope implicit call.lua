local _={}
_[17]={}
_[16]={}
_[15]={}
_[14]={}
_[13]={}
_[12]={tags=_[17],text="ok"}
_[11]={tags=_[16],text="1"}
_[10]={tags=_[16],text="a.\240\159\145\129\239\184\143: "}
_[9]={tags=_[15],text="ko"}
_[8]={tags=_[14],text="In function:"}
_[7]={tags=_[13],text="0"}
_[6]={tags=_[13],text="a.\240\159\145\129\239\184\143: "}
_[5]={_[8],_[9],_[10],_[11],_[12]}
_[4]={_[6],_[7]}
_[3]={"return"}
_[2]={"text",_[5]}
_[1]={"text",_[4]}
return {_[1],_[2],_[3]}
--[[
{ "text", { {
      tags = <1>{},
      text = "a.👁️: "
    }, {
      tags = <table 1>,
      text = "0"
    } } }
{ "text", { {
      tags = {},
      text = "In function:"
    }, {
      tags = {},
      text = "ko"
    }, {
      tags = <1>{},
      text = "a.👁️: "
    }, {
      tags = <table 1>,
      text = "1"
    }, {
      tags = {},
      text = "ok"
    } } }
{ "return" }
]]--