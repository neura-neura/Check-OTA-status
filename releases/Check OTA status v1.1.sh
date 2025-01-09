#!/bin/sh
# Name: Check OTA Status
# Author: neura
# Icon: 
# Created: jan-08-2025
# Modified: jan-09-2025
# Version: 1.1
# Description: This scriptlet checks the status of OTA (Over-The-Air) update binaries on Kindle devices and informs the user whether updates are enabled or blocked.
#
# Changelog:
#   - jan-09-2025: Added dynamic touch device detection in order to increase the compatibility across devices.
#   - jan-08-2025: First working version (works on KT4 using event2 device).

# Check the status of OTA binaries
if [ -f /usr/bin/otaupd.bck ] && [ -f /usr/bin/otav3.bck ]; then
    MESSAGE1="OTA blocking is enabled."
    MESSAGE2="Your Kindle will NOT update."
    MESSAGE3="Your jailbreak is safe."
    MESSAGE4="Wanna restore OTA? Enable Airplane mode."

elif [ -f /usr/bin/otaupd ] && [ -f /usr/bin/otav3 ]; then
    MESSAGE1="OTA blocking is disabled."
    MESSAGE2="Your Kindle can be updated."
    MESSAGE3="Your jailbreak is in danger."
    MESSAGE4="Rename OTA binaries to keep jailbreak."

else
    MESSAGE1="OTA binaries are corrupted."
    MESSAGE2="Check manually."
    MESSAGE3=""  # No third message
    MESSAGE4=""  # No fourth message
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
