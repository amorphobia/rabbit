--[[
    Smart Selector
    Copyright (C) 2020  lyserenity <https://github.com/lyserenity>
    Copyright (C) 2023  Xuesong Peng <pengxuesong.cn@gmail.com>

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

local semicolon = "semicolon"
local apostrophe = "apostrophe"
local kRejected = 0 -- do the OS default processing
local kAccepted = 1 -- consume it
local kNoop     = 2 -- leave it to other processors

local function processor(key_event, env)
    if key_event:release() or key_event:alt() or key_event:super() then
        return kNoop
    end
    local key = key_event:repr()
    if key ~= semicolon and key ~= apostrophe then
        return kNoop
    end

    local context = env.engine.context
    if not context:has_menu() then
        return kNoop
    end
    local page_size = env.engine.schema.page_size
    local selected_index = context.composition:back().selected_index
    local page_start = (selected_index / page_size) * page_size

    local index = key == semicolon and 1 or 2
    if context:select(page_start + index) then
        context:commit()
        return kAccepted
    end

    if not context:get_selected_candidate() then
        if context.input:len() <= 1 then
            -- 分号引导的符号需要交给下一个处理器
            return kNoop
        end
        context:clear()
    else
        context:commit()
    end

    return kAccepted
end

return { func = processor }
