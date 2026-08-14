unit MWQ.LogBridge.Log4DAdapter;

interface

uses
  Log4D, MWQ.LogBridge.CommLoggerBase, MWQ.LogBridge.ICommonLogger;

type
  TLog4DLoggerAdapter = class(TCommLoggerBase)
  private
    FLogger: TLogLogger;
  protected
    function GetLoggerType: TLoggerType; override;
  public
    constructor Create(const LoggerName: string = 'Log4D');
    destructor Destroy; override;

    procedure Log(const Level: TLogType; const Msg: string); override;
    procedure SetOutputTypes(const ATypes: TLogOutputTypes); override;
  end;

procedure RegisterLog4DAdapter;
implementation
uses
  MWQ.LogBridge;

{ TLog4DLoggerAdapter }

constructor TLog4DLoggerAdapter.Create(const LoggerName: string = 'Log4D');
begin
  inherited Create;
  FLogger := TLogLogger.GetLogger(LoggerName);
end;

destructor TLog4DLoggerAdapter.Destroy;
begin
  inherited;
end;

function TLog4DLoggerAdapter.GetLoggerType: TLoggerType;
begin
  Result := TLoggerType.lgtLog4D;
end;

procedure TLog4DLoggerAdapter.Log(const Level: TLogType; const Msg: string);
begin
  if not IsLevelEnabled(Level) then
    Exit;

  case Level of
    ltHeader,
    ltInfo,
    ltSuccess,
    ltDone,
    ltCustom1,
    ltCustom2:
      FLogger.Info(Msg);

    ltWarn:
      FLogger.Warn(Msg);

    ltError,
    ltException:
      FLogger.Error(Msg);

    ltCritical,
    ltFatal:
      FLogger.Fatal(Msg);

    ltDebug:
      FLogger.Debug(Msg);

    ltTrace:
      FLogger.Trace(Msg);
  end;
end;

procedure TLog4DLoggerAdapter.SetOutputTypes(const ATypes: TLogOutputTypes);
begin
  inherited;

  // Clear existing appenders
  FLogger.Appenders.Clear;

  // Reconfigure based on ATypes
  if loFile in ATypes then
    FLogger.AddAppender(TLogFileAppender.Create('FileAppender', 'log4d.log'));

//  if loConsole in ATypes then
//    FLogger.AddAppender(TLogConsoleAppender.Create('ConsoleAppender'));
//
//  if loMail in ATypes then
//    FLogger.AddAppender(TLogSMTPAppender.Create('MailAppender'));

  // TLogNullAppender, TLogODSAppender, TLogStreamAppender,

end;

procedure RegisterLog4DAdapter;
begin
  GlobalLogBridge.RegisterAdapter(lgtLog4D,
    function: ICommonLogger
    begin
      Result := TLog4DLoggerAdapter.Create;
    end);
end;

initialization
  RegisterLog4DAdapter;

end.
