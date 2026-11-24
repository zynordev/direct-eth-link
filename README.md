# direct-eth-link

**One-command direct Ethernet cable setup** between a **Raspberry Pi** and a **Laptop / Workstation** (Windows, Linux, or macOS) — with **zero router/DHCP required** and **without breaking your Wi-Fi / internet connection**.

---

## Why?

Connecting a Raspberry Pi and a laptop directly with a single Ethernet cable gives you a **1 Gbps, ~0.2 ms latency** private link (perfect for SSH, file transfers, VNC, Sunshine/Moonlight second-monitor streaming, ROS2, or headless Pi setups).

Normally, setting this up is confusing because:
- There is no router/DHCP server on the cable, so both sides fall back to random `169.254.x.x` link-local IPs.
- If you set a static IP *with* a default gateway on Windows/Linux/macOS, your OS may try to route internet traffic through the Ethernet cable and **break your Wi-Fi internet**.

`direct-eth-link` solves this cleanly on **Windows, Linux, macOS, and Raspberry Pi**:
- Assigns a clean `/24` point-to-point subnet (`192.168.10.1` ↔ `192.168.10.2`)
- Sets **NO default gateway** (`never-default yes` on Linux/Pi, no gateway on Windows/macOS) so Wi-Fi stays your internet route
- Optionally sets up **passwordless SSH aliases** (`ssh pi` / `ssh laptop`) and **Wake-on-LAN**

---

## Quick Start

### 1. On your Raspberry Pi
```bash
git clone https://github.com/zynordev/direct-eth-link.git
cd direct-eth-link
./pi/setup-pi.sh          # Configures eth0 -> 192.168.10.2/24
```

### 2. On your Laptop / Workstation

#### Linux (NetworkManager / `nmcli`)
```bash
git clone https://github.com/zynordev/direct-eth-link.git
cd direct-eth-link
./linux/setup-linux.sh    # Auto-detects Ethernet interface -> 192.168.10.1/24
```
To revert/remove: `./linux/setup-linux.sh --remove`

#### Windows (PowerShell as Administrator)
```powershell
git clone https://github.com/zynordev/direct-eth-link.git
cd direct-eth-link
.\windows\setup-windows.ps1
```
To revert to DHCP: `.\windows\setup-windows.ps1 -Remove`

#### macOS
```bash
git clone https://github.com/zynordev/direct-eth-link.git
cd direct-eth-link
./macos/setup-macos.sh
```

### 3. Verify & Optional Passwordless SSH
```bash
./scripts/verify.sh 192.168.10.2
./scripts/setup-ssh.sh pi 192.168.10.2 pi
```
Now you can simply run `ssh pi` over the direct cable!

---

## Default Addressing

| Device | Interface | IP Address | Gateway | Purpose |
|---|---|---|---|---|
| **Laptop / Host** | Ethernet (`eno1`, `Ethernet`, etc.) | `192.168.10.1/24` | *(None)* | Primary workstation |
| **Raspberry Pi** | `eth0` | `192.168.10.2/24` | *(None)* | Edge device / Pi |

All scripts accept custom interface names and IPs as arguments (run with `-h` or `--help`).

---

## Related Projects

- [pi-monitor](https://github.com/zynordev/pi-monitor) — Use a Raspberry Pi 5 as a 1080p60 hardware-accelerated second monitor for Hyprland over this direct Ethernet link.

---

## License

MIT — see [LICENSE](LICENSE).
