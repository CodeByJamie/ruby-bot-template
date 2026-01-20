require "discordrb"
require "dotenv/load"
require "colorize"
require_relative "src/utils/logger"

class ExtendedClient < Discordrb::Bot 
    attr_reader :commands, :buttons, :menus, :modals

    # Initialise the client
    def initialize

        if ENV["CLIENT_TOKEN"].empty? || ENV["CLIENT_ID"].empty?
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
    end

    # Loader for all the modules required
    def loadModules()

        # Initialise a "loaded" module counter (purely for logging)
        totalModules = 0

        # Build the path to the source file
        srcPath = File.join(__dir__, "src").tr("\\", "/")

        # Scan all the module folders for .rb files
        files = Dir.glob(File.join(srcPath, "{commands,events,interactions}/**/*.rb"))

        # Exit the process if no files were found
        if files.empty?
            Logger.notification(LogType::CRITICAL, "No files were found in the specified modules.")
            exit 1
        end

        # Loop through all of the files and cache them
        files.each do |file|
            begin
                formattedFile = file.tr("\\", "/")
                # Dynamically import the fle
                load formattedFile

                # Convert the file name into the className
                className = File.basename(formattedFile, ".rb").split('_').map(&:capitalize).join

                if Object.const_defined?(className)                             
                    # Create a new instance of the module
                    component = Object.const_get(className).new
                else
                    Logger.notification(LogType::WARNING, "Class #{className} not found in #{formattedFile}")
                    next
                end

                # Split the file path into it's category and name
                relativePath = formattedFile.sub("#{srcPath}/", "").split("/")
                category = relativePath.find{ |dir| ["interactions", "commands", "events"].include?(dir) }

                # A case function for specific modules
                case category
                    # Handles modules that are in the "commands" directory
                    when "commands"
                        # Check if the loaded command follows the specific structure
                        if component.respond_to?(:name) && component.name

                            # Cache the loaded command to the client
                            @commands[component.name] = component
                            totalModules += 1
                        else
                            # Throw a notification if the file does not follow the format
                            Logger.notification(LogType::WARNING, "Skipped #{className}: Missing @name attribute.")
                        end

                    # Handles modules that are in the "interactions" directory
                    when "interactions"
                        # Determine which interaction needs to be loaded "Buttons", "Modals" or "Menus"
                        subModule = relativePath.find{ |int| ["buttons", "menus", "modals"].include?(int) }

                        # Cache the loaded interaction to the client
                        instance_variable_get("@#{subModule}")[component.name] = component
                        totalModules += 1

                    when "events"
                        # execute the event
                        component.execute(self)
                        totalModules += 1
                end

            # If an error occurred during the loading process, display it
            rescue => error
                Logger.error("Failed to load #{file}", error)
            end
        end
        Logger.notification(LogType::SYSTEM, "Loaded #{totalModules} modules.")
    end

    # Function to handle any incoming interactions
    def handleInteractions()
        # Detect when an interaction is created
        self.interaction_create do |event|

            case event.interaction.type
                # Handle when the interaction is a command
                when 2

                    # Fetch the command name
                    commandName = event.interaction.data["name"] 
            
                    # Fetch the command from the cache
                    command = @commands[commandName]

                    # If the command exists then execute it
                    if command
                        begin
                            command.execute(event)
                        
                        # If an error occurred => throw the error
                        rescue => error
                                Logger.error("Command Execution Failed", error)
                                event.respond(content: "Sorry an unexpected error occurred when executing the command. Please contact the developer.", ephemeral: true)
                        end
                    else
                        Logger.notification(LogType::SYSTEM, "Command: /#{commandName} was not found in the cache.");
                        event.respond(content: "Command not found. If this was a mistake, please contact the developer.", ephemeral: true)
                    end

                # Handle if the interaction is a MessageComponent ("buttons" or "menus") (type 3)
                when 3
                        # Fetch the custom id from the interaction
                        custom_id = event.interaction.data["custom_id"]

                        # Fetch the module from the cache
                        @buttons[custom_id]&.execute(event) || @menus[custom_id]&.execute(event)
                
                # Handle if the interaction is a Modal Submit (type 5)
                when 5
                    custom_id = event.interaction.data["custom_id"]
                    modal = @modals[custom_id]

                    if modal
                        modal.execute(event)
                    else
                        Logger.notification(LogType::SYSTEM, "Modal ID: #{custom_id} not found in the cache.")
                    end
            end
        end
    end 

    # Function to register commands onto Discord
    def registerCommands()

        # Handle when the client is ready
        self.ready do |event|
            # Map through the commands to register them
            @commands.each do |name, cmd|
                self.register_application_command(
                    name.to_sym, 
                    cmd.description || "No description", 
                )
            end
            Logger.notification(LogType::SYSTEM, "Registered #{@commands.size} commands locally.")
        end
    end
end

# Main Execution
client = ExtendedClient.new
client.loadModules
client.handleInteractions
client.registerCommands
client.run