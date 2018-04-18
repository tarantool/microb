-- This is script for running Tarantool benchmarks

box.cfg {
    log_level = 5,
    wal_dir = 'wal',
}

local microb = require('microb.runner')
microb.start()
