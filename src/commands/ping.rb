class Ping
    attr_reader :name, :description

    def initialize
        @name = "ping"
        @description = "Replies with pong!"
    end

    def execute(event)
        event.respond(content: "🏓 Pong!",)
    end
end