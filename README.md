# UnivReminder

This is a tool for synchronizing your canvas todo list to apple reminder.

It's too cumbersome to log in to canvas every time you want to check your work, especially after IT department adding a useless 2FA authentication ):. 

This repository helps you to sync all assignment to your apple reminder and no need for you to move away from computer, get your phone and input the 2FA code.

# Usage

Get your canvas token from account settings and set your token by command below
```shell
univcli config set token <your-canvas-token>
```
This will create a config file in ~/.univreminder/config.json and write the token value.

Then let the syncer run and grant apple reminder access to it.

```shell
univcli run
```

This is only test in macOS 18 now.