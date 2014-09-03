-- This module for start and work Trantool microB metric storage

local function start()
    -- Space for storage metric header
    local headers = box.space.headers
    if not headers then
        headers = box.schema.create_space('headers')
    end
    headers:create_index('primary', {unique = true, parts = {1, 'STR'}})
    -- Space for storage metric value
    result = box.space.result 
    if not result then
        result = box.schema.create_space('result')
    end
    result:create_index('primary', {unique = true, parts = {1, 'STR'}})
end

return {
start = start
}
