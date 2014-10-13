-- This module for start web page with 
-- Tarantool benchmark charts

local log = require('log')
local json = require('json')
local server = require('http.server')
local remote = require('net.box')

local APP_DIR = '.'

local conn = nil

-- Function for box-net-bo connect/reconnert
local function remote_box(host, port)
    print ('start_remote')
    if conn == nil then
        conn = remote:new(host, port, { reconnect_after = .1 })
    end
    return conn
end

-- Handler for request
local function handler(self)
-- Start box-net-box connection for using storage
    local conn = conn    
    if not conn:ping() then
        error('Remote storage not available or not started')
    end
    
    log.info('Start getting data')
    
    --[[####################################################
    JSON use highcharts.js (see .../templates/index.html)
    Example:
    {
        "series":[
            {"name":"insert benchmark", "data":[111, 222]},
            {"name":"select benchmark", "data":[333, 123]}
        ]   
        "categories":
            ["version-1.6-404", "version-1.6-405"]
    }
    ########################################################]]-- 
    
    local dt = {categories = {}, series = {}}   
 
    -- Get data results from storage and data configuration
    local sel = conn.space.results:select({iterator = ALL})
    local id = 0
    local series = nil
    
    if not sel[1] then
       log.error('Storage is empty')
    end

    for _,res in ipairs(sel) do
        
        local i = nil
        local metric_id = res[1]

        -- Get benchmark metric name
        local mname = conn.space.headers:select{metric_id}[1][3]
        
        for _,version in ipairs(dt.categories) do

        -- Get Tarantool version 
            print ('version in categ',version)  
            if version == res[2] then
                print ('have version in categ')
                i = 1
                break
            end
        end

        if not i then
            table.insert(dt.categories, res[2])
            print('Insert version in catergor')
        end
        
        -- Get result data
        req = res[3]
        time = res[4] -- in milisec
        local result_data = (req/time)*1000

        -- Get benchmark result
        if id == metric_id then   
            table.insert(series.data, result_data)
        else
            if series then
                table.insert(dt.series, series)
            end
            series = {name = mname, data = {result_data}}
            
        end
        
        id = metric_id
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
