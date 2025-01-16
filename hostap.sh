#!/bin/bash


echo "Start AP @ WLAN0"

sudo hostapd /etc/hostapd/hostapd.conf -B
sudo ifconfig wlan0 192.168.175.1
sudo udhcpd /etc/udhcpd.conf &

