--[[
    Hint Filter
    Copyright (C) 2020  Rea <hi@rea.ink>
    Copyright (C) 2021, 2023  Xuesong Peng <pengxuesong.cn@gmail.com>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
--]]

local function startswith(str, start)
    return string.sub(str, 1, string.len(start)) == start
end

local function hint(cand, context, reverse)
    if utf8.len(cand.text) < 2 then
        return false
    end
    
    local lookup = " " .. reverse:lookup(cand.text) .. " "
    local short = string.match(lookup, " ([bcdefghjklmnpqrstwxyz][auiov]+) ") or 
                  string.match(lookup, " ([bcdefghjklmnpqrstwxyz][bcdefghjklmnpqrstwxyz]) ")
    local input = context.input 
    if short and utf8.len(input) > utf8.len(short) and not startswith(short, input) then
        cand:get_genuine().comment = cand.comment .. "〔" .. short .. "〕"
        return true
    end

    return false
end

local function danzi(cand)
    if utf8.len(cand.text) < 2 then
        return true
    end
    return false
end

local function commit_hint(cand, hint_text)
    cand:get_genuine().comment = hint_text .. cand.comment
end

local function filter(input, env)
    local is_danzi_mode_on = env.engine.context:get_option('danzi_mode')
    local is_630_hint_on = env.engine.context:get_option('630_hint')
    local is_topup_hint_on = env.engine.context:get_option('topup_hint')
    local hint_text = env.engine.schema.config:get_string('hint_text') or '🚫'
    local first = true
    local input_text = env.engine.context.input
    local no_commit = is_topup_hint_on and input_text:len() < 4 and input_text:match("^[bcdefghjklmnpqrstwxyz]+$")
    for cand in input:iter() do
        if first and no_commit and cand.type ~= 'completion' then
            commit_hint(cand, hint_text)
        end
        first = false
        if not is_danzi_mode_on or danzi(cand) then
            local has_630 = false
            if is_630_hint_on then
                has_630 = hint(cand, env.engine.context, env.reverse)
            end
            yield(cand)
        end
    end
end

local function init(env)
    local dict = env.engine.schema.config:get_string("translator/dictionary")
    env.reverse = ReverseDb("build/" .. dict .. ".reverse.bin")
end

return { init = init, func = filter }
