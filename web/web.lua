-- This module for start web page with 
-- Tarantool benchmark charts

local log = require('log')
local json = require('json')
local server = require('http.server')
local remote = require('net.box')

local APP_DIR = '.'

local conn = nil

local function remote_box(host, port)
    print ('start_remote')
    if conn == nil then
        conn = remote:new(host, port, { reconnect_after = .1 })
    end
    return conn
end

-- Handler fo request
local function handler(self)
-- Start box-net-box connection for using storage
    local conn = conn    
    if not conn:ping() then
        error('Remote storage not available or not started')
    end
    log.info('Start getting data')
    print (conn:ping())
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

local function start(web_host, web_port, storage_host, storage_port)
    if web_host == nil or web_port == nil then
        error('Usage: start(host, port)')
    end
    httpd = server.new(web_host, web_port, {app_dir = APP_DIR})
    
    if not httpd then
        error('Tarantool https server not start, have a problem')
    end
    
    conn = remote_box(storage_host, storage_port)
    
    log.info('Started http server at host = %s and port = %s ', web_host, web_port)

    httpd:route({ path = '', file = '/index.html'})
    httpd:route({ path = '/bench'}, handler)
    httpd:start()
end

return {
start = start
}
