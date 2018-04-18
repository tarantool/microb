-- This is module includes tarantool benchmark
-- insert one million tuples into space. Test based on
-- http://tarantool.org/doc/book/app_c_lua_tutorial.html

local log = require('log')
local time = require('microb.time')
local result = {}

-- random string generation
local function string_function()
    local random_number
    local random_string = ""
    for _ = 1, 10, 1 do
        random_number = math.random(65, 90)
        random_string = random_string .. string.char(random_number)
    end
    return random_string
end

-- million strings benchmark
local function test(space, count)
    local string_value
    for i = 1, count, 1 do
        string_value = string_function()
        local t = box.tuple.new({ i, string_value })
        space:replace(t)
    end
end

-- measurements
local function bench(space, name, description, tab, count)
    math.randomseed(0)
    log.info('Start %s benchmarks', name)
    local time_diff = time.diff(test, space, count)
    local version = box.info.version
    local res = {
        key = name, description = description,
        version = version, unit = 'units/milisec',
        size = count, time_diff = time_diff,
        space_id = space.id, engine = space.engine, tab = tab
    }

    table.insert(result, res)
end

local function start_bench(index, engine, count, wal_mode)
    local space = box.schema.create_space('tester', { engine = engine })
    space:create_index('primary', { type = index, parts = { 1, 'UNSIGNED' } })
    bench(space,
          'string.' .. index .. '.' .. engine .. '.' .. wal_mode,
          'insert million strings',
          'strings', count)
    space:drop()
    return result
end

-- Function for running benchmarking

return {
    run = start_bench
}
