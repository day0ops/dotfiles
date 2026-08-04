if Config.use_nvim_treesitter then
  require("lazyload").on_vim_enter(function()
    vim.api.nvim_create_autocmd("PackChanged", {
      callback = function(ev)
        if ev.data.spec.name == "nvim-treesitter" then
          vim.cmd("TSUpdate")
        end
      end,
    })

    vim.pack.add({
      { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
      { src = "https://github.com/nvim-treesitter/nvim-treesitter-context" },
    })

    -- Custom parsers not shipped with nvim-treesitter.
    local custom_parsers = {
      godoc = {
        filetype = "godoc",
        install_info = {
          url = "https://github.com/fredrikaverpil/tree-sitter-godoc",
          branch = "main",
          generate = false,
          queries = "queries",
        },
      },
      fga = {
        filetype = "fga",
        install_info = {
          url = "https://github.com/matoous/tree-sitter-fga",
          branch = "main",
          generate = false,
          queries = "queries",
        },
      },
    }

    for lang, p in pairs(custom_parsers) do
      vim.treesitter.language.register(lang, p.filetype)
    end

    local function inject_custom_parsers()
      local parsers = require("nvim-treesitter.parsers")
      for lang, p in pairs(custom_parsers) do
        parsers[lang] = { install_info = p.install_info }
      end
    end

    inject_custom_parsers()

    vim.api.nvim_create_autocmd("User", {
      pattern = "TSUpdate",
      callback = inject_custom_parsers,
    })

    require("treesitter-context").setup({
      multiwindow = true,
    })

    local ensure_installed = require("treesitter_parsers").ensure_installed

    --- Auto-start treesitter highlighting for every buffer.
    --- Registered synchronously (see `{ sync = true }` below) so this runs
    --- before any async on_vim_enter callback, preventing race conditions
    --- with plugins that use treesitter queries on LspAttach or at require time.
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("treesitter-start", { clear = true }),
      callback = function(event)
        local bufnr = event.buf
        local ft = event.match
        if ft == "" then
          return
        end

        local lang = vim.treesitter.language.get_lang(ft)
        if not lang then
          return
        end

        local ok = pcall(vim.treesitter.start, bufnr, lang)
        if ok then
          return
        end

        if ensure_installed(lang) then
          pcall(vim.treesitter.start, bufnr, lang)
        end
      end,
    })
  end, { sync = true })
end
