local _={}
_[36]={}
_[35]={tags=_[36],text="Surprise choice!"}
_[34]={1}
_[33]={}
_[32]={}
_[31]={tags=_[32],text="Surprise choice!"}
_[30]={1}
_[29]={}
_[28]={tags=_[33],text=" to move."}
_[27]={tags=_[33],text=" joystick"}
_[26]={tags=_[36],text="ok2"}
_[25]={_[35]}
_[24]={tags=_[34],text="left"}
_[23]={tags=_[33],text="Use "}
_[22]={tags=_[29],text=" to jump."}
_[21]={tags=_[32],text="ok"}
_[20]={_[31]}
_[19]={tags=_[30],text="A"}
_[18]={tags=_[29],text="Press "}
_[17]={_[27],_[28]}
_[16]={_[26]}
_[15]={_[25]}
_[14]={_[23],_[24]}
_[13]={_[22]}
_[12]={_[21]}
_[11]={_[20]}
_[10]={_[18],_[19]}
_[9]={"return"}
_[8]={"text",_[17]}
_[7]={"text",_[16]}
_[6]={"choice",_[15]}
_[5]={"text",_[14]}
_[4]={"text",_[13]}
_[3]={"text",_[12]}
_[2]={"choice",_[11]}
_[1]={"text",_[10]}
return {_[1],_[2],_[3],_[4],_[5],_[6],_[7],_[8],_[9]}
--[[
{ "text", { {
      tags = {},
      text = "Press "
    }, {
      tags = { 1 },
      text = "A"
    } } }
{ "choice", { { {
        tags = {},
        text = "Surprise choice!"
      } } } }
{ "text", { {
      tags = {},
      text = "ok"
    } } }
{ "text", { {
      tags = {},
      text = " to jump."
    } } }
{ "text", { {
      tags = {},
      text = "Use "
    }, {
      tags = { 1 },
      text = "left"
    } } }
{ "choice", { { {
        tags = {},
        text = "Surprise choice!"
      } } } }
{ "text", { {
      tags = {},
      text = "ok2"
    } } }
{ "text", { {
      tags = <1>{},
      text = " joystick"
    }, {
      tags = <table 1>,
      text = " to move."
    } } }
{ "return" }
]]--