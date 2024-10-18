boottext = 'v2.0 raw\n'
kerneltext = 'v2.0 raw\n'
testtext = ''

with open('./kernel.bin',mode='rb') as f:
    bts = f.read()
    hexs = bts.hex(' ').split(' ')
    i = 0
    while i < len(hexs):
        kerneltext += f'{hexs[i]}\n'
        testtext += f'{hexs[i]}\n'
        i += 1
    
with open('./kernel.hex',mode='w') as f:
    f.write(kerneltext)

with open('./boot.bin',mode='rb') as f:
    bts = f.read()
    hexs = bts.hex(' ').split(' ')
    i = 0
    while i < len(hexs):
        boottext += f'{hexs[i]}\n'
        # testtext += f'{hexs[i]}\n'
        i += 1

with open('./boot.hex',mode='w') as f:
    f.write(boottext)
    
with open('./test.hex',mode='w') as f:
    f.write(testtext)
    