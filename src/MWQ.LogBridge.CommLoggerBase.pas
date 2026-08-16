unit MWQ.LogBridge.CommLoggerBase;

interface

uses
  MWQ.LogBridge.ICommonLogger;

type
  TCommLoggerBase = class(TInterfacedObject, ICommonLogger)
  private
    FEnableLog: Boolean;
  protected
//    FTargets: TList<ICommonLogger>;
    FOutputTypes: TLogOutputTypes;
    FLogTypeMask: TLogTypeMask;
    FFileName: String;
    function LogTypeToStr(const Level: TLogType): string;
    function GetLoggerType: TLoggerType; virtual; abstract;
  public
    constructor Create;
    destructor Destroy; override;

//    procedure AddLogger(const Logger: ICommonLogger);

    procedure Log(const Level: TLogType; const Msg: string); overload; virtual; abstract;
    procedure Log(const Level: TLogType; const MsgFmt: string; const Args: array of const); overload; virtual;

    procedure SetEnable(const AValue: Boolean);
    procedure SetOutputTypes(const ATypes: TLogOutputTypes); virtual;
    procedure SetLogFileName(const AFileName: string); virtual;  // <-- Add this
    procedure RotateLog; virtual;

    function IsLevelEnabled(const Level: TLogType): Boolean; virtual;
    function GetLogTypeMask: TLogTypeMask;
    procedure SetLogTypeMask(const AMask: TLogTypeMask); virtual;

    function GetOutputTypes: TLogOutputTypes;

    procedure Trace(const Msg: string);
    procedure Debug(const Msg: string);
    procedure Info(const Msg: string);
    procedure Warn(const Msg: string);
    procedure Error(const Msg: string);
    procedure Fatal(const Msg: string);

    procedure Header(const Msg: string);
    procedure Success(const Msg: string);
    procedure Critical(const Msg: string);
    procedure ExceptionMsg(const Msg: string);
    procedure Done(const Msg: string);
    procedure Custom1(const Msg: string);
    procedure Custom2(const Msg: string);

    property EnableLog: Boolean read FEnableLog write FEnableLog; // "Controls whether log messages are routed to targets. Disabling this stops log dispatching altogether."
  end;

implementation

uses
  System.SysUtils;

constructor TCommLoggerBase.Create;
begin
  inherited;
  FEnableLog := True;          // Enabled by default
  FOutputTypes := [loFile]; // default
  FLogTypeMask := LOG_TYPE_MASK_ALL;
//  FTargets := TList<ICommonLogger>.Create;
end;

destructor TCommLoggerBase.Destroy;
begin
//  FTargets.Free;
  inherited;
end;

//procedure TCommLoggerBase.AddLogger(const Logger: ICommonLogger);
//begin
//  if Assigned(Logger) then
//    FTargets.Add(Logger);
//end;

//procedure TCommLoggerBase.Log(const Level: TLogType; const Msg: string);
//var
//  Logger: ICommonLogger;
//begin
//  if not FEnableLog then exit;
//  if FOutputTypes = [] then
//    Exit;
//  // Sub-class need to implement the log logic after this.
//end;

procedure TCommLoggerBase.Log(const Level: TLogType; const MsgFmt: string; const Args: array of const);
begin
  if not IsLevelEnabled(Level) then
    Exit;
  Log(Level, Format(MsgFmt, Args));
end;

function TCommLoggerBase.IsLevelEnabled(const Level: TLogType): Boolean;
begin
  Result := FEnableLog and
    ((FLogTypeMask and LogTypeToMask(Level)) <> 0);
end;

function TCommLoggerBase.GetLogTypeMask: TLogTypeMask;
begin
  Result := FLogTypeMask;
end;

procedure TCommLoggerBase.SetLogTypeMask(const AMask: TLogTypeMask);
begin
  FLogTypeMask := AMask;
end;

function TCommLoggerBase.LogTypeToStr(const Level: TLogType): string;
begin
  case Level of
    ltHeader:    Result := 'HEADER';
    ltInfo:      Result := 'INFO';
    ltSuccess:   Result := 'SUCCESS';
    ltWarn:      Result := 'WARN';
    ltError:     Result := 'ERROR';
    ltCritical:  Result := 'CRITICAL';
    ltException: Result := 'EXCEPTION';
    ltDebug:     Result := 'DEBUG';
    ltTrace:     Result := 'TRACE';
    ltDone:      Result := 'DONE';
    ltFatal:     Result := 'FATAL';
    ltCustom1:   Result := 'CUSTOM1';
    ltCustom2:   Result := 'CUSTOM2';
  else
    Result := 'UNKNOWN';
  end;
end;

// Simple wrappers
procedure TCommLoggerBase.Trace(const Msg: string); begin Log(ltTrace, Msg); end;
procedure TCommLoggerBase.Debug(const Msg: string); begin Log(ltDebug, Msg); end;
procedure TCommLoggerBase.Info(const Msg: string); begin Log(ltInfo, Msg); end;
procedure TCommLoggerBase.Warn(const Msg: string); begin Log(ltWarn, Msg); end;
procedure TCommLoggerBase.Error(const Msg: string); begin Log(ltError, Msg); end;
procedure TCommLoggerBase.Fatal(const Msg: string); begin Log(ltFatal, Msg); end;
function TCommLoggerBase.GetOutputTypes: TLogOutputTypes;
begin
  Result := FOutputTypes;
end;

// Additional shorthands
procedure TCommLoggerBase.Header(const Msg: string);    begin Log(ltHeader, Msg);    end;
procedure TCommLoggerBase.SetEnable(const AValue: Boolean);
begin
  Self.FEnableLog := AValue;
end;

procedure TCommLoggerBase.SetLogFileName(const AFileName: string);
begin
  FFileName := AFileName;
end;

procedure TCommLoggerBase.RotateLog;
begin
end;

procedure TCommLoggerBase.SetOutputTypes(const ATypes: TLogOutputTypes);
begin
  FOutputTypes := ATypes;
end;

procedure TCommLoggerBase.Success(const Msg: string);   begin Log(ltSuccess, Msg);   end;
procedure TCommLoggerBase.Critical(const Msg: string);  begin Log(ltCritical, Msg);  end;
procedure TCommLoggerBase.ExceptionMsg(const Msg: string); begin Log(ltException, Msg); end;
procedure TCommLoggerBase.Done(const Msg: string);      begin Log(ltDone, Msg);      end;
procedure TCommLoggerBase.Custom1(const Msg: string);   begin Log(ltCustom1, Msg);   end;
procedure TCommLoggerBase.Custom2(const Msg: string);   begin Log(ltCustom2, Msg);   end;

end.
