
local
% See project statement for API details.
   [Project] = {Link ['Project2018.ozf']}
   Time = {Link ['x-oz://boot/Time']}.1.getReferenceTime

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Translate a note to the extended notation.
   fun {NoteToExtended Note}
      case Note
      of Name#Octave then note(name:Name octave:Octave sharp:true duration:1.0 instrument:none)
      [] silence(duration:D) then silence(duration:D)
      [] note(name:Name octave:Octave sharp:Boolean duration:Dur instrument:none) then
	 note(name:Name octave:Octave sharp:Boolean duration:Dur instrument:none)
      [] H|T then if T == nil then  {NoteToExtended H} | nil %chord
		  else {NoteToExtended H} | {NoteToExtended T} end
      [] Atom then
	 case {AtomToString Atom}
	 of [_] then note(name:Atom octave:4 sharp:false duration:1.0 instrument:none)
	 [] [N O] then
	    note(name:{StringToAtom [N]}
		 octave:{StringToInt [O]}
		 sharp:false
		 duration:1.0
		 instrument: none)
	 end
      end
   end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


   fun {PartitionToTimedList Partition}%exemple de partition:[a b c duration(seconds:30 [a b duration(seconds:20 [a b [c d]]) c]) d e]
      case Partition of nil then nil
      [] H|T then
	 case H of duration(seconds:Dur Partion) then {List.append {Duration Dur Partion} {PartitionToTimedList T}} %NEW MODIFS.
%On rajoute de la complexité avec le append, mais on a pas le choix car nos transformation renvoient des listes or,
%on ne veut pas que celle ci soient interpretées comme des extended chords dans la partition. J'ai cherché d'autres méthodes à complexités
%plus basses, mais elles considérait l'ensemble d'éléments à insérer comme un seul et unique.
	 [] strech(factor:Factor Partion) then {List.append {Strech Factor Partion}  {PartitionToTimedList T}}
	 [] drone(note:NoteChord amount:Natural) then {List.append {Drone NoteChord Natural} {PartitionToTimedList T}}
	 [] transpose(semitones:Integer Partition )then {List.append {Transpose Seminotes Partition} {PartitionToTimedList T}}
	 else {NoteToExtended H} | {PartitionToTimedList T}
	 end
      end
   end
  %-------------------------------------------------------------------------------
  %retourne la partition prise en argument avec comme durée totale Secondes (en sec.)
   %Secondes doit être un float sinon la comparaison Somme==Secondes plante.
   fun {Duration Secondes Partition} % /!\ doit retourner un liste qu'on va append!!!!
      local
	 Facteur
	 Somme
	 fun {Parcours Partition Acc}%additionne tout les temps
	    case Partition of H|T then %étape2:on parcourt la timedList afin de savoir la durée initale de la partition
	       if {List.is H} then {Parcours T Acc+{Parcours H 0.0}}%parcour d'une extended chord.
	       else
		  {Parcours T Acc+H.duration}
	       end
	    [] nil then Acc
	    end
	 end
      in %étape1:on appelle PartitionToTimedList pour mettre tout en timedList.
	 Somme={Parcours {PartitionToTimedList Partition} 0.0}
	 if {Int.is Somme} then %etape 3changement de somme et Secondes en float car l'opérateur '/' ne fonctionne qu'avec ce type.
	    if {Int.is Secondes}then Facteur={Int.toFloat Secondes}/{Int.toFloat Somme}
	    else Facteur=Secondes/{Int.toFloat Somme}
	    end
	 elseif {Int.is Secondes} then
	    Facteur={Int.toFloat Secondes}/Somme %etape4: on calcule le rapport Tfinal/Tinitial
	 else
	    Facteur=Secondes/Somme
	 end
	 if Somme == Secondes then Partition
	 else
	    {Strech Facteur Partition}%etape5, on retourne une liste modifiée.
	 end
      end
   end


  %-------------------------------------------------------------------------------

   %crashe quand Fact\= de float même parsing dans le local.
   fun {Strech Factor Parti}
      local
	 Partition={PartitionToTimedList Parti}
      in
	 case Partition of nil then nil
	 [] H|T then
	    case H of note(name:Name octave:Octave sharp:Boolean duration:Dur instrument:Instru)
	    then note(name:Name octave:Octave sharp:Boolean duration:Dur*Factor instrument:Instru)|{Strech Factor T}%faire gaffe avec'*' car si int*float->crash
	    [] U|V then {Strech Factor H}|{Strech Factor T}
	    end
	 end
      end
   end



  % %-------------------------------------------------------------------------------

  % renvoie une liste avec la note répétée autant de fois que la quantité indiquée par ​amount​.
    % testé et approuvé
   fun {Drone Note Amount}
         local DroneAcc in 
   	      fun{DroneAcc Note Amount Acc L}
   	         if Acc < Amount then
    {DroneAcc Note Amount Acc+1 Note|L}
         else L
         end
      end
      {DroneAcc Note Amount 0 nil}
         end
   end

 %-------------------------------------------------------------------------------

    % transpose la partition d'un certain nombre de demi-tons vers le haut (nombre positif) ou vers le bas (nombre négatif).
    fun {Transpose Seminotes Partition}
      local GetRow GetNumber GetNote Merge Transpose2 in
fun{GetRow Note} % renvoie la ligne du tableau dans lequel se trouve la note (cfr tableau wiki)
   case Note of
      note(name:c octave:- sharp:false duration:- instrument:none) then 1
   [] note(name:c octave:- sharp:true duration:- instrument:none) then 2
   [] note(name:d octave:- sharp:false duration:- instrument:none) then 3
   [] note(name:d octave:- sharp:true duration:- instrument:none) then 4
   [] note(name:e octave:- sharp:false duration:- instrument:none) then 5
   [] note(name:f octave:- sharp:false duration:- instrument:none) then 6
   [] note(name:f octave:- sharp:true duration:- instrument:none) then 7
   [] note(name:g octave:- sharp:false duration:- instrument:none) then 8
   [] note(name:g octave:- sharp:true duration:- instrument:none) then 9
   [] note(name:a octave:- sharp:false duration:- instrument:none) then 10
   [] note(name:a octave:- sharp:true duration:- instrument:none) then 11
   [] note(name:b octave:- sharp:false duration:- instrument:none) then 12
   end
end
fun{GetNumber Note} % renvoie le nombre associé à une note
   ((Note.octave + 2) * ({GetRow Note} + 11)) - 12
end
fun{GetNote X} % renvoie la note correspondant à un chiffre (cfr tableau wiki)
   local GetNote1 GetNote2 A B in
      A = X mod 12 % ligne
      fun{GetNote1 X}
 case A of
    1 then note(name:c octave:- sharp:false duration:- instrument:none)
 [] 2 then note(name:c octave:- sharp:true duration:- instrument:none)
 [] 3 then note(name:d octave:- sharp:false duration:- instrument:none)
 [] 4 then note(name:d octave:- sharp:true duration:- instrument:none)
 [] 5 then note(name:e octave:- sharp:false duration:- instrument:none)
 [] 6 then note(name:f octave:- sharp:false duration:- instrument:none)
 [] 7 then note(name:f octave:- sharp:true duration:- instrument:none)
 [] 8 then note(name:g octave:- sharp:false duration:- instrument:none)
 [] 9 then note(name:g octave:- sharp:true duration:- instrument:none)
 [] 10 then note(name:a octave:- sharp:false duration:- instrument:none)
 [] 11 then note(name:a octave:- sharp:true duration:- instrument:none)
 [] 12 then note(name:b octave:- sharp:false duration:- instrument:none)
 end
      end
   fun{GetNote2 X}
      B = (X div 12 ) - 1 % colonne
      case B of
 -1 then note(name:- octave:-1 sharp:- duration:- instrument:none)
      [] 0 then note(name:- octave:0 sharp:- duration:- instrument:none)
      [] 1 then note(name:- octave:1 sharp:- duration:- instrument:none)
      [] 2 then note(name:- octave:2 sharp:- duration:- instrument:none)
      [] 3 then note(name:- octave:3 sharp:- duration:- instrument:none)
      [] 4 then note(name:- octave:4 sharp:- duration:- instrument:none)
      [] 5 then note(name:- octave:5 sharp:- duration:- instrument:none)
      [] 6 then note(name:- octave:6 sharp:- duration:- instrument:none)
      [] 7 then note(name:- octave:7 sharp:- duration:- instrument:none)
      [] 8 then note(name:- octave:8 sharp:- duration:- instrument:none)
      [] 9 then note(name:- octave:9 sharp:- duration:- instrument:none)
      [] 10 then note(name:- octave:0 sharp:- duration:- instrument:none)
      end
   end
   {Merge {GetNote1 X} {GetNote2 X}}
   end
end
fun{Merge Note1 Note2} 
   case Note1 of
      note(name:N octave:- sharp:S duration:- instrument:none) then
      case Note2 of
 note(name:- octave:O sharp:- duration:- instrument:none) then
 note(name:N octave:O sharp:S duration:- instrument:none)
      end
   end
end
fun{Transpose2 Seminotes Partition L} 
      case Partition of
 nil then {List.reverse L}
      [] H|T then
 local C in
    C = {GetNumber {NoteToExtended H}} + Seminotes
    {Transpose2 Seminotes T {GetNote C}|L }
 end
      end
end
{Transpose2 Seminotes Partition nil}
      end
   end

 %-------------------------------------------------------------------------------

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   fun {Mix P2T Music} %P2T correspond à PartitionToTimedList
   % interprète l'argument Music retourne une liste d'échantillons
   % On est pas sortis de l'auberge
   % On est même carrément dans le lac 
      {Project.readFile 'wave/animaux/cow.wav'}
   end

 %-------------------------------------------------------------------------------

   fun{Samples S}
   end

 %-------------------------------------------------------------------------------

   fun{Partition P}
   end

 %-------------------------------------------------------------------------------

   fun{Wave FileName}
   end

 %-------------------------------------------------------------------------------

   fun{Merge Musics}
   end

 %-------------------------------------------------------------------------------

   fun{Reverse Music}
   end

 %-------------------------------------------------------------------------------

   fun{Repeat Amount Music}
   end

 %-------------------------------------------------------------------------------

   fun{Loop Seconds Music}
   end

 %-------------------------------------------------------------------------------

   fun{Clip Low High Music}
   end

 %-------------------------------------------------------------------------------

   fun{Echo Delay Factor Music}
   end

 %-------------------------------------------------------------------------------

   fun{Fade Start Out Music}
   end

 %-------------------------------------------------------------------------------

   fun{Cut Start Finish Music}
   end

 %-------------------------------------------------------------------------------


x   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   Music = {Project.load 'joy.dj.oz'}
   Start

   % Uncomment next line to insert your tests.
   % \insert 'tests.oz'
   % !!! Remove this before submitting.
in
   Start = {Time}

   % Uncomment next line to run your tests.
   % {Test Mix PartitionToTimedList}

   % Add variables to this list to avoid "local variable used only once"
   % warnings.
   {ForAll [NoteToExtended Music] Wait}
   
   % Calls your code, prints the result and outputs the result to out.wav.
   % You don't need to modify this.
   {Browse {Project.run Mix PartitionToTimedList Music 'out.wav'}}
   
   % Shows the total time to run your code.
   {Browse {IntToFloat {Time}-Start} / 1000.0}
end