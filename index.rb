require "discordrb"
require "dotenv/load"
require "colorize"
require_relative "src/utils/logger"

class ExtendedClient < Discordrb::Bot 
    attr_reader :commands, :buttons, :menus, :modals

    # Initialise the client
    def initialize

        if File.exist?(".env") == false || ENV["CLIENT_TOKEN"].empty? || ENV["CLIENT_ID"].empty?
            Logger.notification(LogType::WARNING, "Environmental Variables have not been set correctly in the .env file!")
            exit 1
        end

        super(
            token: ENV["CLIENT_TOKEN"],
            client_id: ENV["CLIENT_ID"],
            intents: :all,
            log_mode: :error
        )

        # Initialise a Hash for all the required modules
        @commands = {}
        @buttons = {}
        @menus = {}
        @modals = {}
        @autocomplete = {}
    end

    def loadModules
        # Build the absolute path to the src folder
        # Format the path so there are no conflicts on windows (back-slashing)
        srcPath = File.join(__dir__, "src").gsub(/\\/, '/');
        
        # Create a search pattern to look in all the required modules
        files = Dir.glob(File.join(srcPath, "{commands,events,interactions}/**/*.rb"));

        # Check if there are no files are found
        if files.empty?
            Logger.notification(LogType::CRITICAL, "No available modules to load.");
            exit 1
        end
    
        totalModules = files.length;

        # Loop through each file to cache them
        files.each do |file|
            begin
                # Load the file relatively
                load file

                # Fetch the className of each Module
                className = File.read(file).split[1];

                # Check if the class instance exists
                if Object.const_defined?(className)
                    component = Object.const_get(className).new
                else
                    totalModules -= 1;
                    Logger.notification(LogType::WARNING, "Skipped module #{className}, as it does not exist.");
                    next
                end

                relativePath = file.split("src/")[1];
                category = relativePath.split("/")[0];

                # puts "path: #{relativePath} | category: #{category}"

                case category
                    # Cache the command found
                    when "commands"
                        if component.respond_to?(:name) && component.name
                            @commands[component.name] = component
                        else
                            totalModules -= 1
                            Logger.notification(LogType::WARNING, "Skipped module #{className} as it is missing the @name attribute.");
                        end

                    # Execute the event found
                    when "events"
                        component.execute(self);
                    
                    when "interactions"
                        # Determine the type of component (Buttons, Modals etc)
                        subModule = relativePath.split("/")[1];

                        # Dynamically cache the interaction
                        instance_variable_get("@#{subModule}")[component.name] = component;
                end
            rescue => error
                totalModules -= 1;
                Logger.error("Failed to load #{relativePath}", error);
            end
        end

        Logger.notification(LogType::SYSTEM, "Successfully cached #{totalModules}/#{files.length} modules.");
    end

    # Function to register commands
    def registerCommands
        body = @commands.map do |name, cmd|
            data = {
                name: name,
                description: cmd.description
            };

            if cmd.respond_to?(:options)
                data[:options] = cmd.options;
            end

            data
        end

        begin

            # Check if a guild ID was defined in the env
            if ENV["GUILD_ID"]
                Discordrb::API::Application.bulk_overwrite_guild_commands(self.token, ENV["CLIENT_ID"], ENV["GUILD_ID"], body)
            else
                Discordrb::API::Application.bulk_overwrite_global_commands(self.token, ENV["CLIENT_ID"], body)
            end
            Logger.notification(LogType::SYSTEM, "Successfully registered #{@commands.size} commands.");
        rescue  => error
            Logger.error("Failed to register the commands to discord.", error);
            puts error
        end
    end

    # Function to handle interactions
    def handleInteractions
        # Listen for any interaction emitted
        self.interaction_create do |event|
            interaction = event.interaction

            # Handle which interaction was emitted
            case interaction.type
                # Slash Command
                when 2
                    # Fetch the command from the bots cache
                    command = @commands[event.interaction.data["name"]];

                    # If command exists => execute it
                    if command
                        begin
                            command.execute(interaction);
                        rescue => error
                            Logger.error("Command Execution Failed.", error);
                            interaction.respond(content: "Sorry, there was a problem executing the command.");
                        end
                    else
                        Logger.notification(LogType::WARNING, "Command not found in the cache.");
                        interaction.respond(content: "Command not found in the cache.");
                    end

                # Message Components
                when 3
                    # Fetch the custom id for the message component
                    customId = interaction.data["custom_id"]
                    begin
                        @buttons[customId]&.execute(interaction) || @menus[customId]&.execute(interaction)
                    rescue => error
                        Logger.error("Failed to execute #{customId}.", error);
                    end
                
                # Autocomplete Options
                when 4
                    
                    # Find the autocomplete 
                    handler = @autocomplete[interaction.data["name"]]

                    puts "handler: #{handler}"
                    if handler
                        begin
                            handler.execute(interaction)
                        rescue => error
                            Logger.error("Autocomplete Failed.", error)
                        end
                    end

                # Modal Submit
                when 5
                    modal = @modals[interaction.data["custom_id"]]
                    if modal
                        modal.execute(interaction);
                    else
                        Logger.notification(LogType::SYSTEM, "Modal Not found in the cache.");
                    end

            end
        end
    end
end

# Main Execution
client = ExtendedClient.new;
client.loadModules;
client.handleInteractions;
if ARGV.include?("-r")
    Logger.notification(LogType::SYSTEM, "Flag detected. Updating Slash Commands.");
    client.registerCommands
else
    Logger.notification(LogType::SYSTEM, "Pre-cached #{client.commands.size} commands.");
end
client.run;