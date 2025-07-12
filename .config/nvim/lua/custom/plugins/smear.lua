return {
  "sphamba/smear-cursor.nvim",
  enabled = false,
  opts = {
    smear_between_buffers = true,
    smear_between_neighbor_lines = false,
    scroll_buffer_space = true,
    legacy_computing_symbols_support = false,
    -- faster
    stiffness = 0.6,               -- 0.6      [0, 1]
    trailing_stiffness = 0.3,      -- 0.3      [0, 1]
    distance_stop_animating = 0.5, -- 0.1      > 0
    hide_target_hack = false,      -- true     boolean
  },
}
