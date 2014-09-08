-- This module for starting tarantool benchmarking

local yaml = require('yaml')
local log = require('log')
local remote = require('net.box')

local BENCH_MOD = 'microb.benchmarks.'
local LIST_FILE = 'init_list'
local STORAGE_HOST = '127.0.0.1'
local STORAGE_PORT = '33002' 

-- Listing benchmark files
local list = require(BENCH_MOD..LIST_FILE)

-- Function for run some benchmark
local function run_bench(bench_name)
    -- Make a temporary file fo start benchmark
    local fname = os.tmpname()
    f = io.open(fname, 'w')
    script = "box.cfg{}\nyaml=require('yaml')\nprint(yaml.encode(require('"..BENCH_MOD..bench_name.."').run()))\nos.exit()"
    f:write(script)

    local fb = io.popen('tarantool < '..fname, 'r')
    local res = yaml.decode(fb:read('*a'))
    
    fb:close()
    f:close()
    os.remove(fname)
    if not res then 
        error ('There are not output results for '..bench_name..' benchmark')
    end
    log.info('Have %s benchmark result', bench_name) 
    for x, y in pairs(res) do
        print (x, y)
    end
    return (res)
end

-- Function that  starts benchmarking process
local function start()
    log.info('Start Tarantool benchmarking')
    if not list then
    error ('Benchmarks list is empty')
    end

    -- Connection to remote storage by the use box.net.box
    conn = remote:new(STORAGE_HOST, STORAGE_PORT)
    print (conn.state, conn:ping())
    if not conn:ping() then
        error('Remote storage not available or not started')
    end
    print('hey')
    -- Get results for all benchmarks in list
    for k,b in pairs(list) do
        res = run_bench(b)
        print ('res',res.key)
        metric_id = conn.space.headers.index.secondary:select({res.key})[1]
        print(metric_id)
        if not metric_id then
            log.info('The %s metric is not in the headers table', res.key)
            -- Add tuple with metric in headers space
            conn:call('box.space.headers:auto_increment', {res.key}, res.description, res.unit)
            metric_id = conn.space.headers.index.secondary:select({res.key})
            print ('res')
            for k,v in pairs(metric_id) do print(k,v) end
            conn.space.results:insert{res.key, res.version, res.size, res.time_diff}
        else
            log.info('We already had some benchmarks result for this metcrics')
            if not conn.space.results:select({metric_id, res.version}) then
                log.info('The %s metric on tarantool %s is not in the result table', res.key, res.version)
                conn.space.results:insert{metric_id, res.version, res.size, res.time_diff}
            else
                 log.info('The %s metric on tarantool %s have tuple in the table. Updating this result', res.key, res.version)
                 conn.space.results.res:update({metric_id, res.version}, {{res.size, res.time_diff}})
            end
        end
    end
    
    --os.exit() 
end

return {
start = start
} 
