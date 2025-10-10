# Quick Start Guide

Get up and running with F1 Tracker in 5 minutes! 🏎️

## Step 1: Get Your Device's IP Address

### iPhone/iPad:
```
Settings → Wi-Fi → (i) button → IP Address
```
Example: `192.168.1.42`

### Mac:
```
System Settings → Network → [Your Connection] → IP Address
```

---

## Step 2: Configure F1 24

1. Launch **F1 24**
2. Go to **Settings → Telemetry Settings**
3. Set:
   - **UDP Telemetry:** `ON`
   - **IP Address:** `[Your device IP from Step 1]`
   - **Port:** `20777`
   - **Send Rate:** `20Hz`

---

## Step 3: Run the App

1. Open `f1-tracker.xcodeproj` in Xcode
2. Press **⌘+R** to build and run
3. Grant local network permission when asked

---

## Step 4: Start Racing!

1. In F1 24, start any session (practice, qualifying, race)
2. Watch the app dashboard light up with real-time data!

---

## Troubleshooting

### Not seeing data?

**Quick Checklist:**
- ✅ Both devices on same Wi-Fi?
- ✅ Correct IP address in F1 24?
- ✅ UDP Telemetry ON in game?
- ✅ Local network permission granted?
- ✅ In an active session (not menus)?

**Still not working?**

1. **Restart the app**
2. **Toggle UDP Telemetry OFF and ON** in F1 24
3. **Check your IP hasn't changed**
4. **Try port 20778** if 20777 is in use

---

## What You'll See

### 🎯 Real-time Data:
- **Speed** in km/h (large display)
- **Gear** and **RPM** with color indicators
- **Throttle/Brake/Steering** bars
- **Lap times** and position
- **Tyre temperatures** for all 4 wheels
- **Fuel** remaining and laps
- **Engine temp** and ERS status
- **DRS** availability/activation

### 🟢 Connection Status:
- Green dot = Connected and receiving data
- Red dot = Waiting for telemetry

---

## Pro Tips

🔥 **High Refresh Rate:** Set UDP send rate to 60Hz for ultra-smooth updates

📊 **Multiple Devices:** Enable UDP Broadcast Mode to send to multiple devices

🏁 **Practice Mode:** Use Time Trial mode for clean telemetry without other cars

📱 **iPad:** Looks amazing on iPad with the larger screen!

---

**Need more help?** Check the full [README.md](README.md) for detailed information.

**Happy Racing! 🏁**

