-- This module for start web page with 
-- Tarantool benchmark charts

local log = require('log')
local json = require('json')
local server = require('http.server')
local remote = require('net.box')

local APP_DIR = '.'
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
    local series = nil
    
    for k,v in pairs(sel) do
        local i = nil

        -- Get benchmark metric name
        local mname = conn.space.headers:select{v[1]}[1][3]
        
        for x,y in pairs(dt.categories) do

        -- Get Tarantool version 
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
        
        -- Get result data
        local result_data = (v[3]/v[4])*1000

        -- Get benchmark result
        if id == v[1] then   
            table.insert(series.data, result_data)
        else
            if series then
                table.insert(dt.series, series)
            end
            series = {name = mname, data = {result_data}}
            
        end
        
        id = v[1] 
    end     
    if series then
        table.insert(dt.series, series)
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
