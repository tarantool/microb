-- Simple Tarantool benchmark

--box.cfg{}

local time = require('microb.time')

local BENCH_NAME = 'simple'
local N = 10000

local function bench(s)
    for i = 1, N do
        s:insert({i, i*i})
        s:select{i}
    end
end

local function run()
    local s = box.schema.create_space(BENCH_NAME)
    s:create_index('primary', {unique = true, parts = {1, 'NUM'}})
    local time_diff = time.diff(bench, s)
    s:drop()
    local version = box.info.version
    result = {key = BENCH_NAME..'.insert-select', description = 'box insert and select bench', version = version, unit = 'units/milisec', size = N, time_diff = time_diff}
    return result
end

--run()

return {
run = run
}
