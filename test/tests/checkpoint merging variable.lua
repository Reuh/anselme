local _={}
_[27]={}
_[26]={}
_[25]={}
_[24]={}
_[23]={}
_[22]={tags=_[27],text="3"}
_[21]={tags=_[27],text="3: "}
_[20]={tags=_[26],text="4"}
_[19]={tags=_[26],text="4: "}
_[18]={tags=_[25],text="3"}
_[17]={tags=_[25],text="3: "}
_[16]={tags=_[24],text="2"}
_[15]={tags=_[24],text="2: "}
_[14]={tags=_[23],text="1"}
_[13]={tags=_[23],text="1: "}
_[12]={_[21],_[22]}
_[11]={_[19],_[20]}
_[10]={_[17],_[18]}
_[9]={_[15],_[16]}
_[8]={_[13],_[14]}
_[7]={"return"}
_[6]={"text",_[12]}
_[5]={"error","cancel merge; in Lua function \"error\"; at test/tests/checkpoint merging variable.ans:23"}
_[4]={"text",_[11]}
_[3]={"text",_[10]}
_[2]={"text",_[9]}
_[1]={"text",_[8]}
return {_[1],_[2],_[3],_[4],_[5],_[6],_[7]}
--[[
{ "text", { {
      tags = <1>{},
      text = "1: "
    }, {
      tags = <table 1>,
      text = "1"
    } } }
{ "text", { {
      tags = <1>{},
      text = "2: "
    }, {
      tags = <table 1>,
      text = "2"
    } } }
{ "text", { {
      tags = <1>{},
      text = "3: "
    }, {
      tags = <table 1>,
      text = "3"
    } } }
{ "text", { {
      tags = <1>{},
      text = "4: "
    }, {
      tags = <table 1>,
      text = "4"
    } } }
{ "error", 'cancel merge; in Lua function "error"; at test/tests/checkpoint merging variable.ans:23' }
{ "text", { {
      tags = <1>{},
      text = "3: "
    }, {
      tags = <table 1>,
      text = "3"
    } } }
{ "return" }
]]--