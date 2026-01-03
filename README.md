# Patient Monitoring App

A real-time patient monitoring application built with React Native (Expo) that displays sensor data from an Arduino device. The app monitors patient posture, pressure, and battery levels with a modern, intuitive UI.

## Features

- 📊 **Real-time Sensor Data**: Displays posture, pressure, and battery level updates every 500ms
- 🎨 **Modern UI**: Beautiful, dark-themed interface with color-coded indicators
- ⚠️ **Alert System**: Visual warnings for dangerous positions and high pressure (>30 mmHg)
- 🔋 **Battery Monitoring**: Color-coded battery level indicators
- 📱 **Cross-platform**: Works on iOS, Android, and Web

## Prerequisites

- Node.js (v18 or higher)
- npm or yarn
- Expo CLI
- Arduino device with serial communication
- Windows PC (for the development startup script)

## Installation

1. Clone the repository:
```bash
git clone <your-repo-url>
cd PatientMonitoringApp
```

2. Install dependencies:
```bash
npm install
```

3. Install server dependencies:
```bash
cd server
npm install
cd ..
```

## Configuration

### IP Address Setup

Update the server IP address in `ip.ts`:

```typescript
export const SERVER_IP = "YOUR_IP_ADDRESS"; // Change this
export const SERVER_PORT = "3000";
```

### Server Configuration

Edit `server/server.js` to configure:
- Serial port (default: COM3 for Windows, /dev/tty.usbserial-xxx for macOS/Linux)
- Baud rate (default: 9600)

## Usage

### Windows (Automated)

Use the provided startup script:

1. **Double-click** `start-dev.bat` or run:
```powershell
.\start-dev.ps1
```

The script will:
- Automatically detect your local IP address
- Update `ip.ts` with the detected IP
- Start the server in a new window
- Launch Expo development server

### Manual Setup

1. **Start the server**:
```bash
cd server
node server.js
```

2. **Update IP address** in `ip.ts` with your PC's IP address

3. **Start Expo**:
```bash
npx expo start
```

4. **Connect your mobile device**:
   - Scan the QR code with Expo Go app (iOS/Android)
   - Or press `w` for web, `a` for Android emulator, `i` for iOS simulator

## Network Considerations

⚠️ **Important**: For the app to connect to the server, both devices must be on the same network.

- ✅ **Recommended**: Use a mobile hotspot or private WiFi network
- ⚠️ **Public networks** (eduroam, etc.) may have client isolation enabled
- 🔌 **Alternative**: Use USB tethering for direct connection

## Project Structure

```
PatientMonitoringApp/
├── app/
│   ├── index.tsx          # Main monitoring screen
│   └── _layout.tsx        # Root layout
├── server/
│   └── server.js          # Express server with serial communication
├── components/            # Reusable UI components
├── ip.ts                  # Server IP configuration
├── start-dev.ps1          # Windows startup script
└── start-dev.bat          # Batch file launcher
```

## Data Format

The server expects data in the following format from Arduino:

```
DATA,posture,pressure,battery
```

Example:
```
DATA,Sitting,25,3.8
```

## Alert Thresholds

- **Pressure**: Red indicator when > 30 mmHg
- **Posture**: Red indicator for dangerous positions (lying, etc.)
- **Battery**: 
  - Green: ≥ 3.7V
  - Yellow: ≥ 3.3V
  - Red: < 3.3V

## Troubleshooting

### Cannot connect to server
- Ensure both devices are on the same network
- Check firewall settings on Windows
- Verify the IP address in `ip.ts` matches your PC's IP
- Try using a mobile hotspot instead of public WiFi

### Server not starting
- Check if COM port is correct in `server/server.js`
- Ensure Arduino is connected and serial port is available
- Check Node.js dependencies: `cd server && npm install`

### Expo connection issues
- Make sure Expo Go app is installed on your device
- Check that both devices are on the same network
- Try restarting Expo: `npx expo start --clear`

## Development

### Tech Stack
- **Frontend**: React Native, Expo, TypeScript
- **Backend**: Node.js, Express
- **Serial Communication**: SerialPort
- **UI**: Material Icons, React Native Animated

## License

[Add your license here]

## Contributors

[Add contributors here]
