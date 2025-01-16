#!/bin/bash

pkill -f hostap
/etc/init.d/network-manager restart
rmmod ./ko/rtw* > /dev/null 2>&1
rmmod ./ko/rtw* > /dev/null 2>&1
rmmod ./ko/rtw* > /dev/null 2>&1
rmmod ./ko/rtw* > /dev/null 2>&1

echo Test Band 2+5G [2] or 2G Only [1]?

read c1

if (( $c1 < 1 || $c1 > 2 )); then
	echo "Select 2G or 2+5G Only!"
	exit 1
elif (($c1 == 1)); then

	echo "2G Test Only"
else
	echo "2+5G Test"
fi

echo What USB device is testing?

read v1

echo \# ${v1^^} USB Dongle Testing

cat << EOF

### Test USB Gear

|Test Board|USB Dongle HW|
|-|-|
|<img src="" height="400"/>|<img src="" height="400"/>|

\`\`\`
EOF

uname -r
echo ""
cat /etc/lsb-release
echo ""
lscpu

cat << EOF
\`\`\`

### USB Tree

\`\`\`
Before driver is inserted.
EOF

lsusb -t

cat << EOF

After driver is inserted.
EOF

cd ./ko
NAME=${v1:3}
FILE="./run_"${NAME,,}".sh"
if [ -f $FILE ]; then
	./$FILE
   else
	echo "File $FILE does not exist."
   	exit 0
fi
cd ..
lsusb -t

cat << EOF
\`\`\`

<details>

<summary>USB Details</summary>

\`\`\`
EOF
lsusb -v -s 001:002
lsusb -v -s 001:003
lsusb -v -s 001:004

cat << EOF
\`\`\`

</details>

### Driver Load

The driver is loaded via "insmod"

\`\`\`
EOF

lsmod

cat << EOF
\`\`\`

### iw list

<details>

<summary>iw list</summary>

\`\`\`
EOF

iw list

cat << EOF
\`\`\`

</details>

EOF

declare -a band_ary=("2.4" "5G")

for i in $(seq 1 ${c1});
do

bash

cat << EOF
### Network Manager - Band ${band_ary[${i}-1]}G

\`\`\`
EOF

v2=$(ifconfig wlan0)
sed -e '3d;4d' <<< "${v2}"

cat << EOF
\`\`\`

### iwconfig ${band_ary[${i}-1]}

\`\`\`
EOF

iwconfig wlan0

cat << EOF
\`\`\`

### Network Speed Test via Ookla - Band ${band_ary[${i}-1]}G

\`\`\`
EOF

speedtest-cli --secure

cat << EOF
\`\`\`

### Network Ping Tests - Band ${band_ary[${i}-1]}G

#### DNS-Ping

\`\`\`
EOF

ping 8.8.8.8 -c 20

cat << EOF
\`\`\`

#### Self-Ping 

\`\`\`
EOF

ping $(hostname -I) -c 20 -s 10000

cat << EOF
\`\`\`

### Server & Client Test via iperf3 (HOST <-> Router <-> DUT)

<details>

<summary>iperf3</summary>

\`\`\`
EOF

iperf3 -s &
pid=$!
read
kill ${pid}
dmesg | grep rtw

cat << EOF
\`\`\`

</details>

EOF

done

cat << EOF

### AP Test - Band 2.4G

#### hostapd.conf

Setup the configuration at /etc/hostapd/hostapd.conf

\`\`\`
interface=wlan0
driver=nl80211
ieee80211n=1
hw_mode=g
channel=6
ssid=AP-TEST
wpa=2
wpa_passphrase=12345678
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP TKIP
wpa_pairwise=TKIP CCMP
\`\`\`

#### hostapd.conf

\`\`\`
start 192.168.175.2
end 192.168.175.254
interface wlan0
max_leases 234
opt router 192.168.175.1
\`\`\`

#### Start AP Test

\`\`\`
sudo hostapd /etc/hostapd/hostapd.conf -B
Using interface wlan0 with hwaddr and ssid "AP-NAME"
wlan0: interface state UNINITIALIZED->ENABLED
wlan0: AP-ENABLED
\`\`\`

#### Server & Client Test via iperf3 (PC-DUT)

<details>

<summary>iperf3</summary>

\`\`\`
EOF

nmcli --terse connection show | cut -d : -f 1 | \
while read name; do nmcli connection delete "$name" >/dev/null 2>&1; done

while ! pgrep hostap >/dev/null 2>&1
do
	echo "Wlan0 Not Ready."
	sleep 0.5
	./hostap.sh
done

iperf3 -s &
pid=$!
read
kill ${pid}
dmesg | grep rtw

cat << EOF
\`\`\`

</details>

### End of Report
EOF

