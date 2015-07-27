#!/usr/bin/python3

import subprocess
import time
import sys
import os
import re

def seqspeed(device, t=6, blocksize=1048576):  # return seq read speed in MB/s
    with open('/proc/sys/vm/drop_caches', 'w') as stream:
        stream.write('3\n')  # Flushing the read buffers
    f = open(device, "rb")
    i = 0
    start = time.time()
    while time.time() < start+t:
        record = f.read(blocksize)
        if not record:
            break
        i += 1
    end = time.time()
    t = end - start
    f.close
    return int( ( i * blocksize ) / ( t * 1048576 ) )


def getpooldisksbystatus(poolname, diskstatus):
    command = 'zpool status %s' % poolname
    cmd = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE)
    result=[]
    for line in cmd.stdout:
        data = line.decode().split()
        if diskstatus in data:
            result.append(data[0])
    return (result)


def mediasize(dev):
    try:
        fh = open(dev, 'r')
        fh.seek(0, 2)
        mediasize = fh.tell()
        fh.close()
    except:
        mediasize = ''
    return mediasize


def listdisks(size=0):
    filelist = []
    drivelist = []
    path = '/dev/disk/by-id'
    for (dirpath, dirnames, filenames) in os.walk(path):
        filelist.extend(filenames)
        break
    for drive in filelist:
        if not re.search('^wwn-|-part.$', drive):
            if mediasize('%s/%s'%(path, drive)) == size or size == 0:
                drivelist.append(drive)
    return drivelist
      

def getallraid(disks,minspare=0):
    combinations = {}
    i=0
    for active in (8, 4, 2, 1):
      for parity in (3, 2, 1):
        cluster = active + parity
        pools = int( disks / cluster)
        spare = disks - pools * cluster
        if spare < minspare:
          continue
        efficiency = int(100 * (pools * active / disks) )
        risk = int(100 * (active * pools / ( 1 + parity ) ) / disks )  
        if pools > 0 :
          combinations[i] = { 'pools' : pools, \
          'cluster' : cluster, \
          'parity' : parity, \
          'spare' : spare, \
          'efficiency' : efficiency, \
          'risk' : risk }
          i+=1
#    print (combinations)
    return combinations


def mixed_order( a ):
    return ( a['efficiency'], -a['risk'] )


def checkzpool(zpoolname):
    cmd = subprocess.Popen('/sbin/zpool list -H %s'%zpoolname, shell=True, stdout=subprocess.PIPE)
    for line in cmd.stdout:
      #  print(line)
      data=line.decode().split()
      health=data[8]#.decode()

      if health == 'ONLINE':
        return 0  # Everythings OK
      elif health == 'DEGRADED':
        return 2  # Not healthy
      else:
        return 1  # zpool probably not found

def shellcmd(command):
    print (command)
    cmd = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE)
    return (cmd.stdout)

def partition(drive, size):
    command = 'parted -s %s mklabel gpt && ' %(drive)
    command += 'parted -s -a opt %s mkpart primary zfs 0%% %s && ' %(drive,size)
    command += 'parted -s -a opt %s mkpart primary zfs %s 100%%' %(drive,size)
    shellcmd(command)


def createpool(name, disksize, numdisk, hotspare, journalsize, cachesize):

    disklist=listdisks(disksize)
    if len(disklist) == 0:
        print ('No disks of %s bytes found!\n\
        Type lsblk -b to get the exact disks size.' % args.disksize)
        exit(1)
    elif len(disklist) < numdisks:
        print ('Couldn\'t find %s available disks.\nOnly got %s' % (numdisks, len(disklist)))
        exit(1)
    bestraid=sorted(getallraid(numdisk,hotspare).items(),key = lambda x :mixed_order( x[1] ),reverse = True)[0][1]
    print('The following raid will be created: %s'%bestraid)

    i=0
    zpoolargs='-f -o ashift=12 -o autoexpand=on %s' %name
    
    for p in range(0,bestraid['pools'],1):
        if bestraid['parity'] in [1, 2, 3]:
            zpoolargs += ' raidz%s' % str(bestraid['parity'])
        benchmarkresultlist = [None] * len(disklist)
        for c in range(0,bestraid['cluster'],1):        
            print('Benchmarking: %s' % disklist[i])
            benchmarkresultlist[i] = seqspeed('/dev/disk/by-id/%s' % disklist[i])
            zpoolargs += ' %s'%disklist[i]
            i += 1
    averageresult=sum(benchmarkresultlist) / len(benchmarkresultlist)
 
   

    if hotspare > 0:
      zpoolargs += ' spare'
      for s in range(0,bestraid['spare'],1):
        zpoolargs += ' %s'%disklist[i]
        i += 1

    # Checking if disk performance is good
    i = 0
    baddisk = False
    baddisklist = []
    for item in benchmarkresultlist:
        if item < ( 9 * averageresult / 10 ):
            baddisk = True
            baddisklist.append(disklist[i])
        i += 1
    if baddisk == True:
        print( 'Error, these disks may be bad', baddisklist )
        exit(1)





    if not journalsize == cachesize and not journalsize == 0: #Dedicated journal device
        journaldrives=listdisks(journalsize)
        if len(journaldrives) == 1:
            zpoolargs += ' log %s' % journaldrives[0]
        else:
            zpoolargs += ' log mirror'
            for d in journaldrives:
                zpoolargs += (' %s' % d)
        
    elif journalsize == cachesize and not journalsize == 0: #Shared cache and journal
        journaldrives=listdisks(journalsize)
        cachedrives=journaldrives
        journalargs = ' log'
        if len(journaldrives) > 1:
            journalargs += ' mirror'
        cacheargs = ' cache'
        for d in journaldrives:
            #  print('Partitionning %s' % d)
            partition('/dev/disk/by-id/%s' % d, '8G')
            journalargs += (' %s-part1' % d)
            cacheargs += (' %s-part2' % d)
        zpoolargs += journalargs
        zpoolargs += cacheargs

    elif cachesize > 0:
        cachedrives=listdisks(cachesize)
        zpoolargs += ' cache'
        for d in cachedrives:      
            zpoolargs += (' %s'%d)      


    shellcmd('/sbin/zpool create %s' % zpoolargs)


def fixpool(name, size):
    useddisks = getpooldisksbystatus(name, 'ONLINE')
    freedisks = []
    for d in listdisks(size):
        if not d in useddisks:
            freedisks.append(d)

    for f in freedisks:
 #       shellcmd('zpool add -f %s spare %s' % (name, f))
        for b in getpooldisksbystatus(name, 'UNAVAIL'):
            if mediasize(b) == mediasize(f):
                time.sleep(2)
                shellcmd('zpool replace %s %s %s && zpool detach %s %s' % (name, b, f, name, b))
                break


if __name__ == '__main__':

    #Input Reading
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('-n','--name',help='Name of the pool', type=str,required=True)
    parser.add_argument('-s','--disksize', help='Size of disks to use in bytes',type=int, required=False)
    parser.add_argument('-hd','--disks',help='Number of hard drives(including spare) to use', type=int, required=False)
    parser.add_argument('-e','--exclude', help='List of excluded drives (Eg. sda)',type=str, required=False)
    parser.add_argument('-z','--raidz',help='Number of parity disks', type=int, choices=[0, 1, 2, 3], required=False)
    parser.add_argument('-c','--cache',help='Size of the cache(s) drive', type=int, required=False)
    parser.add_argument('-hs','--hotspare',help='Number of hotspare disks', type=int, required=False)
    parser.add_argument('-j','--journal',help='Size of the cache(s) drive', type=int, required=False)
    args = parser.parse_args()


    pattern = r'[^a-zA-Z0-9]'
    if re.search(pattern, args.name):
        print ('Invalid zpool name: %r' % args.name)
        exit(1)

    if args.disks:
        numdisks=args.disks
    else:
        numdisks=0

    if args.disksize:
        disksize=args.disksize
    else:
        print('You must specify a size to identify disks.\nType lsblk -b to get the exact disks size.')
        exit(1)

    if args.hotspare:
        hotspare=args.hotspare
    else:
        hotspare=0

    if args.journal:
        journalsize=args.journal
    else:
        journalsize=0

    if args.cache:
        cachesize=args.cache
    else:
        cachesize=0


    zpoolstatus = checkzpool(args.name)
    
    if zpoolstatus == 0:
        print('Pool %s exists and is healthy' % args.name)

    elif zpoolstatus == 2:
        print('Pool %s exists but is degraded. Running fix' % args.name)
        fixpool(args.name, disksize)

    else:
        print('Running creation of pool %s' % args.name)  
        createpool(args.name, disksize, numdisks, hotspare, journalsize, cachesize)       

    exit(0)
    
