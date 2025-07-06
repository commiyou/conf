return {
  {
    "AstroNvim/astroui",
    ---@type AstroUIOpts
    opts = {
      colorscheme = "sonokai",
    },
  },
  {
    "sainnhe/sonokai",
    --lazy = false,
    priority = 1000,
    config = function()
      --require 'lualine'.setup { options = { theme = 'sonokai' } }

      vim.cmd [[
        function! s:sonokai_custom() abort
        " Link a highlight group to a predefined highlight group.
        " See `colors/sonokai.vim` for all predefined highlight groups.
        " highlight! link groupA groupB
        " highlight! link groupC groupD

        " Initialize the color palette.
        " The first parameter is a valid value for `g:sonokai_style`,
        " and the second parameter is a valid value for `g:sonokai_colors_override`.
        let l:palette = sonokai#get_palette('default', {})
        " Define a highlight group.
        " The first parameter is the name of a highlight group,
        " the second parameter is the foreground color,
        " the third parameter is the background color,
        " the fourth parameter is for UI highlighting which is optional,
        " and the last parameter is for `guisp` which is also optional.
        " See `autoload/sonokai.vim` for the format of `l:palette`.
        " call sonokai#highlight('NonText', l:palette.red, l:palette.none, 'undercurl', l:palette.red)

        "
        " The "NonText" highlighting will be used for "eol", "extends" and "precedes".  "Whitespace" for "nbsp", "tab" and "trail".
        " SpecialKey Unprintable characters: Text displayed differently from what it realy is. But not 'listchars' whitespace
        call sonokai#highlight('NonText', l:palette.grey, l:palette.none)
        call sonokai#highlight('SpecialKey', l:palette.grey, l:palette.none)
        call sonokai#highlight('Whitespace', l:palette.grey, l:palette.none)

        endfunction

        " TODO:
        " augroup SonokaiCustom
        " autocmd!
        " autocmd ColorScheme sonokai call s:sonokai_custom()
        " augroup END
        ]]

      vim.g.sonokai_transparent_background = 0
      vim.g.sonokai_diagnostic_text_highlight = 1
      vim.g.sonokai_diagnostic_line_highlight = 1
      -- -- The configuration options should be placed before `colorscheme sonokai`.
      vim.g.sonokai_better_performance = 1
      -- vim.g.sonokai_enable_italic = 1
      vim.g.sonokai_disable_italic_comment = 1
      vim.g.sonokai_style = "default"
      --vim.colorscheme = "sonokai"
    end,
  },
}
