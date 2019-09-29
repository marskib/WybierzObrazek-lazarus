unit u_odtwarzacz;
//symulacja TMediaPlayer'a z Delphi
{$MODE Delphi}

interface

uses
  Classes, SysUtils, MMSystem, FileUtil, ExtCtrls;

Type

{ TMediaPlayerSki }

 TMediaPlayerSki=Class
  procedure Play(plik:String; ileCzekac: Byte);
  constructor WlasnyCreate();
  private
    Filename : String;  //plik do odegrania - jezeli ma polskie znaki w nazwie to trzeba go bedzie zamieniac na plik roboczy ze znakami tylko ansii w nazwie
    TimerOpozniacz : TTimer;
    plik_roboczy : string;   //ten plik bedzie de facto odgrywany (PlaySound i problem polskich znakow - patrz nizej)
    procedure GranieWlasciwe(Sender: TObject); //uwaga na parametr - musi byc - wymog formalny przy podstawianiu pod Eventa
End;

implementation


procedure TMediaPlayerSki.Play(plik:String; ileCzekac: Byte);
(* Decydujemy czy gramy z opoznieniem, czy natychmiast *)
(* ileCzekac - wielokrotnosc 750 ms                    *)
Begin
 Filename := plik; //plik do odegrania
 if ileCzekac=0 then
   GranieWlasciwe(nil)   //TMediaPlayerSki.GranieWlasciwe wykona sie natychmiast (bez opoznienia przez timer)
 else begin
   TimerOpozniacz.Interval:=ileCzekac*750; //wynik w ms
   TimerOpozniacz.Enabled:=True            //za xxx milisekund odegra sie glos (wykona sie TMediaPlayerSki.GranieWlasciwe)
 end;
End;

procedure TMediaPlayerSki.GranieWlasciwe();
Begin
  //Kopiowanie pliku oraz granie robie w Tray'u, bo na poczatku programu, jesli nie ma pliku do odegrania, to wali sie wszystko...
  Try
    if FileExists(*UTF8*)(Filename) then begin
      plik_roboczy := GetEnvironmentVariable('TEMP')+DirectorySeparator+'kopia_ansii.wav';     //SciezkaZasoby+'kopia_ansii.wav';
      CopyFile(filename,plik_roboczy); //plik do odegrania bedzia nazywal sie jw - bo PlaySound nie odgrywa plikow z polskimi znakami
      (**)
      //Kamiennogorska, wylaczam:
      PlaySound(PChar(plik_roboczy),0,SND_ASYNC)
      (**)
    end;
  Except
    //Beep;
  end;
  TimerOpozniacz.Enabled := False; //jesli bylo wywolanie przez timer, to 'sprzatamy'...
End;


constructor TMediaPlayerSki.WlasnyCreate;
Begin
 Self := TMediaPlayerSki.Create;
 TimerOpozniacz := TTimer.Create(nil);
 TimerOpozniacz.OnTimer  := GranieWlasciwe;
 TimerOpozniacz.Enabled  := False;
End;



end.

