-- This is module includes Tarantool benchmarks

local log = require('log')
local time = require('microb.time')
local N = 2 ^ 32
local result = {}

-- Descriptions function for benchmark

local function insert_bench(s, n)
    local key = math.random(0, n)
    s:replace({ key, key })
end

local function select_bench(s, n)
    local key = math.random(0, n)
    s:select({ key })
end

local function update_bench(s, n)
    local key = math.random(0, n)
    s:update({ key }, { { '=', 2, key } })
end

local function delete_bench(s, n)
    local key = math.random(0, n)
    s:delete({ key })
end

-- List with function (and their name) for benchmarking

local list = {
    { 'insert', insert_bench },
    { 'select', select_bench },
    { 'update', update_bench },
    { 'delete', delete_bench },
}

-- Function for doing benchmark functions iteration

local function do_bench(count, fun, s, n)
    for _ = 1, count, 1 do
        fun(s, n)
    end
end

-- Function for start function benchmark with different options

local function bench(s, fun, name, description, tab, count)
    math.randomseed(0)
    log.info('Start %s benchmarks', name)
    local time_diff = time.diff(do_bench, count, fun, s, N)
    local version = box.info.version
    local res = {
        key = name,
        description = description,
        version = version,
        unit = 'units/milisec',
        size = count,
        time_diff = time_diff,
        space_id = s.id,
        engine = s.engine,
        tab = tab
    }

    table.insert(result, res)
end

local function start_bench(index, engine, count, wal_mode)

    local space = box.schema.create_space('glade1', { engine = engine })
    space:create_index('primary', { type = index, parts = { 1, 'UNSIGNED' } })
    -- Selecting benchmark funcion
    for _, fname in pairs(list) do
        local description = fname[1] .. ' benchmark with ' .. index .. ' index'
        local name = fname[1] .. '.' .. index
        name = name .. '.' .. engine .. '.' .. wal_mode
        description = engine .. ', ' .. description
        bench(space, fname[2], name, description, engine, count)
    end
    space:drop()
    return result
end

return {
    run = start_bench
}
