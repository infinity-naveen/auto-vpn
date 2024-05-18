# auto-vpn

auto-vpn is a utility designed for MacOS to streamline VPN connections with Multi-Factor Authentication (MFA) support. It creates a background service that continuously attempts to connect to the VPN, ensuring a persistent connection even in the event of internet disconnection or system restarts. By automating the VPN connection process, it eliminates the need for manual intervention such as entering MFA OTPs and waiting for connections.

## Installation

To use auto-vpn, you need to have two dependencies installed: `openvpn` and `oath-toolkit`. You can install them using Homebrew:

```bash
brew install openvpn
brew install oath-toolkit
```

Once dependencies are installed, you can install auto-vpn by running the following command in your terminal:

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/infinity-naveen/auto-vpn/main/install.sh)"
```

## Configuration

To configure auto-vpn, follow these steps:

1. Set the configuration with the following command, replacing placeholders with your own information:
   ```bash
   sudo auto-vpn --set-config profile_ovpn_file_path username pin 2fa_secret_key
   ```
    - `profile_ovpn_file_path`: Path to your OpenVPN profile file.
    - `username`: Your VPN username.
    - `pin`: Your VPN login PIN.
    - `2fa_secret_key`: Secret key to generate MFA OTP.

2. Start the auto-vpn service with:
   ```bash
   sudo auto-vpn --start
   ```

<br/>

Once started, the background process will maintain the VPN connection persistently, even if the system restarts or internet fluctuates, unless manually stopped by using the command:
```bash
sudo auto-vpn --stop
```

You can check the status of the connection & utility process anytime using:
```bash
sudo auto-vpn --status
```


For more detailed information and available commands, you can use:
```bash
sudo auto-vpn --help
```
