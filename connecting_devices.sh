
#!/bin/bash

# Detect adb executable
adb_executable=$(command -v adb)

# Verify adb installed
if [ -z "$adb_executable" ]; then
  echo "Error: adb is not installed. Please install Android SDK Platform-Tools."
  exit 1
fi

# Get list of connected devices (android only of course)
connected_devices=$("$adb_executable" devices | awk '$2 == "device" {print $1}')

# Workflow of connecting devices over wifi
connect_device() {
  local port=$((5555 + $2))
  echo "Connecting to device with serial: $1"
  "$adb_executable" -s $1 tcpip $port
  sleep 2 # Wait for the device to restart in TCP/IP mode
  device_ip=$("$adb_executable" -s $1 shell ip addr show wlan0 | awk '/inet / {print $2}' | cut -d'/' -f1)
  "$adb_executable" -s $1 connect $device_ip:$port
}

# perform adb devices to check device availability
if [ -z "$connected_devices" ]; then
  echo "No devices connected. Connect devices via USB and try again."
else
  # Loop over devices to connect it
  port_counter=0
  for device_serial in $connected_devices; do
    connect_device "$device_serial" $port_counter
    ((port_counter++))
  done

  # verification
  "$adb_executable" devices
  echo "Process is over"
fi
