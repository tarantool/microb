-- This module for start web page with 
-- Tarantool benchmark charts

local log = require('log')
local json = require('json')
local server = require('http.server')
local remote = require('net.box')

local APP_DIR = '.'

local conn = nil

-- Function for box-net-box connect/reconnect

local function remote_box(host, port)
    log.info('Starting_remote connection box-net-box on host = %s, port = %s', host, port)
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
        log.info('Remote storage not available or not started')
    end
    
    log.info('Start getting data')
    
    --[[####################################################
    JSON use highcharts.js (see .../templates/index.html)
    Example data table:
    {
        "series":[
            {"name":"insert benchmark", "data":[111, 222]},
            {"name":"select benchmark", "data":[333, 123]}
        ]   
        "categories":
            ["version-1.6-404", "version-1.6-405"]
    }
    ########################################################]]-- 
    
    local dt = {series = {}, categories = {}} -- data table   
 
    -- Get data results from storage(headers table) and data configuration
    local sel = conn.space.headers:select({iterator = ALL})
    
    -- Check the availability of data
    if not sel[1] then
       log.info('Storage is empty')
    end
 
    -- Configuration series {name = 'name' , data = {}} each metric
    local st = {} -- table with series
    
    for _,tuple in ipairs(sel) do
        local metric_id = tuple[1]
        st[metric_id] = {name = tuple[2], data = {}}
    end
    
    -- Get data from storage versions table
    sel = conn.space.versions:select({iterator = ALL})
   
    local i = sel[1][2]
    log.info('Get data from version table. First version %s', i) 
    
    -- Iteration for all version in version table
    for _,version in ipairs(sel) do
        -- Insert version in categories table
        table.insert(dt.categories, version[2])
        log.debug('Add %s version in categories', version[2])

        -- Iteration on the metric
        for metric_id, series in pairs(st) do
            local res = conn.space.results:select({version[1], metric_id})
            log.debug('Get result', res[1])
            if res[1] then 
                -- Calculate benchmark result
                local req = res[1][3]
                local time = res[1][4] -- in milisec
                local result_data = (req/time)*1000
                table.insert(series.data, result_data)
            else
                table.insert(series.data, 0) 
            end
            log.debug('Insert result') 
        end
    end
    log.info('Add all result in series data')
    
    -- Insert series from st in dt.series
    for metric_id, series in pairs(st) do
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
