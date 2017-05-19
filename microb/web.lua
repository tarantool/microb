-- This module for start web page with 
-- Tarantool benchmark charts

local log = require('log')
local json = require('json')
local server = require('http.server')
local remote = require('net.box')
local runner = require('microb.runner')

local MODULE_DIR = debug.getinfo(1).source:match("@?(.*/)") or '.'
local APP_DIR = MODULE_DIR
local AUTH_TOKEN
local conn = nil

-- Function for box-net-box connect/reconnect

local function remote_box(host, port)
    log.info('Starting_remote connection box-net-box on host = %s, port = %s', host, port)
    if conn == nil then
        conn = remote:new(host, port, { reconnect_after = .1 })
    end
    return conn
end

--[[ Function for transformation version string in some integer
 13 Example:
 14 version = 1.6.3-404-g4f59a4
 15 int_version = 1 06 030 404 
 16 ]]--

local function int_v(version)
    local a, b, c, d = string.match(version, '^(.-)%.(.*)%.(%d-)%-(%d*)%-')
    local result = a * 10^8 + b * 10^6 + c * 10^4 + d
    return result
end


-- Function for getting Tarantool version in storage

local function get_versions(self)
    log.info('start getting version list')
    
    -- Start box-net-box connection for using storage
    local conn = conn    
    if not conn:ping() then
        log.info('Remote storage not available or not started')
    end

    -- Get all versions from versions table 
    local versions  = conn.space.versions:select({iterator = ALL})
    local data = {}
    
    -- Create data information for client
    for _,v in ipairs(versions) do
        table.insert(data, v[2])
    end
    
    data = json.encode(data)
    log.debug(data)
    return self:render({ text = data })
end

-- Handler for request

local function start_handler(self)
    
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
       dt = json.encode(dt)
       return self:render({text=dt})
    end
 
    -- Configuration series {name = 'name' , data = {}} each metric
    local st = {} -- table with series
    
    for _,tuple in ipairs(sel) do
        local metric_id = tuple[1]
        st[metric_id] = {name = tuple[2], data = {}}
    end
    
    -- Check parameters from client (first and last version)
    -- Get data from storage versions table
    local fv = self:query_param('firstVersion')
    local lv = self:query_param('lastVersion')    

    if not fv then
        fv = conn.space.versions.index.primary:max()[1]
        lv = fv
    else
        fv = int_v(fv)
        lv = int_v(lv)
        if fv > lv then fv, lv = lv, fv end
    end 
     
    local i = fv
    log.info('Get data from version table. First version %s', i) 
    
    sel = conn.space.versions:select({fv}, {iterator = 'GE'})
    
    -- Iteration for all version in version table
    for _,version in ipairs(sel) do

        --Check version interval 
        if version[1] > lv then break end 

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
                local val = res[1][4]
                local result_data
                -- check microbench format and common format
                -- common format: [int_version, metric_id, -1, value]
                -- microb format: [int_version, metric_id, count, time]
                if req > 0 then
                    -- in milisec
                    result_data = (req/val)*1000
                else
                    result_data = val
                end
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

    log.debug(dt)

    return self:render({ text = dt })
end

local function push(bench_id, value, version, unit, tab)
    local conn = conn
    if not conn:ping() then
        log.info('Remote storage not available or not started')
    end
    local name = bench_id..'#'..tab
    local header = conn.space.headers.index.secondary:select({name})[1]

    -- Add metric in storage 
    if not header then
        header = conn:call('box.space.headers:auto_increment',{{name ,'remote bench data', unit}})
    end

    local int_version = runner.int_v(version)
    conn.space.versions:replace{int_version, version}
    metric_id = header[1]
    -- Add result in common format
    conn.space.results:replace{int_version, metric_id, -1, tonumber(value)}
end

local function insert(self)
    local key = self:query_param('key')
    local bench_id = self:query_param('name')
    local val = self:query_param('param')
    local version = self:query_param('v')
    local unit = self:query_param('unit')
    local tab = self:query_param('tab')

    if not key or not bench_id or not val or not version or not unit then
        return self:render({text='{"error": "wrong params"}'})
    end

    -- check auth token
    if key ~= AUTH_TOKEN then
        return self:render({text='{"error":"invalid auth token"}'})
    end

    -- call insert for params
    push(bench_id, val, version, unit, tab)
    return self:render({text='{"status": "OK"}'})
end

-- Start tarantool server

local function start(web_host, web_port, storage_host, storage_port, auth_token)
    if web_host == nil or web_port == nil then
        error('Usage: start(host, port)')
    end
    httpd = server.new(web_host, web_port, {app_dir = APP_DIR})
    AUTH_TOKEN = auth_token
    
    if not httpd then
        error('Tarantool https server not start, have a problem')
    end
    
    conn = remote_box(storage_host, storage_port)
    
    log.info('Started http server at host = %s and port = %s ', web_host, web_port)

    httpd:route({ path = '', file = '/index.html'})
    httpd:route({ path = '/bench'}, start_handler)
    httpd:route({ path = '/versionList'}, get_versions)
    httpd:route({ path = '/push'}, insert)
    
    httpd:start()
end

return {
start = start
}
