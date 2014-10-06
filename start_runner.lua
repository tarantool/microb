-- This is script for running Tarantool benchmarks 

box.cfg {
    log_level = 5,
    --logger = 'runner.log',
    --pid_file = 'runner.pid',
}

local STORAGE_HOST = '127.0.0.1'
local STORAGE_PORT = '33011'

require('console').listen('127.0.0.1:33000')

local microb = require('microb.runner')

microb.start(STORAGE_HOST, STORAGE_PORT)
