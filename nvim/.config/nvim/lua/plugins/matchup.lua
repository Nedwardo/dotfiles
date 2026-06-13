return {
	"andymass/vim-matchup",
	event = "BufReadPost",
	init = function()
		vim.g.matchup_matchparen_deferred = 1
	end,
}
