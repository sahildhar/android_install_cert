#!/bin/sh
# Author: Sahil Dhar (Twitter: @0x401)
# Description: Script to add proxy cert to system cert store for Android API > 23

# Generate key, certification and pkcs12 bundle
# import certificate.p12 file to burp with password 1234567890

openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout pk.key -out certificate.crt -subj "/C=IN/ST= /L= /O=Burp Certificate (@0x401)/OU=Certificate Install/CN=localhost"
openssl pkcs12 -export -out certificate.p12 -password pass:1234567890 -inkey pk.key -certfile certificate.crt -in certificate.crt 

# Generate der cert to be imported to devices
openssl x509 -outform DER -in certificate.crt -out cacert.der
openssl x509 -inform DER -in cacert.der -out cacert.pem

CERTNAME="$(openssl x509 -inform PEM -subject_hash_old -in cacert.pem |head -1).0"
mv cacert.pem $CERTNAME

echo "Copying cert to the device"
adb push $CERTNAME /sdcard/
sleep 2
adb shell  "su 0,0 -c ls -l /sdcard/$CERTNAME"

echo "Mounting /system as writable"
adb shell "su 0,0 -c mount"|grep -i "/system type"|grep -iv "magisk"
adb shell "su 0,0 -c mount -o rw,remount /system"
adb shell "su 0,0 -c mount"|grep -i "/system type"|grep -iv "magisk"

echo "Adding $CERTNAME to the system certs"
adb shell  "su 0,0 -c mv /sdcard/$CERTNAME /system/etc/security/cacerts/"
adb shell "su 0,0 -c ls -l /system/etc/security/cacerts"|grep -i $CERTNAME
adb shell "su 0,0, -c chmod 644 /system/etc/security/cacerts/$CERTNAME"

echo "Rebooting device"
adb shell "su 0,0 -c reboot"
