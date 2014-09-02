--
-- Simple Tarantool benchmark
--

box.cfg {

}

--local os = require('os')

local bench_name = 'microb'
local metrics_number = 2
local N = 100

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
    print (time_diff)
    s:drop()
    return { bench_name = bench_name,
             metrics_number = metrics_number,
             metric_name1 = 'microb_num_req',
             metric_unit2 = '',
             metric_val1 = N,
             metric_name2 = 'microb_time',
             metric_unit2 = 'milisec',
             metric_val2 = time_diff,
             data =  os.time()
            }

end

res = run()

for k,v in pairs(res) do
    print(k, v)
end


