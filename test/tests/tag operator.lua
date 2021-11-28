local _={}
_[15]={5,2}
_[14]={[2]=2}
_[13]={5}
_[12]={}
_[11]={tags=_[14],text=" c"}
_[10]={tags=_[15],text="b"}
_[9]={tags=_[14],text="a "}
_[8]={tags=_[12],text=" c"}
_[7]={tags=_[13],text="b"}
_[6]={tags=_[12],text="a "}
_[5]={_[9],_[10],_[11]}
_[4]={_[6],_[7],_[8]}
_[3]={"return"}
_[2]={"text",_[5]}
_[1]={"text",_[4]}
return {_[1],_[2],_[3]}
--[[
{ "text", { {
      tags = <1>{},
      text = "a "
    }, {
      tags = { 5 },
      text = "b"
    }, {
      tags = <table 1>,
      text = " c"
    } } }
{ "text", { {
      tags = <1>{
        [2] = 2
      },
      text = "a "
    }, {
      tags = { 5, 2 },
      text = "b"
    }, {
      tags = <table 1>,
      text = " c"
    } } }
{ "return" }
]]--