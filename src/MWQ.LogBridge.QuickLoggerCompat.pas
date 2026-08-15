unit MWQ.LogBridge.QuickLoggerCompat;

interface

uses
  MWQ.LogBridge.ICommonLogger,
  Quick.Logger;

type
  TEventType = Quick.Logger.TEventType;
  TLogLevel = Quick.Logger.TLogLevel;

const
  etHeader = Quick.Logger.etHeader;
  etInfo = Quick.Logger.etInfo;
  etSuccess = Quick.Logger.etSuccess;
  etWarning = Quick.Logger.etWarning;
  etError = Quick.Logger.etError;
  etCritical = Quick.Logger.etCritical;
  etException = Quick.Logger.etException;
  etDebug = Quick.Logger.etDebug;
  etTrace = Quick.Logger.etTrace;
  etDone = Quick.Logger.etDone;
  etCustom1 = Quick.Logger.etCustom1;
  etCustom2 = Quick.Logger.etCustom2;

  LOG_ONLYERRORS = [etHeader, etInfo, etError, etCritical, etException];
  LOG_ERRORSANDWARNINGS = [etHeader, etInfo, etWarning, etError, etCritical, etException];
  LOG_BASIC = [etInfo, etSuccess, etWarning, etError, etCritical, etException];
  LOG_ALL = [etHeader, etInfo, etSuccess, etDone, etWarning, etError, etCritical,
    etException, etCustom1, etCustom2];
  LOG_TRACE = [etHeader, etInfo, etSuccess, etDone, etWarning, etError, etCritical,
    etException, etTrace];
  LOG_DEBUG = [etHeader, etInfo, etSuccess, etDone, etWarning, etError, etCritical,
    etException, etTrace, etDebug];
  LOG_VERBOSE: TLogLevel = [Low(TEventType)..High(TEventType)];

function LogTypeFromEventType(const EventType: TEventType): TLogType;
function IsLogLevelEnabled(const EventType: TEventType): Boolean; inline;
function LogTypeMaskFromEventLevel(const Levels: TLogLevel): TLogTypeMask;

procedure Log(const Msg: string); overload;
procedure Log(const Msg: string; const EventType: TEventType); overload;
procedure Log(const MsgFmt: string; const Args: array of const;
  const EventType: TEventType); overload;

implementation

uses
  MWQ.LogBridge,
  MWQ.LogBridge.QuickLoggerAdapter;

function LogTypeFromEventType(const EventType: TEventType): TLogType;
begin
  case EventType of
    etHeader:    Result := ltHeader;
    etInfo:      Result := ltInfo;
    etSuccess:   Result := ltSuccess;
    etWarning:   Result := ltWarn;
    etError:     Result := ltError;
    etCritical:  Result := ltCritical;
    etException: Result := ltException;
    etDebug:     Result := ltDebug;
    etTrace:     Result := ltTrace;
    etDone:      Result := ltDone;
    etCustom1:   Result := ltCustom1;
    etCustom2:   Result := ltCustom2;
  else
    Result := ltInfo;
  end;
end;

function IsLogLevelEnabled(const EventType: TEventType): Boolean;
begin
  Result := Assigned(LogBridge) and
    LogBridge.IsLevelEnabled(LogTypeFromEventType(EventType));
end;

function LogTypeMaskFromEventLevel(const Levels: TLogLevel): TLogTypeMask;
var
  EventType: TEventType;
begin
  Result := 0;
  for EventType := Low(TEventType) to High(TEventType) do
    if EventType in Levels then
      Result := Result or LogTypeToMask(LogTypeFromEventType(EventType));
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

initialization
  GlobalLogBridge.UseLogger([lgtQuickLogger]);

end.
