-- This module for start web page with 
-- Tarantool benchmark charts

local server = require('http.server')
local log = require('log')

local APP_DIR = './web/'


-- Handler fo request

local function handler()
end

-- Start tarantool server

local function start(host, port)
    if host == nil or port == nil then
        error('Usage: start(host, port)')
    end
    httpd = server.new(host, port, {app_dir = APP_DIR})
    log.info('Started http server at host = %s and port = %s ', host, port)

    httpd:route({ path = '', file = '/index.html'}, handler)
    httpd:start()
end

return {
start = start
}
