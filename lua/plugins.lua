return require('packer').startup(function(use)
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'

  -- Theme
  use 'folke/tokyonight.nvim'

  -- GitHub CoPilot
  use 'github/copilot.vim'

  -- Fzf native
  use {'nvim-telescope/telescope-fzf-native.nvim', run = ' arch -arm64 make' }

  -- Telescope
  use {
	'nvim-telescope/telescope.nvim', tag = '0.1.0',
    requires = {
      'nvim-lua/plenary.nvim',
    },
  }

  -- Telescope orthogonal deps
  use {
    'nvim-treesitter/nvim-treesitter',
    run = function() require('nvim-treesitter.install').update({ with_sync = true }) end,
  }
end)

