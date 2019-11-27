nginx≈‰÷√
        set $cache_key "";
        set $cache_expire "";
        set $cache_fetch_skip 1;
        set $cache_store_skip 1;

        rewrite_by_lua_file lua/cache/rewrite.lua;
        
        srcache_fetch_skip $cache_fetch_skip;
        srcache_store_skip $cache_store_skip;
                  
        srcache_fetch GET /cache/content key=$cache_key;
        srcache_store PUT /cache/content key=$cache_key&expire=$cache_expire;       

        add_header X-SRCache-Fetch-Status $srcache_fetch_status;
        add_header X-SRCache-Store-Status $srcache_store_status;