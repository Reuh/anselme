local _={}
_[13]={}
_[12]={}
_[11]={}
_[10]={data="idk::esperanto::name::string is english or generic",tags=_[13]}
_[9]={data="pierre::french::name::string is french",tags=_[12]}
_[8]={data="bob::name::string is english or generic",tags=_[11]}
_[7]={_[10]}
_[6]={_[9]}
_[5]={_[8]}
_[4]={"return"}
_[3]={"text",_[7]}
_[2]={"text",_[6]}
_[1]={"text",_[5]}
return {_[1],_[2],_[3],_[4]}
--[[
{ "text", { {
      data = "bob::name::string is english or generic",
      tags = {}
    } } }
{ "text", { {
      data = "pierre::french::name::string is french",
      tags = {}
    } } }
{ "text", { {
      data = "idk::esperanto::name::string is english or generic",
      tags = {}
    } } }
{ "return" }
]]--