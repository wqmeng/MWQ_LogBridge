unit MWQ.LogBridge;

interface

uses
  MWQ.LogBridge.ICommonLogger,
  Spring, Spring.Collections, Spring.Collections.Lists;

type
  TLoggerType = MWQ.LogBridge.ICommonLogger.TLoggerType;
  TLogType = MWQ.LogBridge.ICommonLogger.TLogType;
  TLogTypeMask = MWQ.LogBridge.ICommonLogger.TLogTypeMask;
  TLogOutputType = MWQ.LogBridge.ICommonLogger.TLogOutputType;
  TLogOutputTypes = MWQ.LogBridge.ICommonLogger.TLogOutputTypes;

  TLogBridge = class
  private
    class var FEnableLog: Boolean;
  protected
    FFactories: IDictionary<TLoggerType, TLoggerFactoryFunc>;
    FTargets: IDictionary<TLoggerType, ICommonLogger>;
    FSessionIDs: IDictionary<Integer, TArray<TLoggerType>>;
    FNextUserID: Integer;
    FOutputTypes: TLogOutputTypes;
    FLogTypeMask: TLogTypeMask;
    FFileName: String;
    function LogTypeToStr(const Level: TLogType): string; inline;
  public
    constructor Create;
    destructor Destroy; override;

    procedure RegisterAdapter(const LoggerType: TLoggerType;
      const Factory: TLoggerFactoryFunc); inline;
    procedure AddLogger(const Logger: ICommonLogger); inline;
    procedure RemoveLogger(const Logger: ICommonLogger); inline;
    procedure UseDefaultLogger; inline;
    procedure UseConsoleOnly; inline;
    function UseLogger(const ALoggers: TArray<TLoggerType>): Integer; inline;
    procedure ClearLogger; inline; // ✅ remove extra ()

    function GetOrCreateAdapter(const LoggerType: TLoggerType): ICommonLogger;

    procedure Log(const Level: TLogType; const Msg: string); overload; inline;
    procedure Log(const Level: TLogType; const MsgFmt: string; const Args: array of const); overload;
    procedure Log(const Level: TLogType; const MsgFmt: string;
      const Args: array of const; const ASessionID: Integer); overload;
    procedure Log(const Level: TLogType; const Msg: string; const ASessionID: Integer); overload; inline;
    function IsLevelEnabled(const Level: TLogType): Boolean; inline;

    procedure SetEnable(const AValue: Boolean); inline;
    procedure SetLogTypeMask(const AMask: TLogTypeMask); inline;
    function GetLogTypeMask: TLogTypeMask; inline;
    procedure SetOutputTypes(const ATypes: TLogOutputTypes); inline;
    procedure SetLogFileName(const AFileName: string); inline;
    procedure RotateLog; inline;
    function GetOutputTypes: TLogOutputTypes; inline;

    property LogFileName: string read FFileName;

  public
    class property EnableLog: Boolean read FEnableLog write FEnableLog;
  end;

  // Backend-independent aliases kept for source compatibility with existing
  // callers. Their values are defined by TLogType, not by Quick.Logger.
  TEventType = TLogType;
  TLogLevel = set of TLogType;

const
  etHeader = ltHeader;
  etInfo = ltInfo;
  etSuccess = ltSuccess;
  etWarning = ltWarn;
  etError = ltError;
  etCritical = ltCritical;
  etException = ltException;
  etDebug = ltDebug;
  etTrace = ltTrace;
  etDone = ltDone;
  etCustom1 = ltCustom1;
  etCustom2 = ltCustom2;

  LOG_ONLYERRORS: TLogLevel = [ltHeader, ltInfo, ltError, ltCritical, ltException];
  LOG_ERRORSANDWARNINGS: TLogLevel =
    [ltHeader, ltInfo, ltWarn, ltError, ltCritical, ltException];
  LOG_BASIC: TLogLevel = [ltInfo, ltSuccess, ltWarn, ltError, ltCritical, ltException];
  LOG_ALL: TLogLevel =
    [ltHeader, ltInfo, ltSuccess, ltDone, ltWarn, ltError, ltCritical,
     ltException, ltCustom1, ltCustom2];
  LOG_TRACE: TLogLevel =
    [ltHeader, ltInfo, ltSuccess, ltDone, ltWarn, ltError, ltCritical,
     ltException, ltTrace];
  LOG_DEBUG: TLogLevel =
    [ltHeader, ltInfo, ltSuccess, ltDone, ltWarn, ltError, ltCritical,
     ltException, ltTrace, ltDebug];
  LOG_VERBOSE: TLogLevel = [Low(TLogType)..High(TLogType)];

const
  lgtConsole = MWQ.LogBridge.ICommonLogger.lgtConsole;
  lgtQuickLogger = MWQ.LogBridge.ICommonLogger.lgtQuickLogger;
  lgtLog4D = MWQ.LogBridge.ICommonLogger.lgtLog4D;
  lgtCustom1 = MWQ.LogBridge.ICommonLogger.lgtCustom1;
  lgtCustom2 = MWQ.LogBridge.ICommonLogger.lgtCustom2;
  lgtCustom3 = MWQ.LogBridge.ICommonLogger.lgtCustom3;

  loFile = MWQ.LogBridge.ICommonLogger.loFile;
  loMemory = MWQ.LogBridge.ICommonLogger.loMemory;
  loMail = MWQ.LogBridge.ICommonLogger.loMail;
  loSyslog = MWQ.LogBridge.ICommonLogger.loSyslog;
  loEventlog = MWQ.LogBridge.ICommonLogger.loEventlog;
  loConsole = MWQ.LogBridge.ICommonLogger.loConsole;
  loIDEDebug = MWQ.LogBridge.ICommonLogger.loIDEDebug;
  loStringList = MWQ.LogBridge.ICommonLogger.loStringList;
  loCustom = MWQ.LogBridge.ICommonLogger.loCustom;

var
  LogBridge: TLogBridge;

function LogTypeFromEventType(const EventType: TEventType): TLogType; inline;
function IsLogLevelEnabled(const EventType: TEventType): Boolean; inline;
function LogTypeMaskFromEventLevel(const Levels: TLogLevel): TLogTypeMask;

procedure Log(const Msg: string); overload; inline;
procedure Log(const Msg: string; const EventType: TEventType); overload; inline;
procedure Log(const MsgFmt: string; const Args: array of const;
  const EventType: TEventType); overload;

// Helpers support both an already-built message and deferred formatting:
//   LBI('ready message');
//   LBI('Price=%f', [Price]);
//   LBI('Price=%f', [Price], SessionID);
procedure LBT(const Msg: string; const ASessionID: Integer = 0); overload; inline;
procedure LBT(const MsgFmt: string; const Args: array of const;
  const ASessionID: Integer = 0); overload;
procedure LBD(const Msg: string; const ASessionID: Integer = 0); overload; inline;
procedure LBD(const MsgFmt: string; const Args: array of const;
  const ASessionID: Integer = 0); overload;
procedure LBI(const Msg: string; const ASessionID: Integer = 0); overload; inline;
procedure LBI(const MsgFmt: string; const Args: array of const;
  const ASessionID: Integer = 0); overload;
procedure LBW(const Msg: string; const ASessionID: Integer = 0); overload; inline;
procedure LBW(const MsgFmt: string; const Args: array of const;
  const ASessionID: Integer = 0); overload;
procedure LBE(const Msg: string; const ASessionID: Integer = 0); overload; inline;
procedure LBE(const MsgFmt: string; const Args: array of const;
  const ASessionID: Integer = 0); overload;
procedure LBF(const Msg: string; const ASessionID: Integer = 0); overload; inline;
procedure LBF(const MsgFmt: string; const Args: array of const;
  const ASessionID: Integer = 0); overload;

procedure LBH(const Msg: string; const ASessionID: Integer = 0); overload; inline;
procedure LBH(const MsgFmt: string; const Args: array of const;
  const ASessionID: Integer = 0); overload;
procedure LBS(const Msg: string; const ASessionID: Integer = 0); overload; inline;
procedure LBS(const MsgFmt: string; const Args: array of const;
  const ASessionID: Integer = 0); overload;
procedure LBC(const Msg: string; const ASessionID: Integer = 0); overload; inline;
procedure LBC(const MsgFmt: string; const Args: array of const;
  const ASessionID: Integer = 0); overload;
procedure LBEx(const Msg: string; const ASessionID: Integer = 0); overload; inline;
procedure LBEx(const MsgFmt: string; const Args: array of const;
  const ASessionID: Integer = 0); overload;
procedure LBDo(const Msg: string; const ASessionID: Integer = 0); overload; inline;
procedure LBDo(const MsgFmt: string; const Args: array of const;
  const ASessionID: Integer = 0); overload;
procedure LBC1(const Msg: string; const ASessionID: Integer = 0); overload; inline;
procedure LBC1(const MsgFmt: string; const Args: array of const;
  const ASessionID: Integer = 0); overload;
procedure LBC2(const Msg: string; const ASessionID: Integer = 0); overload; inline;
procedure LBC2(const MsgFmt: string; const Args: array of const;
  const ASessionID: Integer = 0); overload;

function GlobalLogBridge: TLogBridge;

implementation

uses
  System.SysUtils,
  MWQ.LogBridge.ConsoleLogger;
//  MWQ.LogBridge.Log4DAdapter,
//  MWQ.LogBridge.QuickLoggerAdapter;

function GlobalLogBridge: TLogBridge;
begin
  if LogBridge = nil then
  begin
    LogBridge := TLogBridge.Create;
  end;
  Result := LogBridge;
end;

function LogTypeFromEventType(const EventType: TEventType): TLogType;
begin
  Result := EventType;
end;

function IsLogLevelEnabled(const EventType: TEventType): Boolean;
begin
  Result := Assigned(LogBridge) and
    LogBridge.IsLevelEnabled(LogTypeFromEventType(EventType));
end;

function LogTypeMaskFromEventLevel(const Levels: TLogLevel): TLogTypeMask;
var
  Level: TLogType;
begin
  Result := 0;
  for Level := Low(TLogType) to High(TLogType) do
    if Level in Levels then
      Result := Result or LogTypeToMask(Level);
end;

procedure Log(const Msg: string);
begin
  GlobalLogBridge.Log(ltInfo, Msg);
end;

procedure Log(const Msg: string; const EventType: TEventType);
begin
  GlobalLogBridge.Log(LogTypeFromEventType(EventType), Msg);
end;

procedure Log(const MsgFmt: string; const Args: array of const;
  const EventType: TEventType);
begin
  GlobalLogBridge.Log(LogTypeFromEventType(EventType), MsgFmt, Args);
end;

{ TLogBridge }

procedure TLogBridge.ClearLogger;
begin
  if Assigned(FTargets) then
    FTargets.Clear;
end;

constructor TLogBridge.Create;
begin
  inherited;
  FEnableLog := True;
  FFileName := '';
  FOutputTypes := [loFile];
  FLogTypeMask := LOG_TYPE_MASK_ALL;
  FFactories := TCollections.CreateDictionary<TLoggerType, TLoggerFactoryFunc>();
  FTargets := TCollections.CreateDictionary<TLoggerType, ICommonLogger>();
  FSessionIDs := TCollections.CreateDictionary<Integer, TArray<TLoggerType>>(); // ✅ added ()
  FNextUserID := 1;
//  AddLogger(TConsoleLogger.Create);
end;

destructor TLogBridge.Destroy;
begin
  FFactories := nil;
  FTargets := nil;
  inherited;
end;

procedure TLogBridge.AddLogger(const Logger: ICommonLogger);
begin
  if Assigned(Logger) then
  begin
    FTargets[Logger.GetLoggerType] := Logger; // ✅ safer
    Logger.SetLogTypeMask(FLogTypeMask);
  end;
end;

procedure TLogBridge.Log(const Level: TLogType; const Msg: string);
begin
  Log(Level, Msg, 0);
end;

procedure TLogBridge.Log(const Level: TLogType; const MsgFmt: string; const Args: array of const);
begin
  Log(Level, MsgFmt, Args, 0);
end;

procedure TLogBridge.Log(const Level: TLogType; const MsgFmt: string;
  const Args: array of const; const ASessionID: Integer);
var
  SafeMsg: string;
begin
  if not IsLevelEnabled(Level) then
    Exit;

  try
    SafeMsg := Format(MsgFmt, Args);
  except
    on E: Exception do
      SafeMsg := MsgFmt + ' [Format error: ' + E.Message + ']';
  end;
  Log(Level, SafeMsg, ASessionID);
end;

function TLogBridge.LogTypeToStr(const Level: TLogType): string;
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

procedure TLogBridge.RegisterAdapter(const LoggerType: TLoggerType; const Factory: TLoggerFactoryFunc);
begin
  FFactories[LoggerType] := Factory;
end;

procedure TLogBridge.RemoveLogger(const Logger: ICommonLogger);
begin
  FTargets.Remove(Logger.GetLoggerType);
end;

procedure TLogBridge.UseConsoleOnly;
begin
  ClearLogger;
  AddLogger(TConsoleLogger.Create('ConsoleOnly'));
  FOutputTypes := [loConsole];
end;

procedure TLogBridge.UseDefaultLogger;
begin
  ClearLogger;
  AddLogger(TConsoleLogger.Create);
end;

function TLogBridge.UseLogger(const ALoggers: TArray<TLoggerType>): Integer;
begin
  Result := FNextUserID;
  Inc(FNextUserID);
  FSessionIDs[Result] := ALoggers; // ✅ safer

  for var L in ALoggers do
    GetOrCreateAdapter(L);
end;

function TLogBridge.GetOrCreateAdapter(const LoggerType: TLoggerType): ICommonLogger;
var
  Factory: TLoggerFactoryFunc;
begin
  if not FTargets.TryGetValue(LoggerType, Result) then
  begin
    if not FFactories.TryGetValue(LoggerType, Factory) then
      raise Exception.CreateFmt('Logger type %d not registered.', [Ord(LoggerType)]);
    Result := Factory();
    Result.SetEnable(FEnableLog);
    Result.SetOutputTypes(FOutputTypes);
    Result.SetLogTypeMask(FLogTypeMask);
    Result.SetLogFileName(FFileName);
    FTargets.Add(LoggerType, Result);
  end;
end;

function TLogBridge.GetOutputTypes: TLogOutputTypes;
begin
  Result := FOutputTypes;
end;

function TLogBridge.IsLevelEnabled(const Level: TLogType): Boolean;
begin
  Result := FEnableLog and
    ((FLogTypeMask and LogTypeToMask(Level)) <> 0);
end;

function TLogBridge.GetLogTypeMask: TLogTypeMask;
begin
  Result := FLogTypeMask;
end;

procedure TLogBridge.SetEnable(const AValue: Boolean);
var
  Logger: ICommonLogger;
begin
  TLogBridge.FEnableLog := AValue; // ✅ use class var directly
  for Logger in FTargets.Values do
    Logger.SetEnable(AValue);
end;

procedure TLogBridge.SetLogTypeMask(const AMask: TLogTypeMask);
var
  Logger: ICommonLogger;
begin
  FLogTypeMask := AMask;
  for Logger in FTargets.Values do
    Logger.SetLogTypeMask(AMask);
end;

procedure TLogBridge.SetLogFileName(const AFileName: string);
var
  Logger: ICommonLogger;
begin
  FFileName := AFileName;
  for Logger in FTargets.Values do
    Logger.SetLogFileName(AFileName);
end;

procedure TLogBridge.SetOutputTypes(const ATypes: TLogOutputTypes);
var
  Logger: ICommonLogger;
begin
  FOutputTypes := ATypes;
  for Logger in FTargets.Values do
    Logger.SetOutputTypes(ATypes);
end;

procedure TLogBridge.RotateLog;
var
  Logger: ICommonLogger;
begin
  for Logger in FTargets.Values do
    Logger.RotateLog;
end;

procedure TLogBridge.Log(const Level: TLogType; const Msg: string; const ASessionID: Integer);
var
  LoggerTypes: TArray<TLoggerType>;
  Logger: ICommonLogger;
  LType: TLoggerType;
begin
  if not IsLevelEnabled(Level) then
    Exit;

  if (ASessionID > 0) and FSessionIDs.TryGetValue(ASessionID, LoggerTypes) then
  begin
    for LType in LoggerTypes do
      if FTargets.TryGetValue(LType, Logger) then
        Logger.Log(Level, Msg);
  end
  else
  begin
    if FTargets.Count = 0 then
      Exit;

    for Logger in FTargets.Values do
      Logger.Log(Level, Msg);
  end;
end;

// === Helper procedures ===

procedure LBT(const Msg: string; const ASessionID: Integer = 0);
begin
  if TLogBridge.EnableLog and Assigned(LogBridge) then
    LogBridge.Log(ltTrace, Msg, ASessionID);
end;

procedure LBT(const MsgFmt: string; const Args: array of const;
  const ASessionID: Integer = 0);
begin
  if Assigned(LogBridge) then
    LogBridge.Log(ltTrace, MsgFmt, Args, ASessionID);
end;

procedure LBD(const Msg: string; const ASessionID: Integer = 0);
begin
  if TLogBridge.EnableLog and Assigned(LogBridge) then
    LogBridge.Log(ltDebug, Msg, ASessionID);
end;

procedure LBD(const MsgFmt: string; const Args: array of const;
  const ASessionID: Integer = 0);
begin
  if Assigned(LogBridge) then
    LogBridge.Log(ltDebug, MsgFmt, Args, ASessionID);
end;

procedure LBI(const Msg: string; const ASessionID: Integer = 0);
begin
  if TLogBridge.EnableLog and Assigned(LogBridge) then
    LogBridge.Log(ltInfo, Msg, ASessionID);
end;

procedure LBI(const MsgFmt: string; const Args: array of const;
  const ASessionID: Integer = 0);
begin
  if Assigned(LogBridge) then
    LogBridge.Log(ltInfo, MsgFmt, Args, ASessionID);
end;

procedure LBW(const Msg: string; const ASessionID: Integer = 0);
begin
  if TLogBridge.EnableLog and Assigned(LogBridge) then
    LogBridge.Log(ltWarn, Msg, ASessionID);
end;

procedure LBW(const MsgFmt: string; const Args: array of const;
  const ASessionID: Integer = 0);
begin
  if Assigned(LogBridge) then
    LogBridge.Log(ltWarn, MsgFmt, Args, ASessionID);
end;

procedure LBE(const Msg: string; const ASessionID: Integer = 0);
begin
  if TLogBridge.EnableLog and Assigned(LogBridge) then
    LogBridge.Log(ltError, Msg, ASessionID);
end;

procedure LBE(const MsgFmt: string; const Args: array of const;
  const ASessionID: Integer = 0);
begin
  if Assigned(LogBridge) then
    LogBridge.Log(ltError, MsgFmt, Args, ASessionID);
end;

procedure LBF(const Msg: string; const ASessionID: Integer = 0);
begin
  if TLogBridge.EnableLog and Assigned(LogBridge) then
    LogBridge.Log(ltFatal, Msg, ASessionID);
end;

procedure LBF(const MsgFmt: string; const Args: array of const;
  const ASessionID: Integer = 0);
begin
  if Assigned(LogBridge) then
    LogBridge.Log(ltFatal, MsgFmt, Args, ASessionID);
end;

procedure LBH(const Msg: string; const ASessionID: Integer = 0);
begin
  if TLogBridge.EnableLog and Assigned(LogBridge) then
    LogBridge.Log(ltHeader, Msg, ASessionID);
end;

procedure LBH(const MsgFmt: string; const Args: array of const;
  const ASessionID: Integer = 0);
begin
  if Assigned(LogBridge) then
    LogBridge.Log(ltHeader, MsgFmt, Args, ASessionID);
end;

procedure LBS(const Msg: string; const ASessionID: Integer = 0);
begin
  if TLogBridge.EnableLog and Assigned(LogBridge) then
    LogBridge.Log(ltSuccess, Msg, ASessionID);
end;

procedure LBS(const MsgFmt: string; const Args: array of const;
  const ASessionID: Integer = 0);
begin
  if Assigned(LogBridge) then
    LogBridge.Log(ltSuccess, MsgFmt, Args, ASessionID);
end;

procedure LBC(const Msg: string; const ASessionID: Integer = 0);
begin
  if TLogBridge.EnableLog and Assigned(LogBridge) then
    LogBridge.Log(ltCritical, Msg, ASessionID);
end;

procedure LBC(const MsgFmt: string; const Args: array of const;
  const ASessionID: Integer = 0);
begin
  if Assigned(LogBridge) then
    LogBridge.Log(ltCritical, MsgFmt, Args, ASessionID);
end;

procedure LBEx(const Msg: string; const ASessionID: Integer = 0);
begin
  if TLogBridge.EnableLog and Assigned(LogBridge) then
    LogBridge.Log(ltException, Msg, ASessionID);
end;

procedure LBEx(const MsgFmt: string; const Args: array of const;
  const ASessionID: Integer = 0);
begin
  if Assigned(LogBridge) then
    LogBridge.Log(ltException, MsgFmt, Args, ASessionID);
end;

procedure LBDo(const Msg: string; const ASessionID: Integer = 0);
begin
  if TLogBridge.EnableLog and Assigned(LogBridge) then
    LogBridge.Log(ltDone, Msg, ASessionID);
end;

procedure LBDo(const MsgFmt: string; const Args: array of const;
  const ASessionID: Integer = 0);
begin
  if Assigned(LogBridge) then
    LogBridge.Log(ltDone, MsgFmt, Args, ASessionID);
end;

procedure LBC1(const Msg: string; const ASessionID: Integer = 0);
begin
  if TLogBridge.EnableLog and Assigned(LogBridge) then
    LogBridge.Log(ltCustom1, Msg, ASessionID);
end;

procedure LBC1(const MsgFmt: string; const Args: array of const;
  const ASessionID: Integer = 0);
begin
  if Assigned(LogBridge) then
    LogBridge.Log(ltCustom1, MsgFmt, Args, ASessionID);
end;

procedure LBC2(const Msg: string; const ASessionID: Integer = 0);
begin
  if TLogBridge.EnableLog and Assigned(LogBridge) then
    LogBridge.Log(ltCustom2, Msg, ASessionID);
end;

procedure LBC2(const MsgFmt: string; const Args: array of const;
  const ASessionID: Integer = 0);
begin
  if Assigned(LogBridge) then
    LogBridge.Log(ltCustom2, MsgFmt, Args, ASessionID);
end;

initialization
  TLogBridge.EnableLog := True;
//  LogBridge := TLogBridge.Create;

finalization
  LogBridge.Free; // ✅ clean shutdown

end.

