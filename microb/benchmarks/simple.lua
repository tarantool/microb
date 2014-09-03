-- Simple Tarantool benchmark

local time = require('microb.time')

local BENCH_NAME = 'simple'
local N = 10000

local function insert(s)
    for i = 1, N do
        s:insert({i})
    end
end

local function run()
    local s = box.schema.create_space(BENCH_NAME)
    s:create_index('primary', {unique = true, parts = {1, 'NUM'}})
    local time_diff = time.diff(insert, s)
    s:drop()
    metric = {key = BENCH_NAME..'.insert', description = 'box.insert bench', unit     = 'units/milisec', size = N, time = time_diff}
    return metric
end

return {
    run = run
}
