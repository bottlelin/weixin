{ ***************************************************************************** }
{ }
{ 泛思微平台 }
{ }
{ 版权所有 (C) 2016 石家庄泛思电子商务有限公司 }
{ }
{ 微信消息加密解密单元，使用DelphiXE2版本编写 }
{ 作者：Delphi力量 }
{ QQ：404328970 }
{ EMail: heblxy@163.com }
{ Blog：www.cnblogs.com/dpower }
{ 参考链接： }
{ http://mp.weixin.qq.com/wiki/14/70e73cedf9fd958d2e23264ba9333ad2.html }
{ }
{ ***************************************************************************** }

unit uWxMsgCrypt;

interface

uses
  System.Classes, System.SysUtils;

const
  RandCodeArr: array [0 .. 41] of Char = ('2', '3', '4', '5', '6', '7', 'a',
    'c', 'd', 'e', 'f', 'h', 'i', 'j', 'k', 'm', 'n', 'p', 'r', 's', 't', 'A',
    'C', 'D', 'E', 'F', 'G', 'H', 'J', 'K', 'M', 'N', 'P', 'Q', 'R', 'S', 'U',
    'V', 'W', 'X', 'Y', 'Z');
  AesBlockSize: Integer = 32;

type
  WXBizMsgCryptErrorCode = (WXBizMsgCrypt_OK = 0,
    WXBizMsgCrypt_ValidateSignature_Error = -40001,
    WXBizMsgCrypt_ParseXml_Error = -40002, // 未使用
    WXBizMsgCrypt_ComputeSignature_Error = -40003,
    WXBizMsgCrypt_IllegalAesKey = -40004,
    WXBizMsgCrypt_ValidateAppid_Error = -40005,
    WXBizMsgCrypt_EncryptAES_Error = -40006,
    WXBizMsgCrypt_DecryptAES_Error = -40007,
    WXBizMsgCrypt_IllegalBuffer = -40008, // 未使用
    WXBizMsgCrypt_EncodeBase64_Error = -40009, // 未使用
    WXBizMsgCrypt_DecodeBase64_Error = -40010);

  /// <summary>
  /// 提供微信加密消息解密和微信明文消息加密功能
  /// </summary>
  TWxMsgCrypt = class
  private
    function CreateRandCode(codeLen: Integer): string;
    function AES_decrypt(const sEncodingAESKey, sMsgEncrypt: string;
      var cpid: string): string;
    function AES_encrypt(const sEncodingAESKey, sMsg, cpid: string): string;
  public
    /// <summary>
    /// 解密微信消息
    /// </summary>
    /// <param name="sToken">Token，看公众号设置</param>
    /// <param name="sTimeStamp">时间戳，随微信消息一起传入，可以通过Url参数获取</param>
    /// <param name="sNonce">随机字符串，随微信消息一起传入，可以通过Url参数获取</param>
    /// <param name="sMsgEncrypt">微信消息xml的Encrypt字段内容</param>
    /// <param name="sSigture">签名，随微信消息一起传入，可以通过Url参数获取</param>
    /// <param name="sAppID">AppID，看公众号设置</param>
    /// <param name="sEncodingAESKey">EncodingAESKey，看公众号设置</param>
    /// <param name="sMsg">sMsg: 解密后的Encrypt字段内容原文，当return返回WXBizMsgCrypt_OK时有效</param>
    /// <returns>成功WXBizMsgCrypt_OK，失败返回对应的错误码</returns>
    function DecryptMsg(const sToken, sTimeStamp, sNonce, sMsgEncrypt, sSigture,
      sAppID, sEncodingAESKey: string; var sMsg: string)
      : WXBizMsgCryptErrorCode;

    /// <summary>
    /// 加密微信消息
    /// </summary>
    /// <param name="sMsg">全部xml内容（明文）</param>
    /// <param name="sAppID">AppID，看公众号设置</param>
    /// <param name="sEncodingAESKey">EncodingAESKey，看公众号设置</param>
    /// <param name="sMsgEncrypt">sMsgEncrypt: 输出的是加密后的全部xml（可以直接发送无需再编组xml），当return返回WXBizMsgCrypt_OK时有效</param>
    /// <returns>成功WXBizMsgCrypt_OK，失败返回对应的错误码</returns>
    function EncryptMsg(const sMsg, sToken, sAppID, sEncodingAESKey: string;
      var sMsgEncrypt: string): WXBizMsgCryptErrorCode;
  end;

implementation

uses
  CnSHA1, EncdDecd, CnAES, System.Math, uWxGlobal;

{ TWxMsgCrypt }

function TWxMsgCrypt.AES_decrypt(const sEncodingAESKey, sMsgEncrypt: string;
  var cpid: string): string;
var
  aEncodingAESKeyStr, sInput: AnsiString;
  aEncodingAESKeyBts, IvBts, InputBts: TBytes;
  InputStream, DecodeStream: TMemoryStream;
  AesKey: TAESKey256;
  Iv: TAESBuffer;
  P: PByteArray;
  iLen, iDecodeDataLen: Integer;
  bMsg, bAppid: TBytes;

  function GetRealDataLenWithoutKCS7Bytes: Integer;
  var
    lstBt: Byte;
    AllKCS7ByteCount: Integer;
  begin
    lstBt := P^[DecodeStream.Size - 1];
    AllKCS7ByteCount := AesBlockSize - (AesBlockSize - Ord(lstBt));
    if (AllKCS7ByteCount > 0) and (AllKCS7ByteCount < DecodeStream.Size) then
    begin
      if P^[DecodeStream.Size - AllKCS7ByteCount] = lstBt then
        Result := DecodeStream.Size - AllKCS7ByteCount
      else
        Result := DecodeStream.Size;
    end
    else
      Result := DecodeStream.Size;
  end;

begin
  try
    aEncodingAESKeyStr := AnsiString(sEncodingAESKey + '=');
    aEncodingAESKeyBts := DecodeBase64(aEncodingAESKeyStr);
  except
    raise Exception.Create('1');
  end;
  try
    SetLength(IvBts, 16);
    Move(aEncodingAESKeyBts[0], IvBts[0], 16);

    // aes.KeySize = 256; aes.BlockSize = 128; aes.Mode = CipherMode.CBC; aes.Padding = PaddingMode.None;
    sInput := AnsiString(sMsgEncrypt);
    InputBts := DecodeBase64(sInput);

    InputStream := TMemoryStream.Create;
    DecodeStream := TMemoryStream.Create;
    try
      InputStream.Write(InputBts[0], Length(InputBts));
      Move(aEncodingAESKeyBts[0], AesKey, Length(aEncodingAESKeyBts));
      Move(IvBts[0], Iv, Length(IvBts));
      InputStream.Position := 0;
      DecryptAESStreamCBC(InputStream, 0, AesKey, Iv, DecodeStream);
      P := PByteArray(DecodeStream.Memory);
      iDecodeDataLen := GetRealDataLenWithoutKCS7Bytes;

      iLen := P^[16] shl 24 + P^[17] shl 16 + P^[18] shl 8 + P^[19];
      SetLength(bMsg, iLen);
      SetLength(bAppid, iDecodeDataLen - 20 - iLen);
      Move(P^[20], bMsg[0], iLen);
      Move(P^[20 + iLen], bAppid[0], iDecodeDataLen - 20 - iLen);
      Result := TEncoding.UTF8.GetString(bMsg);
      cpid := TEncoding.UTF8.GetString(bAppid);
    finally
      InputStream.Free;
      DecodeStream.Free;
    end;
  except
    raise Exception.Create('2');
  end;
end;

function TWxMsgCrypt.AES_encrypt(const sEncodingAESKey, sMsg,
  cpid: string): string;
var
  aEncodingAESKeyStr: AnsiString;
  aEncodingAESKeyBts, IvBts, bRand, bAppid, btmpMsg, bMsg, bMsgLen, msg,
    pad: TBytes;
  Randcode: string;
  AesKey: TAESKey256;
  Iv: TAESBuffer;
  InputStream, OutputStream: TMemoryStream;

  function KCS7Encoder(text_length: Integer): TBytes;
  var
    amount_to_pad: Integer;
    pad_chr: Char;
    tmp: string;
    i: Integer;
  begin
    // 计算需要填充的位数
    amount_to_pad := AesBlockSize - (text_length mod AesBlockSize);
    if (amount_to_pad = 0) then
      amount_to_pad := AesBlockSize;
    // 获得补位所用的字符
    pad_chr := Chr(amount_to_pad);
    tmp := '';
    for i := 0 to amount_to_pad - 1 do
      tmp := tmp + pad_chr;
    Result := BytesOf(tmp);
  end;

begin
  aEncodingAESKeyStr := AnsiString(sEncodingAESKey + '=');
  aEncodingAESKeyBts := DecodeBase64(aEncodingAESKeyStr);

  SetLength(IvBts, 16);
  Move(aEncodingAESKeyBts[0], IvBts[0], 16);

  Randcode := CreateRandCode(16);

  bRand := TEncoding.UTF8.GetBytes(Randcode);
  bAppid := TEncoding.UTF8.GetBytes(cpid);
  btmpMsg := TEncoding.UTF8.GetBytes(sMsg);
  SetLength(bMsgLen, 4);
  bMsgLen[0] := (Length(btmpMsg) shr 24) and $FF;
  bMsgLen[1] := (Length(btmpMsg) shr 16) and $FF;
  bMsgLen[2] := (Length(btmpMsg) shr 8) and $FF;
  bMsgLen[3] := Length(btmpMsg) and $FF;

  SetLength(bMsg, Length(bRand) + Length(bAppid) + Length(btmpMsg) +
    Length(bMsgLen));
  Move(bRand[0], bMsg[0], Length(bRand));
  Move(bMsgLen[0], bMsg[Length(bRand)], Length(bMsgLen));
  Move(btmpMsg[0], bMsg[Length(bRand) + Length(bMsgLen)], Length(btmpMsg));
  Move(bAppid[0], bMsg[Length(bRand) + Length(bMsgLen) + Length(btmpMsg)],
    Length(bAppid));

{$REGION '自己进行PKCS7补位'}
  SetLength(msg, Length(bMsg) + 32 - Length(bMsg) mod 32);
  Move(bMsg[0], msg[0], Length(bMsg));
  pad := KCS7Encoder(Length(bMsg));
  Move(pad[0], msg[Length(bMsg)], Length(pad));
{$ENDREGION}
  // aes.KeySize = 256; aes.BlockSize = 128; aes.Padding = PaddingMode.None; aes.Mode = CipherMode.CBC;
  Move(aEncodingAESKeyBts[0], AesKey, Length(aEncodingAESKeyBts));
  Move(IvBts[0], Iv, Length(IvBts));
  InputStream := TMemoryStream.Create;
  OutputStream := TMemoryStream.Create;
  try
    InputStream.Write(msg[0], Length(msg));
    InputStream.Position := 0;
    EncryptAESStreamCBC(InputStream, 0, AesKey, Iv, OutputStream);
    Result := string(EncodeBase64(OutputStream.Memory, OutputStream.Size));
  finally
    InputStream.Free;
    OutputStream.Free;
  end;
end;

function TWxMsgCrypt.CreateRandCode(codeLen: Integer): string;
var
  code: string;
  randValue, i: Integer;
begin
  if codeLen > Length(RandCodeArr) then
    raise Exception.Create('codeLen max ' +
      IntToStr(Length(RandCodeArr)) + '！');
  if (codeLen = 0) then
    codeLen := 16;
  code := '';
  Randomize;
  for i := 0 to codeLen - 1 do
  begin
    randValue := Random(Length(RandCodeArr));
    code := code + RandCodeArr[randValue];
  end;
  Result := code;
end;

function TWxMsgCrypt.DecryptMsg(const sToken, sTimeStamp, sNonce, sMsgEncrypt,
  sSigture, sAppID, sEncodingAESKey: string; var sMsg: string)
  : WXBizMsgCryptErrorCode;
var
  ret: WXBizMsgCryptErrorCode;
  cpid: string;

  function VerifySignature: WXBizMsgCryptErrorCode;
  var
    hash: string;
    aStr: AnsiString;
    AL: TStringList;
    i: Integer;
  begin
    AL := TStringList.Create;
    try
      AL.Add(sToken);
      AL.Add(sTimeStamp);
      AL.Add(sNonce);
      AL.Add(sMsgEncrypt);
      AL.Sort;
      hash := '';
      for i := 0 to AL.Count - 1 do
        hash := hash + AL[i];
      aStr := AnsiString(hash);
      hash := LowerCase(SHA1Print(SHA1StringA(aStr)));
    finally
      AL.Free;
    end;
    if (hash = sSigture) then
      Result := WXBizMsgCrypt_OK
    else
      Result := WXBizMsgCrypt_ValidateSignature_Error;
  end;

begin
  sMsg := '';
  if (Length(sEncodingAESKey) <> 43) then
  begin
    Result := WXBizMsgCryptErrorCode.WXBizMsgCrypt_IllegalAesKey;
    Exit;
  end;

  // verify signature
  ret := VerifySignature;
  if (ret <> WXBizMsgCrypt_OK) then
  begin
    Result := ret;
    Exit;
  end;

  // decrypt
  cpid := '';
  try
    sMsg := AES_decrypt(sEncodingAESKey, sMsgEncrypt, cpid);
  except
    on E: Exception do
    begin
      if E.Message = '1' then
        Result := WXBizMsgCrypt_DecodeBase64_Error
      else
        Result := WXBizMsgCrypt_DecryptAES_Error;
      Exit;
    end;
  end;

  if (cpid <> sAppID) then
  begin
    Result := WXBizMsgCrypt_ValidateAppid_Error;
    Exit;
  end;

  Result := WXBizMsgCrypt_OK;
end;

function TWxMsgCrypt.EncryptMsg(const sMsg, sToken, sAppID, sEncodingAESKey
  : string; var sMsgEncrypt: string): WXBizMsgCryptErrorCode;
var
  hash, wxDt, wxNonce, EncryptField: string;

  function GenSignature: string;
  var
    hash: string;
    aStr: AnsiString;
    AL: TStringList;
    i: Integer;
  begin
    AL := TStringList.Create;
    try
      AL.Add(sToken);
      AL.Add(EncryptField);
      wxDt := GetWxNowStr;
      AL.Add(wxDt);
      wxNonce := CreateRandCode(10);
      AL.Add(wxNonce);
      AL.Sort;
      hash := '';
      for i := 0 to AL.Count - 1 do
        hash := hash + AL[i];
      aStr := AnsiString(hash);
      hash := LowerCase(SHA1Print(SHA1StringA(aStr)));
    finally
      AL.Free;
    end;
    Result := hash;
  end;

begin
  sMsgEncrypt := '';
  if (Length(sEncodingAESKey) <> 43) then
  begin
    Result := WXBizMsgCryptErrorCode.WXBizMsgCrypt_IllegalAesKey;
    Exit;
  end;

  // encrypt
  try
    EncryptField := AES_encrypt(sEncodingAESKey, sMsg, sAppID);
  except
    on E: Exception do
    begin
      if E.Message = '1' then
        Result := WXBizMsgCrypt_DecryptAES_Error
      else
        Result := WXBizMsgCrypt_EncryptAES_Error;
      Exit;
    end;
  end;

  // gen signature
  try
    hash := GenSignature;
  except
    Result := WXBizMsgCrypt_ComputeSignature_Error;
    Exit;
  end;

  // xml
  sMsgEncrypt := '<xml><Encrypt><![CDATA[' + EncryptField + ']]></Encrypt>' +
    '<MsgSignature><![CDATA[' + hash + ']]></MsgSignature>' +
    '<TimeStamp><![CDATA[' + wxDt + ']]></TimeStamp>' + '<Nonce><![CDATA[' +
    wxNonce + ']]></Nonce></xml>';

  Result := WXBizMsgCrypt_OK;
end;

end.
