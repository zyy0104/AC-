local json = require "cjson"
local ac_mod = require "jhac.ac_module"
local jhred = require "redis.jhcredis"
local num = ngx.var.arg_num
local key = ngx.var.arg_key

local function retJson(data)
    local result = {
        errno = 0,
        errmsg = "SUCCESS",
        data = data,
        count = #data,
    }
    ngx.say(json.encode(result))
    ngx.exit(200)
end

if not num or not key then
    retJson({})
end

--redis连接
local red = jhred.getRedisConnect()
if not red then
    ngx.log(ngx.ERR,"failed to get redis connect")
    retJson({})
end

--redis中缓存keyname,例如ac_filter_dict_0
local ac_incr_keyname = "ac_filter_set_incr"
local keyname = "ac_filter_set_" .. num
local new_data = {}
local data = ac_mod.splitKey(key)
for k,v in ipairs(data) do
    local ok,err = red:srem(keyname,v)
    if ok then 
        table.insert(new_data,v) 
        red:incr(ac_incr_keyname)
    end
end

--把连接放入连接池
jhred.close_redis(red)

retJson(new_data)
