-- This module for start web page with 
-- Tarantool benchmark charts

local log = require('log')
local json = require('json')
local server = require('http.server')
local remote = require('net.box')

local APP_DIR = './web/'
local STORAGE_HOST = '127.0.0.1'
local STORAGE_PORT = '33011'

-- Handler fo request

local function handler(self)
    -- Connection to remote storage by the use box.net.box
    local conn = remote:new(STORAGE_HOST, STORAGE_PORT)
    
    if not conn:ping() then
        error('Remote storage not available or not started')
    end
    log.info('Start getting data')
   
   
    -- For use highcharts.js (see .../templates/index.html)
    local DATA_CFG = {categories = {}, series = {}}   
 
    -- Get data results from storage and data configuration
    local dt = DATA_CFG
    local sel = conn.space.results:select({iterator = ALL})
    local id = 0
    local series = {}
    
    for k,v in pairs(sel) do
        print(k,v)
        print('have result')
        local i = nil
        for x,y in pairs(dt.categories) do
            print ('version in categ',y)  
            if y == v[2] then
                print ('have version in categ')
                i = 1
                break
            end
        end
        if not i then
            table.insert(dt.categories, v[2])
            print('Insert version in catergor')
        end
        
        if id == v[1] then   
            table.insert(series.data, v[3]/v[4])
        else
            series = {name = v[1], data = {v[3]/v[4]}}
        end
        
        table.insert(dt.series, series)
        id = v[1] 
    end     
    
    dt = json.encode(dt)
    print(dt)
    return self:render({ text = dt })
end

-- Start tarantool server

local function start(host, port)
    if host == nil or port == nil then
        error('Usage: start(host, port)')
    end
    httpd = server.new(host, port, {app_dir = APP_DIR})
    log.info('Started http server at host = %s and port = %s ', host, port)

    httpd:route({ path = '', file = '/index.html'})
    httpd:route({ path = '/bench'}, handler)
    httpd:start()
end

return {
start = start
}
