# connect to the J-Link gdb server
target remote 192.168.1.46:2331
# Set JTAG speed to 30 kHz
monitor endian little
monitor speed 30
# Reset the target
monitor reset
#monitor sleep 10
   
# Setup GDB for faster downloads
#set remote memory-write-packet-size 1024
monitor speed auto
b _start
load
continue
