
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
  msefileutils, { tosysfilepath }
  desktop,
  readversion,
  log;

const
  capp = 'InstallMSE 0.5';
  clog = 'installmse.log';
  ctargetos = {$IFDEF mswindows}'windows'{$ELSE}'linux'{$ENDIF};
  cpathdelim = {$IFDEF mswindows}'\'{$ELSE}'/'{$ENDIF};

var
  llog: TLog;
  
procedure createbuildscript(const scriptname, msedir: filenamety);
const
  clinebreak = {$IFDEF mswindows}'^'{$ELSE}'\'{$ENDIF};
var
  lstream: ttextstream;
begin
  lstream := ttextstream.create(scriptname, fm_create);
  lstream.writeln(unicodeformat('cd %s' + cpathdelim + 'apps' + cpathdelim + 'ide', [msedir]));
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
  lstream.writeln(unicodeformat({$IFDEF mswindows}'set ' +{$ENDIF}'MSEIDE=%s' + cpathdelim + 'apps' + cpathdelim + 'ide' + cpathdelim + 'mseide', [msedir]));
  lstream.writeln(cmseidevalue + ' --globstatfile=' + cmseidevalue + '.sta ' + cparamsvalue);
  lstream.close;
  lstream.free;
end;

(* -------------------------------------------------------------------------- *)

const
  caction = {$IFDEF release}true{$ELSE}false{$ENDIF};
  cext = {$IFDEF mswindows}'.cmd'{$ELSE}'.sh'{$ENDIF};
  cexe = {$IFDEF mswindows}'cmd /C '{$ELSE}'sh '{$ENDIF};
  
var
  ltimestamp, linstall: msestring;
  lparentdir, lmsedir: filenamety;

procedure Exec(const cmd: msestring);
var
  lresult: integer;
begin
  llog.Append(unicodeformat('Exec(%s)', [cmd]));
  if caction then
  begin
    lresult := execwaitmse(cmd);
    llog.Append(unicodeformat('lresult: %d', [lresult]));
  end;
end;

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
  lparentdir := tosysfilepath(sys_getcurrentdir);
  
{ Vérification de la ligne de commande }
  writeln('[INFO] Checking command-line');
  larg := getcommandlinearguments;
  for i := 1 to high(larg) do
  begin
    llog.Append(unicodeformat('larg[%d]:%s  "%s"', [i, LineEnding, larg[i]]));
    if msestrlicomp(pmsechar(larg[i]), pmsechar(copt), length(copt)) = 0 then
      lparentdir := copy(larg[i], length(copt) + 1, msetypes.bigint);
  end;
  
{ Réglage des autres variables }
  writeln('[INFO] Setting variables');
  ltimestamp := utf8tostring(FormatDateTime(cfmt, Now));
  linstall := 'mseide-' + ltimestamp;
  lmsedir := lparentdir + cpathdelim + linstall;
  llog.Append(unicodeformat('lmsedir:%s  "%s"', [LineEnding, lmsedir]));
end;

procedure Clone;
const
  curl = 'https://codeberg.org/mse-org/mseide-msegui.git';
  //curl = 'https://github.com/mse-org/mseide-msegui.git';
var
  lcmd: msestring;
begin
{ Clonage du dépôt git }
  writeln('[INFO] Cloning repository');
  lcmd := UnicodeFormat('git clone --single-branch --depth 1 %s %s', [curl, lmsedir]);
  llog.Append(unicodeformat('lcmd:%s  "%s"', [LineEnding, lcmd]));
  Exec(lcmd);
end;

procedure Build;
var
  lfilename, lfilename2: filenamety;
  lcmd: msestring;
begin
{ Compilation de MSEide }
  writeln('[INFO] Creating build script');
  lfilename := extractfilepath(tosysfilepath(sys_getapplicationpath)) + 'build-' + linstall + cext;
  lfilename2 := tosysfilepath(filedir(sys_getapplicationpath) + 'build-' + linstall + cext);
  llog.Append(unicodeformat('lfilename:%s  "%s"', [LineEnding, lfilename]));
  llog.Append(unicodeformat('lfilename2:%s  "%s"', [LineEnding, lfilename2]));
  createbuildscript(lfilename, lmsedir);
  writeln('[INFO] Building MSEide');
  lcmd := cexe + lfilename;
  llog.Append(unicodeformat('lcmd:%s  "%s"', [LineEnding, lcmd]));
  Exec(lcmd);
end;

procedure Configure;
var
  lfilename: filenamety;
  lcmd, lcmd2: msestring;
begin
{ Configuration de MSEide }

  writeln('[INFO] Creating start script');
  
  lfilename := extractfilepath(tosysfilepath(sys_getapplicationpath)) + 'start-' + linstall + cext;
  createstartscript(lfilename, lmsedir);

  writeln('[INFO] Configuring MSEide');
  
  lcmd := UnicodeFormat(
    cexe + '%s --macrodef=MSEDIR,%s --storeglobalmacros',
    [lfilename, lmsedir + cpathdelim]
  );
  llog.Append(unicodeformat('lcmd:%s  "%s"', [LineEnding, lcmd]));
  lcmd2 := UnicodeFormat(
    cexe + '%s --macrodef=MSEDIR,%s --storeglobalmacros',
    [lfilename, tomsefilepath(lmsedir + cpathdelim)]
  );
  llog.Append(unicodeformat('lcmd2:%s  "%s"', [LineEnding, lcmd2]));
  Exec(lcmd);
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
  llog.Append(unicodeformat('lmseidever:%s  "%s"', [LineEnding, lmseidever]));
  
  lfilename := extractfilepath(sys_getapplicationpath) + linstall + '.desktop';

  createdesktopfile(
    lfilename,
    unicodeformat('MSEide %s', [lmseidever]),
    unicodeformat('%s/apps/ide/mseide --globstatfile=%s/apps/ide/mseide.sta %%F', [lmsedir, lmsedir]),
    unicodeformat('%s/msegui_48.png', [lmsedir]),
    unicodeformat('%s/apps/ide', [lmsedir])
  );
  
  lcmd := unicodeformat('chmod +x %s', [lfilename]);
  Exec(lcmd);
  
  i := 0;
  repeat
    ltargetdir := sys_getuserhomedir + '/' + cdesktopnames[i];
    
    if DirectoryExists(ltargetdir) then
    begin
      lcmd := unicodeformat('cp -f %s %s', [lfilename, ltargetdir + '/' + linstall + '.desktop']);
      llog.Append(unicodeformat('lcmd:%s  "%s"', [LineEnding, lcmd]));
      Exec(lcmd);
      break;
    end else
      writeln(unicodeformat('[WARNING] Directory not found: "%s"', [ltargetdir]));
    
    inc(i);
  until i > high(cdesktopnames); 
  
  ltargetdir := sys_getuserhomedir + '/.local/share/applications';
  if DirectoryExists(ltargetdir) then
  begin
    lcmd := unicodeformat('cp -f %s %s', [lfilename, ltargetdir + '/' + linstall + '.desktop']);
    llog.Append(unicodeformat('lcmd:%s  "%s"', [LineEnding, lcmd]));
    Exec(lcmd);
  end else
    writeln(unicodeformat('[WARNING] Directory not found: "%s"', [ltargetdir]));
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
