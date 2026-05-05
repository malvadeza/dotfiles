return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          files = {
            hidden = true,
            ignored = true,
            follow = true,
          },
          explorer = {
            hidden = true,
            ignored = true,
          },
          grep = {
            hidden = true,
            follow = true,
          },
        },
      },
    },
  },
}
