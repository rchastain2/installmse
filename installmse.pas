
program InstallMSE;
{$MODE objfpc}{$H+}
{$IFDEF mswindows}
{$APPTYPE console}
{$ENDIF}

uses
{$IFDEF unix}
  cthreads,
 {cwstring,}
{$ENDIF}
  sysutils,
  mseprocutils, { execwaitmse } 
  msetypes,     { msestringarty }
  msesys,       { getcommandlinearguments, fm_create }
  msestrings,   { msestrlicomp }
  msesysintf,   { sys_* }
  msestream,    { ttextstream }
  desktop,
  readversion,
  log;

const
  capp = 'InstallMSE 0.3';
  clog = 'installmse.log';
  ctargetos = {$IFDEF mswindows}'windows'{$ELSE}'linux'{$ENDIF};

var
  llog: TLog;
  
procedure createbuildscript(const scriptname, msedir: filenamety);
const
  clinebreak = {$IFDEF mswindows}'^'{$ELSE}'\'{$ENDIF};
var
  lstream: ttextstream;
begin
  lstream := ttextstream.create(scriptname, fm_create);
  lstream.writeln(unicodeformat('cd %s/apps/ide', [msedir]));
  lstream.writeln('fpc ' + clinebreak);
  lstream.writeln('-Fu../../lib/common/* ' + clinebreak);
  lstream.writeln('-Fu../../lib/common/kernel ' + clinebreak);
  lstream.writeln('-Fi../../lib/common/kernel ' + clinebreak);
  lstream.writeln('-Fu../../lib/common/kernel/' + ctargetos + ' ' + clinebreak);
  lstream.writeln('-Mobjfpc -Sh mseide.pas');
  lstream.close;
  lstream.free;
end;

procedure createstartscript(const scriptname, msedir: filenamety);
const
  cmseidevalue = {$IFDEF mswindows}'%MSEIDE%'{$ELSE}'$MSEIDE'{$ENDIF};
  cparamsvalue = {$IFDEF mswindows}'%*'{$ELSE}'$*'{$ENDIF};
var
  lstream: ttextstream;
begin
  lstream := ttextstream.create(scriptname, fm_create);
  lstream.writeln(unicodeformat('MSEIDE=%s/apps/ide/mseide', [msedir]));
  lstream.writeln('$MSEIDE --globstatfile=$MSEIDE.sta ' + cparamsvalue);
  lstream.close;
  lstream.free;
end;

(* -------------------------------------------------------------------------- *)

const
  caction = {$IFDEF release}true{$ELSE}false{$ENDIF};
  cscriptext = {$IFDEF mswindows}'.cmd'{$ELSE}'.sh'{$ENDIF};
  cinterpreter = {$IFDEF mswindows}'cmd /C '{$ELSE}'sh '{$ENDIF};
  
var
  ltimestamp, linstall: msestring;
  lparentdir, lmsedir: filenamety;

procedure Hello;
const
  cbuild = 'FPC ' + {$I %FPCVERSION%} + ' ' + {$I %DATE%} + ' ' + {$I %TIME%} + ' ' + {$I %FPCTARGETOS%} + '-' + {$I %FPCTARGETCPU%};
  cactionstr: array[boolean] of msestring = ('SIMULATION', 'ACTION');
begin
  writeln(capp + ' (' + cbuild + ')');
  writeln('[INFO] Mode ' + cactionstr[caction]);
  llog := TLog.Create(clog);
end;

procedure Init;
const
  copt = '--DIR='; { Second paramètre de la fonction mseStrLIComp. Doit être en majuscules. }
  cfmt = 'YYMMDDhhnn';
var
  larg: msestringarty;
  i: integer;
begin
{ Emplacement par défaut pour l'installation }
  lparentdir := sys_getcurrentdir;
  
{ Vérification de la ligne de commande }
  writeln('[INFO] Check command-line');
  larg := getcommandlinearguments;
  for i := 1 to high(larg) do
  begin
    llog.Append(unicodeformat('[DEBUG] larg[%d]    = "%s"', [i, larg[i]]));
    if msestrlicomp(pmsechar(larg[i]), pmsechar(copt), length(copt)) = 0 then
      lparentdir := copy(larg[i], length(copt) + 1, msetypes.bigint);
  end;
  
{ Initialisation des autres variables }
  writeln('[INFO] Set variables');
  ltimestamp := utf8tostring(FormatDateTime(cfmt, Now));
  linstall := 'mseide-' + ltimestamp;
  lmsedir := lparentdir + '/' + linstall;
  llog.Append(unicodeformat('[DEBUG] lmsedir    = "%s"', [lmsedir]));
end;

procedure Clone;
const
  curl = 'https://codeberg.org/mse-org/mseide-msegui.git';
var
  lcmd: msestring;
begin
{ Clonage du dépôt git }
  writeln('[INFO] Clone repository');
  lcmd := UnicodeFormat('git clone --single-branch --depth 1 %s %s', [curl, lmsedir]);
  llog.Append(unicodeformat('[DEBUG] lcmd       = "%s"', [lcmd]));
  if caction then
    execwaitmse(lcmd);
end;

procedure Build;
var
  lfilename: filenamety;
  lcmd: msestring;
begin
{ Compilation de MSEide }
  writeln('[INFO] Create script to build MSEide');
  lfilename := extractfilepath(sys_getapplicationpath) + 'build-' + linstall + cscriptext;
  createbuildscript(lfilename, lmsedir);
  
  writeln('[INFO] Build MSEide');
  lcmd := cinterpreter + lfilename;
  llog.Append(unicodeformat('[DEBUG] lcmd       = "%s"', [lcmd]));
  if caction then
    execwaitmse(lcmd);
end;

procedure Configure;
const
  cpathdelim = {$IFDEF mswindows}'\'{$ELSE}'/'{$ENDIF};
var
  lfilename: filenamety;
  lcmd: msestring;
begin
{ Configuration de MSEide }

  writeln('[INFO] Create script to start MSEide');
  
  lfilename := extractfilepath(sys_getapplicationpath) + 'start-' + linstall + cscriptext;
  createstartscript(lfilename, lmsedir);

  writeln('[INFO] Configure MSEide');
  
  lcmd := UnicodeFormat(
    cinterpreter + '%s --macrodef=MSEDIR,%s' + cpathdelim + ' --storeglobalmacros',
    [lfilename, lmsedir]
  );
  llog.Append(unicodeformat('[DEBUG] lcmd       = "%s"', [lcmd]));
  if caction then
    execwaitmse(lcmd);
end;

procedure CreateShortcuts;
const
  cdesktopnames: array[0..1] of msestring = ('Bureau', 'Desktop');
var
  lfilename, ltargetdir: filenamety;
  lmseidever, lmseguiver: string;
  lcmd: msestring;
  i: integer;
begin
  readmseversion(stringtoutf8(lmsedir), lmseidever, lmseguiver);
  llog.Append(unicodeformat('[DEBUG] lmseidever = "%s"', [lmseidever]));
  
  lfilename := extractfilepath(sys_getapplicationpath) + linstall + '.desktop';

  createdesktopfile(
    lfilename,
    unicodeformat('MSEide %s', [lmseidever]),
    unicodeformat('%s/apps/ide/mseide --globstatfile=%s/apps/ide/mseide.sta %%F', [lmsedir, lmsedir]),
    unicodeformat('%s/msegui_48.png', [lmsedir]),
    unicodeformat('%s/apps/ide', [lmsedir])
  );
  
  lcmd := unicodeformat('chmod +x %s', [lfilename]);
  execwaitmse(lcmd);
  
  i := 0;
  repeat
    ltargetdir := sys_getuserhomedir + '/' + cdesktopnames[i];
    
    if DirectoryExists(ltargetdir) then
    begin
      lcmd := unicodeformat('cp -f %s %s', [lfilename, ltargetdir + '/' + linstall + '.desktop']);
      llog.Append(unicodeformat('[DEBUG] lcmd       = "%s"', [lcmd]));
      if caction then
        execwaitmse(lcmd);
      break;
    end else
      writeln(unicodeformat('[WARNING] Cannot find directory "%s"', [ltargetdir]));
    
    inc(i);
  until i > high(cdesktopnames); 
  
  ltargetdir := sys_getuserhomedir + '/.local/share/applications';
  if DirectoryExists(ltargetdir) then
  begin
    lcmd := unicodeformat('cp -f %s %s', [lfilename, ltargetdir + '/' + linstall + '.desktop']);
    llog.Append(unicodeformat('[DEBUG] lcmd       = "%s"', [lcmd]));
    if caction then
      execwaitmse(lcmd);
  end else
    writeln(unicodeformat('[WARNING] Cannot find directory "%s"', [ltargetdir]));
end;

procedure CreateShortcutsWin;
begin
end;

procedure GoodBye;
begin
  writeln('[INFO] Done');
  llog.Free;
end;

begin
  Hello;
  Init;
  Clone;
  Build;
  Configure;
{$IFDEF mswindows}
  CreateShortcutsWin;
{$ELSE}
  CreateShortcuts;
{$ENDIF}
  GoodBye;
end.
