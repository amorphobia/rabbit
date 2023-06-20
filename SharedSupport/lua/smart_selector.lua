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
