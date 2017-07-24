object DataModule1: TDataModule1
  OldCreateOrder = False
  Height = 269
  Width = 382
  object UniConnection1: TUniConnection
    ProviderName = 'SQL Server'
    Database = 'QUEUE'
    SpecificOptions.Strings = (
      'SQL Server.Provider=prSQL')
    Username = 'sa'
    Server = '.'
    Connected = True
    LoginPrompt = False
    Left = 88
    Top = 64
    EncryptedPassword = '8CFF9EFF'
  end
  object SQLServerUniProvider1: TSQLServerUniProvider
    Left = 160
    Top = 64
  end
end
