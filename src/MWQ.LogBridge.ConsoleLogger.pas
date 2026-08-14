unit MWQ.LogBridge.ConsoleLogger;

interface

uses
  MWQ.LogBridge.CommLoggerBase, MWQ.LogBridge.ICommonLogger;

type
  TConsoleLogger = class(TCommLoggerBase)
  private

  protected
    function GetLoggerType: TLoggerType; override;

  public
    constructor Create(const LoggerName: string = 'ConsoleLogger');
    procedure Log(const Level: TLogType; const Msg: string); overload; override;
  end;
procedure RegisterConsoleLoggerAdapter;
implementation
uses
  MWQ.LogBridge, System.SysUtils;

constructor TConsoleLogger.Create(const LoggerName: string);
begin
  inherited Create;
  SetOutputTypes([loConsole]); // default
end;

function TConsoleLogger.GetLoggerType: TLoggerType;
begin
  Result := TLoggerType.lgtConsole;
end;

procedure TConsoleLogger.Log(const Level: TLogType; const Msg: string);
begin
  if IsLevelEnabled(Level) and (loConsole in FOutputTypes) then
    Writeln(Format('[%s] %s', [LogTypeToStr(Level), Msg]));
end;

procedure RegisterConsoleLoggerAdapter;
begin
  GlobalLogBridge.RegisterAdapter(lgtConsole,
    function: ICommonLogger
    begin
      Result := TConsoleLogger.Create;
    end);
end;

//procedure TConsoleLogger.Log(const Level: TLogType; const MsgFmt: string; const Args: array of const);
//begin
//  Log(Level, Format(MsgFmt, Args));
//end;

initialization
  RegisterConsoleLoggerAdapter;
end.
