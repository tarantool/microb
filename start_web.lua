-- This is script for running Tarantool benchmarks 

box.cfg {
    log_level = 5,
    --logger = 'runner.log',
    --pid_file = 'runner.pid',
}

require('console').listen('127.0.0.1:33002')

local WEB_HOST = '0.0.0.0' 
local WEB_PORT = '22222'
local STORAGE_HOST = '127.0.0.1'
local STORAGE_PORT = '33011'
local web = require('microb.web')

web.start(WEB_HOST, WEB_PORT, STORAGE_HOST, STORAGE_PORT)
