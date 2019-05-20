import 'dart:convert';

//May 2019 - BSS

class DirEnt {
  String fname;
  int start,size;
  DateTime dateTime;
  bool isHidden,isSystem,isLabel,isDir,isArc;

  String toString() {
    return '${fname} start:$start $size b ${isDir?'DIR':''}${isLabel?'VLABEL':''} Date: ${dateTime.toString()}';
  }
}

class Dir {
  Dir parent;
  List<DirEnt> entries;

  Dir(Dir parent,List<DirEnt> entries) {
    this.parent = parent;
    this.entries = entries;
  }
}

class FloppyReader {
  List<int> image,fat;
  Dir rootDir,currDir;
  String oemName;
  int bps,spf,spc,rsect,fcopies,rents,hsect;

  ///Creates a new FloppyReader by reading the raw disk data in [image]
  FloppyReader(List<int> image) {
    this.image = image;
    oemName = AsciiCodec().decode(image.sublist(3,11));
    bps = image[11] + (image[12] <<8);
    spc = image[13];
    rsect = image[14] + (image[15]<<8);
    fcopies = image[16];
    rents = image[17] + (image[18]<<8);
    spf = image[22] + (image[23]<<8);
    hsect = image[28] + (image[29]<<8);
    fat = image.sublist(rsect*bps,(rsect+spf)*bps);
    int rdStart = (rsect+fcopies*spf)*bps;
    rootDir = Dir(null,readDir(image.sublist(rdStart,rdStart+rents*32)));
    currDir = rootDir;
  }

  Dir changeDir(int index){
    if (index >= currDir.entries.length) throw IndexError(index,currDir.entries);
    if (!currDir.entries[index].isDir) throw ArgumentError('Directory entry at index {index} is not a directory');
    if (currDir.entries[index].fname=='.') return currDir;
    if (currDir.entries[index].fname == '..') {
      if (currDir.parent != null) return (currDir = currDir.parent);
      return currDir;
    }
    else return (currDir = Dir(currDir,readDir(readFile(currDir.entries[index].start))));
  }

  List<int> getFile(int index) {
    if (index < currDir.entries.length) return readFile(currDir.entries[index].start).sublist(0,currDir.entries[index].size);
    throw IndexError(index,currDir.entries);
  }

  List<DirEnt> readDir(List<int> data) {
    List<DirEnt> dir = List();
    for (int i=0;data[i]!=0;i+=32) {
      DirEnt currEnt = DirEnt();
      if (data[i]== 0xE5) data[i] = 33;
      //place . between name and extension and remove extraneous spaces
      currEnt.fname = AsciiCodec().decode(data.sublist(i,i+8)+[32]+data.sublist(i+8,i+11)).trim().replaceAll(new RegExp(' +'),'.'); 
      currEnt.start = data[i+26] + (data[i+27]<<8);
      currEnt.size = data[i+28] + (data[i+29]<<8) + (data[i+30]<<16) + (data[i+31]<<24);
      currEnt.isDir = data[i+11] & 0x10 != 0;
      currEnt.isLabel = data[i+11] & 0x08 !=0;
      int hrs = (data[i+23] & 0xF8)>>3,mins=((data[i+22]+(data[i+23]<<8))&0x7E0)>>5,dsecs= data[i+22] & 0x1F;
      int year=(data[25]& 0xFE)>>1,month=((data[i+24]+(data[i+25]<<8))&0x1E0)>>5,day=data[i+24] & 0x1F;
      currEnt.dateTime = DateTime(1980+year,month,day,hrs,mins,dsecs*2);
      dir.add(currEnt);
    }
    return dir;
  }

  List<int> readFile(int startSect) {
    int currSect = startSect;
    List<int> file = List();
    while (currSect<0xFF0) {
      int sectStart = (this.rsect+this.fcopies*this.spf+this.spc*(currSect-2))*this.bps+this.rents*32;
      file.addAll(this.image.sublist(sectStart,sectStart+this.spc*this.bps));
      if (currSect & 1 != 0) currSect = (this.fat[(currSect*3/2).floor()] >>4 )+ (this.fat[(currSect*3/2).floor()+1] <<4);
      else currSect = ((this.fat[(currSect*3/2).floor()+1]&0xF) <<8 )+ (this.fat[(currSect*3/2).floor()]);
    }
    return file;
  }
}