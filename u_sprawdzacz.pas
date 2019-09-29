unit u_sprawdzacz;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, u_tmimage;

TYPE
  (****************************************************************************************************************)
  (* Obiekt Sprawdzacz, ktory po podniesieniu myszki, sprawdzi, czy obrazek znajduje sie we wlasciwym obszarze ('nad linią') *)
  (* Oprocz tego prowadzi 'ewidencje' liczby zebranych w nim obrazkow *)
  (* Rejestruje/sprawdza czy byl sygnal Beep podczas dokladania 1-go prawidlowego obrazka do Obszaru Gornego      *)
  (* Mozna Sprawdzacz odpytac o to, czy w obszarze jest szukany obrazek                                           *)
  (* (chodzi o to, zeby byl tylko 1 beep - po jesli beep rowniez przy drugim, to komplikacje - bo obowiazkowo musze miec beep *)
  (****************************************************************************************************************)

  TSprawdzacz = class

     private FIlewObsz : Smallint;
     public property IlewObsz : SmallInt Read FIlewObsz; //Ile aktualnie obrazkow znajduje sie w obszarze

     private FJestWlasciwy : Boolean;
     public property JestWlasciwy : Boolean Read FJestWlasciwy; //Czy w obszarze przebywa wlasciwy (szukany) obrazek

     public BylBeep  : Boolean;          //opis - patrz wyzej, w metryczce
     {}
     constructor Create();
     procedure Resetuj();                       //Po 'succesfull'nym' pytaniu resetujemy obiekt (glownie IlewObsz := 0)
     procedure Sprawdz(var Obrazek:TMojImage);  //Sprawdzenie Obrazka z parametrow
     private ld : integer;   //polozenie lini dolnej' dzielącej ekran
  end;


implementation
  uses  u_operacje;

{ TSprawdzacz }

constructor TSprawdzacz.Create();
Begin
  inherited Create();
  //Self := TSprawdzacz.Create();
  ld := FOperacje.SLinia.Top;
  FIlewObsz := 0;
  FJestWlasciwy := False;
  BylBeep  := False;
End;

procedure TSprawdzacz.Resetuj;
(* Przed kazdym nowym cwiczeniem ustawiamy Sprawdzacz na nowo *)
Begin
  FIlewObsz := 0;
  FJestWlasciwy := False;
  BylBeep  := False;
End;

procedure TSprawdzacz.Sprawdz(var Obrazek: TMojImage);
(* Sprawdzam gdzie Obrazek jest i ustawiam jego oraz Sprawdzacza charakterystyki wlasiwosci *)
Begin
  //Obrazek wszedl/jest na Obszar Gorny OG:
  if Obrazek.Top < ld then begin
     if not Obrazek.inArea then begin //jesli obrazek juz byl w Obszarze OG - nie robic nic(!) - to bylo przemieszczeni "poziome"
       //Obrazek wszedl do OG:
       Obrazek.inArea := True;
       FIlewObsz := FIlewObsz + 1;
       if not FJestWlasciwy then
         FJestWlasciwy := (Obrazek.getIdOb()=FOperacje.idWylos);
       Exit;
     end;
   end;

  //Obrazek wYszedl/jest na Obszar Dolny OD:
  if Obrazek.Top > ld then begin
     if Obrazek.inArea then begin //jesli obrazek juz byl w Obszarze OD - nie robic nic(!) - to bylo przemieszczeni "poziome"
       //Obrazek wyszedl z OG:
       Obrazek.inArea := False;
       FIlewObsz := FIlewObsz - 1;
       if FJestWlasciwy then begin
         if (Obrazek.getIdOb()=FOperacje.idWylos) then  //z obszaru wlasnie wyszedl zgadywany obrazek.....
           FJestWlasciwy:=FALSE;
       end;
       Exit;
     end;
   end;

End;

end.

