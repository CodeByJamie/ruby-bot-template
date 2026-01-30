class Ping
    attr_reader :name, :description, :options

    def initialize
        @name = "ping"
        @description = "Replies with pong!"
        @options = [
            {
                type: 3,
                name: "mode",
                description: "The type of ping to perform",
                required: true,
                autocomplete: true 
            }
        ]
    end

    def execute(interaction)
        # Extract the value the user selected/typed
        # interaction.data["options"] is an array of options provided
        selected_mode = interaction.data["options"]&.find { |o| o["name"] == "mode" }&.dig("value")

        interaction.respond(content: "🏓 Pong! You selected the **#{selected_mode}** mode.")
    end
end