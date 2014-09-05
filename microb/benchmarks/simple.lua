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
    local version = box.info.version
    result = {key = BENCH_NAME..'.insert', description = 'box.insert bench', version = version, unit = 'units/milisec', size = N, time_diff = time_diff}
    return result
end

return {
run = run
}
