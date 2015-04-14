-- This is module includes Tarantool benchmarks

--[[box.cfg{
wal_mode = 'none'}]]--

local log = require('log')
local time = require('microb.time')
--local BENCH_NAME = 'insert-random-hash-bench'
--local DESCRIPTION = 'Insert benchmark (hash, random)'
local N = 2^32
local COUNT = require('microb.cfg').count

local index = {'hash', 'tree'} -- Options indexes
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

local function update_bench(s, n)
    local key = math.random(0, n)
    s:update({key}, {{'=', 2, key}})
end

local function delete_bench(s, n)
    local key = math.random(0, n)
    s:delete({key})
end

-- List with function (and their name) for benchmarking 

local list = {
    {'insert', insert_bench},
    {'select', select_bench},
    {'update', update_bench},
    {'delete', delete_bench},
}

-- Function for doing benchmark functions iteration

local function do_bench(count, fun, s, n)
    for i=1,count,1 do
        fun(s, n)
    end
end

-- Function for start function benchmark with diffrent options

local function bench(s, fun, name, description)
    math.randomseed(0)
    log.info ('Start %s benchmarks', name)
    local time_diff = time.diff(do_bench, COUNT, fun, s, N)
    local version = box.info.version
    local res = {
        key = name, description = description, 
        version = version, unit = 'units/milisec', 
        size = COUNT, time_diff = time_diff,
        space_id=s.id, engine=s.engine
    }
    --[[for k,v in pairs(res) do
        log.info('%s, %s', k,v)
    end]]--
    table.insert(result, res)
end

-- Function for start benchmarking loop

local function start_bench(index, sophia)
    local s = nil
    if sophia then 
        s = box.schema.create_space('glade1', {engine = 'sophia'})
    else
        s = box.schema.create_space('glade1')
    end
    s:create_index('primary', {type = index, parts = {1, 'NUM'}}) 
    -- Selecting benchmark funcion
    for k,fname in pairs(list) do
        local description = fname[1]..' benchmark with '..index..' index'
        local name = fname[1]..'.'..index
        if sophia then
            name = name..'.sophia'
            description = 'Sophia, '..description
        end 
        bench(s, fname[2], name, description)
    end
    s:drop()
end

-- Function for running benchmarking

local function run()
    --Select index option
    for _,ind in ipairs(index) do
        start_bench(ind)
    end
    -- Start benchmarking for tarantool with sophia
    local ind = 'tree'
    start_bench(ind, 1)   
    return result
end

--local res = run()

return {
    run = run
}
