-- This module for start and work Trantool microB metric storage

local log = require('log')
local server = require('http.server')
local socket = require('socket')

local APP_DIR = '.'

-- Function for start tarantool storage

local function start(host, port)
    -- Add grants for 'guest' users
    box.schema.user.grant('guest', 'read,write,execute', 'universe')
    
    -- Space for storage metric header
    local headers = box.space.headers
    if not headers then
        headers = box.schema.create_space('headers')
        headers:create_index('primary', {unique = true, parts = {1, 'NUM'}})
        headers:create_index('secondary', {unique = true, parts = {2, 'STR'}})
    end
    -- Space for storage metric value
    result = box.space.result 
    if not result then
        results = box.schema.create_space('results')
        results:create_index('primary', {unique = true, parts = {1, 'NUM', 2, 'STR'}})
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
