#!/bin/sh
# Name: Check OTA Status
# Author: neura
# Icon: 
# Created: jan-08-2025
# Modified: nov-01-2025
# Version: 1.2
# Description: This scriptlet checks the status of OTA (Over-The-Air) update binaries on Kindle devices and informs the user whether updates are enabled or blocked.
#
# Changelog:
#   - nov-01-2025: Added support for firmware <=5.10.x by checking for update.bin.tmp.partial folder.
#   - jan-09-2025: Added dynamic touch device detection in order to increase the compatibility across devices.
#   - jan-08-2025: First working version (works on KT4 using event2 device).

# First, determine firmware version to know which OTA blocking method to check
FIRMWARE_VERSION=$(cat /etc/prettyversion.txt | grep -o '[0-9]\+\.[0-9]\+' | head -n 1)
FIRMWARE_MAJOR=$(echo $FIRMWARE_VERSION | cut -d '.' -f 1)
FIRMWARE_MINOR=$(echo $FIRMWARE_VERSION | cut -d '.' -f 2)

# For debug (uncomment if needed)
# echo "[ DEBUG ] Firmware version: $FIRMWARE_VERSION (Major: $FIRMWARE_MAJOR, Minor: $FIRMWARE_MINOR)"

# Check the appropriate OTA blocking method based on firmware version
if [ "$FIRMWARE_MAJOR" -eq 5 ] && [ "$FIRMWARE_MINOR" -le 10 ]; then
    # For firmware <=5.10.x, check for update.bin.tmp.partial folder
    if [ -d "/mnt/us/update.bin.tmp.partial" ]; then
        MESSAGE1="OTA blocking is enabled (<=5.10.x method)."
        MESSAGE2="Folder is blocking updates."
        MESSAGE3="Your jailbreak is safe."
        MESSAGE4="Your Kindle will NOT update."
    else
        MESSAGE1="OTA blocking is disabled (<=5.10.x)."
        MESSAGE2="Folder is missing."
        MESSAGE3="Your jailbreak is in danger."
        MESSAGE4="Create update.bin.tmp.partial folder."
    fi
else
    # For firmware >=5.11.x, check for renamed OTA binaries
    if [ -f /usr/bin/otaupd.bck ] && [ -f /usr/bin/otav3.bck ]; then
        MESSAGE1="OTA blocking is enabled (>=5.11.x method)."
        MESSAGE2="Your Kindle will NOT update."
        MESSAGE3="Your jailbreak is safe."
        MESSAGE4="Wanna restore OTA? Enable Airplane mode."
    elif [ -f /usr/bin/otaupd ] && [ -f /usr/bin/otav3 ]; then
        MESSAGE1="OTA blocking is disabled (>=5.11.x)."
        MESSAGE2="Your Kindle can be updated."
        MESSAGE3="Your jailbreak is in danger."
        MESSAGE4="Rename OTA binaries to keep jailbreak."
    else
        MESSAGE1="OTA binaries are corrupted or missing."
        MESSAGE2="Check manually."
        MESSAGE3=""  # No third message
        MESSAGE4=""  # No fourth message
    fi
fi

# Function to force a full screen refresh
force_refresh() {
    eips -c > /dev/null 2>&1     # Clear the screen silently
    eips -c > /dev/null 2>&1     # Double clear to ensure full refresh
    sleep 1                      # Use integer value for sleep
}

# Function to detect the correct touch device
detect_touch_device() {
    awk '{ 
        if ($1 == "Section" && $2 == "\"InputDevice\"") { isInput=1 }; 
        if ($2 == "\"Device\"" && isInput) { inputDevice=$3; hasInputDevice=1 }; 
        if ($2 == "\"CorePointer\"" && hasInputDevice && isInput) { 
            gsub(/\"/, "", inputDevice); 
            print inputDevice 
        } 
    }' /etc/xorg.conf
}

# Set the correct touch device dynamically
TOUCH_DEVICE=$(detect_touch_device)
if [ -z "$TOUCH_DEVICE" ]; then
    echo "Error: Could not detect touch device."
    exit 1
fi

# Print the detected touch device (uncomment for debugging)
# echo "[ DEBUG ] Detected touch device: $TOUCH_DEVICE"

# Display the messages with forced refresh
force_refresh
eips 0 0 "$MESSAGE1" > /dev/null 2>&1  # Display the first message
eips 0 1 "$MESSAGE2" > /dev/null 2>&1  # Display the second message
if [ -n "$MESSAGE3" ]; then            # Check if there's a third message
    eips 0 2 "$MESSAGE3" > /dev/null 2>&1
fi
if [ -n "$MESSAGE4" ]; then            # Check if there's a fourth message
    eips 0 3 "$MESSAGE4" > /dev/null 2>&1
fi
eips 0 5 "Tap the screen to exit." > /dev/null 2>&1  # Display instructions

# Wait for a tap
while :; do
    # Refresh the screen periodically to keep messages visible
    force_refresh
    eips 0 0 "$MESSAGE1" > /dev/null 2>&1
    eips 0 1 "$MESSAGE2" > /dev/null 2>&1
    if [ -n "$MESSAGE3" ]; then
        eips 0 2 "$MESSAGE3" > /dev/null 2>&1
    fi
    if [ -n "$MESSAGE4" ]; then
        eips 0 3 "$MESSAGE4" > /dev/null 2>&1
    fi
    eips 0 5 "Tap the screen to exit." > /dev/null 2>&1
    
    # Wait for a touch event to occur
    dd if="$TOUCH_DEVICE" bs=16 count=1 2>/dev/null | grep -q .
    if [ $? -eq 0 ]; then
        break
    fi
    sleep 1  # Reduce CPU usage
done

# Clear the screen and return to home
force_refresh
lipc-set-prop com.lab126.appmgrd start app://com.lab126.booklet.home