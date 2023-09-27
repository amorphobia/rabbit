--[[
    Unicode Translator
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

local function translator(input, seg)
    local is_win = package.config:sub(1,1) == "\\"
    local delimiter = string.find(input, "u`")
    if delimiter ~= nil then
        local input_code = string.sub(input, delimiter + 2)
        local codepoint = tonumber(input_code, 16)
        if codepoint ~= nil then
            local ch = utf8.char(codepoint)
            -- to prevent software crashing on Windows
            if is_win and codepoint == 10 then
                ch = "LF"
            end
            local cand = Candidate("unicode", seg.start, seg._end, ch, " Unicode")
            -- input_code = string.format("%04s", input_code)
            -- string.format not working in Hamster
            local num_prefix = 4 - string.len(input_code)
            if num_prefix > 0 then
                input_code = string.rep("0", num_prefix) .. input_code
            end
            cand.preedit = "U+" .. string.upper(input_code)
            yield(cand)
        end
    end
end

return translator
