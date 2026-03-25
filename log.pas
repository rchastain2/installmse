
unit Log;

interface

uses
  msetypes;
  
type
  TLog = class
    private
      FFile: text;
    public
      constructor Create(const AName: filenamety); overload;
      destructor Destroy; override;
      procedure Append(const ALine: msestring; const AFlush: boolean = FALSE);
  end;

implementation

constructor TLog.Create(const AName: filenamety);
begin
  AssignFile(FFile, AName);
  Rewrite(FFile);
end;

destructor TLog.Destroy;
begin
  CloseFile(FFile);
end;

procedure TLog.Append(const ALine: msestring; const AFlush: boolean);
begin
  WriteLn(FFile, ALine);
  if AFlush then
    Flush(FFile);
end;

end.
