local _={}
_[22]={}
_[21]={1}
_[20]={tags=_[22],text="No"}
_[19]={text=" to jump."}
_[18]={text="SPLIT"}
_[17]={}
_[16]={tags=_[21],text="A"}
_[15]={tags=_[17],text="Press "}
_[14]={tags=_[17],text="ok"}
_[13]={_[20]}
_[12]={_[18],_[19]}
_[11]={tags=_[17],text="ok"}
_[10]={_[15],_[16]}
_[9]={_[14]}
_[8]={_[12],_[13]}
_[7]={_[11]}
_[6]={_[10]}
_[5]={"return"}
_[4]={"text",_[9]}
_[3]={"choice",_[8]}
_[2]={"text",_[7]}
_[1]={"choice",_[6]}
_[0]={_[1],_[2],_[3],_[4],_[5]}
_[18].tags=_[17]
_[19].tags=_[17]
return _[0]
--[[
{ "choice", { { {
        tags = {},
        text = "Press "
      }, {
        tags = { 1 },
        text = "A"
      } } } }
{ "text", { {
      tags = {},
      text = "ok"
    } } }
{ "choice", { { {
        tags = <1>{},
        text = "SPLIT"
      }, {
        tags = <table 1>,
        text = " to jump."
      } }, { {
        tags = {},
        text = "No"
      } } } }
{ "text", { {
      tags = {},
      text = "ok"
    } } }
{ "return" }
]]--