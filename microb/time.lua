-- Module with time function for Tarantool benchmarking 

local ffi = require('ffi')

-- Add C gettimeofday

ffi.cdef [[
    typedef long time_t;
    typedef struct timeval {
    time_t tv_sec;
        time_t tv_usec;
    } timeval;
    int gettimeofday(struct timeval *t, void *tzp);
]]

-- Function for getting current time

local now = function()
    local t = ffi.new("timeval")
    ffi.C.gettimeofday(t, nil)
    return tonumber(t.tv_sec * 1000 + (t.tv_usec / 1000))
end

-- Function fot getting runtime some function

local function diff(fun, ...)
    local start_time = now()
    fun(...)
    local diff = now() - start_time
    return diff
end

return {
    now = now,
    diff = diff
}
