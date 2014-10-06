-- This module for starting tarantool benchmarking

local yaml = require('yaml')
local log = require('log')
local remote = require('net.box')

local MODULE = 'microb.benchmarks.'

local list = require('microb.cfg').list -- Listing benchmark files
local result = {} -- Table for benchmark results

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
    
    -- Start script
    local res = {}

    local fb = io.popen('tarantool < '..fname, 'r')
    res = yaml.decode(fb:read('*a'))
    fb:close()

    f:close()
    os.remove(fname)

    if not res then 
        error ('There are not output results for '..bench_name..' benchmark')
    end

    log.info('Have %s benchmark result', bench_name)
    
    for x, y in pairs(res) do
        print(x, y)
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
            print ('!!!!!!!!!!!!!!!!!!'..res.key)
            -- Add metric in storage 
            if not header then
                log.info('The %s metric is not in the headers table', res.key)
                -- Add tuple with metric in headers space
                header = conn:call('box.space.headers:auto_increment',{res.key ,res.description, res.unit})[1]
                log.info('The %s metric added in headers space with metric_id = %d', res.key, header[1])
            end
            metric_id = header[1]
            conn.space.results:replace{metric_id, res.version, res.size, res.time_diff}
            log.info('The %s metric added/updated in results spaces with metric_id = %d and tarantool version = %s', res.key, metric_id, res.version)
        end
    end
    
    os.exit() 
end

return {
start = start
} 
