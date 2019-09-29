program WybierzObrazek;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, Forms,  u_operacje, u_tmimage, u_parametry, u_sprawdzacz, u_ramka,
  u_lapka, u_odtwarzacz, uoprogramie;

{$R *.res}

begin
  //RequireDerivedFormResource:=True;  ??
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TFOperacje, FOperacje);
  Application.CreateForm(TFParametry, FParametry);
  Application.CreateForm(TFOprogramie, FOprogramie);
  Application.Run;
end.
