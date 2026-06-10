-- ts-compat.lua
--
-- Compatibility shim: nvim-treesitter `master` branch (archived 2025-05-24)
-- vs Neovim 0.12+.
--
-- Neovim 0.11 made treesitter query matches return *arrays* of nodes
-- (`match[capture_id]` == `TSNode[]`) instead of a single `TSNode`, behind an
-- `all` opt with legacy coercion. Neovim 0.12 *removed* that legacy coercion:
-- `vim.treesitter.query.add_predicate`/`add_directive` now only honor
-- `opts.force` and ALWAYS hand the handler array-valued captures.
--
-- The archived master branch still registers its handlers with
-- `{ force = true, all = false }` and treats `match[id]` as a single node, so
-- on 0.12 every affected directive/predicate calls a node method on a table
-- and crashes, e.g. render-markdown -> markdown injections:
--   "attempt to call method 'range' (a nil value)"  (get_node_text -> get_range)
--
-- We patch the failure points here. Safe & idempotent; `master` is archived so
-- nothing upstream will ever overwrite the plugin and re-break this.

local M = {}

-- Coerce an array-style match value down to a single node (last captured).
local function pick(node)
  if type(node) == "table" then
    return node[#node]
  end
  return node
end

function M.setup()
  local ts = vim.treesitter

  -- 1) Make get_node_text tolerant of array-style match values.
  --    TSNode is userdata, so the `type(node) == "table"` guard only ever fires
  --    for the new array form and leaves all normal calls untouched. This alone
  --    fixes the directives set-lang-from-mimetype!, set-lang-from-info-string!
  --    and downcase! without having to replicate nvim-treesitter internals.
  if not ts.__compat_get_node_text_wrapped then
    local orig = ts.get_node_text
    ts.get_node_text = function(node, source, opts)
      node = pick(node)
      if node == nil then
        return nil
      end
      return orig(node, source, opts)
    end
    ts.__compat_get_node_text_wrapped = true
  end

  -- 2) Re-register the predicates that call node methods directly (the
  --    get_node_text wrapper can't help these). force=true overrides the
  --    handlers nvim-treesitter registered when it loaded.
  local ok, query = pcall(require, "vim.treesitter.query")
  if not ok then
    return
  end

  query.add_predicate("nth?", function(match, _pattern, _bufnr, pred)
    local node = pick(match[pred[2]])
    local n = tonumber(pred[3])
    if node and node:parent() and node:parent():named_child_count() > n then
      return node:parent():named_child(n) == node
    end
    return false
  end, { force = true })

  query.add_predicate("is?", function(match, _pattern, bufnr, pred)
    local locals = require("nvim-treesitter.locals")
    local node = pick(match[pred[2]])
    local types = { unpack(pred, 3) }
    if not node then
      return true
    end
    local _, _, kind = locals.find_definition(node, bufnr)
    return vim.tbl_contains(types, kind)
  end, { force = true })

  query.add_predicate("kind-eq?", function(match, _pattern, _bufnr, pred)
    local node = pick(match[pred[2]])
    local types = { unpack(pred, 3) }
    if not node then
      return true
    end
    return vim.tbl_contains(types, node:type())
  end, { force = true })
end

return M
