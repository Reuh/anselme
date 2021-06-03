local _={}
_[1]={"error","function call \"fn\" is ambigous; may be at least either:\n\9function type dispatch ambigous.fn(a::number) (at test/tests/function type dispatch ambigous.ans:4)\n\9function type dispatch ambigous.fn(x::number) (at test/tests/function type dispatch ambigous.ans:1); at test/tests/function type dispatch ambigous.ans:7"}
return {_[1]}
--[[
{ "error", 'function call "fn" is ambigous; may be at least either:\n\tfunction type dispatch ambigous.fn(a::number) (at test/tests/function type dispatch ambigous.ans:4)\n\tfunction type dispatch ambigous.fn(x::number) (at test/tests/function type dispatch ambigous.ans:1); at test/tests/function type dispatch ambigous.ans:7' }
]]--