object IWServerController: TIWServerController
  OldCreateOrder = False
  OnCreate = IWServerControllerBaseCreate
  AppName = 'MyApp'
  Description = 'My IntraWeb Application'
  DisplayName = 'IntraWeb Application'
  Port = 80
  ServerResizeTimeout = 0
  ShowLoadingAnimation = True
  SessionTimeout = 10
  SSLOptions.NonSSLRequest = nsAccept
  SSLOptions.Port = 0
  SSLOptions.SSLVersions = []
  Version = '14.1.4'
  AllowMultipleSessionsPerUser = False
  OnConfig = IWServerControllerBaseConfig
  OnNewSession = IWServerControllerBaseNewSession
  OnBrowserCheck = IWServerControllerBaseBrowserCheck
  Height = 310
  Width = 342
  object Pool: TIWDataModulePool
    OnCreateDataModule = PoolCreateDataModule
    OnFreeDataModule = PoolFreeDataModule
    Active = False
    Version = '2.1.0'
    RaiseExceptions = True
    AutoGrow = False
    GrowToSize = 100
    PoolCount = 20
    Left = 60
    Top = 12
  end
end
