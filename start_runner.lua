-- This is script for running Tarantool benchmarks 

box.cfg {
    log_level = 5,
    --logger = 'runner.log',
    --pid_file = 'runner.pid',
}

require('console').listen('127.0.0.1:33000')

local microb = require('microb.runner')

microb.start()
