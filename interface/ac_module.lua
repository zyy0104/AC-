local ac = require "ac.load_ac"
local json = require "cjson"
local _M = { version = 1.0 }
local ac_create = ac.create_ac
local ac_match = ac.match

--Worker公共table，用于缓存多模实例
local ac_tab = {}

--实现字符串到table的分割转换
function split(key,sep)
    local sep, fields = sep or "\t", {}
    local pattern = string.format("([^%s]+)", sep)
    local func = function(m)
      local s = ngx.unescape_uri(m[0])
      fields[#fields+1] = s:lower()
      return m[0] 
    end
    ngx.re.gsub(key,pattern,func,"jo")
    return fields
end

--获取多模实例
function _M.getAcInst(dict,update,ty) 
    local ac_inst
    local key = "ac_inst_" .. ty
    if not ac_tab[key] or update then
        if not dict then
	    ngx.log(ngx.ERR,"filter dict is nil")
	    dict = {}
	end
        ac_inst = ac_create(dict)
        ac_tab[key] = ac_inst
    else
        ac_inst = ac_tab[key]
    end
    return ac_inst 
end


function _M.jhAcMatch(ac_inst,match)
    local b,c = ac_match(ac_inst, match)
    local _ret = {
        key = match:sub(b+1,c+1),
        startIndex = b,
        endIndex = c,
        endStr = match:sub(c+2)
    }

    return _ret
end

function _M.splitKey(key)
    local key_list = split(key,",")
    return key_list
end

function _M.splitKey2(dict)
    local one_key_table = {}
    local two_key_table = {}
    --多个key字典,存单个
    local one_count = 0
    local multi_key_table_one = {}
    --多个key字典,存多个
    local multi_key_table_more = {}

    for k,v in ipairs(dict) do
        local _t = split(v,"|")
        if #_t > 1 then
            for k,v in ipairs(_t) do
                table.insert(two_key_table,v)
                multi_key_table_one[v] = v
                one_count = one_count + 1
            end
            table.insert(multi_key_table_more,_t)
        else
            table.insert(one_key_table,_t[1])
        end
    end
    
    local _ret = {
        [0] = one_key_table,
	[1] = two_key_table,
        [2] = multi_key_table_one,
        [3] = multi_key_table_more,
        [4] = one_count,
    }
     
    return _ret
end

return _M
