#!/usr/bin/python3

data = (int(a, 16) for a in open("vsim/test_frame.dat").read().split())

polynomial = 1<<26 | 1<<23 | 1<<22 | 1<<16 | 1<<12 | 1<<11 | 1<<10 | 1<<8 \
	| 1<<7 | 1<<5 | 1<<4 | 1<<2 | 1<<1 | 1<<0;

mask = (1<<32) - 1;

crc = mask;

for byte in data:
	for i in range(8):
		bit = 1 if byte & 1<<i else 0
		msb = 1 if crc & 1<<31 else 0
		crc = (crc << 1) & mask
		if bit ^ msb:
			crc = crc ^ polynomial

fcs = ~crc & mask

rev = 0
for i in range(32):
	if fcs & 1<<i:
		rev = rev | 1<<(31-i)

print(hex(rev))
print(bin(rev))
