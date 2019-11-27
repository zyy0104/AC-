local cache_urls = {
    ["/comments/getlist"] = {["expire"] = "5"},
}

local request_uri_without_args = ngx.re.sub(ngx.var.request_uri, "\\?.*", "")
local urlinfo = cache_urls[request_uri_without_args]

if urlinfo then
    local key = {ngx.var.request_method, " ",ngx.var.scheme, "://",ngx.var.host, request_uri_without_args,}
    local args = ngx.req.get_uri_args()
    local query = ngx.encode_args(args)
    if query ~= "" then
        key[#key + 1] = "?"
        key[#key + 1] = query
    end
    key = table.concat(key)
    key = ngx.md5(key)
    ngx.var.cache_key = key
    ngx.var.cache_expire = urlinfo["expire"]
    ngx.var.cache_fetch_skip = 0
    ngx.var.cache_store_skip = 0
end
