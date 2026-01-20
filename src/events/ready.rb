class Ready
  def execute(client)
    client.ready do |event|
      Logger.notification(LogType::CLIENT, "Logged in as #{client.profile.username}.")
      
      # Set bot status
      client.update_status("online", "with Ruby!", nil)
    end
  end
end