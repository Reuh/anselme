local _={}
_[18]={}
_[17]={}
_[16]={}
_[15]={}
_[14]={}
_[13]={text="ok",tags=_[18]}
_[12]={text=" ",tags=_[17]}
_[11]={text="1",tags=_[17]}
_[10]={text="a.\240\159\145\129\239\184\143: ",tags=_[17]}
_[9]={text="ko",tags=_[16]}
_[8]={text="In function:",tags=_[15]}
_[7]={text="0",tags=_[14]}
_[6]={text="a.\240\159\145\129\239\184\143: ",tags=_[14]}
_[5]={_[8],_[9],_[10],_[11],_[12],_[13]}
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
      tags = <table 1>,
      text = " "
    }, {
      tags = {},
      text = "ok"
    } } }
{ "return" }
]]--