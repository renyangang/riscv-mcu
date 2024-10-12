hex1text = 'v2.0 raw\n'
hex2text = 'v2.0 raw\n'
hex3text = 'v2.0 raw\n'
hex4text = 'v2.0 raw\n'
kerneltext = 'v2.0 raw\n'
testtext = ''

with open('./boot.bin',mode='rb') as f:
    bts = f.read()
    hexs = bts.hex(' ').split(' ')
    i = 0
    while i < len(hexs):
        hex1text += f'{hexs[i]}\n'
        hex2text += f'{hexs[i+1]}\n'
        hex3text += f'{hexs[i+2]}\n'
        hex4text += f'{hexs[i+3]}\n'
        i += 4

with open('./1.hex',mode='w') as f:
    f.write(hex1text)

with open('./2.hex',mode='w') as f:
    f.write(hex2text)

with open('./3.hex',mode='w') as f:
    f.write(hex3text)

with open('./4.hex',mode='w') as f:
    f.write(hex4text)

with open('./kernel.bin',mode='rb') as f:
    bts = f.read()
    hexs = bts.hex(' ').split(' ')
    i = 0
    while i < len(hexs):
        kerneltext += f'{hexs[i]}\n'
        i += 1
    
with open('./kernel.hex',mode='w') as f:
    f.write(kerneltext)

with open('./test.bin',mode='rb') as f:
    bts = f.read()
    hexs = bts.hex(' ').split(' ')
    i = 0
    while i < len(hexs):
        testtext += f'{hexs[i]}\n'
        i += 1
    
with open('../verilog/test.hex',mode='w') as f:
    f.write(testtext)
    