-- This module for starting tarantool benchmarking

local yaml = require('yaml')
local log = require('log')
local remote = require('net.box')
local ITER_COUNT = 20
local MODULE = 'microb.benchmarks.'

local list = require('microb.cfg').list -- Listing benchmark files
local result = {} -- Table for benchmark results

--[[ Function for transformation version string in some integer
Example:
version = 1.6.3-404-g4f59a4
int_version = 1 06 030 404 
]]--

local function int_v(version)
    local a, b, c, d = string.match(version, '^(.-)%.(.*)%.(%d-)%-(%d*)%-')
    local result = a * 10^8 + b * 10^6 + c * 10^4 + d
    return result
end

local function cleanup_sophia(results)
    for _, result in pairs(results) do
        if result.engine == 'sophia' then
            os.execute('rm -rf ' .. tostring(result.space_id))
        end
    end
end

local function median(values_list)
    table.sort(values_list)
    local len = #values_list
    if not math.fmod(len, 2) then
        return math.ceil((values_list[len/2] + values_list[len/2 + 1]) / 2)
    end
    return values_list[math.ceil(len/2)]
end

local function bench_avg(iterations)
    local map = {}
    -- Fill bench results
    for _, bench in pairs(iterations) do
        for _, result in pairs(bench) do
            if not map[result.key] then
                map[result.key] = {}
            end
            table.insert(map[result.key], result.time_diff)
        end
    end

    -- Use median average
    local res = iterations[1]
    for _, total in pairs(res) do
        total.time_diff = median(map[total.key])
    end
    return res
end


-- Function for run some benchmark

local function run_bench(bench_name)
    -- Make a temporary file fo start benchmark
    local fname = os.tmpname()
    f = io.open(fname, 'w')
    script = [[box.cfg{wal_mode='none'}
        yaml=require('yaml')
        print(yaml.encode(require(']]..MODULE..bench_name..[[').run()))
        os.exit()
    ]]
    f:write(script)

    local results = {}
    for i=1,ITER_COUNT do
        log.info('Iteration #' .. tostring(i))
        -- Start script
        local iteration = {}
        local fb = io.popen('tarantool < '..fname, 'r')
        iteration = yaml.decode(fb:read('*a'))
        results[i] = iteration
        fb:close()
        cleanup_sophia(iteration)
        log.info('----------------------------------')
    end
    f:close()
    os.remove(fname)

    -- Average results
    local res = bench_avg(results)
    if not res then 
        error ('There are not output results for '..bench_name..' benchmark')
    end

    log.info('Have %s result median values', bench_name)
    
    for x, y in pairs(res) do
        log.info(yaml.encode(y))
    end
    for k,v in pairs(res) do
        table.insert(result, v)
    end
end

-- Function that  starts benchmarking process

local function start(storage_host, storage_port)
    log.info('Start Tarantool benchmarking')
    if not list then
    error ('Benchmarks list is empty')
    end

    -- Connection to remote storage by the use box.net.box
    local conn = remote:new(storage_host, storage_port)
    
    if not conn:ping() then
        error('Remote storage not available or not started')
    end
    
    -- Get results for all benchmarks in list
    for k,b in pairs(list) do
        log.info("Start '%s' benchmark", b)
        local metric_id = nil
        
        run_bench(b)
        
        for k,res in pairs(result) do
            local header = conn.space.headers.index.secondary:select({res.key})[1]
            -- Add metric in storage 
            if not header then
                log.info('The %s metric is not in the headers table', res.key)
                -- Add tuple with metric in headers space
                header = conn:call('box.space.headers:auto_increment',{res.key ,res.description, res.unit})[1]
                log.info('The %s metric added in headers space with metric_id = %d', res.key, header[1])
            end
            local int_version = int_v(res.version)
            conn.space.versions:replace{int_version, res.version}
            log.info('The %s tarantool version in versions table', res.version)
            metric_id = header[1]
            conn.space.results:replace{int_version, metric_id, res.size, res.time_diff}
            log.info('The %s metric added/updated in results spaces with metric_id = %d and tarantool version = %s', res.key, metric_id, res.version)
        end
    end
    
    os.exit() 
end

return {
start = start
} 
