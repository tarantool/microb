--
-- Simple Tarantool benchmark
--

local bench_name = 'microb'
local metrics_number = 2
local N = 10000

local ffi = require('ffi')
ffi.cdef[[
    typedef long time_t;
    typedef struct timeval {
        time_t tv_sec;
        time_t tv_usec;
    } timeval;
    int gettimeofday(struct timeval *t, void *tzp);
]]

local time_now = function()
    local t = ffi.new("timeval")
    ffi.C.gettimeofday(t, nil)
    return tonumber(t.tv_sec * 1000 + (t.tv_usec / 1000))
end

local function run ()
    local start_time = time_now()
    local s = box.schema.create_space('glade')
    s:create_index('primary', {unique = true, parts = {1, 'NUM'}})
    for i = 1, N do
        s:insert({ i })
    end
    local time_diff = time_now() - start_time
    s:drop()
    metric = {key = bench_name..'.insert', description = 'box.insert bench', unit = 'units/milisec', size = N/time_diff, time = time_diff}
    return metric
end

return {
    run = run
}

--os.exit()
