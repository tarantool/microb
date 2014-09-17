-- Insert request Tarantool benchmark

local time = require('microb.time')

local BENCH_NAME = 'insert-tree-bench'
local DESCRIPTION = 'Insert benchmark (tree index)'
local N = 10000

local function bench(s)
    for i = 1, N do
        s:insert({i})
    end
end

local function run()
    local s = box.schema.create_space('glade')
    s:create_index('primary', {type = 'tree', parts = {1, 'NUM'}})
    local time_diff = time.diff(bench, s)
    s:drop()
    local version = box.info.version
    result = {key = BENCH_NAME, description = DESCRIPTION, version = version, unit = 'units/milisec', size = N, time_diff = time_diff}
    return result
end

return {
run = run
}
