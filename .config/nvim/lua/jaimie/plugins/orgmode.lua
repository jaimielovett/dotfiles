return {
	"nvim-orgmode/orgmode",
	event = "VeryLazy",
	ft = { "org" },
	config = function()
		-- Setup orgmode
		require("orgmode").setup({
			org_agenda_files = "~/projects/org/**/*",
			org_default_notes_file = "~/projects/org/refile.org",
			org_todo_keywords = { "TODO(t)", "DOING(f)", "DONE(d)" },

			org_capture_templates = {
				t = "Task",
				tt = {
					description = "Task",
					template = "** TODO %?\n",
					target = "~/projects/org/todo.org",
					headline = "One-Off Tasks",
				},
				ts = {
					description = "Scheduled Task",
					template = "** TODO %?\nSCHEDULED: %^t",
					target = "~/projects/org/todo.org",
					headline = "One-Off Tasks",
				},
				tr = {
					description = "Recurring Task",
					template = "** TODO %?\n %u",
					target = "~/projects/org/todo.org",
					heading = "Recurring",
				},
				j = {
					description = "Journal",
					template = "\n* [%<%d-%m-%Y>]\n** Thankful for\n** What worked\n** What didn't work \n** Reflection",
					target = "~/projects/org/journal.org",
				},
				g = {
					description = "Game",
					template = "\n* BACKLOG %^{TITLE}\n:ADDED: [%<%d-%m-%Y>]\n:RATING: %^{RATING}",
					target = "~/projects/org/entertainment/games.org",
				},

				b = {
					description = "Books",
					template = "\n* TBR %^{TITLE}\n:ADDED: [%<%d-%m-%Y>]\n:RATING: %^{RATING}\n:AUTHOR: %^{AUTHOR}\n** Notes\n%^{NOTES}",
					target = "~/projects/org/entertainment/books.org",
				},
			},
		})
	end,
}
