{ ******************************************************* }
{ }
{ 泛思微平台 }
{ }
{ 版权所有 (C) 2016 石家庄泛思电子商务有限公司 }
{ }
{ ******************************************************* }

unit uWxGlobal;

interface

/// <summary>
/// 获取适合微信使用的当前日期，以int64表示，是当前时间和1970-01-01 00:00:00之间的秒差
/// 然后再减去3600*8转成UTC时间秒差即为微信时间
/// </summary>
/// <returns>当前时间，int64格式</returns>
function GetWxNow: Int64;
/// <summary>
/// 获取适合微信使用的当前日期，以int64表示，是当前时间和1970-01-01 00:00:00之间的秒差
/// 然后再减去3600*8转成UTC时间秒差即为微信时间
/// </summary>
/// <returns>当前时间，int64字符串格式</returns>
function GetWxNowStr: string;

function ConvertWxDtToDateTime(wxDt: string): TDateTime;

implementation

uses
  System.SysUtils, System.DateUtils, System.Variants;

/// <summary>
/// 微信的日期时间都是int64类型，是和1970-01-01 00:00:00之间的秒差，这个函数用来返回1970-01-01 00:00:00时刻
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
