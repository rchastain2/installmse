
unit readversion;

interface

uses
  sysutils;

procedure readmseversion(const amsedir: tfilename; out amseideversion, amseguiversion: string);

implementation

uses
  classes, regexpr;

function readtext(const afilename: tfilename): ansistring;
var
  fs: tfilestream;
begin
  fs := tfilestream.create(afilename, fmopenread);
  try
    setlength(result, fs.size div sizeof(ansichar));
    fs.readbuffer(pansichar(result)^, fs.size);
  finally
    fs.free;
  end;
end;

function readconstantvalue(const afilepath: tfilename; const aconstantname: string; const aexpr: string = '[^'']+'): string;
const
  cdefault = '?';
var
  ltext: string;
  expr: TRegExpr;
begin
  if not FileExists(afilepath) then
    Exit(cdefault);
  
  ltext := readtext(afilepath);
  
  expr := TRegExpr.Create(aconstantname + '\s*=\s*''(' + aexpr + ')''');
  
  if expr.Exec(ltext) then
    result := expr.Match[1]
  else
    result := cdefault;
  
  expr.Free;
end;

procedure readmseversion(const amsedir: tfilename; out amseideversion, amseguiversion: string);
{
  apps/ide/main.pas:49: versiontext = '4.6.3';
  lib/common/kernel/msegui.pas:37: mseguiversiontext = '4.6.3';
}
begin
  amseideversion := readconstantvalue(IncludeTrailingPathDelimiter(amsedir) + 'apps/ide/main.pas', 'versiontext', '\d+\.\d+\.\d+');
  amseguiversion := readconstantvalue(IncludeTrailingPathDelimiter(amsedir) + 'lib/common/kernel/msegui.pas', 'mseguiversiontext', '\d+\.\d+\.\d+');
end;

end.
