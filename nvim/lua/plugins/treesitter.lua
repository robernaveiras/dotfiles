return {
  "nvim-treesitter/nvim-treesitter",
  opts = function(_, opts)
    -- Extend the ensure_installed list
    vim.list_extend(opts.ensure_installed, {
      "hyprlang",
    })
  end,
}
