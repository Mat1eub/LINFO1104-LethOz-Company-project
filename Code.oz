local 
   % Vous pouvez remplacer ce chemin par celui du dossier qui contient LethOzLib.ozf
   % Please replace this path with your own working directory that contains LethOzLib.ozf

   % Dossier = {Property.condGet cwdir '/home/max/FSAB1402/Projet-2017'} % Unix example
   Dossier = {Property.condGet cwdir '/Users/mateobauvir/Desktop/UCL/BAC2/Q2/LINFO1104-LethOz-Company-project'}
   % Dossier = {Property.condGet cwdir 'C:\\Users\Thomas\Documents\UCL\Oz\Projet'} % Windows example.
   LethOzLib

   % Les deux fonctions que vous devez implémenter
   % The two function you have to implement
   Next
   DecodeStrategy
   
   % Hauteur et largeur de la grille
   % Width and height of the grid
   % (1 <= x <= W=24, 1 <= y <= H=24)
   W = 24
   H = 24

   Options
in
   % Merci de conserver cette ligne telle qu'elle.
   % Please do NOT change this line.
   [LethOzLib] = {Link [Dossier#'/'#'LethOzLib.ozf']}
   {Browse LethOzLib.play}

%%%%%%%%%%%%%%%%%%%%%%%%
% Your code goes here  %
% Votre code vient ici %
%%%%%%%%%%%%%%%%%%%%%%%%

   local
      %Fonctionnalités
      Outils Mouvements Event Effets
   in
      Outils = local

         /**
         * Déplace d'une case dans la direction D et s'il sort des limites du plateau il réapparait
         * de l'autre côté.
         * args: P : position du vaisseau
         *       D : direction du déplacement
         * returns: nouvelle position après le déplacement.
         */
         fun{PostPos P D}
            case P.to
            of north then
               if P.y == 1 then pos(x:P.x y:H to:D)
               else pos(x:P.x y:(P.y-1) to:D) end
            [] west then
               if P.x == 1 then pos(x:W y:P.y to:D)
               else pos(x:(P.x-1) y:P.y to:D) end
            [] south then
               if P.y == H then pos(x:P.x y:1 to:D)
               else pos(x:P.x y:(P.y+1) to:D) end
            [] east then
               if P.x == W then pos(x:1 y:P.y to:D)
               else pos(x:(P.x+1) y:P.y to:D) end
            end
         end

         /**
         * Calcule la position précédente du vaisseau avant d'avancer dans la direction opposée
         * à celle donnée par la direction D
         * args : P : position actuelle du vaisseau
         *        D : direction du vaisseau
         * returns : position précédente du vaisseau avant d'avancer dans la direction opposée 
         */
         fun{PrePos P D}
            case P.to
            of north then
               pos(x:P.x y:(P.y+1) to:D)
            [] west then
               pos(x:(P.x+1) y:P.y to:D)
            [] east then
               pos(x:(P.x-1) y:P.y to:D)
            [] south then
               post(x:P.x y:(P.y-1) to:D)
            end
         end
         
         /**
         * Applique récursivement la fonction F à chaque élément d'une liste List
         * args: List : Liste d'éléments
         *       F : Fonction à appliquer à chaque élément de la liste
         *       MappedList : Accumulateur
         * returns: Nouvelle liste mappée
         */
         fun{MapList List F MappedList}
            case List
            of nil then MappedList
            [] H|T then 
               {F H}|{MapList T F MappedList}
            end
         end

         /**
         * Calcule la nouvelle direction après un virage (left, right ou revert)
         * à partir de la direction actuelle D.
         * args: D: Direction actuelle du vaisseau
         *       V: Sens du virage
         * returns: Nouvelle direction du vaisseau après avoir tourné
         * */
         fun{NewDirection D V}
            case D
            of north then
               case V
               of left then west
               [] right then east
               [] revert then south
               end
            [] west then
               case V
               of left then south
               [] right then north
               [] revert then east
               end
            [] south then
               case V
               of left then east
               [] right then west
               [] revert then north
               end
            [] east then
               case V
               of left then north
               [] right then south
               [] revert then west
               end
            end
         end
         
         /**
         * Crée une liste de N fois un élément Elem.
         * args: N : Nombre de répétitions.
         *       E : Elément à répéter.
         * returns: Une liste contenant N fois l'élément Elem.
         */
         fun{Repeat N Elem}
            if N==0 then nil
            else Elem | {Repeat N-1 Elem}
            end
         end
      in
         utils(postPos : PostPos
               prePos : PrePos
               map : MapList
               newDir : NewDirection
               repeat : Repeat
               )
      end

      /**
      Event = local
         State ={NouvelEtat}
         Events = [
            event(name: "Attaque d'un vaisseau pirate", effect: {State.increaseEnnemyThreat 1}),
            event(name: "Mysterieuse anomalie", effect: {State.randomTeleport}),
            event(name: "Signaux de détresse", effect: {State.addMission "Operation sauvatage"})
            ]
      end
      */

      Mouvements = local
         
         /**
         * Fait avancer le vaisseau dans la direction actuelle 
         * args: Spaceship : Le vaisseau spacial à faire avancer
         * returns: Spaceship : Le vaisseau bougé
         */
         fun{Forward S}
            declare ForwardShipNormally
            % Fonction locale pour avancer d'une position dans la direction donnée
            fun{ForwardShipNormally PrePos P}
               % direction actuelle
               D = if PrePos == nil then P.to else PrePos.to end

               % calcule de la nouvelle position
               if PrePos == nil then % == si c'est la tete du vaisseau
                  {utils.postPos P D}
               else
                  PrePos
               end
            end
            % Vérifie si le vaisseau à un effet wormhole
            if{HasFeature S wormhole} then
               % Si trou de ver on récupère les coordonnées du trou
               X = (S.wormhole).1
               Y = (S.wormhole).2
               % Téléporte le vaisseau à la nouvelle position
               {UpdateShipAfterTeleport S X Y}
            else
               {ForwardShipNormally S}
            end
         end

         /**
         * Fonction locale pour vérifier si un vaisseau a une fonctionnalité
         * args: Ship : vaisseau spaciale actuel
         *       Feature : fonctionnalité
         * returns : true si Ship possède la fonctionnalité
         *           false sinon
         */
         fun{HasFeature Ship Feature}
            {List.exists Ship.effects fun{$ Effect}{Value.hasFeature Effect Feature} end}
         end

         /**
         * Fonction locale pour mettre à jour la position du vaisseau après une tp
         * args: Ship : vaisseau spaciale actuel
         *       X : Coordonnée X où le vaisseau doit être téléporté
         *       Y : Coordonnée Y où le vaisseau doit être téléporté
         */
         fun{UpdateShipAfterTeleport Ship X Y}
            {MapList Ship.positions fun{$ P} pos(x:X y:Y to:P.to) end nil}
         end
      in
         mouvements(
            forward : Forward
         )
      end

            



      % La fonction qui renvoit les nouveaux attributs du serpent après prise
      % en compte des effets qui l'affectent et de son instruction
      % The function that computes the next attributes of the spaceship given the effects
      % affecting him as well as the instruction
      % 
      % instruction ::= forward | turn(left) | turn(right)
      % P ::= <integer x such that 1 <= x <= 24>
      % direction ::= north | south | west | east
      % spaceship ::=  spaceship(
      %               positions: [
      %                  pos(x:<P> y:<P> to:<direction>) % Head
      %                  ...
      %                  pos(x:<P> y:<P> to:<direction>) % Tail
      %               ]
      %               effects: [scrap|revert|wormhole(x:<P> y:<P>)|... ...]
      %            )
      fun {Next Spaceship Instruction}
         {Browse Instruction}
         Spaceship
      end

      
      
      % La fonction qui décode la stratégie d'un serpent en une liste de fonctions. Chacune correspond
      % à un instant du jeu et applique l'instruction devant être exécutée à cet instant au spaceship
      % passé en argument
      % The function that decodes the strategy of a spaceship into a list of functions. Each corresponds
      % to an instant in the game and should apply the instruction of that instant to the spaceship
      % passed as argument
      %
      % strategy ::= <instruction> '|' <strategy>
      %            | repeat(<strategy> times:<integer>) '|' <strategy>
      %            | nil
      fun {DecodeStrategy Strategy}
         [
            fun{$ Spaceship}
               Spaceship
            end
         ]
      end

      % Options
      Options = options(
		   % Fichier contenant le scénario (depuis Dossier)
		   % Path of the scenario (relative to Dossier)
		   scenario:'scenario/scenario_crazy.oz'
		   % Utilisez cette touche pour quitter la fenêtre
		   % Use this key to leave the graphical mode
		   closeKey:'Escape'
		   % Visualisation de la partie
		   % Graphical mode
		   debug: true
		   % Instants par seconde, 0 spécifie une exécution pas à pas. (appuyer sur 'Espace' fait avancer le jeu d'un pas)
		   % Steps per second, 0 for step by step. (press 'Space' to go one step further)
		   frameRate: 5
		)
   end

%%%%%%%%%%%
% The end %
%%%%%%%%%%%
   
   local 
      R = {LethOzLib.play Dossier#'/'#Options.scenario Next DecodeStrategy Options}
   in
      {Browse R}
   end
end
