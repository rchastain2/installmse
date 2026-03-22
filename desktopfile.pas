
unit desktopfile;

{$ifdef FPC}{$mode objfpc}{$h+}{$endif}

interface

uses
  msetypes;
  
procedure createdesktopfile(const afilename, aappname, aexec, aicon, apath: msestring);

implementation

uses
  classes,
  sysutils,
  msestream, (* ttextstream *)
  msesys; (* fm_create *)
  
procedure createdesktopfile(const afilename, aappname, aexec, aicon, apath: msestring);
var
  lstream: ttextstream;
begin
  lstream := ttextstream.create(afilename, fm_create);
  lstream.writeln('[Desktop Entry]');
  lstream.writeln('Version=1.0');
  lstream.writeln('Type=Application');
  lstream.writeln(unicodeformat('Name=%s', [aappname]));
  lstream.writeln('Comment=Pascal IDE');
  lstream.writeln(unicodeformat('Exec=%s', [aexec]));
  lstream.writeln(unicodeformat('Icon=%s', [aicon]));
  lstream.writeln(unicodeformat('Path=%s', [apath]));
  lstream.writeln('Terminal=false');
  lstream.writeln('StartupNotify=true');
  lstream.writeln('Categories=Application;IDE;Development;GUIDesigner;Programming;');
  lstream.writeln('Keywords=editor;Pascal;IDE;FreePascal;fpc;Design;Designer;');
  lstream.close;
  lstream.free;
end;

end.
