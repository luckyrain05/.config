return {
  {
    "projekt0n/github-nvim-theme",
    lazy = false,
    priority = 1000,
    opts = {
      options = {
        transparent = true, -- strip background so the terminal shows through
      },
    },
    config = function(_, opts)
      require("github-theme").setup(opts)
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "github_dark_dimmed",
    },
  },
}
