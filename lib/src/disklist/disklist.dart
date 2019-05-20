import 'dart:html';

import 'dart:convert';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:html/dom.dart';
import 'package:floppyreader/FloppyReader.dart';

//May 2019 - BSS

@Component(selector: 'disklist', templateUrl: 'disklist.html', styleUrls: [
  'disklist.css',
  'package:angular_components/app_layout/layout.scss.css'
], providers: [
  overlayBindings
], directives: [
  materialInputDirectives,
  NgFor,
  NgIf,
  MaterialIconComponent,
  MaterialButtonComponent,
  MaterialExpansionPanel,
  MaterialExpansionPanelSet,
  MaterialExpansionPanelAutoDismiss
], pipes: [
  commonPipes
])
class DiskListComponent {
  String fContents;

  FloppyReader floppy;

  List<DirEnt> currDir;

  Document get document => window.document;

  void fRead(int ind) {
    DirEnt currFile = currDir[ind];
    print(currFile);

    if (currFile.isDir)
      currDir = floppy.changeDir(ind).entries;
    else {
      try {
        fContents = AsciiCodec().decode(floppy.getFile(ind));
      } on FormatException {
        fContents = '<preview not available>';
      }
      AnchorElement link = window.document.querySelector("#ent_$ind");
      if (link != null) {
        List<String> test = List();
        test.add(AsciiDecoder(allowInvalid: true).convert(floppy.getFile(ind)));
        link.href = Url.createObjectUrlFromBlob(Blob(test));
        link.download = currFile.fname;
      }
    }
  }

  void fileLoad(event) {
    fContents = '';
    InputElement fInput = window.document.getElementById('fload');
    File file = fInput.files[0];
    FileReader reader = FileReader();
    reader.readAsArrayBuffer(file);
    reader.onLoad.listen((fileEvent) {
      floppy = FloppyReader(reader.result);
      currDir = floppy.rootDir.entries;
    });
  }
}
