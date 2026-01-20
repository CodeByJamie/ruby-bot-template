class Hello
    attr_reader :name

    def initialize
        @name = "hello"
    end

    def execute(event)
        event.update_message(content: "Updated pong!")
    end
end