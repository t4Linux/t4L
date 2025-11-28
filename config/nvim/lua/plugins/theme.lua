return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      -- Załaduj motyw
      require("catppuccin").setup()
      -- Ustaw go jako aktywny
      vim.cmd.colorscheme("catppuccin")
    end,
  },

  -- Opcjonalnie: wyłącz domyślny tokyonight, żeby nie ładował się niepotrzebnie
  { "folke/tokyonight.nvim", enabled = false },
}
