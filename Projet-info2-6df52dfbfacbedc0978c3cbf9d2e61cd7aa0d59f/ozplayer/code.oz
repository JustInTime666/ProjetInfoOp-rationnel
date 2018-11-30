% --- QUESTIONS ET REMARQUES ---



local
% See project statement for API details.
   [Project] = {Link ['Project2018.ozf']}
   Time = {Link ['x-oz://boot/Time']}.1.getReferenceTime

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Translate a note to the extended notation.
   fun {NoteToExtended Note}
      case Note
      of Name#Octave then note(name:Name octave:Octave sharp:true duration:1.0 instrument:none)
      [] silence(duration:D) then Note
      [] note(name:Name octave:Octave sharp:Boolean duration:Dur instrument:none) then Note
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
%On rajoute de la complexite avec le append, mais on a pas le choix car nos transformation renvoient des listes or,
%on ne veut pas que celle ci soient interpretees comme des extended chords dans la partition. J'ai cherche d'autres methodes a complexites
%plus basses, mais elles considerait l'ensemble d'elements à inserer comme un seul et unique.
	 [] strech(factor:Factor Partion) then {List.append {Strech Factor Partion}  {PartitionToTimedList T}}
	 [] drone(note:NoteChord amount:Natural) then {List.append {Drone NoteChord Natural} {PartitionToTimedList T}}
	 [] transpose(semitones:Integer Partition )then {List.append {Transpose Seminotes Partition} {PartitionToTimedList T}}
	 else {NoteToExtended H} | {PartitionToTimedList T}
	 end
      end
   end
  %-------------------------------------------------------------------------------
  %retourne la partition prise en argument avec comme duree totale Secondes (en sec.)
   %Secondes doit etre un float sinon la comparaison Somme==Secondes plante.
   fun {Duration Secondes Partition} % /!\ doit retourner un liste qu'on va append!!!!
      local
	 Facteur
	 Somme
	 fun {Parcours Partition Acc}%additionne tout les temps
	    case Partition of H|T then %etape2:on parcourt la timedList afin de savoir la duree initale de la partition
	       if {List.is H} then {Parcours T Acc+H.1.duration}%une chord ne se joue qu'en 1temps, je prends donc un temps dans le chord
	       else
		  {Parcours T Acc+H.duration}
	       end
	    [] nil then Acc
	    end
	 end
      in %etape1:on appelle PartitionToTimedList pour mettre tout en timedList.
	 Somme={Parcours {PartitionToTimedList Partition} 0.0}
	 if {Int.is Somme} then %etape 3changement de somme et Secondes en float car l'operateur '/' ne fonctionne qu'avec ce type.
	    if {Int.is Secondes}then Facteur={Int.toFloat Secondes}/{Int.toFloat Somme}
	    else Facteur=Secondes/{Int.toFloat Somme}
	    end
	 elseif {Int.is Secondes} then %cas suppose ne pas arriver dans les consignes
	    Facteur={Int.toFloat Secondes}/Somme %etape4: on calcule le rapport Tfinal/Tinitial
	 else
	    Facteur=Secondes/Somme
	 end
	 if Somme == Secondes then Partition
	 else
	    {Stretch Facteur Partition}%etape5, on retourne une liste modifiee.
	 end
      end
   end


  %-------------------------------------------------------------------------------

   %crashe quand Fact\= de float meme parsing dans le local.
   fun {Stretch Factor Parti}
      local
	 Partition={PartitionToTimedList Parti}
      in
	 case Partition of nil then nil
	 [] H|T then
	    case H of note(name:Name octave:Octave sharp:Boolean duration:Dur instrument:Instru)
	    then note(name:Name octave:Octave sharp:Boolean duration:Dur*Factor instrument:Instru)|{Stretch Factor T}%faire gaffe avec'*' car si int*float->crash
	    [] U|V then {Stretch Factor H}|{Stretch Factor T}
	    end
	 end
      end
   end



  % %-------------------------------------------------------------------------------

  % renvoie une liste avec la note repetee autant de fois que la quantite indiquee par ​amount​.
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
      local GetRow GetNumber GetNote MergeTranspose Transpose2 in
	 {Transpose2 Seminotes Partition nil}
	 fun{Transpose2 Seminotes Partition L} 
	    case {PartitionToTimedList Partition} of
	       nil then {List.reverse L}
	    [] H|T then
	       case H of
		  K|L then if L == nil then {Transpose2 K I+1} {Transpose T}
			   else {Transpose2 K I+2} {Transpose L} end
	       else 
		  local C in
		     C = {GetNumber {NoteToExtended H}} + Seminotes
		     {Transpose2 Seminotes T {GetNote C}|L }
		  end
	       end
	    end
	 end
	 fun{GetRow Note} % renvoie la ligne du tableau dans lequel se trouve la note (cfr tableau wiki)
	    case {NoteToExtended Note} of
	       note(name:c octave:O sharp:false duration:D instrument:none) then 1
	    [] note(name:c octave:O sharp:true duration:D instrument:none) then 2
	    [] note(name:d octave:O sharp:false duration:D instrument:none) then 3
	    [] note(name:d octave:O sharp:true duration:D instrument:none) then 4
	    [] note(name:e octave:O sharp:false duration:D instrument:none) then 5
	    [] note(name:f octave:O sharp:false duration:D instrument:none) then 6
	    [] note(name:f octave:O sharp:true duration:D instrument:none) then 7
	    [] note(name:g octave:O sharp:false duration:D instrument:none) then 8
	    [] note(name:g octave:O sharp:true duration:D instrument:none) then 9
	    [] note(name:a octave:O sharp:false duration:D instrument:none) then 10
	    [] note(name:a octave:O sharp:true duration:D instrument:none) then 11
	    [] note(name:b octave:O sharp:false duration:D instrument:none) then 12
	    [] silence(duration:D) then 13
	    [] H|T then {Transpose2 Semitones Partition T}
	    else nil
	    end
	 end
	 fun{GetNumber Note} % renvoie le nombre associé à une note
	    if {GetRow Note} == O then O else
	       ((Note.octave + 2) * ({GetRow Note} + 11)) - 12 end
	 end
	 fun{GetNote X} % renvoie la note correspondant à un chiffre (cfr tableau wiki)
	    local GetNote1 GetNote2 A B in
	       A = X mod 12 % ligne
	       fun{GetNote1 X}
		  case A of
		     1 then note(name:c octave:Note.octave sharp:false duration:Note.duration instrument:none)
		  [] 2 then note(name:c octave:Note.octave sharp:true duration:Note.duration instrument:none)
		  [] 3 then note(name:d octave:Note.octave sharp:false duration:Note.duration instrument:none)
		  [] 4 then note(name:d octave:Note.octave sharp:true duration:Note.duration instrument:none)
		  [] 5 then note(name:e octave:Note.octave sharp:false duration:Note.duration instrument:none)
		  [] 6 then note(name:f octave:Note.octave sharp:false duration:Note.duration instrument:none)
		  [] 7 then note(name:f octave:Note.octave sharp:true duration:Note.duration instrument:none)
		  [] 8 then note(name:g octave:Note.octave sharp:false duration:Note.duration instrument:none)
		  [] 9 then note(name:g octave:Note.octave sharp:true duration:Note.duration instrument:none)
		  [] 10 then note(name:a octave:Note.octave sharp:false duration:Note.duration instrument:none)
		  [] 11 then note(name:a octave:Note.octave sharp:true duration:Note.duration instrument:none)
		  [] 12 then note(name:b octave:Note.octave sharp:false duration:Note.duration instrument:none)
		  [] 13 then silence(duration:Note.duration)
		  end
	       end
	       fun{GetNote2 X}
		  B = (X div 12 ) - 1 % colonne
		  case B of
		     -1 then note(name:Note.name octave:-1 sharp:Note.sharp duration:Note.duration instrument:none)
		  [] 0 then note(name:Note.name octave:0 sharp:Note.sharp duration:Note.duration instrument:none)
		  [] 1 then note(name:Note.name octave:1 sharp:Note.sharp duration:Note.duration instrument:none)
		  [] 2 then note(name:Note.name octave:2 sharp:Note.sharp duration:Note.duration instrument:none)
		  [] 3 then note(name:Note.name octave:3 sharp:Note.sharp duration:Note.duration instrument:none)
		  [] 4 then note(name:Note.name octave:4 sharp:Note.sharp duration:Note.duration instrument:none)
		  [] 5 then note(name:Note.name octave:5 sharp:Note.sharp duration:Note.duration instrument:none)
		  [] 6 then note(name:Note.name octave:6 sharp:Note.sharp duration:Note.duration instrument:none)
		  [] 7 then note(name:Note.name octave:7 sharp:Note.sharp duration:Note.duration instrument:none)
		  [] 8 then note(name:Note.name octave:8 sharp:Note.sharp duration:Note.duration instrument:none)
		  [] 9 then note(name:Note.name octave:9 sharp:Note.sharp duration:Note.duration instrument:none)
		  [] 10 then note(name:Note.name octave:10 sharp:Note.sharp duration:Note.duration instrument:none)
		  [] 11 then silence(duration:Note.duration)
		  end
	       end
	       {MergeTranspose {GetNote1 X} {GetNote2 X}}
	    end
	 end
	 fun{MergeTranspose Note1 Note2} 
	    case Note1 of
	       note(name:N1 octave:O1 sharp:S1 duration:D1 instrument:none) then
	       case Note2 of
		  note(name:N2 octave:O2 sharp:S2 duration:D2 instrument:none) then note(name:N1 octave:O2 sharp:S1 duration:D1 instrument:none)
	       else nil end
	    [] silence(duration:D1) then case Note2 of
					    note(name:N2 octave:O2 sharp:S2 duration:D2 instrument:none) then note(name:N2 octave:O2 sharp:S2 duration:D2 instrument:none)
					 [] silence(duration:D2) then silence(duration:D2) % on aura pu mettre D1 mais c'est d'office les mêmes
					 else nil end
	    else nil end
	 end
      end
   end


%local Part1 Numb in
%   Part1 = [ note(name:c octave:4 sharp:false duration:- instrument:none) note(name:f octave:4 sharp:true duration:- instrument:none) ]
%   Numb = 5
%   {Browse 'expected : note(name:f octave:4 sharp:false duration:- instrument:none) note(name:b octave:4 sharp:false duration:- instrument:none)'}
%   {Browse 'what is calculated:'}
%   {Browse {Transpose Numb Part1} }
%end

 %-------------------------------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   fun {Mix P2T Music} %P2T correspond à PartitionToTimedList
   % interprete l'argument Music retourne une liste d'échantillons
  
      case Music of nil then nil
      [] H|T then
	 case H of samples(Samp) then
	    {List.append {Samples Samp}        {Mix P2T T}}
	 [] partition(Partit) then
	    {List.append {Partition Partit}    {Mix P2T T}}
	 [] wave(FileName) then
	    {List.append {Wave FileName}       {Mix P2T T}}
	 [] merge(MusWithInte) then
	    {List.append {Merge MusWithInte}   {Mix P2T T}}
	 [] reverse(Musi) then
	    {List.append {Reverse Musi}        {Mix P2T T}}
	 [] repeat(amount:Int Musi) then
	    {List.append {Repeat Int Musi}     {Mix P2T T}}
	 [] loop(duration:Duration Musi) then
	    {List.append {Loop Duration​ Musi}  {Mix P2T T}}
	 [] clip(low:Sample1 high:Sample2 Musi)then
	    {List.append {Clip Sample​1 Sample2​ Musi} {Mix P2T T}}
	 [] echo(delay:Duration Musi) then
	    {List.append {Echo Duration​ Musi}  {Mix P2T T}}
	 [] fade(in:Dur1 out:Dur2 Musi)then
	    {List.append {Fade Dur Dur2 ​Musi} {Mix P2T T}}
	 [] cut(start:Dur1 end:Dur2 Musi)then
	    {List.append {Cut Dur1 Dur2 Musi}  {Mix P2T T}}
	 end
      end
   end

 %-------------------------------------------------------------------------------

   fun{Samples S}
      S
   end

 %-------------------------------------------------------------------------------

   fun{Partition P}
      local Partition2 GetRow GetNumber in
	 case {PartitionToTimedList P} of
	    H|T then
	    case H of
	       K|L then if L == nil then {Partition2 K I+1} {Partition T} else {Partition2 K I+1} {Partition L} end
	    [] note(name:N octave:O sharp:S duration:D instrument:none) then {Partition2 H I+1} {Partition T}
	    end
	 end
	 fun{Partition2 P I}
	    local F in
	       if {GetNumber Note} == 0 then I=I+1 {Append 0 {Partition T}}
	       else
		  F = (2**(({GetNumber Note}-69)/12) )*440
		  I=I+1
		  {Append 1/2*Sin((2*3.14159265359*F*I)/44100) {Partition T}}
	       end
	    end
	 end
	 fun{GetRow Note} % renvoie la ligne du tableau dans lequel se trouve la note (cfr tableau wiki)
	    case Note of
	       note(name:c octave:O sharp:false duration:D instrument:none) then 1
	    [] note(name:c octave:O sharp:true duration:D instrument:none) then 2
	    [] note(name:d octave:O sharp:false duration:D instrument:none) then 3
	    [] note(name:d octave:O sharp:true duration:D instrument:none) then 4
	    [] note(name:e octave:O sharp:false duration:D instrument:none) then 5
	    [] note(name:f octave:O sharp:false duration:D instrument:none) then 6
	    [] note(name:f octave:O sharp:true duration:D instrument:none) then 7
	    [] note(name:g octave:O sharp:false duration:D instrument:none) then 8
	    [] note(name:g octave:O sharp:true duration:D instrument:none) then 9
	    [] note(name:a octave:O sharp:false duration:D instrument:none) then 10
	    [] note(name:a octave:O sharp:true duration:D instrument:none) then 11
	    [] note(name:b octave:O sharp:false duration:D instrument:none) then 12
	    [] silence(duration:D) then 0
	    end
	 end
	 fun{GetNumber Note} % renvoie le nombre associe à une note
	    if {GetRow Note} == O then O
	    else
	       ((Note.octave + 2) * ({GetRow Note} + 11)) - 12
	    end
	 end
	 {Partition2 P 0}
      end
   end
 % [a b c duration(seconds:30 [a b duration(seconds:20 [a b [c d]]) c]) d e]

 %-------------------------------------------------------------------------------

   fun{Wave FileName}
      {Project.load Filename}
   end

 %-------------------------------------------------------------------------------

   fun{Merge Musics}
   end

 %-------------------------------------------------------------------------------

	    %Musi est une partition tel que {Music} en recoit.Je considere que {Music} ne renvoie bien qu'une liste!
   %retourne alors une liste d'echantillons
   fun{Reverse Music}
      local
	 fun {Rev List Acc}
	    case List of H|T then{Rev T H|Acc}
	    else Acc
	    end
	 end
      in
	 {Rev {Mix Music} nil}
      end
   end

 %-------------------------------------------------------------------------------

   %repete Amout fois la musique Music si Amount=1 alors music n'est jouée que une fois-------------------------------------------------------------------------- Just t'es d'accord?
   %retourne des echantillons, echantillonner tout en premier temps permet de faire appel a {Music} 1 fois contre Amount fois pour la meme Music
   fun{Repeat Amount Music}% Amount=int
      local
	 List={Mix Music}
	 fun {Repe Amount List Acc}
	    if Amount>1 then {Repe Amount-1 List {Append List Acc}}
	    else Acc
	    end
	 end
      in
	 {Repe Amount List List}
      end
   end

 %-------------------------------------------------------------------------------

	  % repete Musi tant que Seconds de sample n'est pas atteint.
   % /!\ l'ordi approxime les floats, du coup, 3/44100 \= de 3* (1/44100)
   fun{Loop Seconds Musi}
      local
	 MusiT={Music Musi}
	 fun {Loo Sec Mus MusiT}
	    case Mus of H|T then
	       if Sec-1.0/44100.0 >= 0.0 then H|{Loo Sec-1.0/44100.0 T MusiT}
	       else nil
	       end
	    [] nil then {Loo Sec MusiT MusiT}
	    end
	 end
      in
	 {Loo Seconds MusiT MusiT}
      end
   end %teste avec {Browse {Loop 3.1/44100.0 [1 2]}} (si on met 3.0, ne sort pas le 3ème à cause de l'approx)


 %-------------------------------------------------------------------------------

   fun {Clip Low High Musi}
      local
	 Samps={Music Musi}
	 fun {Parcours Samps}
	    case Samps of H|T then
	       if H<Low then Low|{Parcours T}
	       elseif H>High then High|{Parcours T}
	       else H|{Parcours T}
	       end
	    else nil
	    end
	 end
      in
	 {Parcours Samps}
      end
   end %test effectué avec {Browse {Clip 1.0 10.0 [0.0 ~1.0 2.99 3.0 4.0 5.0 13.0 3.0 11.1 ~10.2]}}

 %-------------------------------------------------------------------------------

  % /!\ peut sortir de l'intervalle!! et facteur et delay=float!!
   
   %duree approximee vers le bas, et utilisation de Repeat et pas loop car plus precis
   fun{Echo Delay Factor Musique}
      local DelayedMusic={Repeat {floatToInt Delay*44100.0} 0.0} %0.0 car un silence en sample=0
	 in
	 {Merge [1#Musique Factor#DelayedMusic]}
      end
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