-- This is module includes tarantool benchmark
-- insert one million tuples into space. Test based on 
-- http://tarantool.org/doc/book/app_c_lua_tutorial.html

local log = require('log')
local time = require('microb.time')
local COUNT = 1000
local index = {'hash', 'tree'} -- Options indexes
local result = {}

-- random string generation
function string_function()
    local random_number
    local random_string = ""
    for x = 1,10,1 do
        random_number = math.random(65, 90)
        random_string = random_string .. string.char(random_number)
    end
    return random_string
end

-- million strings benchmark
local function test(s)
    local string_value
    for i = 1,COUNT,1 do
        string_value = string_function()
        t = box.tuple.new({i,string_value})
        box.space.tester:replace(t)
    end
end

-- measurements
local function bench(s, name, description, tab)
    math.randomseed(0)
    log.info ('Start %s benchmarks', name)
    local time_diff = time.diff(test, s)
    local version = box.info.version
    local res = {
        key = name, description = description, 
        version = version, unit = 'units/milisec', 
        size = COUNT, time_diff = time_diff,
        space_id=s.id, engine=s.engine, tab = tab
    }

    table.insert(result, res)
end

local function start_bench(index)
    local s = box.schema.create_space('tester')
    s:create_index('primary', {type = index, parts = {1, 'UNSIGNED'}})
    bench(s, 'string.' .. index, 'insert million strings', 'strings')
    s:drop()
end

-- Function for running benchmarking

local function run()
    --Select index option
    for _,ind in ipairs(index) do
        start_bench(ind)
    end
    return result
end

return {
    run = run
}
