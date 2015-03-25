dofile("urlcode.lua")
dofile("table_show.lua")

local url_count = 0
local tries = 0

local downloaded = {}
local addedtolist = {}

read_file = function(file)
  if file then
    local f = assert(io.open(file))
    local data = f:read("*all")
    f:close()
    return data
  else
    return ""
  end
end

wget.callbacks.get_urls = function(file, url, is_css, iri)
  local urls = {}
  local html = nil
  
  local function check(newurl)
    if (downloaded[newurl] ~= true and addedtolist[newurl] ~= true) then
      table.insert(urls, { url=newurl })
      addedtolist[newurl] = true
    end
  end
  
  if string.match(url, "https?://rapid%-search%-engine%.com/") then
    html = read_file(file)
    for newurl in string.gmatch(html, '"(https?://rapidshare%.com/[^"]+)"') do
      check(newurl)
      local newurl1 = string.gsub(newurl, "/files/[0-9]", "/files/")
      check(newurl1)
    end
    for newurl in string.gmatch(html, '"(https?://www%.rapidshare%.com/[^"]+)"') do
      check(newurl)
      local newurl1 = string.gsub(newurl, "/files/[0-9]", "/files/")
      check(newurl1)
    end
  end

  if string.match(url, "rapidshare%.com/files/[0-9]+/") then
    html = read_file(file)
    for newurl in string.gmatch(html, 'location="(https?://[^%.]+%.rapidshare%.com/cgi%-bin/[^"]+)"') do
      check(newurl)
    end
  end
  
  return urls
end

wget.callbacks.httploop_result = function(url, err, http_stat)
  -- NEW for 2014: Slightly more verbose messages because people keep
  -- complaining that it's not moving or not working
  local status_code = http_stat["statcode"]
  last_http_statcode = status_code
  
  url_count = url_count + 1
  io.stdout:write(url_count .. "=" .. status_code .. " " .. url["url"] .. ".  \n")
  io.stdout:flush()
  
  if (status_code >= 200 and status_code <= 399) then
    downloaded[url["url"]] = true
  end
  
  if status_code >= 500 or
    (status_code >= 400 and status_code ~= 404) then
    io.stdout:write("\nServer returned "..http_stat.statcode..". Sleeping.\n")
    io.stdout:flush()

    os.execute("sleep 5")

    tries = tries + 1

    if tries >= 20 then
      io.stdout:write("\nI give up...\n")
      io.stdout:flush()
      return wget.actions.ABORT
    else
      return wget.actions.CONTINUE
    end
  elseif status_code == 0 then
    io.stdout:write("\nServer returned "..http_stat.statcode..". Sleeping.\n")
    io.stdout:flush()

    os.execute("sleep 10")

    tries = tries + 1

    if tries >= 10 then
      io.stdout:write("\nI give up...\n")
      io.stdout:flush()
      return wget.actions.ABORT
    else
      return wget.actions.CONTINUE
    end
  end

  tries = 0

  -- We're okay; sleep a bit (if we have to) and continue
  -- local sleep_time = 0.1 * (math.random(500, 5000) / 100.0)
  local sleep_time = math.random(1, 5)

  --  if string.match(url["host"], "cdn") or string.match(url["host"], "media") then
  --    -- We should be able to go fast on images since that's what a web browser does
  --    sleep_time = 0
  --  end

  if sleep_time > 0.001 then
    os.execute("sleep " .. sleep_time)
  end

  return wget.actions.NOTHING
end
