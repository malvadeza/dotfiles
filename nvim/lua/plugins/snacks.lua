return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          files = {
            hidden = true,
            ignored = false,
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
