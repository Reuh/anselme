local class = require("anselme.lib.class")
local fmt = require("anselme.common").fmt
local binser = require("anselme.lib.binser")
local utf8 = utf8 or require("lua-utf8")
local unpack = table.unpack or unpack

-- NODES SHOULD BE IMMUTABLE AFTER CREATION IF POSSIBLE!
-- i don't think i actually rely on this behavior for anything but it makes me feel better about life in general
-- (well, unless node.mutable == true, in which case go ahead and break my little heart)
-- UPDATE: i actually assumed nodes to be immutable by default in a lot of places now, thank you past me, it did indeed make me feel better about life in general

-- reminder: when requiring AST nodes somewhere, try to do it at the end of the file. and if you need to require something in this file, do it in the :_i_hate_cycles method.
-- i've had enough headaches with cyclics references and nodes required several times...

local uuid = require("anselme.common").uuid

local Call, Identifier, Struct, Tuple, String, Pair
local resume_manager

local custom_call_identifier

local context_max_length = 50
local function cutoff_text(str)
	if str:match("\n") or utf8.len(str) > context_max_length then
		local cut_pos = math.min((str:match("()\n") or math.huge)-1, (utf8.offset(str, context_max_length, 1) or math.huge)-1)
		str = str:sub(1, cut_pos) .. "…"
	end
	return str
end
local function format_error(state, node, message)
	if node.hide_in_stacktrace then
		return message
	else
		local ctx = cutoff_text(node:format(state)) -- get some context code around error
		return fmt("%{red}%s%{reset}\n\t↳ from %{underline}%s%{reset} in %s: %{dim}%s", message, node.source, node.type, ctx)
	end
end

-- traverse helpers
local traverse
traverse = {
	set_source = function(self, source)
		self:set_source(source)
	end,
	merge = function(self, state, cache)
		self:merge(state, cache)
	end,
	post_deserialize = function(self, state, cache)
		self:post_deserialize(state, cache)
	end,
	hash = function(self, t)
		table.insert(t, self:hash())
	end,
	list_translatable = function(self, t)
		self:list_translatable(t)
	end,
	list_resume_targets = function(self, add_to_node)
		for hash, target in pairs(self:list_resume_targets()) do
			add_to_node._list_resume_targets_cache[hash] = target
		end
	end,
	list_used_identifiers = function(self, t)
		self:list_used_identifiers(t)
	end
}

local Node
Node = class {
	type = "node",
	mutable = false,
	hide_in_stacktrace = false,

	-- abstract class
	-- must be redefined
	init = false,

	-- set the source of this node and its children (unless a source is already set)
	-- to be preferably used during construction only
	set_source = function(self, source)
		local str_source = tostring(source)
		if self.source == "?" and str_source ~= "?" then
			self.source = str_source
			self:traverse(traverse.set_source, str_source)
		end
		return self
	end,
	source = "?",

	-- call function callback with args ... on the children Nodes of this Node
	-- by default, assumes no children Nodes
	-- you will want to redefine this for nodes with children nodes
	-- (note: when calling, remember that cycles are common place in the AST, so stay safe use a cache)
	traverse = function(self, callback, ...) end,

	-- returns new AST
	-- whatever this function returned is assumed to be already evaluated
	-- the actual evaluation is done in _eval
	eval = function(self, state)
		if self._evaluated then return self end
		local s, r = pcall(self._eval, self, state)
		if s then
			r._evaluated = true
			r:set_source(self.source)
			return r
		else
			error(format_error(state, self, r), 0)
		end
	end,
	-- same as eval but called on the top node of a statement (i.e. a line of a block)
	-- redefine if the statement behavior should be different
	eval_statement = function(self, state)
		return self:eval(state)
	end,
	_evaluated = false, -- if true, node is assumed to be already evaluated and :eval will be the identity function
	-- evaluate this node and return the result
	-- by default assume the node can't be evaluated further and return itself; redefine for everything else, probably
	-- THIS SHOULD NOT MUTATE THE CURRENT NODE; create and return a new Node instead! (even if node is mutable)
	_eval = function(self, state)
		return self
	end,

	-- returns a reversed list { [target hash] = true, ... } of the resume targets contained in this node and its children
	-- this is cached, redefine _list_resume_targets if needed, not this function
	list_resume_targets = function(self)
		if not self._list_resume_targets_cache then
			self._list_resume_targets_cache = {}
			self:_list_resume_targets()
		end
		return self._list_resume_targets_cache
	end,
	_list_resume_targets_cache = nil, -- list resume target cache { [target hash] = target, ... }
	-- add resume targets to _list_resume_targets_cache
	_list_resume_targets = function(self)
		self:traverse(traverse.list_resume_targets, self)
	end,

	-- returns true if the node or its children contains the resume target
	contains_resume_target = function(self, target)
		return not not self:list_resume_targets()[target:hash()]
	end,

	-- returns true if we are currently trying to resume to a resume target contained in the current node
	contains_current_resume_target = function(self, state)
		return resume_manager:resuming(state) and self:contains_resume_target(resume_manager:get(state))
	end,

	-- generate a list of translatable nodes that appear in this node
	-- should only be called on non-evaluated nodes (non-evaluated nodes don't contain cycles)
	-- if a node is translatable, redefine this to add it to the table - note that it shouldn't call :traverse or :list_translatable on its children, as nested translations should not be needed
	list_translatable = function(self, t)
		t = t or {}
		self:traverse(traverse.list_translatable, t)
		return t
	end,

	-- generate a list of identifiers that are used in this node
	-- should only be called on non-evaluated nodes
	-- the list contains at least all used nodes; some unused nodes may be present
	-- redefine on identifier nodes to add an identifier to the table
	list_used_identifiers = function(self, t)
		self:traverse(traverse.list_used_identifiers, t)
	end,

	-- generate anselme code that can be used as a base for a translation file
	-- will include every translatable element found in this node and its children
	generate_translation_template = function(self)
		local mandatory_context = {"file"} -- will always be present in template
		local discriminating_context = "source" -- only used when there may be conflicts

		-- if there are several identical translations in the tuple, wrap them in a struct with the discriminating context
		local function classify_discriminating(tr_tuple)
			local r_tuple = Tuple:new()
			local discovered = Struct:new()
			for _, tr in tr_tuple:iter() do
				if not discovered:has(tr) then
					r_tuple:insert(tr)
					discovered:set(tr, r_tuple:len())
				else
					local context_name = String:new(discriminating_context)
					-- replace previousley discovered translation
					local discovered_index = discovered:get(tr)
					if discovered_index ~= -1 then
						local discovered_tr = r_tuple:get(discovered_index)
						local context = Pair:new(context_name, discovered_tr.context:get(context_name))
						local discovered_strct = Struct:new()
						discovered_strct:set(context, discovered_tr)
						r_tuple:set(discovered_index, discovered_strct)
						discovered:set(tr, -1)
					end
					-- add current translation
					local context = Pair:new(context_name, tr.context:get(context_name))
					local strct = Struct:new()
					strct:set(context, tr)
					r_tuple:insert(strct)
				end
			end
			return r_tuple
		end

		-- build a Struct{ [context1] = Struct{ [context2]} = Tuple[translatable, Struct { [context3] = translatable }, ...], ... }, ... }
		local function classify(tr_tuple, context_i)
			local r = Struct:new()
			local context_name = String:new(mandatory_context[context_i])
			for _, tr in tr_tuple:iter() do
				local context = Pair:new(context_name, tr.context:get(context_name))
				if not r:has(context) then
					r:set(context, Tuple:new())
				end
				local context_tr_tuple = r:get(context)
				context_tr_tuple:insert(tr)
			end
			for context, context_tr_tuple in r:iter() do
				if context_i < #mandatory_context then
					r:set(context, classify(context_tr_tuple, context_i+1))
				elseif context_i == #mandatory_context then
					r:set(context, classify_discriminating(context_tr_tuple))
				end
			end
			return r
		end

		local classified = classify(Tuple:new(unpack(self:list_translatable())), 1)

		local function build_str(tr, level)
			level = level or 0
			local indent = ("\t"):rep(level)
			local r = {}
			if Struct:is(tr) then
				for context, context_tr in tr:iter() do
					table.insert(r, indent..Call:from_operator("_#_", context, Identifier:new("_")):format():gsub(" _$", ""))
					table.insert(r, build_str(context_tr, level+1))
				end
			elseif Tuple:is(tr) then
				for _, v in tr:iter() do
					table.insert(r, build_str(v, level))
					table.insert(r, "")
				end
			else
				table.insert(r, indent.."/* "..tr.source.." */")
				table.insert(r, indent..Call:from_operator("_->_", tr, tr):format())
			end
			return table.concat(r, "\n")
		end

		return build_str(classified)
	end,

	-- call the node with the given arguments
	-- return result AST
	-- arg is a ArgumentTuple node (already evaluated)
	-- do not redefine; instead redefine :dispatch and :call_dispatched
	call = function(self, state, arg)
		local dispatched, dispatched_arg = self:dispatch(state, arg)
		if dispatched then
			return dispatched:call_dispatched(state, dispatched_arg)
		else
			error(("can't call %s %s: %s"):format(self.type, self:format_short(state), dispatched_arg), 0)
		end
	end,
	-- find a function that can be called with the given arguments
	-- return function, arg if a function is found that can be called with arg. The returned arg may be different than the input arg.
	-- return nil, message if no matching function found
	dispatch = function(self, state, arg)
		-- by default, look for custom call operator
		if state.scope:defined(custom_call_identifier) then
			local custom_call = custom_call_identifier:eval(state)
			local dispatched, dispatched_arg = custom_call:dispatch(state, arg:with_first_argument(self))
			if dispatched then
				return dispatched, dispatched_arg
			else
				return nil, dispatched_arg
			end
		end
		return nil, "not callable"
	end,
	-- call the node with the given arguments
	-- this assumes that this node was correctly dispatched to (was returned by a previous call to :dispatch)
	-- you can therefore assume that the arguments are valid and compatible with this node
	call_dispatched = function(self, state, arg)
		error(("%s is not callable"):format(self.type))
	end,

	-- merge any changes back into the main branch
	-- cache is a table indicating nodes when the merge has already been triggered { [node] = true, ... }
	-- (just give an empty table on the initial call)
	-- redefine :_merge if needed, not this
	merge = function(self, state, cache)
		if not cache[self] then
			cache[self] = true
			self:_merge(state, cache)
			self:traverse(traverse.merge, state, cache)
		end
	end,
	_merge = function(self, state, cache) end,

	-- return string that uniquely represent this node
	-- the actual hash is computed in :_hash, don't redefine :hash directly
	-- note: if the node is mutable, this will return a UUID instead of calling :_hash
	hash = function(self)
		if not self._hash_cache then
			if self.mutable then
				self._hash_cache = uuid()
			else
				self._hash_cache = self:_hash()
			end
		end
		return self._hash_cache
	end,
	_hash_cache = nil, -- cached hash
	-- return string that uniquely represent this node
	-- by default, build a "node type<children node hash;...>" representation using :traverse
	-- you may want to redefine this for base types and other nodes with discriminating info that's not in children nodes.
	-- also beware if :traverse uses pairs() or any other non-deterministic function, it'd be nice if this was properly bijective...
	-- (no need to redefine for mutable nodes, since an uuid is used instead)
	_hash = function(self)
		local t = {}
		self:traverse(traverse.hash, t)
		return ("%s<%s>"):format(self.type, table.concat(t, ";"))
	end,

	-- return a pretty string representation of the node.
	-- for non-evaluated nodes, this should return valid Anselme code that is functionnally equivalent to the parsed code. note that it currently does not preserve comment.
	-- assuming nothing was mutated in the node, the returned string should remain the same - so if make sure the function is deterministic, e.g. sort if you use pairs()
	-- redefine _format, not this - note that _format is a mandary method for all nodes.
	-- state is optional and should only have an effect on evaluated nodes; if specified, only show what is relevant for the current branch.
	-- indentation_level and parent_priority are optional value that respectively keep track in nester :format calls of the indentation level (number) and parent operator priority (number); if the node has a strictly lower priority than the parent node, parentheses will be added
	-- also remember that execution is done left-to-right, so in case of priority equality, all is fine if the term appear left of the operator, but parentheses will need to be added if the term is right of the operator - so make sure to call :format_right for such cases
	-- short_mode, if set to true, will use the identifier the expression was last retrieved from instead of calling :_format. Should have no effect on non-evaluated nodes.
	-- (:format is not cached as even immutable nodes may contain mutable children)
	format = function(self, state, parent_priority, indentation_level, short_mode, right)
		indentation_level = indentation_level or 0
		parent_priority = parent_priority or 0

		local s
		if short_mode and self.from_symbol then
			s = self.from_symbol.string
		else
			s = self:_format(state, self:format_priority(), indentation_level, short_mode)
			if self:format_priority() < parent_priority or (right and self:format_priority() <= parent_priority) then
				s = ("(%s)"):format(s)
			end
		end

		return s
	end,
	-- same as :format, but should be called only for nodes right of the current operator
	format_right = function(self, state, parent_priority, indentation_level, short_mode)
		return self:format(state, parent_priority, indentation_level, short_mode, true)
	end,
	-- same as :format, but enable short mode
	format_short = function(self, state, parent_priority, indentation_level)
		return self:format(state, parent_priority, indentation_level, true)
	end,
	-- redefine this to provide a custom :format. returns a string.
	_format = function(self, state, self_priority, identation, short_mode)
		error("format not implemented for "..self.type)
	end,
	-- compute the priority of the node that will be used in :format to add eventually needed parentheses.
	-- should alwaus return the same value after object construction (will be cached anyway)
	-- redefine _format_priority, not this function
	format_priority = function(self)
		if not self._format_priority_cache then
			self._format_priority_cache = self:_format_priority()
		end
		return self._format_priority_cache
	end,
	-- redefine this to compute the priority, see :format_priority
	_format_priority = function(self)
		return math.huge -- by default, assumes primary node, i.e. never wrap in parentheses
	end,
	_format_priority_cache = nil, -- cached priority
	from_symbol = nil, -- last symbol this node was retrived from

	-- return Lua value
	-- this should probably be only called on a Node that is already evaluated
	-- redefine if you want, probably only for nodes that are already evaluated
	to_lua = function(self, state)
		error("cannot convert "..self.type.." to a Lua value")
	end,

	-- returns truthiness of node
	-- redefine for false stuff
	truthy = function(self)
		return true
	end,

	-- register the node for serialization on creation
	__created = function(self)
		if self.init then -- only call on non-abstract node
			binser.register(self, self.type)
		end
	end,
	-- return a serialized representation of the node
	-- can redefine _serialize and _deserialize to customize the serialization, see binser docs
	serialize = function(self, state)
		package.loaded["anselme.serializer_state"] = state
		local r = binser.serialize(self)
		package.loaded["anselme.serializer_state"] = nil
		return r
	end,
	-- return the deserialized Node
	-- class method
	deserialize = function(self, state, str, index)
		package.loaded["anselme.serializer_state"] = state
		local r = binser.deserializeN(str, 1, index)
		package.loaded["anselme.serializer_state"] = nil
		r:post_deserialize(state, {})
		return r
	end,
	-- call :_post_deserialize on all children nodes
	-- automatically called after a sucesfull deserialization, intended to perform finishing touches for deserialization
	-- notably, there is no guarantee that children nodes are already deserialized when _deserialize is called on a node
	-- anything that require such a guarantee should be done here
	post_deserialize = function(self, state, cache)
		if not cache[self] then
			cache[self] = true
			self:_post_deserialize(state, cache)
			self:traverse(traverse.post_deserialize, state, cache)
		end
	end,
	_post_deserialize = function(self, state, cache) end,

	__tostring = function(self) return self:format() end,

	-- Node is required by every other AST node, some of which exist in cyclic require loops.
	-- Delaying the requires in each node after it is defined is enough to fix it, but not for abstract Nodes, since because we are subclassing each node from
	-- them, we need them to be available BEFORE the Node is defined. But Node require several other modules, which themselves require some other AST...
	-- The worst thing with this kind of require loop combined with our existing cycle band-aids is that Lua won't error, it will just execute the first node to subclass from Node twice. Which is annoying since now we have several, technically distinct classes representing the same node frolicking around.
	-- Thus, any require here that may require other Nodes shall be done here. This method is called in anselme.lua after everything else is required.
	_i_hate_cycles = function(self)
		local ast = require("anselme.ast")
		Call, Identifier, Struct, Tuple, String, Pair = ast.Call, ast.Identifier, ast.Struct, ast.Tuple, ast.String, ast.Pair
		custom_call_identifier = Identifier:new("_!")

		resume_manager = require("anselme.state.resume_manager")
	end,

	_debug_traverse = function(self, level)
		level = level or 0
		local t = {}
		self:traverse(function(v) table.insert(t, v:_debug_ast(level+1)) end)
		return ("%s%s:\n%s"):format((" "):rep(level), self.type, table.concat(t, "\n"))
	end,
}

return Node
