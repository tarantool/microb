-- This is module includes Tarantool benchmarks

--[[box.cfg{
wal_mode = 'none'}]]--

local log = require('log')
local clock = require('clock')
--local BENCH_NAME = 'insert-random-hash-bench'
--local DESCRIPTION = 'Insert benchmark (hash, random)'
local N = 2^32
local COUNT = require('microb.init_cfg').count

local index = {'tree'} -- Options indexes
local format = {'NUM', 'STR'} -- Options keys view
local result = {}

-- Descriptions function for benchmark

local function insert_bench(s, n)
    local key = math.random(0, n)
    s:replace({key, key})
end

local function select_bench(s, n)
    local key = math.random(0, n)
    s:select({key})
end

local function update(s, key, n)
    s:update({key})
end

local function delete_bench(s, n)
    local key = math.random(0, n)
    s:delete({key})
end

-- List with function (and their name) for benchmarking 

local list = {
    {'insert', insert_bench},
    {'select', select_bench},
    {'delete', delete_bench},
}

-- Function for doing benchmark functions iteration

local function do_bench(count, fun, s, n)
    for i=1,count,1 do
        fun(s, n)
    end
end

-- Function for start function benchmark with diffrent options

local function bench(s, fun, name, index)
    math.randomseed(0)
    log.info ('Start %s functions benchmark with %s index and sophia engine', name, index)
    local time_diff = 1000 * clock.bench(do_bench, COUNT, fun, s, N)[1]
    local version = box.info.version
    local res = {key = 'sophia.'..name..'.'..index, description = name..' sophia benchmark with '..index..' index', version = version, unit = 'units/milisec', size = COUNT, time_diff = time_diff}
    for k,v in pairs(res) do
        log.info('%s, %s', k,v)
    end
    table.insert(result, res)
end

-- Function for running benchmarking

local function run()
    --Select index option
    for x,y in pairs(index) do
        local s = box.schema.create_space('glade', {engine = 'vinyl'})
        s:create_index('primary', {type = y, parts = {1, 'NUM'}})
        -- Selecting benchmark funcion
        for k,v in pairs(list) do
            bench(s, v[2], v[1], y)
        end
    s:drop()
    end
    
    return result
end

--local res = run()

return {
    run = run
}
