-- This is script for running Tarantool benchmarks

box.cfg {
    log_level = 5,
    wal_dir = '/opt/microb/wal',
    -- wal_mode = 'write',
    --logger = 'runner.log',
    --pid_file = 'runner.pid',
}

local microb = require('microb.runner')
microb.start()
