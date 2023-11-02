#!/system/bin/sh

LOGF=/data/adb/enable_wifi.log
rm -f $LOGF
echo "Env info:" >> $LOGF
export >> $LOGF

SVC=/system/bin/svc

wifiMode() {
    if [ -z $1 ]; then
        echo "Enabling Wifi..."
    fi
    $SVC data disable # avoid expensive data usage!
    service call wifi 29 i32 0 i32 0 # name=null, enable=false
    service call connectivity 40 i32 0
    $SVC wifi enable
    $SVC wifi prefer
}

tetherMode() {
    echo "Enabling Tether..."
    $SVC data disable # avoid expensive data usage!
    $SVC wifi disable
    service call wifi 29 i32 0 i32 1 # name=null, enable=true
    service call connectivity 40 i32 1 # usb tether enable
}


checkWifi() {
    if ip a show wlan0 | grep inet | grep -v "scope link" | grep -v "169.254" >/dev/null; then
        echo "Has WiFi IP"
        return 0
    else
        echo "No WiFi IP"
        return 1
    fi
}

keepWifi() {
    while true; do 
        wifiMode quiet
        sleep 2
    done
}


mainFunc() {
    set -x
    if [ -z "$DEBUG" ]; then
        echo "Waiting for bootup!"
        sleep 60
    fi
    
    for i in $(busybox seq 1 20); do # 1min not connected then go hotspot
        wifiMode;
        if checkWifi; then
            echo "Wifi Connected, good to go!"
            keepWifi &
            break
        fi
        if [ $i = 20 ]; then
            echo "Failed to connect to WiFi! Going to tether mode!"
            tetherMode;
            break
        fi
        sleep 3
    done
    
    echo "Updating clock!"
    for i in $(busybox seq 1 20); do
        am broadcast -a android.intent.action.NETWORK_SET_TIME -f 536870912
        sleep 2
    done

    set +x
    fg
}

mainFunc >> $LOGF 2>&1
