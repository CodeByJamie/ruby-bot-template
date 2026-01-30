# Ruby Discord Bot Template

A clean, modular, and easy-to-use template for building Discord bots with Ruby. This project is configured with best practices in mind, including environment variable management, a structured command layout, and ready-to-go dependency handling.

## 🚀 Features

- **Quick Start**: Pre-configured setup to get your bot running in minutes.
- **Environment Management**: Uses `dotenv` for secure token and configuration storage.
- **Modular Design**: organized folder structure to keep your commands and logic clean.
- **Discordrb**: Built on top of the powerful [discordrb](https://github.com/shardlab/discordrb) gem.

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

- **Ruby** (Version 3.4 or higher recommended)
- **Bundler** (`gem install bundler`)

## 🛠️ Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/CodeByJamie/ruby-bot-template.git
   cd ruby-bot-template
   ```

2. **Bundle (If necessary)**
    ```bash
    bundle install
    ```
- This ensures your Gemfile.lock is up to date with the latest dependencies.

3. **Running the process** <br />
    There are 2 ways to run the process:
    - **Registering Slash Commands & running the bot.**
    ```bash
    ruby index.rb -r
    ```
    - **Without -r which will run your bot**
    ```bash
    ruby index.rb
    ```
> [!TIP] 
> Please note: That everytime you update the logic of your code, you do **not need to run -r**. You only need to add the flag if you have update the command data, such as the name, description or added options.