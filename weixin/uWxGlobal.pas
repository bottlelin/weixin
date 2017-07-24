{ ******************************************************* }
{ }
{ ��˼΢ƽ̨ }
{ }
{ ��Ȩ���� (C) 2016 ʯ��ׯ��˼�����������޹�˾ }
{ }
{ ******************************************************* }

unit uWxGlobal;

interface

/// <summary>
/// ��ȡ�ʺ�΢��ʹ�õĵ�ǰ���ڣ���int64��ʾ���ǵ�ǰʱ���1970-01-01 00:00:00֮������
/// Ȼ���ټ�ȥ3600*8ת��UTCʱ����Ϊ΢��ʱ��
/// </summary>
/// <returns>��ǰʱ�䣬int64��ʽ</returns>
function GetWxNow: Int64;
/// <summary>
/// ��ȡ�ʺ�΢��ʹ�õĵ�ǰ���ڣ���int64��ʾ���ǵ�ǰʱ���1970-01-01 00:00:00֮������
/// Ȼ���ټ�ȥ3600*8ת��UTCʱ����Ϊ΢��ʱ��
/// </summary>
/// <returns>��ǰʱ�䣬int64�ַ�����ʽ</returns>
function GetWxNowStr: string;

function ConvertWxDtToDateTime(wxDt: string): TDateTime;

implementation

uses
  System.SysUtils, System.DateUtils, System.Variants;

/// <summary>
/// ΢�ŵ�����ʱ�䶼��int64���ͣ��Ǻ�1970-01-01 00:00:00֮��������������������1970-01-01 00:00:00ʱ��
/// </summary>
/// <returns>1970-01-01 00:00:00</returns>
function GetWxBaseDt: TDateTime;
begin
  Result := VarToDateTime('1970-01-01 00:00:00');
end;

function GetWxNow: Int64;
begin
  Result := SecondsBetween(Now, GetWxBaseDt) - 3600 * 8;
end;

function GetWxNowStr: string; overload;
var
  i64: Int64;
begin
  i64 := GetWxNow;
  Result := IntToStr(i64);
end;

function ConvertWxDtToDateTime(wxDt: string): TDateTime;
var
  i64: Int64;
begin
  i64 := StrToInt64(wxDt);
  Result := IncSecond(GetWxBaseDt, i64 + 3600 * 8);
end;

end.
