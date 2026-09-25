unit MWQ.LogBridge.LockDiagnostics;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.SyncObjs,
  System.SysUtils;

type
  TLockDiagnosticToken = record
    LockAddress: Pointer;
    OperationId: TGUID;
    StartTick: UInt64;
    AcquiredTick: UInt64;
    Kind: Integer;
    Mode: Integer;
  end;

  TLockDiagnostics = class sealed
  public
    class procedure TraceBegin(const ALock: Pointer; const AKind, AMode: Integer;
      const ASite: string; out AToken: TLockDiagnosticToken); static;
    class procedure TraceAcquired(var AToken: TLockDiagnosticToken; const ASite: string); static;
    class procedure TraceBeginRelease(const ALock: Pointer; const AKind, AMode: Integer;
      const ASite: string; out AToken: TLockDiagnosticToken); static;
    class procedure TraceReleased(const AToken: TLockDiagnosticToken; const ASite: string); static;
    class procedure MonitorEnter(const AObject: TObject; const ASite: string = ''); static;
    class procedure MonitorExit(const AObject: TObject; const ASite: string = ''); static;
    class function MonitorTryEnter(const AObject: TObject; const ATimeout: Cardinal;
      const ASite: string = ''): Boolean; static;
    class procedure CriticalSectionEnter(const ALock: TCriticalSection; const ASite: string = ''); static;
    class procedure CriticalSectionExit(const ALock: TCriticalSection; const ASite: string = ''); static;
    class procedure CriticalSectionTryEnterBegin(const ALock: TCriticalSection;
      const ASite: string; out AToken: TLockDiagnosticToken); static;
    class function CriticalSectionTryEnter(const ALock: TCriticalSection;
      const ASite: string = ''): Boolean; overload; static;
    class function CriticalSectionTryEnter(const ALock: TCriticalSection;
      const ASite: string; var AToken: TLockDiagnosticToken): Boolean; overload; static;
    class procedure CriticalSectionTryEnterTimeout(const AToken: TLockDiagnosticToken;
      const ASite: string); static;
    class procedure MultiReadBeginRead(const ALock: TMultiReadExclusiveWriteSynchronizer;
      const ASite: string = ''); static;
    class procedure MultiReadEndRead(const ALock: TMultiReadExclusiveWriteSynchronizer;
      const ASite: string = ''); static;
    class procedure MultiReadBeginWrite(const ALock: TMultiReadExclusiveWriteSynchronizer;
      const ASite: string = ''); static;
    class procedure MultiReadEndWrite(const ALock: TMultiReadExclusiveWriteSynchronizer;
      const ASite: string = ''); static;
    class procedure LightweightBeginRead(var ALock: TLightweightMREW; const ASite: string = '';
      const AIdentity: Pointer = nil); static;
    class procedure LightweightEndRead(var ALock: TLightweightMREW; const ASite: string = '';
      const AIdentity: Pointer = nil); static;
    class procedure LightweightBeginWrite(var ALock: TLightweightMREW; const ASite: string = '';
      const AIdentity: Pointer = nil); static;
    class procedure LightweightEndWrite(var ALock: TLightweightMREW; const ASite: string = '';
      const AIdentity: Pointer = nil); static;
    class function LightweightTryBeginRead(var ALock: TLightweightMREW;
      const ASite: string = ''; const AIdentity: Pointer = nil): Boolean; static;
    class function LightweightTryBeginWrite(var ALock: TLightweightMREW;
      const ASite: string = ''; const AIdentity: Pointer = nil): Boolean; static;
    class function ThreadListLock<T>(const AList: TThreadList<T>;
      const ASite: string = ''): TList<T>; static;
    class procedure ThreadListUnlock<T>(const AList: TThreadList<T>;
      const ASite: string = ''); static;
  end;

implementation

uses
  MWQ.LogBridge;

type
  TLockTraceKind = (ltkMonitor, ltkCriticalSection, ltkMultiRead, ltkLightweight, ltkThreadList);
  TLockTraceMode = (ltmExclusive, ltmRead, ltmWrite);
  TLockTraceEntry = record
    LockAddress: Pointer;
    OperationId: TGUID;
    AcquiredTick: UInt64;
    Kind: TLockTraceKind;
    Mode: TLockTraceMode;
  end;

const
  LOCK_TRACE_MAX_DEPTH = 1023;

threadvar
  GLockTraceDepth: Integer;
  GLockTraceStack: array[0..LOCK_TRACE_MAX_DEPTH] of TLockTraceEntry;

function LockKindToText(const AKind: TLockTraceKind): string;
begin
  case AKind of
    ltkMonitor: Result := 'Monitor';
    ltkCriticalSection: Result := 'CriticalSection';
    ltkMultiRead: Result := 'MultiRead';
    ltkLightweight: Result := 'LightweightMREW';
    ltkThreadList: Result := 'ThreadList';
  else
    Result := 'Unknown';
  end;
end;

function LockModeToText(const AMode: TLockTraceMode): string;
begin
  case AMode of
    ltmRead: Result := 'Read';
    ltmWrite: Result := 'Write';
  else
    Result := 'Exclusive';
  end;
end;

function NewOperationId: TGUID;
begin
  if CreateGUID(Result) <> 0 then
    Result := TGUID.Empty;
end;

procedure LockTraceLog(const AEvent: string; const AEntry: TLockTraceEntry;
    const ASite: string; const AElapsedMs: UInt64; const AHasElapsed: Boolean);
var
  LMessage: string;
begin
  try
    LMessage := Format(
        'LOCK %s Op=%s Kind=%s Mode=%s Lock=%p Thread=%d Site=%s',
        [AEvent, GUIDToString(AEntry.OperationId), LockKindToText(AEntry.Kind),
         LockModeToText(AEntry.Mode), AEntry.LockAddress, TThread.CurrentThread.ThreadID, ASite]
    );
    if AHasElapsed then
      LMessage := LMessage + Format(' ElapsedMs=%d', [AElapsedMs]);
    Log(LMessage, etInfo);
  except
    // Diagnostic logging must not alter the original lock behavior.
  end;
end;

procedure LockTraceWait(const ALockAddress: Pointer; const AKind: TLockTraceKind;
    const AMode: TLockTraceMode; const ASite: string; out AEntry: TLockTraceEntry;
    out AStartTick: UInt64);
begin
  AEntry.LockAddress := ALockAddress;
  AEntry.OperationId := NewOperationId;
  AEntry.Kind := AKind;
  AEntry.Mode := AMode;
  AStartTick := TThread.GetTickCount64;
  LockTraceLog('WAIT', AEntry, ASite, 0, False);
end;

procedure LockTraceAcquired(const AEntry: TLockTraceEntry; const AStartTick: UInt64;
    const ASite: string);
var
  LEntry: TLockTraceEntry;
begin
  LEntry := AEntry;
  LEntry.AcquiredTick := TThread.GetTickCount64;
  if GLockTraceDepth <= LOCK_TRACE_MAX_DEPTH then begin
    GLockTraceStack[GLockTraceDepth] := LEntry;
    Inc(GLockTraceDepth);
  end
  else
    LockTraceLog('TRACKING_OVERFLOW', LEntry, ASite, 0, False);
  LockTraceLog('ACQUIRED', LEntry, ASite, LEntry.AcquiredTick - AStartTick, True);
end;

function LockTraceBeginRelease(const ALockAddress: Pointer; const AKind: TLockTraceKind;
    const AMode: TLockTraceMode; const ASite: string): TLockTraceEntry;
var
  I, J: Integer;
begin
  Result.LockAddress := ALockAddress;
  Result.OperationId := NewOperationId;
  Result.AcquiredTick := 0;
  Result.Kind := AKind;
  Result.Mode := AMode;
  for I := GLockTraceDepth - 1 downto 0 do
    if (GLockTraceStack[I].LockAddress = ALockAddress)
        and (GLockTraceStack[I].Kind = AKind)
        and (GLockTraceStack[I].Mode = AMode) then begin
      Result := GLockTraceStack[I];
      for J := I to GLockTraceDepth - 2 do
        GLockTraceStack[J] := GLockTraceStack[J + 1];
      Dec(GLockTraceDepth);
      Break;
    end;
  LockTraceLog('RELEASING', Result, ASite, TThread.GetTickCount64 - Result.AcquiredTick,
    Result.AcquiredTick <> 0);
end;

procedure LockTraceReleased(const AEntry: TLockTraceEntry; const ASite: string);
begin
  LockTraceLog('RELEASED', AEntry, ASite, 0, False);
end;

class procedure TLockDiagnostics.MonitorEnter(const AObject: TObject; const ASite: string);
var
  LEntry: TLockTraceEntry;
  LStartTick: UInt64;
begin
  LockTraceWait(Pointer(AObject), ltkMonitor, ltmExclusive, ASite, LEntry, LStartTick);
  TMonitor.Enter(AObject);
  LockTraceAcquired(LEntry, LStartTick, ASite);
end;

class procedure TLockDiagnostics.MonitorExit(const AObject: TObject; const ASite: string);
var
  LEntry: TLockTraceEntry;
begin
  LEntry := LockTraceBeginRelease(Pointer(AObject), ltkMonitor, ltmExclusive, ASite);
  TMonitor.Exit(AObject);
  LockTraceReleased(LEntry, ASite);
end;

class procedure TLockDiagnostics.TraceBegin(const ALock: Pointer; const AKind, AMode: Integer;
    const ASite: string; out AToken: TLockDiagnosticToken);
var
  LEntry: TLockTraceEntry;
begin
  LockTraceWait(ALock, TLockTraceKind(AKind), TLockTraceMode(AMode), ASite, LEntry,
      AToken.StartTick);
  AToken.LockAddress := LEntry.LockAddress;
  AToken.OperationId := LEntry.OperationId;
  AToken.Kind := Ord(LEntry.Kind);
  AToken.Mode := Ord(LEntry.Mode);
  AToken.AcquiredTick := 0;
end;

class procedure TLockDiagnostics.TraceAcquired(var AToken: TLockDiagnosticToken;
    const ASite: string);
var
  LEntry: TLockTraceEntry;
begin
  LEntry.LockAddress := AToken.LockAddress;
  LEntry.OperationId := AToken.OperationId;
  LEntry.Kind := TLockTraceKind(AToken.Kind);
  LEntry.Mode := TLockTraceMode(AToken.Mode);
  LEntry.AcquiredTick := 0;
  LockTraceAcquired(LEntry, AToken.StartTick, ASite);
  AToken.AcquiredTick := TThread.GetTickCount64;
end;

class procedure TLockDiagnostics.TraceBeginRelease(const ALock: Pointer;
    const AKind, AMode: Integer; const ASite: string; out AToken: TLockDiagnosticToken);
var
  LEntry: TLockTraceEntry;
begin
  LEntry := LockTraceBeginRelease(ALock, TLockTraceKind(AKind), TLockTraceMode(AMode), ASite);
  AToken.LockAddress := LEntry.LockAddress;
  AToken.OperationId := LEntry.OperationId;
  AToken.AcquiredTick := LEntry.AcquiredTick;
  AToken.Kind := Ord(LEntry.Kind);
  AToken.Mode := Ord(LEntry.Mode);
  AToken.StartTick := 0;
end;

class procedure TLockDiagnostics.TraceReleased(const AToken: TLockDiagnosticToken;
    const ASite: string);
var
  LEntry: TLockTraceEntry;
begin
  LEntry.LockAddress := AToken.LockAddress;
  LEntry.OperationId := AToken.OperationId;
  LEntry.AcquiredTick := AToken.AcquiredTick;
  LEntry.Kind := TLockTraceKind(AToken.Kind);
  LEntry.Mode := TLockTraceMode(AToken.Mode);
  LockTraceReleased(LEntry, ASite);
end;

class function TLockDiagnostics.MonitorTryEnter(const AObject: TObject; const ATimeout: Cardinal;
    const ASite: string): Boolean;
var
  LEntry: TLockTraceEntry;
  LStartTick: UInt64;
begin
  LockTraceWait(Pointer(AObject), ltkMonitor, ltmExclusive, ASite, LEntry, LStartTick);
  Result := TMonitor.Enter(AObject, ATimeout);
  if Result then
    LockTraceAcquired(LEntry, LStartTick, ASite)
  else
    LockTraceLog('TIMEOUT', LEntry, ASite, TThread.GetTickCount64 - LStartTick, True);
end;

class procedure TLockDiagnostics.CriticalSectionEnter(const ALock: TCriticalSection; const ASite: string);
var
  LEntry: TLockTraceEntry;
  LStartTick: UInt64;
begin
  LockTraceWait(Pointer(ALock), ltkCriticalSection, ltmExclusive, ASite, LEntry, LStartTick);
  ALock.Enter;
  LockTraceAcquired(LEntry, LStartTick, ASite);
end;

class procedure TLockDiagnostics.CriticalSectionExit(const ALock: TCriticalSection; const ASite: string);
var
  LEntry: TLockTraceEntry;
begin
  LEntry := LockTraceBeginRelease(Pointer(ALock), ltkCriticalSection, ltmExclusive, ASite);
  ALock.Leave;
  LockTraceReleased(LEntry, ASite);
end;

class function TLockDiagnostics.CriticalSectionTryEnter(const ALock: TCriticalSection;
    const ASite: string): Boolean;
var
  LEntry: TLockTraceEntry;
  LStartTick: UInt64;
begin
  LockTraceWait(Pointer(ALock), ltkCriticalSection, ltmExclusive, ASite, LEntry, LStartTick);
  Result := ALock.TryEnter;
  if Result then
    LockTraceAcquired(LEntry, LStartTick, ASite)
  else
    LockTraceLog('TIMEOUT', LEntry, ASite, TThread.GetTickCount64 - LStartTick, True);
end;

class procedure TLockDiagnostics.CriticalSectionTryEnterBegin(const ALock: TCriticalSection;
    const ASite: string; out AToken: TLockDiagnosticToken);
begin
  TraceBegin(Pointer(ALock), Ord(ltkCriticalSection), Ord(ltmExclusive), ASite, AToken);
end;

class function TLockDiagnostics.CriticalSectionTryEnter(const ALock: TCriticalSection;
    const ASite: string; var AToken: TLockDiagnosticToken): Boolean;
begin
  Result := ALock.TryEnter;
  if Result then
    TraceAcquired(AToken, ASite);
end;

class procedure TLockDiagnostics.CriticalSectionTryEnterTimeout(
    const AToken: TLockDiagnosticToken; const ASite: string);
var
  LEntry: TLockTraceEntry;
begin
  LEntry.LockAddress := AToken.LockAddress;
  LEntry.OperationId := AToken.OperationId;
  LEntry.AcquiredTick := 0;
  LEntry.Kind := TLockTraceKind(AToken.Kind);
  LEntry.Mode := TLockTraceMode(AToken.Mode);
  LockTraceLog('TIMEOUT', LEntry, ASite, TThread.GetTickCount64 - AToken.StartTick, True);
end;

class procedure TLockDiagnostics.MultiReadBeginRead(const ALock: TMultiReadExclusiveWriteSynchronizer;
    const ASite: string);
var
  LEntry: TLockTraceEntry;
  LStartTick: UInt64;
begin
  LockTraceWait(Pointer(ALock), ltkMultiRead, ltmRead, ASite, LEntry, LStartTick);
  ALock.BeginRead;
  LockTraceAcquired(LEntry, LStartTick, ASite);
end;

class procedure TLockDiagnostics.MultiReadEndRead(const ALock: TMultiReadExclusiveWriteSynchronizer;
    const ASite: string);
var
  LEntry: TLockTraceEntry;
begin
  LEntry := LockTraceBeginRelease(Pointer(ALock), ltkMultiRead, ltmRead, ASite);
  ALock.EndRead;
  LockTraceReleased(LEntry, ASite);
end;

class procedure TLockDiagnostics.MultiReadBeginWrite(const ALock: TMultiReadExclusiveWriteSynchronizer;
    const ASite: string);
var
  LEntry: TLockTraceEntry;
  LStartTick: UInt64;
begin
  LockTraceWait(Pointer(ALock), ltkMultiRead, ltmWrite, ASite, LEntry, LStartTick);
  ALock.BeginWrite;
  LockTraceAcquired(LEntry, LStartTick, ASite);
end;

class procedure TLockDiagnostics.MultiReadEndWrite(const ALock: TMultiReadExclusiveWriteSynchronizer;
    const ASite: string);
var
  LEntry: TLockTraceEntry;
begin
  LEntry := LockTraceBeginRelease(Pointer(ALock), ltkMultiRead, ltmWrite, ASite);
  ALock.EndWrite;
  LockTraceReleased(LEntry, ASite);
end;

class procedure TLockDiagnostics.LightweightBeginRead(var ALock: TLightweightMREW; const ASite: string;
    const AIdentity: Pointer);
var
  LEntry: TLockTraceEntry;
  LStartTick: UInt64;
begin
  if AIdentity <> nil then
    LockTraceWait(AIdentity, ltkLightweight, ltmRead, ASite, LEntry, LStartTick)
  else
    LockTraceWait(Pointer(@ALock), ltkLightweight, ltmRead, ASite, LEntry, LStartTick);
  ALock.BeginRead;
  LockTraceAcquired(LEntry, LStartTick, ASite);
end;

class procedure TLockDiagnostics.LightweightEndRead(var ALock: TLightweightMREW; const ASite: string;
    const AIdentity: Pointer);
var
  LEntry: TLockTraceEntry;
begin
  if AIdentity <> nil then
    LEntry := LockTraceBeginRelease(AIdentity, ltkLightweight, ltmRead, ASite)
  else
    LEntry := LockTraceBeginRelease(Pointer(@ALock), ltkLightweight, ltmRead, ASite);
  ALock.EndRead;
  LockTraceReleased(LEntry, ASite);
end;

class procedure TLockDiagnostics.LightweightBeginWrite(var ALock: TLightweightMREW; const ASite: string;
    const AIdentity: Pointer);
var
  LEntry: TLockTraceEntry;
  LStartTick: UInt64;
begin
  if AIdentity <> nil then
    LockTraceWait(AIdentity, ltkLightweight, ltmWrite, ASite, LEntry, LStartTick)
  else
    LockTraceWait(Pointer(@ALock), ltkLightweight, ltmWrite, ASite, LEntry, LStartTick);
  ALock.BeginWrite;
  LockTraceAcquired(LEntry, LStartTick, ASite);
end;

class procedure TLockDiagnostics.LightweightEndWrite(var ALock: TLightweightMREW; const ASite: string;
    const AIdentity: Pointer);
var
  LEntry: TLockTraceEntry;
begin
  if AIdentity <> nil then
    LEntry := LockTraceBeginRelease(AIdentity, ltkLightweight, ltmWrite, ASite)
  else
    LEntry := LockTraceBeginRelease(Pointer(@ALock), ltkLightweight, ltmWrite, ASite);
  ALock.EndWrite;
  LockTraceReleased(LEntry, ASite);
end;

class function TLockDiagnostics.LightweightTryBeginRead(var ALock: TLightweightMREW;
    const ASite: string; const AIdentity: Pointer): Boolean;
var
  LEntry: TLockTraceEntry;
  LStartTick: UInt64;
  LLockAddress: Pointer;
begin
  LLockAddress := AIdentity;
  if LLockAddress = nil then
    LLockAddress := Pointer(@ALock);
  LockTraceWait(LLockAddress, ltkLightweight, ltmRead, ASite, LEntry, LStartTick);
  Result := ALock.TryBeginRead;
  if Result then
    LockTraceAcquired(LEntry, LStartTick, ASite)
  else
    LockTraceLog('TIMEOUT', LEntry, ASite, TThread.GetTickCount64 - LStartTick, True);
end;

class function TLockDiagnostics.LightweightTryBeginWrite(var ALock: TLightweightMREW;
    const ASite: string; const AIdentity: Pointer): Boolean;
var
  LEntry: TLockTraceEntry;
  LStartTick: UInt64;
  LLockAddress: Pointer;
begin
  LLockAddress := AIdentity;
  if LLockAddress = nil then
    LLockAddress := Pointer(@ALock);
  LockTraceWait(LLockAddress, ltkLightweight, ltmWrite, ASite, LEntry, LStartTick);
  Result := ALock.TryBeginWrite;
  if Result then
    LockTraceAcquired(LEntry, LStartTick, ASite)
  else
    LockTraceLog('TIMEOUT', LEntry, ASite, TThread.GetTickCount64 - LStartTick, True);
end;

class function TLockDiagnostics.ThreadListLock<T>(const AList: TThreadList<T>;
    const ASite: string): TList<T>;
var
  LToken: TLockDiagnosticToken;
begin
  TLockDiagnostics.TraceBegin(Pointer(AList), Ord(ltkThreadList), Ord(ltmExclusive), ASite, LToken);
  Result := AList.LockList;
  TLockDiagnostics.TraceAcquired(LToken, ASite);
end;

class procedure TLockDiagnostics.ThreadListUnlock<T>(const AList: TThreadList<T>;
    const ASite: string);
var
  LToken: TLockDiagnosticToken;
begin
  TLockDiagnostics.TraceBeginRelease(Pointer(AList), Ord(ltkThreadList), Ord(ltmExclusive),
      ASite, LToken);
  AList.UnlockList;
  TLockDiagnostics.TraceReleased(LToken, ASite);
end;

end.
