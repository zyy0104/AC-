local my_cache = ngx.shared.my_cache
local method = ngx.req.get_method()

if method == "GET" then
    local key = ngx.var.arg_key
    local value = my_cache:get(key)
    if value then
        ngx.print(value)
    end
elseif method == "PUT" then
    local value = ngx.req.get_body_data()
    local expire = ngx.var.arg_expire or 60
    local key = ngx.var.arg_key
    local success,err,forcible = my_cache:set(key,value,expire)
    if err then
        my_cache:delete(key)
    end
else
    ngx.exit(ngx.HTTP_NOT_ALLOWED)
end



