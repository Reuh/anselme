local _={}
_[17]={}
_[16]={}
_[15]={}
_[14]={}
_[13]={tags=_[17],text=" b"}
_[12]={tags=_[16],text="d"}
_[11]={tags=_[15],text="lol"}
_[10]={tags=_[14],text="a"}
_[9]={_[12],_[13]}
_[8]={_[11]}
_[7]={_[10]}
_[6]={"text",_[9]}
_[5]={"flush"}
_[4]={"text",_[8]}
_[3]={"text",_[7]}
_[2]={_[3],_[4],_[5],_[6]}
_[1]={"return",_[2]}
return {_[1]}
--[[
{ "return", { { "text", { {
          tags = {},
          text = "a"
        } } }, { "text", { {
          tags = {},
          text = "lol"
        } } }, { "flush" }, { "text", { {
          tags = {},
          text = "d"
        }, {
          tags = {},
          text = " b"
        } } } } }
]]--