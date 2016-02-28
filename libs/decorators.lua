function decorator(func)
	local wrapper = {
		f = func
	}
	_mt = {
		__concat = function(decorating, decorated)
			return decorating.f(decorated)
		end
	}
	return setmetatable(wrapper, _mt)
end

