return {
  -- Automatically insert `end` after `function`, `if ... then`, `for ... do`, etc.
  {
    "RRethy/nvim-treesitter-endwise",
    -- Must load before FileType fires: it attaches to buffers on FileType.
    event = { "BufReadPre", "BufNewFile" },
  },
}
