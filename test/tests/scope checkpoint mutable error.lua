local _={}
_[44]={}
_[43]={}
_[42]={}
_[41]={}
_[40]={}
_[39]={}
_[38]={}
_[37]={}
_[36]={}
_[35]={}
_[34]={}
_[33]={}
_[32]={}
_[31]={}
_[30]={tags=_[44],text="[1, 2, 3]"}
_[29]={tags=_[43],text="l: "}
_[28]={tags=_[42],text="AFTER ERROR"}
_[27]={tags=_[41],text="CHECK"}
_[26]={tags=_[40],text="[1, 2, 3]"}
_[25]={tags=_[39],text=" "}
_[24]={tags=_[38],text="[1, 2, 3]"}
_[23]={tags=_[37],text="f1: "}
_[22]={tags=_[36],text="REC"}
_[21]={tags=_[35],text="CHECK"}
_[20]={tags=_[34],text="[1, 2]"}
_[19]={tags=_[33],text=" "}
_[18]={tags=_[32],text="[1, 2]"}
_[17]={tags=_[31],text="f1: "}
_[16]={_[29],_[30]}
_[15]={_[28]}
_[14]={_[27]}
_[13]={_[23],_[24],_[25],_[26]}
_[12]={_[22]}
_[11]={_[21]}
_[10]={_[17],_[18],_[19],_[20]}
_[9]={"return"}
_[8]={"text",_[16]}
_[7]={"text",_[15]}
_[6]={"error","t; in Lua function \"error\"; at test/tests/scope checkpoint mutable error.ans:25; at test/tests/scope checkpoint mutable error.ans:19; at test/tests/scope checkpoint mutable error.ans:29"}
_[5]={"text",_[14]}
_[4]={"text",_[13]}
_[3]={"text",_[12]}
_[2]={"text",_[11]}
_[1]={"text",_[10]}
return {_[1],_[2],_[3],_[4],_[5],_[6],_[7],_[8],_[9]}
--[[
{ "text", { {
      tags = {},
      text = "f1: "
    }, {
      tags = {},
      text = "[1, 2]"
    }, {
      tags = {},
      text = " "
    }, {
      tags = {},
      text = "[1, 2]"
    } } }
{ "text", { {
      tags = {},
      text = "CHECK"
    } } }
{ "text", { {
      tags = {},
      text = "REC"
    } } }
{ "text", { {
      tags = {},
      text = "f1: "
    }, {
      tags = {},
      text = "[1, 2, 3]"
    }, {
      tags = {},
      text = " "
    }, {
      tags = {},
      text = "[1, 2, 3]"
    } } }
{ "text", { {
      tags = {},
      text = "CHECK"
    } } }
{ "error", 't; in Lua function "error"; at test/tests/scope checkpoint mutable error.ans:25; at test/tests/scope checkpoint mutable error.ans:19; at test/tests/scope checkpoint mutable error.ans:29' }
{ "text", { {
      tags = {},
      text = "AFTER ERROR"
    } } }
{ "text", { {
      tags = {},
      text = "l: "
    }, {
      tags = {},
      text = "[1, 2, 3]"
    } } }
{ "return" }
]]--