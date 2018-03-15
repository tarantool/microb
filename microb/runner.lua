-- This module for starting tarantool benchmarking

local yaml = require('yaml')
local log = require('log')
local ITER_COUNT = require('microb.cfg').bench_iters -- Listing benchmark files
local MODULE = 'microb.benchmarks.'
local list = require('microb.cfg').benchmarks -- Listing benchmark files

local function cleanup_vinyl(results)
    for _, result in pairs(results) do
        if result.engine == 'vinyl' then
            os.execute('rm -rf ' .. tostring(result.space_id))
        end
    end
end

local function median(values_list)
    table.sort(values_list)
    local len = #values_list
    if not math.fmod(len, 2) then
        return math.ceil((values_list[len / 2] + values_list[len / 2 + 1]) / 2)
    end
    return values_list[math.ceil(len / 2)]
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

local function write_bench_script_file(fname, bench, engine_name, index, wal_mode, count)

    local f = io.open(fname, 'w')
    local script = [[box.cfg{wal_mode=']] .. wal_mode .. [['}
                    yaml=require('yaml')
                    print(yaml.encode(require(']]
            .. MODULE .. bench .. [[').run(']]
            .. index .. [[',']]
            .. engine_name .. [[',]]
            .. count .. [[,']]
            .. wal_mode .. [[')))
                    os.exit()
                ]]
    f:write(script)
    return f
end

local function start_script(fname, results, count)
    log.info('Iteration #' .. tostring(count))
    -- Start script
    local fb = io.popen('tarantool < ' .. fname, 'r')
    local iteration = yaml.decode(fb:read('*a'))
    results[count] = iteration

    fb:close()
    cleanup_vinyl(iteration)
    log.info('----------------------------------')
end

local function report_results(res, bench)
    if not res then
        error('There are not output results for ' .. bench .. ' benchmark')
    end

    log.info('Have %s result median values', bench)
    for _, v in pairs(res) do
        log.info('Have %s, %d result median values', v.key, v.time_diff)
    end
end

local function run_bench(config)

    local fname = os.tmpname()
    local bench = config['name']
    for _, engine_config in ipairs(config['engines']) do
        for _, index in ipairs(engine_config['index']) do

            local tmp_file = write_bench_script_file(fname,
                bench,
                engine_config.engine_name,
                index,
                engine_config.wal_mode,
                engine_config.count)

            local results = {}
            for count = 1, ITER_COUNT do
                start_script(fname, results, count)
            end

            -- cleanup
            tmp_file:close()
            os.remove(fname)

            -- Average results
            local res = bench_avg(results)
            report_results(res, bench)
        end
    end
end

-- Function that  starts benchmarking process
local function start()
    log.info('Start Tarantool benchmarking')

    if not list then
        error('Benchmarks list is empty')
    end
    for _, config in pairs(list) do
        log.info("Start '%s' benchmark", config['name'])
        run_bench(config)
    end
    os.exit()
end

return {
    start = start
}
