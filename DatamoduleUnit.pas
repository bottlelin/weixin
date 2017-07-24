unit DataModuleUnit;

interface

uses
  Forms,
  SysUtils, Classes, Data.DB, DBAccess, Uni, UniProvider, SQLServerUniProvider;

type
  TDataModule1 = class(TDataModule)
    UniConnection1: TUniConnection;
    SQLServerUniProvider1: TSQLServerUniProvider;
  private
  public
  end;

implementation

{$R *.dfm}

end.
