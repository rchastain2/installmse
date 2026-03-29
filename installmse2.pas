
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

type
  TInstallMSE = class
    constructor Create(const action: boolean);
    destructor Destroy; override;
    procedure Execute;
  strict private
    flog: TLog;
    finstall: msestring;
    fparentdir, fmsedir: filenamety;
    faction: boolean;
    procedure Shell(const cmd: msestring);
    procedure Init;
    procedure Clone;
    procedure Build;
    procedure Configure;
    procedure CreateShortcuts;
    procedure CreateShortcutsWin;
  end;

(* -------------------------------------------------------------------------- *)

const
  ctargetos = {$IFDEF mswindows}'windows'{$ELSE}'linux'{$ENDIF};
  cpathdelim = {$IFDEF mswindows}'\'{$ELSE}'/'{$ENDIF};

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
  lstream.writeln('-Mobjfpc -Sh mseide.pas -v0');
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
  cext = {$IFDEF mswindows}'.cmd'{$ELSE}'.sh'{$ENDIF};
  cexe = {$IFDEF mswindows}'cmd /C '{$ELSE}'sh '{$ENDIF};

constructor TInstallMSE.Create(const action: boolean);
const
  capp = 'InstallMSE 0.5';
  cbuild = 'FPC ' + {$I %FPCVERSION%} + ' ' + {$I %DATE%} + ' ' + {$I %TIME%} + ' ' + {$I %FPCTARGETOS%} + '-' + {$I %FPCTARGETCPU%};
  cactionstr: array[boolean] of msestring = ('SIMULATION', 'ACTION');
begin
  inherited Create;
  flog := TLog.Create({clog}tosysfilepath(replacefileext(sys_getapplicationpath, 'log')));
  faction := action;
  writeln(capp + ' (' + cbuild + ')');
  writeln('[INFO] Mode ' + cactionstr[faction]);
end;

destructor TInstallMSE.Destroy;
begin
  writeln('[INFO] Done');
  flog.Free;
  inherited Destroy;
end;

procedure TInstallMSE.Shell(const cmd: msestring);
var
  lresult: integer;
begin
  flog.Append(unicodeformat('Shell(%s)', [cmd]));
  if faction then
  begin
    lresult := execwaitmse(cmd);
    flog.Append(unicodeformat('lresult: %d', [lresult]));
    if lresult = -1 then
    begin
      writeln('[ERROR] Execution failed, switch to simulation mode');
      faction := false;
    end;
  end else
    writeln('[WARNING] Simulation mode, command not executed');
end;

procedure TInstallMSE.Init;
const
  copt = '--DIR='; { Second paramètre de la fonction mseStrLIComp. Doit être en majuscules. }
  cfmt = 'YYMMDDhhnn';
var
  larg: msestringarty;
  ltimestamp: msestring;
  i: integer;
begin
{ Emplacement par défaut }
  fparentdir := tosysfilepath(sys_getcurrentdir);
{ Emplacement spécifié dans la ligne de commande }
  writeln('[INFO] Checking command-line');
  larg := getcommandlinearguments;
  for i := 1 to high(larg) do
  begin
    flog.Append(unicodeformat('larg[%d]:%s  "%s"', [i, LineEnding, larg[i]]));
    if msestrlicomp(pmsechar(larg[i]), pmsechar(copt), length(copt)) = 0 then
      fparentdir := copy(larg[i], length(copt) + 1, msetypes.bigint);
  end;
{ Initialisation des autres variables }
  writeln('[INFO] Setting variables');
  ltimestamp := utf8tostring(FormatDateTime(cfmt, Now));
  finstall := 'mseide-' + ltimestamp;
  fmsedir := fparentdir + cpathdelim + finstall;
  flog.Append(unicodeformat('fmsedir:%s  "%s"', [LineEnding, fmsedir]));
{ Vérification des dépendances }
  writeln('[INFO] Checking dependencies 1/2');
  Shell('git --version');
  writeln('[INFO] Checking dependencies 2/2');
  Shell('fpc -iW');
end;

procedure TInstallMSE.Clone;
const
  curl = 'https://codeberg.org/mse-org/mseide-msegui.git';
  //curl = 'https://github.com/mse-org/mseide-msegui.git';
var
  lcmd: msestring;
begin
{ Clonage du dépôt git }
  writeln('[INFO] Cloning repository');
  lcmd := UnicodeFormat('git clone --single-branch --depth 1 %s %s', [curl, fmsedir]);
  flog.Append(unicodeformat('lcmd:%s  "%s"', [LineEnding, lcmd]));
  Shell(lcmd);
end;

procedure TInstallMSE.Build;
var
  lfilename, lfilename2: filenamety;
  lcmd: msestring;
begin
{ Création du script pour compiler MSEide }
  writeln('[INFO] Creating build script');
  lfilename := extractfilepath(tosysfilepath(sys_getapplicationpath)) + 'build-' + finstall + cext;
  lfilename2 := tosysfilepath(filedir(sys_getapplicationpath) + 'build-' + finstall + cext);
  flog.Append(unicodeformat('lfilename:%s  "%s"', [LineEnding, lfilename]));
  flog.Append(unicodeformat('lfilename2:%s  "%s"', [LineEnding, lfilename2]));
  createbuildscript(lfilename, fmsedir);
{ Compilation de MSEide }
  writeln('[INFO] Building MSEide');
  lcmd := cexe + lfilename;
  flog.Append(unicodeformat('lcmd:%s  "%s"', [LineEnding, lcmd]));
  Shell(lcmd);
end;

procedure TInstallMSE.Configure;
var
  lfilename: filenamety;
  lcmd, lcmd2: msestring;
begin
{ Création du script pour lancer MSEide }
  writeln('[INFO] Creating start script');
  lfilename := extractfilepath(tosysfilepath(sys_getapplicationpath)) + 'start-' + finstall + cext;
  createstartscript(lfilename, fmsedir);
{ Configuration de MSEide }
  writeln('[INFO] Configuring MSEide');
  lcmd := UnicodeFormat(
    cexe + '%s --macrodef=MSEDIR,%s --storeglobalmacros',
    [lfilename, fmsedir + cpathdelim]
  );
  flog.Append(unicodeformat('lcmd:%s  "%s"', [LineEnding, lcmd]));
  lcmd2 := UnicodeFormat(
    cexe + '%s --macrodef=MSEDIR,%s --storeglobalmacros',
    [lfilename, tomsefilepath(fmsedir + cpathdelim)]
  );
  flog.Append(unicodeformat('lcmd2:%s  "%s"', [LineEnding, lcmd2]));
  Shell(lcmd);
end;

procedure TInstallMSE.CreateShortcuts;
const
  cdesktopnames: array[0..1] of msestring = (
    'Bureau',
    'Desktop'
  );
var
  lfilename, ltargetdir: filenamety;
  lmseidever, lmseguiver: string;
  lcmd, lmsedirexp: msestring;
  i: integer;
begin
{ Expansion }
  lmsedirexp := filepath(fmsedir);
  readmseversion(stringtoutf8(lmsedirexp), lmseidever, lmseguiver);
  flog.Append(unicodeformat('lmseidever:%s  "%s"', [LineEnding, lmseidever]));
  
  lfilename := extractfilepath(sys_getapplicationpath) + finstall + '.desktop';

  createdesktopfile(
    lfilename,
    unicodeformat('MSEide %s', [lmseidever]),
    unicodeformat('%s/apps/ide/mseide --globstatfile=%s/apps/ide/mseide.sta %%F', [lmsedirexp, lmsedirexp]),
    unicodeformat('%s/msegui_48.png', [lmsedirexp]),
    unicodeformat('%s/apps/ide', [lmsedirexp])
  );
  
  lcmd := unicodeformat('chmod +x %s', [lfilename]);
  Shell(lcmd);
  
  i := 0;
  repeat
    ltargetdir := sys_getuserhomedir + '/' + cdesktopnames[i];
    
    if DirectoryExists(ltargetdir) then
    begin
      lcmd := unicodeformat('cp -f %s %s', [lfilename, ltargetdir + '/' + finstall + '.desktop']);
      flog.Append(unicodeformat('lcmd:%s  "%s"', [LineEnding, lcmd]));
      Shell(lcmd);
      break;
    end else
      writeln(unicodeformat('[WARNING] Directory not found: "%s"', [ltargetdir]));
    
    inc(i);
  until i > high(cdesktopnames); 
  
  ltargetdir := sys_getuserhomedir + '/.local/share/applications';
  if DirectoryExists(ltargetdir) then
  begin
    lcmd := unicodeformat('cp -f %s %s', [lfilename, ltargetdir + '/' + finstall + '.desktop']);
    flog.Append(unicodeformat('lcmd:%s  "%s"', [LineEnding, lcmd]));
    Shell(lcmd);
  end else
    writeln(unicodeformat('[WARNING] Directory not found: "%s"', [ltargetdir]));
end;

procedure TInstallMSE.CreateShortcutsWin;
begin
end;

procedure TInstallMSE.Execute;
begin
  Init;
  Clone;
  Build;
  Configure;
{$IFDEF mswindows}
  CreateShortcutsWin;
{$ELSE}
  CreateShortcuts;
{$ENDIF}
end;

var
  linstall: TInstallMSE;
  
begin
  linstall := TInstallMSE.Create({$IFDEF release}true{$ELSE}false{$ENDIF});
  linstall.Execute;
  linstall.Free;
end.
