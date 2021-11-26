local _={}
_[25]={}
_[24]={}
_[23]={}
_[22]={}
_[21]={}
_[20]={tags=_[25],text="2"}
_[19]={tags=_[25],text="Reached: "}
_[18]={tags=_[24],text="1"}
_[17]={tags=_[24],text="Seen: "}
_[16]={tags=_[23],text="seen!"}
_[15]={tags=_[22],text="1"}
_[14]={tags=_[22],text="Reached: "}
_[13]={tags=_[21],text="0"}
_[12]={tags=_[21],text="Seen: "}
_[11]={_[19],_[20]}
_[10]={_[17],_[18]}
_[9]={_[16]}
_[8]={_[14],_[15]}
_[7]={_[12],_[13]}
_[6]={"return"}
_[5]={"text",_[11]}
_[4]={"text",_[10]}
_[3]={"text",_[9]}
_[2]={"text",_[8]}
_[1]={"text",_[7]}
return {_[1],_[2],_[3],_[4],_[5],_[6]}
--[[
{ "text", { {
      tags = <1>{},
      text = "Seen: "
    }, {
      tags = <table 1>,
      text = "0"
    } } }
{ "text", { {
      tags = <1>{},
      text = "Reached: "
    }, {
      tags = <table 1>,
      text = "1"
    } } }
{ "text", { {
      tags = {},
      text = "seen!"
    } } }
{ "text", { {
      tags = <1>{},
      text = "Seen: "
    }, {
      tags = <table 1>,
      text = "1"
    } } }
{ "text", { {
      tags = <1>{},
      text = "Reached: "
    }, {
      tags = <table 1>,
      text = "2"
    } } }
{ "return" }
]]--