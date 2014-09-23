-- This module for starting tarantool benchmarking

local yaml = require('yaml')
local log = require('log')
local remote = require('net.box')

local MODULE = 'microb.'
local BENCH_MOD = MODULE..'benchmarks.'
local BENCH_NAME = BENCH_MOD..'benchmarks'-- Benchmarking module
local BENCH_COUNT = 10
local STORAGE_HOST = '127.0.0.1'
local STORAGE_PORT = '33011' 

-- Function for run some benchmark

local function run_bench()
    -- Make a temporary file fo start benchmark
    local fname = os.tmpname()
    f = io.open(fname, 'w')
    script = "box.cfg{wal_mode='none'}\nyaml=require('yaml')\nprint(yaml.encode(require('"..BENCH_NAME.."').run()))\nos.exit()"
    f:write(script)
    
    -- Start script
    local res = {}

    local fb = io.popen('tarantool < '..fname, 'r')
    res = yaml.decode(fb:read('*a'))
    fb:close()

    if not res then 
        error ('There are not output results for benchmark')
    end
    
    f:close()
    os.remove(fname)

    log.info('Have benchmark result')
    print(res) 
    return res
end

-- Function that  starts benchmarking process

local function start()
    log.info('Start Tarantool benchmarking')

    -- Connection to remote storage by the use box.net.box
    local conn = remote:new(STORAGE_HOST, STORAGE_PORT)
    
    if not conn:ping() then
        error('Remote storage not available or not started')
    end
    
    -- Get results for benchmarks
    local metric_id = nil
    local result = run_bench(b)
    
    for k, res in pairs(result) do    
        local header = conn.space.headers.index.secondary:select({res.key})[1]
        
        -- Add metric in storage 
        if not header then
            log.info('The %s metric is not in the headers table', res.key)
            -- Add tuple with metric in headers space
            conn:call('box.space.headers:auto_increment',{res.key ,res.description, res.unit})
            metric_id = conn.space.headers.index.secondary:select({res.key})[1][1]
            conn.space.results:insert{metric_id, res.version, res.size, res.time_diff}
            log.info('The %s metric added in headers and results spaces with metric_id = %d', res.key, metric_id)
        else
            metric_id = header[1] 
            log.info('We already had some benchmarks result for this metcrics')
            if not conn.space.results:select({metric_id, res.version})[1] then
                log.info('We have not result for metric with id %s on Tarantool %s version', metric_id, res.version) 
                conn.space.results:insert{metric_id, res.version, res.size, res.time_diff}
                log.info('The %s metric added in results spaces with metric_id = %d and tarantool version = %s', res.key, metric_id, res.version)
            else
                conn.space.results:update({metric_id, res.version}, {{'=', 3, res.size}, {'=', 4, res.time_diff}})
                log.info('The %s metric updated in results spaces with metric_id = %d and tarantool version = %s', res.key, metric_id, res.version)
            end
        end
    end
    
    os.exit() 
end

return {
start = start
} 
