unit MWQ.LogBridge.QuickLoggerAdapter;

interface

uses
  Quick.Logger, MWQ.LogBridge.CommLoggerBase, MWQ.LogBridge.ICommonLogger;

type
  TQuickLoggerAdapter = class(TCommLoggerBase)
  protected
    function GetLoggerType: TLoggerType; override;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Log(const Level: TLogType; const Msg: string); override;
    procedure SetOutputTypes(const ATypes: TLogOutputTypes); override;
    procedure SetLogFileName(const AFileName: string); override;
  end;

procedure RegisterQuickLoggerAdapter;
implementation
uses
  Quick.Logger.Provider.Files, Quick.Logger.Provider.Console, Quick.Logger.Provider.Memory,
  Quick.Logger.Provider.IDEDebug, {Quick.Logger.Provider.Email, Quick.Logger.Provider.SysLog,}
  Quick.Logger.Provider.EventLog, Quick.Logger.Provider.StringList, MWQ.LogBridge;
{ TQuickLoggerAdapter }

constructor TQuickLoggerAdapter.Create;
begin
  inherited Create;
end;

destructor TQuickLoggerAdapter.Destroy;
begin
  inherited;
end;

function TQuickLoggerAdapter.GetLoggerType: TLoggerType;
begin
  Result := TLoggerType.lgtQuickLogger;
end;

procedure TQuickLoggerAdapter.Log(const Level: TLogType; const Msg: string);
begin
  if not IsLevelEnabled(Level) then
    Exit;

  case Level of
    ltInfo:
      Quick.Logger.Log(Msg, TEventType.etInfo);
    ltDebug:
      Quick.Logger.Log(Msg, TEventType.etDebug);
    ltWarn:
      Quick.Logger.Log(Msg, TEventType.etWarning);
    ltError,
    ltFatal:
      Quick.Logger.Log(Msg, TEventType.etError);
    ltException:
      Quick.Logger.Log(Msg, TEventType.etException);
    ltHeader:
      Quick.Logger.Log(Msg, TEventType.etHeader);
    ltSuccess:
      Quick.Logger.Log(Msg, TEventType.etSuccess);
    ltDone:
      Quick.Logger.Log(Msg, TEventType.etDone);
    ltCritical:
      Quick.Logger.Log(Msg, TEventType.etCritical);
    ltTrace:
      Quick.Logger.Log(Msg, TEventType.etTrace);
    ltCustom1:
      Quick.Logger.Log(Msg, TEventType.etCustom1);
    ltCustom2:
      Quick.Logger.Log(Msg, TEventType.etCustom2);
  else
    Quick.Logger.Log(Msg, TEventType.etInfo);
  end;
end;

procedure TQuickLoggerAdapter.SetLogFileName(const AFileName: string);
begin
  inherited;
  if AFileName = '' then
  begin
    GlobalLogFileProvider.Enabled := False;
    Exit;
  end;
  GlobalLogFileProvider.FileName := AFileName;
end;

procedure TQuickLoggerAdapter.SetOutputTypes(const ATypes: TLogOutputTypes);
begin
  inherited SetOutputTypes(ATypes); // stores to FOutputTypes

  // Disable all providers first
  for var i := Quick.Logger.Logger.Providers.Count - 1 downto 0 do begin
//    Quick.Logger.Logger.Providers[I] := nil;
    TLogProviderBase(Quick.Logger.Logger.Providers[i]).Enabled := False;
  end;
//  Quick.Logger.Logger.Providers.Clear;

  // Enable providers based on ATypes

  if loFile in ATypes then
  begin
    if FFileName <> '' then
    begin
      GlobalLogFileProvider.FileName := FFileName;
      GlobalLogFileProvider.Enabled := True;

      if not Quick.Logger.Logger.Providers.Contains(GlobalLogFileProvider) then
        Quick.Logger.Logger.Providers.add(GlobalLogFileProvider);
    end
    else
      GlobalLogFileProvider.Enabled := False;
  end;

  if loConsole in ATypes then
  begin
    GlobalLogConsoleProvider.Enabled := True;
    if not Quick.Logger.Logger.Providers.Contains(GlobalLogConsoleProvider) then
      Quick.Logger.Logger.Providers.add(GlobalLogConsoleProvider);
  end;

  if loMemory in ATypes then
  begin
    // Enable a memory/log cache provider if you have one
    // e.g. GlobalLogMemoryProvider.Enabled := True;
    GlobalLogMemoryProvider.Enabled := True;
    if not Quick.Logger.Logger.Providers.Contains(GlobalLogMemoryProvider) then
      Quick.Logger.Logger.Providers.add(GlobalLogMemoryProvider);
  end;

  if loIDEDebug in ATypes then
  begin
    GlobalLogIDEDebugProvider.Enabled := True;
    if not Quick.Logger.Logger.Providers.Contains(GlobalLogIDEDebugProvider) then
      Quick.Logger.Logger.Providers.add(GlobalLogIDEDebugProvider);
  end;

//  if loMail in ATypes then  // This need Indy package.
//  begin
//    GlobalLogEmailProvider.Enabled := True;
////    GlobalLogEmailProvider.Mail.SenderName
//    Quick.Logger.Logger.Providers.add(GlobalLogEmailProvider);
//  end;

//  if loSyslog in ATypes then  // This need Indy package.
//  begin
//    GlobalLogSysLogProvider.Enabled := True;
////    GlobalLogEmailProvider.Mail.SenderName
//    Quick.Logger.Logger.Providers.add(GlobalLogSysLogProvider);
//  end;

  if loEventlog in ATypes then
  begin
    GlobalLogEventLogProvider.Enabled := True;
//    GlobalLogEmailProvider.Mail.SenderName
//    GlobalLogEventLogProvider.on
    if not Quick.Logger.Logger.Providers.Contains(GlobalLogEventLogProvider) then
      Quick.Logger.Logger.Providers.add(GlobalLogEventLogProvider);
  end;

  if loStringList in ATypes then
  begin
    GlobalLogStringListProvider.Enabled := True;
//    GlobalLogEmailProvider.Mail.SenderName
//    GlobalLogEventLogProvider.on
    if not Quick.Logger.Logger.Providers.Contains(GlobalLogStringListProvider) then
      Quick.Logger.Logger.Providers.add(GlobalLogStringListProvider);
  end;

  // Other output types...

  // Optional: configure LogLevel on providers to match desired log levels

  // You can skip loCustom — it's checked before calling Log

end;

procedure RegisterQuickLoggerAdapter;
begin
  GlobalLogBridge.RegisterAdapter(lgtQuickLogger,
    function: ICommonLogger
    begin
      Result := TQuickLoggerAdapter.Create;
    end);
end;

initialization
  RegisterQuickLoggerAdapter;
end.
