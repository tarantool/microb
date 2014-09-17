-- Select Tarantool benchmark

local time = require('microb.time')

local BENCH_NAME = 'select-tree-bench'
local DESCRIPTION = 'Select benchmark (with tree index) '
local N = 10000

local function insert(s)
    for i = 1, N do
        s:insert({i, i*i})
    end
end

local function bench(s)
    for i = 1, N do
        s:select{i}
    end
end

local function run()
    local s = box.schema.create_space('glade')
    s:create_index('primary', {type = 'tree', parts = {1, 'NUM'}})
    insert(s)
    local time_diff = time.diff(bench, s)
    s:drop()
    local version = box.info.version
    result = {key = BENCH_NAME, description = DESCRIPTION, version = version, unit = 'units/milisec', size = N, time_diff = time_diff}
    return result
end

return {
run = run
}
