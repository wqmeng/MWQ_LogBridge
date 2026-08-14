unit Test.MWQ.LogBridge.QuickLoggerAdapter;

interface

uses
  DUnitX.TestFramework,
  MWQ.LogBridge.ICommonLogger,
  MWQ.LogBridge.CommLoggerBase,
  MWQ.LogBridge.QuickLoggerAdapter,
  MWQ.LogBridge,
  System.SysUtils;

type
  TRecordingLogger = class(TCommLoggerBase)
  private
    FMessages: TArray<string>;
  protected
    function GetLoggerType: TLoggerType; override;
  public
    procedure Log(const Level: TLogType; const Msg: string); override;
    property Messages: TArray<string> read FMessages;
  end;

  [TestFixture]
  TQuickLoggerAdapterTests = class
  private
    FLogger: TRecordingLogger;
  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    [Test]
    procedure Should_Log_Info_When_Enabled;

    [Test]
    procedure Should_Not_Log_When_Disabled;

    [Test]
    procedure Should_Honor_OutputTypes;

    [Test]
    procedure Should_Create_Log_File;

    [Test]
    procedure Should_Filter_Disabled_Level;

    [Test]
    procedure Should_Skip_Format_When_Level_Disabled;
  end;

implementation

{ TQuickLoggerAdapterTests }

procedure TQuickLoggerAdapterTests.Setup;
begin
  FLogger := TRecordingLogger.Create;
  LogBridge.ClearLogger;
  LogBridge.AddLogger(FLogger);
  LogBridge.SetLogTypeMask(LOG_TYPE_MASK_ALL);
  LogBridge.SetEnable(True);
end;

procedure TQuickLoggerAdapterTests.TearDown;
begin
  LogBridge.ClearLogger;
  FLogger := nil;
end;

procedure TQuickLoggerAdapterTests.Should_Log_Info_When_Enabled;
begin
  LogBridge.SetEnable(True);
  LogBridge.Log(ltInfo, 'Test message for info log');

  Assert.AreEqual(1, Length(FLogger.Messages));
  Assert.AreEqual('Test message for info log', FLogger.Messages[0]);
end;

procedure TQuickLoggerAdapterTests.Should_Not_Log_When_Disabled;
begin
  LogBridge.SetEnable(False);
  LogBridge.Log(ltInfo, 'This message should not be logged');

  Assert.AreEqual(0, Length(FLogger.Messages));
end;

procedure TQuickLoggerAdapterTests.Should_Honor_OutputTypes;
begin
  LogBridge.SetEnable(True);
  LogBridge.Log(ltInfo, 'This should not be written');

  Assert.AreEqual(1, Length(FLogger.Messages));
end;

procedure TQuickLoggerAdapterTests.Should_Create_Log_File;
begin
  FLogger.SetOutputTypes([loFile]);
  Assert.IsTrue(loFile in FLogger.GetOutputTypes);
end;

procedure TQuickLoggerAdapterTests.Should_Filter_Disabled_Level;
begin
  LogBridge.SetEnable(True);
  LogBridge.SetLogTypeMask(LogTypeToMask(ltError));

  Assert.IsFalse(LogBridge.IsLevelEnabled(ltDebug));
  Assert.IsTrue(LogBridge.IsLevelEnabled(ltError));

  LogBridge.Log(ltDebug, 'Debug message should be filtered');
  LogBridge.Log(ltError, 'Error message should be accepted');

  Assert.AreEqual(1, Length(FLogger.Messages));
  Assert.AreEqual('Error message should be accepted', FLogger.Messages[0]);
end;

procedure TQuickLoggerAdapterTests.Should_Skip_Format_When_Level_Disabled;
begin
  LogBridge.SetEnable(True);
  LogBridge.SetLogTypeMask(LogTypeToMask(ltError));

  LogBridge.Log(ltDebug, '%d %d', [1]);

  Assert.AreEqual(0, Length(FLogger.Messages));
end;

function TRecordingLogger.GetLoggerType: TLoggerType;
begin
  Result := lgtCustom1;
end;

procedure TRecordingLogger.Log(const Level: TLogType; const Msg: string);
begin
  if IsLevelEnabled(Level) then
  begin
    SetLength(FMessages, Length(FMessages) + 1);
    FMessages[High(FMessages)] := Msg;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TQuickLoggerAdapterTests);

end.

