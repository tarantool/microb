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

--[[ Function for transformation version string in some integer
Example:
version = 1.6.3-404-g4f59a4
int_version = 1 063 404  
]]--

local function int_v(version)
    local a = string.match(version, '^(.-)%.')
    local b = string.match(version, '%.(.*)%.')
    local c = string.match(version, '%.(%d-)%-') 
    local d = string.match(version, '%-(%d*)%-')
    local result = a * 10^8 + b * 10^6 + c * 1000 + d
    return result
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
       log.info('Storage is empty')
    end

    -- Add version and sort this
    local vt = {} -- versions table
    for _,res in pairs(sel) do 
        local i = nil
        local version = res[2]
        -- Check that Tarantool version is in versions table 
        print ('version in categ',version, i)  
        for k,v in pairs(vt) do
            if v == version then
                print ('have version in categ')
                i = 1
                break
            end
        end
        if not i then
            vt[int_v(version)] = version
            print('Insert version in catergor')
        end
    end

    local t = {} -- table for sort int_version
  
    for k,v in pairs(vt) do
        print(k,v)
        table.insert(t, k)
    end

    table.sort(t)

    for _,v in ipairs(t) do
        print(v)
        table.insert(dt.categories, vt[v])
    end

    for x,y in pairs(dt.categories) do
        print (x,y)
    end

    for _,res in ipairs(sel) do
        
        local i = nil
        local metric_id = res[1]
        local version = res[2] 
        -- Get benchmark metric name
        local mname = conn.space.headers:select{metric_id}[1][3]
        
        local version_id = nil

        -- Get version id from version table
        for k,v in ipairs(dt.categories) do
            if version == v then
                version_id = k
                print ('version_id = ', version_id)
            end
        end
                
        -- Get result data
        req = res[3]
        time = res[4] -- in milisec
        local result_data = (req/time)*1000

        -- Get benchmark result
        if id == metric_id then   
            table.insert(series.data, result_data, version_id)
        else
            if series then
                table.insert(dt.series, series)
            end
            series = {name = mname, data = {}}
            table.insert(series.data, result_data, version_id)
        end
        
        id = metric_id
    end
    
    if series then
        table.insert(dt.series, series)
    end
    for k,v in pairs(dt.series) do
print ('series')
for x,y in pairs(v.data) do
print (x,y)
end
    
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