# Bash-Hero

**Bash-Hero** is a command-line RPG game that tracks your character's stats, including hearts, rupees, experience points (XP), and actions taken. The script includes various commands for interacting with the game, such as healing hearts, gaining XP, logging in, and more.

## Features

- **RPG Stats Tracking**: Track hearts, rupees, XP, and actions.
- **XP and Leveling System**: Gain XP and level up as you progress.
- **Random Rewards**: Earn rupees through random encounters.
- **Login/Logout**: Simulate logging in and out with Redis data.

## Installation

1. Download the `bash-hero.sh` script:

   ```bash
   
    git clone https://github.com/psyfercom/bash-hero.git
   ```

2. Make the script executable:

   ```bash
   chmod +x bash-hero.sh
   ```

3. Add the script to your `.bashrc` or equivalent shell configuration file for automatic loading:

   ```bash
   echo 'source /path/to/bash-hero.sh' >> ~/.bashrc
   ```

   Replace `/path/to/bash-hero.sh` with the actual path where the script is located.

4. Reload your shell configuration:

   ```bash
   source ~/.bashrc
   ```

## Usage

- **Display Stats**: The script displays your current stats after each action.
- **Commands**:
  - `<username>`: Display verbose stats.
  - `potion`: Heal one heart.
  - `login`: Log in and load stats from Redis simulation.
  - `logout`: Log out and reset stats.
  - `version`: Display Bash-Hero version.
  - `help`: Display help message.

## Example

```bash
./bash-hero.sh
```

## License

This project is licensed under the MIT License.

---

This README now includes instructions on adding the script to the `.bashrc` file for automatic loading.
