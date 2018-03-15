-- This module for benchmarks counts and other configuration value

-- Engine configuration options
local engine = {
    memtx = {
        engine_name = 'memtx',
        index = { 'hash', 'tree' },
        count = 500000,
        wal_mode = 'none'
    },
    vinyl_write = {
        engine_name = 'vinyl',
        index = { 'tree' },
        count = 25000,
        wal_mode = 'write'
    },
    vinyl_fsync = {
        engine_name = 'vinyl',
        index = { 'tree' },
        count = 25000,
        wal_mode = 'fsync'
    },
}

-- Benchmarks configuration settings (benchmarks must have the same names as in benchmarks folder)
local string = { name = 'string', engines = { engine.vinyl_fsync, engine.vinyl_write, engine.memtx } }
local crud = { name = 'crud', engines = { engine.vinyl_fsync, engine.vinyl_write, engine.memtx } }

-- Global configuration settings
return {
    -- Number of iterations per benchmark
    bench_iters = 15,
    -- Benchmarks to run
    benchmarks = { string, crud }
}
