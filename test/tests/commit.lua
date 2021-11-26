local _={}
_[21]={}
_[20]={}
_[19]={}
_[18]={}
_[17]={tags=_[21],text="2"}
_[16]={tags=_[21],text="parallel: "}
_[15]={tags=_[20],text="2"}
_[14]={tags=_[20],text="after: "}
_[13]={tags=_[19],text="5"}
_[12]={tags=_[19],text="parallel: "}
_[11]={tags=_[18],text="2"}
_[10]={tags=_[18],text="before: "}
_[9]={_[16],_[17]}
_[8]={_[14],_[15]}
_[7]={_[12],_[13]}
_[6]={_[10],_[11]}
_[5]={"return"}
_[4]={"text",_[9]}
_[3]={"text",_[8]}
_[2]={"text",_[7]}
_[1]={"text",_[6]}
return {_[1],_[2],_[3],_[4],_[5]}
--[[
{ "text", { {
      tags = <1>{},
      text = "before: "
    }, {
      tags = <table 1>,
      text = "2"
    } } }
{ "text", { {
      tags = <1>{},
      text = "parallel: "
    }, {
      tags = <table 1>,
      text = "5"
    } } }
{ "text", { {
      tags = <1>{},
      text = "after: "
    }, {
      tags = <table 1>,
      text = "2"
    } } }
{ "text", { {
      tags = <1>{},
      text = "parallel: "
    }, {
      tags = <table 1>,
      text = "2"
    } } }
{ "return" }
]]--