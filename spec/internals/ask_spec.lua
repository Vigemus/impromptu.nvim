-- luacheck: globals insulate setup describe it assert mock
-- luacheck: globals before_each after_each

local check = {
  command = function() return assert.spy(_G.vim.api.nvim_command) end,
  call_function = function() return assert.spy(_G.vim.api.nvim_call_function) end,
}

local utils = require("impromptu.utils")

check.for_options = function(options, expected_grid, col_size)
    local ask = require('impromptu.internals.ask')
    local lines_to_grid = require('impromptu.internals.shared').lines_to_grid
    local rendered_options = utils.map(options, ask.render_line)
    local window_ops = {height = col_size, top_offset = 0, bottom_offset = 0}
    local grid = lines_to_grid(rendered_options, window_ops)

    assert.are_same(grid, expected_grid)
    return grid
end

local fn_impls = {
  strdisplaywidth = function(args) return #args[1] end
}

insulate("About #ask form", function()
    before_each(function()
        _G.vim = mock({ api = {
                    nvim_call_function = function(fn, args)
                      local impl = fn_impls[fn]
                      if impl ~= nil then
                        return impl(args)
                      end
                      return 1
                    end,
                    nvim_command = function(_) return "" end,
                    nvim_get_option = function(_) return "" end,
                    nvim_get_var = function(_) return "" end,
            }})

        _G.os = mock({
                execute = function(_) return 0 end,
            })
        end)

  after_each(function()
     package.loaded['impromptu.internals.ask'] = nil
     package.loaded['impromptu.internals.shared'] = nil
   end)

  describe("when writing #options to the buffer", function()
    it("We can serialize options to strings", function()
      local ask = require('impromptu.internals.ask')
      local opts = {
        {key = "a", description = "Option a"}
      }
      local line = ask.render_line(opts[1])

      assert.are_same("[a] Option a", line)
    end)

    it("we can columnize 2 items", function()
      local base = {
        {key = "a", description = "Option a"},
        {key = "b", description = "Option b"}
      }

      check.for_options(base, {{
        "  [a] Option a",
        "  [b] Option b"
      }}, 2)

      check.for_options(base, {
          { "  [a] Option a" }, { "  [b] Option b" }
        }, 1)

    end)

    it("we can columnize 3 items", function()
      local base = {
        {key = "a", description = "Option a"},
        {key = "b", description = "Option b"},
        {key = "c", description = "Option c"}
      }

      check.for_options(base, {{
        "  [a] Option a",
        "  [b] Option b",
        "  [c] Option c"
      }}, 3)

    check.for_options(base, {
        { "  [a] Option a", "  [b] Option b", },
        { "  [c] Option c" }
      }, 2)

    check.for_options(base, {
        { "  [a] Option a", },
        { "  [b] Option b", },
        { "  [c] Option c" }
      }, 1)
    end)

    it("We can turn grid into string", function()
      local base = {
        {key = "a", description = "Option a"},
        {key = "b", description = "Opt b"},
        {key = "c", description = "The option c"},
        {key = "d", description = "Opt d"}
      }

      local grid = check.for_options(base, {
          { "  [a] Option a",  "  [b] Opt b" },
          { "  [c] The option c",  "  [d] Opt d" },
        }, 2)

      local ask = require('impromptu.internals.ask')
      assert.are_same({
          '  [a] Option a      [c] The option c',
          '  [b] Opt b         [d] Opt d',
      }, ask.render_grid(grid, false))

      assert.are_same({
          '  [a] Option a  [c] The option c',
          '  [b] Opt b     [d] Opt d',
      }, ask.render_grid(grid, true))

    end)

  end)
end)
