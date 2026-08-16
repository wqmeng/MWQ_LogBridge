unit MWQ.LogBridge.ICommonLogger;

interface

type
  TLoggerType = (lgtConsole, lgtQuickLogger, lgtLog4D, lgtCustom1, lgtCustom2, lgtCustom3);
  TLogType = (ltHeader, ltInfo, ltSuccess, ltWarn, ltError, ltCritical, ltException, ltDebug, ltTrace, ltDone, ltFatal, ltCustom1, ltCustom2);
  TLogTypeMask = Cardinal;
  TLogOutputType = (
    loFile,     // Log to file
    loMemory,   // In-memory logger
    loMail,     // Send via email
    loSyslog,   // Syslog or remote server
    loEventlog,   // Eventlog or remote server
    loConsole,  // Console
    loIDEDebug,   // IDE Debug
    loStringList,
    loCustom    // Custom (user-defined)
  );
  TLogOutputTypes = set of TLogOutputType;

const
  LOG_TYPE_MASK_ALL: TLogTypeMask = $00001FFF;

type
  ICommonLogger = interface
    ['{B44A2CD5-B6AC-4663-877E-ADA6C8790E14}']
    procedure Log(const Level: TLogType; const Msg: string); overload;
    procedure Log(const Level: TLogType; const MsgFmt: string; const Args: array of const); overload;
    function GetLoggerType: TLoggerType;
    function IsLevelEnabled(const Level: TLogType): Boolean;
    function GetLogTypeMask: TLogTypeMask;
    procedure SetLogTypeMask(const AMask: TLogTypeMask);

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

    procedure SetEnable(const AValue: Boolean);
    procedure SetOutputTypes(const ATypes: TLogOutputTypes);
    procedure SetLogFileName(const AFileName: string);  // <-- Add this
    procedure RotateLog;
  end;

  TLoggerFactoryFunc = reference to function: ICommonLogger;

function LogTypeToMask(const ALevel: TLogType): TLogTypeMask; inline;

implementation

function LogTypeToMask(const ALevel: TLogType): TLogTypeMask;
begin
  Result := TLogTypeMask(1) shl Ord(ALevel);
end;

end.
