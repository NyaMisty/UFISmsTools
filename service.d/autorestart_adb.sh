#!/system/bin/sh

while true; do
    sleep 300 # 5min adb keep alive
    setprop ctl.restart adbd
done