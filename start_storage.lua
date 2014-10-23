#!/usr/bin/env tarantool
-- This script for start data storage with Tarantool microB results

local STORAGE_HOST = '0.0.0.0'
local STORAGE_PORT = '33001'

box.cfg {
    log_level = 5,
    listen = 33011,
    --background = true,
    --logger = 'storage.log',
    --pid_file = 'storage.pid'    
}

require('console').listen('127.0.0.1:33003')

storage = require('microb.storage')

storage.start(STORAGE_HOST, STORAGE_PORT)
