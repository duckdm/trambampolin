local Buffer = require("trambampolin.Buffer")
local Line = require("trambampolin.Line")
local Float = require("trambampolin.Float")

---@class Trambampolin
---@field version string
---@field lines Line[]
---@field line_no number
---@field buffer Buffer
---@field columns table
---
---@field print fun(self: Trambampolin): Trambampolin
---@field set_buffer fun(self: Trambampolin, buffer: Buffer): Trambampolin
---@field get_buffer fun(self: Trambampolin): Buffer
---@field line fun(self: Trambampolin, text: string, color: string): Trambampolin
---@field virt_line fun(self: Trambampolin, text: string, opts: table): Trambampolin
---@field inc fun(self: Trambampolin): Trambampolin
---@field get_line_no fun(self: Trambampolin): number
---@field col fun(self: Trambampolin, text: string, color: string|table): Trambampolin
---@field into_line fun(self: Trambampolin, opts: table): Trambampolin
---@field into_virt_line fun(self: Trambampolin, opts: table): Trambampolin
local M = {}

function M:new()
    local m = {}
    setmetatable(m, self)
    self.__index = self

    self.version = "v0.0.1-alpha"
    self.lines = {}
    self.line_no = 0
    self.buffer = nil
    self.columns = {}

    return self
end

function M:print()

    local buffer = self:get_buffer()
    buffer:print(self.lines, 0)

    return self
end

function M:open_float(opts)

    local float = Float:new(self, vim.tbl_extend('force', {
        title = nil,
        width = 10,
        col = 0,
        row = 1,
        enter = false,
    }, opts))
    float:open()

    self:print()

    return float
end
function M:close_float(float) float:close() return self end

function M:create_buffer(opt)

    self.buffer = Buffer:new(vim.tbl_extend('force', {
        listed = false,
        scratch = true
    }, opt))

    return self.buffer
end

function M:set_buffer(buffer)
    self.buffer = buffer
    return self
end

function M:get_buffer()
    if self.buffer then return self.buffer end
    return self:create_buffer({})
end

--- Add a line to the buffer
---@param text string|number
---@param opts table
---@return Trambampolin
function M:line(text, opts)

    self:get_buffer()
    self:col(text, opts.color or "")
    self:into_line(opts)

    return self
end

--- Add a virtual line to the buffer
---@param text string|number
---@param opts table
---@return Trambampolin
function M:virt_line(text, opts)

    self:get_buffer()
    self:col(text, opts.color or "")
    self:into_virt_line(opts)

    return self
end

function M:col(text, color)
    self:get_buffer()
    local ns_name = nil
    if type(color) == "table" then
        ns_name = color.ns_name
        color = color.color
    end
    table.insert(self.columns, { text = text, color = color, ns_name = ns_name })
    return self
end

function M:into_line(opts)

    local line = Line:new()
    for _, column in ipairs(self.columns) do
        line:col({
            text = column.text,
            color = column.color,
            ns_name = column.ns_name or nil,
            line_no = opts.line_no or nil,
            pos = opts.pos or "overlay",
            col = opts.col or nil,
            meta = opts.meta or nil,
        })
    end
    table.insert(self.lines, line)
    self:inc()
    self.columns = {}

    return self
end

function M:into_virt_line(opts)

    local line = Line:new()
    for _, column in ipairs(self.columns) do
        line:col({
            virt_text = column.text,
            color = column.color,
            ns_name = column.ns_name or nil,
            line_no = opts.line_no or nil,
            pos = opts.pos or "overlay",
            col = opts.col or nil,
            strict_col = opts.strict_col or nil,
        })
    end
    table.insert(self.lines, line)
    self.columns = {}

    return self
end

function M:nl()
    self:line("__NL__", "")
    return self
end

function M:get_line_no()
    return self.line_no
end

function M:from(line_no)
    self.line_no = line_no
    return self
end

function M:inc()
    self.line_no = self.line_no + 1
    return self
end

return M
