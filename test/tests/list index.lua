local _={}
_[29]={}
_[28]={}
_[27]={}
_[26]={}
_[25]={}
_[24]={}
_[23]={}
_[22]={}
_[21]={}
_[20]={}
_[19]={text="3",tags=_[29]}
_[18]={text=" == ",tags=_[28]}
_[17]={text="3",tags=_[27]}
_[16]={text="2",tags=_[26]}
_[15]={text=" == ",tags=_[25]}
_[14]={text="2",tags=_[24]}
_[13]={text="1",tags=_[23]}
_[12]={text=" == ",tags=_[22]}
_[11]={text="1",tags=_[21]}
_[10]={text="[1, 2, 3]",tags=_[20]}
_[9]={_[17],_[18],_[19]}
_[8]={_[14],_[15],_[16]}
_[7]={_[11],_[12],_[13]}
_[6]={_[10]}
_[5]={"error","list index out of bounds; in Lua function \"()\"; at test/tests/list index.ans:11"}
_[4]={"text",_[9]}
_[3]={"text",_[8]}
_[2]={"text",_[7]}
_[1]={"text",_[6]}
return {_[1],_[2],_[3],_[4],_[5]}
--[[
{ "text", { {
      tags = {},
      text = "[1, 2, 3]"
    } } }
{ "text", { {
      tags = {},
      text = "1"
    }, {
      tags = {},
      text = " == "
    }, {
      tags = {},
      text = "1"
    } } }
{ "text", { {
      tags = {},
      text = "2"
    }, {
      tags = {},
      text = " == "
    }, {
      tags = {},
      text = "2"
    } } }
{ "text", { {
      tags = {},
      text = "3"
    }, {
      tags = {},
      text = " == "
    }, {
      tags = {},
      text = "3"
    } } }
{ "error", 'list index out of bounds; in Lua function "()"; at test/tests/list index.ans:11' }
]]--