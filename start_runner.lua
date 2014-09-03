--
-- This is script for running Tarantool benchmarks 
--

box.cfg {
}

--print(package.path)

local microb = require('microb.benchmarks.simple')

res = microb.run()

for k,v in pairs(res) do
    print (k, v)
end

