microB
======

Microbenchmarking for Tarantool. More details in [wiki](https://github.com/tarantool/microb/wiki)

Install
-------
* [install tarantool](http://tarantool.org/download.html)
* [install luarocks](http://rocks.tarantool.org/)
* create rpm
```bash
$make
```
* install package
```bash
$sudo yum localinstall tarantool-microb-module-x.y-z.noarch.rpm
```
* enable installed modules in tarantool
```bash
$sudo cp /etc/tarantool/instances.available/*.lua  /etc/tarantool/instances.enabled/
```
* Start microb storage and web ui
```bash
$sudo tarantoolctl start microb_storage
$sudo tarantoolctl start microb_web
```


Usage
-----
1. Configure and run storage
```bash
$tarantool start_storage.lua
2015-03-04 18:01:18.469 [4047] main/101/start_storage.lua C> version 1.6.4-428-g248a2a7
2015-03-04 18:01:18.470 [4047] main/101/start_storage.lua C> log level 5
2015-03-04 18:01:18.471 [4047] main/101/start_storage.lua I> mapping 1073741824 bytes for a shared arena...
...
2015-03-04 18:01:18.563 [4047] main/101/start_storage.lua I> Started http server at host = 0.0.0.0 and port = 3300 
2015-03-04 18:01:18.563 [4047] main/104/http/0.0.0.0:33001 I> started
2015-03-04 18:01:18.564 [4047] main C> entering the event loop

```
2. Run web ui
```bash
$tarantool start_web.lua
2015-03-04 18:05:35.162 [4156] main/101/tarantoolctl C> version 1.6.4-428-g248a2a7
2015-03-04 18:05:35.164 [4156] main/101/tarantoolctl C> log level 5
2015-03-04 18:05:35.164 [4156] main/101/tarantoolctl I> mapping 1073741824 bytes for a shared arena...
...
2015-03-04 18:05:35.278 [4156] main/101/microb_web I> Starting_remote connection box-net-box on host = 127.0.0.1, port = 33011
2015-03-04 18:05:35.284 [4156] main/101/microb_web I> Started http server at host = 0.0.0.0 and port = 22222
2015-03-04 18:05:35.285 [4156] main/108/http/0.0.0.0:22222 I> started
2015-03-04 18:05:35.285 [4156] main C> entering the event loop
```

3. Run benchmark
```bash
$tarantool start_runner.lua
```

Nginx proxy pass
----------------
By default microb run web module at 22222 port. If you want you can handle in with nginx
```nginx
server {
        listen 80;
        server_name bench.build.tarantool.org;
        location / {
                proxy_pass http://127.0.0.1:22222;
        }
}
```



