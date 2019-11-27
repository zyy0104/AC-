local json = require "cjson"
local ac_mod = require "jhac.ac_module"
local jhred = require "redis.jhcredis"
local jhcache = require "redis.jhlru"

local my_cache = ngx.shared.my_cache
local num = ngx.var.arg_num
local text = ngx.var.arg_text

local function retJson(data)
    local result = {
        errno = 0,
        errmsg = "SUCCESS",
        data = "",
    }
    if data then
        result["data"] = data
    end
    ngx.say(json.encode(result))
    ngx.exit(200)
end

if not num or not text then
    retJson({})
end

--urlencode text
text = ngx.unescape_uri(text)
text = text:lower()
--去除空格
local newtext, n, err = ngx.re.gsub(text,' ',"","jo")
--去除符号
--

--redis连接
local red = jhred.getRedisConnect()
if not red then
    ngx.log(ngx.ERR,"failed to get redis connect")
    retJson({})
end

local all_key_table,multi_key_table_one,multi_key_table_more,one_count
local _ret_filter_key_name = "ac_filter_all_one_more_dict"
local _ret
--生成字典
local function productDict()
    --获取关键词集合
    --redis中缓存keyname,例如ac_filter_dict_0
    local keyname = "ac_filter_set_" .. num
    local dict,err = red:smembers(keyname)
    if next(dict) == nil then
        retJson({})
    end
    
    local _ret = ac_mod.splitKey2(dict)
    my_cache:set(_ret_filter_key_name,json.encode(_ret))
    return _ret
end

--判断关键词是否变化
local ac_incr_keyname = "ac_filter_set_incr"
local update

local incr_num_old = jhcache.get(ac_incr_keyname)
local incr_num_new,err = red:get(ac_incr_keyname)


if incr_num_new and incr_num_new ~= ngx.null then
    if not incr_num_old then
        --新增、删除关键词发生变化
        update = true
        productDict()
        jhcache.set(ac_incr_keyname,incr_num_new)
    else
        if tonumber(incr_num_old) ~= tonumber(incr_num_new) then
            --新增、删除关键词发生变化
            update = true
            productDict()          
            jhcache.set(ac_incr_keyname,incr_num_new) 
        end
    end
end

--从nginx缓存中获取
_ret = my_cache:get(_ret_filter_key_name)
if not _ret then
    _ret = productDict()
else
    _ret = json.decode(_ret)
end

one_key_table = _ret[0] or _ret["0"]
two_key_table = _ret[1] or _ret["1"]
multi_key_table_one = _ret[2] or _ret["2"]
multi_key_table_more = _ret[3] or _ret["3"]
one_count = _ret[4] or _ret["4"]

if not next(one_key_table) then
    retJson({})
end

--判断是否匹配且不再multi_key_table_more,匹配则返回匹配关键词
local function matchMore(dict)
    if dict and #dict > 1 then
        local match_key_table_str = table.concat(dict,",")
        for ka,va in ipairs(multi_key_table_more) do
            local va_str = table.concat(va,"([^%s]+)")
            local m = ngx.re.find(match_key_table_str,va_str,"jo")
            if m then
                return table.concat(va,"|")
            end 
        end
    end
end


--匹配唯一的关键词
local ac_inst = ac_mod.getAcInst(one_key_table,update,"one")
local match_ret = ac_mod.jhAcMatch(ac_inst,newtext)
local _tkey = match_ret["key"]
if _tkey and _tkey ~= "" then
    retJson(_tkey)
end

--匹配到的关键词table
local match_key_table = {}
for i=0,one_count do
    local ac_inst = ac_mod.getAcInst(two_key_table,update,"two")
    local match_ret = ac_mod.jhAcMatch(ac_inst,newtext)
    local _tkey = match_ret["key"]
    --没有匹配退出
    if not _tkey or _tkey == "" then
        break
    else
        table.insert(match_key_table,_tkey)
        --匹配到，且不再multi_key_table_one中
        if not multi_key_table_one[_tkey] then
            break
        end
    end
    newtext = match_ret["endStr"]
end

retJson(matchMore(match_key_table))
