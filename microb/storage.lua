-- This module for start and work Trantool microB metric storage

local log = require('log')
local server = require('http.server')
local socket = require('socket')

local APP_DIR = '.'

local function start(host, port)
    -- Space for storage metric header
    local headers = box.space.headers
    if not headers then
        headers = box.schema.create_space('headers')
        headers:create_index('primary', {unique = true, parts = {1, 'STR'}})
    end
    -- Space for storage metric value
    result = box.space.result 
    if not result then
        result = box.schema.create_space('result')
        result:create_index('primary', {unique = true, parts = {1, 'STR'}})
    end
    if host == nil or port == nil then
        error('Usage: start(host, port)')
    end
    httpd = server.new(host, port, {app_dir = APP_DIR})
    log.info('Started http server at host = %s and port = %s ', host, port)
    httpd:start()
end

return {
start = start
}
