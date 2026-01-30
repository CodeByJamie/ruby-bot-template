class PingAutocomplete
	attr_reader :name, :autocomplete

	def initialize
		# Matches the slash command name
		@name = "ping"
	end

	def execute(interaction)
		# Identify the option being typed in
		focused_option = interaction.data["options"].find { |o| o["focused"] }
		return unless focused_option

		# Normalize the input
		input = focused_option["value"].to_s.downcase

		# Your data source (can be a constant, a DB call, or an API)
		data_set = ["Ruby", "Crystal", "JavaScript", "Python", "Rust"]

		# Filter based on input
		# We select items that contain the input string
		suggestions = data_set.select { |item| item.downcase.include?(input) }

		# Discord only allows a maximum of 25 choices
		choices = suggestions.first(25).map do |item|
			{ name: item, value: item.downcase }
		end

		interaction.show_autocomplete_choices(choices)
	end
end