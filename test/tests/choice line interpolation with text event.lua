local _={}
_[30]={1}
_[29]={}
_[28]={}
_[27]={1}
_[26]={}
_[25]={tags=_[26],text=" to move."}
_[24]={tags=_[26],text=" joystick"}
_[23]={tags=_[30],text="left"}
_[22]={tags=_[26],text="Use "}
_[21]={tags=_[29],text="Other"}
_[20]={}
_[19]={tags=_[28],text="No"}
_[18]={tags=_[20],text=" to jump."}
_[17]={tags=_[27],text="A"}
_[16]={tags=_[20],text="Press "}
_[15]={tags=_[26],text="ok"}
_[14]={_[22],_[23],_[24],_[25]}
_[13]={_[21]}
_[12]={tags=_[20],text="ok"}
_[11]={_[19]}
_[10]={_[16],_[17],_[18]}
_[9]={_[15]}
_[8]={_[13],_[14]}
_[7]={_[12]}
_[6]={_[10],_[11]}
_[5]={"return"}
_[4]={"text",_[9]}
_[3]={"choice",_[8]}
_[2]={"text",_[7]}
_[1]={"choice",_[6]}
return {_[1],_[2],_[3],_[4],_[5]}
--[[
{ "choice", { { {
        tags = <1>{},
        text = "Press "
      }, {
        tags = { 1 },
        text = "A"
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
{ "choice", { { {
        tags = {},
        text = "Other"
      } }, { {
        tags = <1>{},
        text = "Use "
      }, {
        tags = { 1 },
        text = "left"
      }, {
        tags = <table 1>,
        text = " joystick"
      }, {
        tags = <table 1>,
        text = " to move."
      } } } }
{ "text", { {
      tags = {},
      text = "ok"
    } } }
{ "return" }
]]--