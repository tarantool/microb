#!/usr/bin/env tarantool
-- This script for start data storage with Tarantool microB results

local STORAGE_HOST = '0.0.0.0'
local STORAGE_PORT = '33333'

box.cfg {
    log_level = 5,
    --background = true,
    --logger = 'try.log',
    --pid_file = 'try.pid'    
}

--package.path = './?/init.lua;'..package.path

require('console').listen('127.0.0.1:33113')

storage = require('microb.storage')

storage.start(STORAGE_HOST, STORAGE_PORT)
