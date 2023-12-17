-- prevent an expression from being immediately evaluated, and instead only evaluate it when the node is explicitely called
-- it can be used to evaluate the expression on demand, as if the quote call AST was simply replaced by the unevaluated associated expression AST (like a macro)
-- keep in mind that this thus bypass any scoping rule, closure, etc.
--
-- used for infix operators where the evaluation of the right term depends of the left one (lazy boolean operators, conditionals, etc.)

local ast = require("ast")

local Quote
Quote = ast.abstract.Node {
	type = "quote",

	expression = nil,

	init = function(self, expression)
		self.expression = expression
		self.format_priority = expression.format_priority
	end,

	_format = function(self, ...)
		return self.expression:format(...) -- Quote is generated transparently by operators
	end,

	traverse = function(self, fn, ...)
		fn(self.expression, ...)
	end,

	call = function(self, state, args)
		assert(args.arity == 0, "Quote! does not accept arguments")
		return self.expression:eval(state)
	end
}

return Quote
