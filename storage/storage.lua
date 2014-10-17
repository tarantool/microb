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
    local results = box.space.results
    if not results then
        results = box.schema.create_space('results')
        results:create_index('primary', {unique = true, parts = {1, 'NUM', 2, 'NUM'}})
    end
    -- Space for storage tarantool version
    local versions = box.space.versions
    if not versions then
        results = box.schema.create_space('versions')
        results:create_index('primary', {unique = true, parts = {1, 'NUM'}})
    end
    
   if host == nil or port == nil then
        error('Usage: start(host, port)')
    end
    httpd = server.new(host, port, {app_dir = APP_DIR})
    if not httpd then
        error('Tarantool https server not start, have a problem')
    end
    log.info('Started http server at host = %s and port = %s ', host, port)
    httpd:start()
end

return {
start = start
}
