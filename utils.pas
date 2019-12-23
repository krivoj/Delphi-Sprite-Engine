unit utils;

interface
uses classes,sysutils, windows,Math, Forms,  Dialogs,strutils;



procedure Delay(msecs: integer);
//function isCritical (Pg:integer): integer;
function IsStrANumber(const S: string): Boolean;
function perc(iperc , iValue : single): single;
function GetTsKeyname (value: string): string;
function MyFormat(value: integer): String;
function Getperc(iperc , iValue : single): single;
function ModifyPerc(iPerc,CurrentValue:single;reverse:boolean): single;

implementation
function ModifyPerc(iPerc,CurrentValue:single;reverse:boolean): single;
var
tmps:string;
begin
    if not reverse then begin
      CurrentValue  := CurrentValue +  (CurrentValue * (  iPerc  / 100)) ;
    end
    else begin
     tmps:= '1.' + FloatToStr(  abs(iPerc) );
     if iPerc <= 0 then CurrentValue  := (CurrentValue /  StrToFloat(tmps) ) else
      begin
        CurrentValue:= (CurrentValue * 100 )  /   (100 - abs(iPerc)); // 79
      end;
    end;
  result:= RoundTo(CurrentValue,-2);
//---------------------
 //           tmps:= '1.' + FloatToStr(  abs(  iPerc   ) );
 //           CurrentValue  := (CurrentValue /  StrToFloat(tmps) ) ;
 // result:= CurrentValue;

end;

function Getperc(iperc , iValue : single): single;
var
tmps:string;
begin
                   //tmps:= '1.' + FloatToStr(  abs(iperc) );
                   //result  := (ivalue *  StrToFloat(tmps) ) ;

//result:= (ivalue * iperc) / 100;
result:= (iperc * 100) / ivalue;
end;
function MyFormat(value: integer): String;
var
tmp: string;
begin
 tmp:= IntToStr(value);
 if length(tmp) = 1 then Result:= '0'+ tmp else Result:= tmp;


end;

function GetTsKeyname (value: string): string;
var
x:integer;
begin
  // collina=1d4
  x:= pos(value,'=',-1);
  result:= LeftStr(value,x-1);
end;

function perc(iperc , iValue : single): single;
begin
result:= (ivalue * iperc) / 100;
end;
procedure Delay(msecs: integer);
var
  FirstTickCount: longint;
begin
  FirstTickCount := GetTickCount;
   repeat
     Application.ProcessMessages;
   until ((GetTickCount-FirstTickCount) >= Longint(msecs));
end;
{function isCritical (Pg:integer): integer;
var
tmp, chance: integer;
begin
Result:=0;

    Chance := BASE_CRIT + StrToInt(DProcess.AdvAll.Cells[11,pg]);
//    Tmp := DProcess.dogenerate(100);
    If Tmp <= Chance then result:= 1;

end;   }

function IsStrANumber(const S: string): Boolean;
begin
  Result := True;
  try
    StrToInt(S);
  except
    Result := False;
  end;
end;


end.
