open Type;;
(*  0 normal
    1 problème lecture
    2 normal sous-block (non initialisé) *)

(*fonction pour ajouter une variable à l'environnement en respectant 
les règles particulières des variable dans les boucles *)
let add_vars (name:string) (b:int) (env:int Env.t) : int Env.t= 
  if not(Env.mem name env) then let env = Env.add name b env in
    env
  else if Env.find name env <> 1
  then     let env = Env.remove name env in
           let env = Env.add name b env in
           env 
        else env
;;

(*fonction qui fait l'union  de deux environnement dans le cas
 des sous-environnements de bloc*)
let union_map (env1:int Env.t) (env2:int Env.t) :int Env.t =
  Env.union (fun key b1 b2->  if b1 = 1 || b2 = 1 then Some(1)
  else if b1 = 0 || b2 = 0 then Some(0)
  else Some(2)) env1 env2
;;

(*fonction qui fait l'intersection de deux environnement dans le cas
 des sous-environnements de bloc*)
let inter_map (env1:int Env.t) (env2:int Env.t) :int Env.t =
  Env.merge (fun key b1 b2->  match (b1,b2) with
      |Some x, Some y -> if x = 1 || y = 1 then Some(1)
  else if x = 0 || y = 0 then Some(0)
  else Some(2)
      |_ -> None )
    env1 env2
;;

(*affiche un élément d'un environnement *)
let print_elt_int (key : string) (v : int) = 
  print_string (key ^ " ")
  ;;

(* affiche tout l'environnement *)
let print_map_int (env : (int) Env.t) = Env.iter print_elt_int env;;



(*Met à jour l'environnement en fonction de l'expression  *)
let rec vars_expr (e:expr) (env : (int) Env.t) : int Env.t= 
    match e with
    |Var x -> if Env.mem x env && Env.find x env = 0 then env else add_vars x 1 env
    |Op (op, e1, e2) -> vars_expr e1 (vars_expr e2 env)
    |_ -> env
;;

(*Met à jour l'environnement en fonction de la condition *)
let vars_cond (co :cond) (env : (int) Env.t) : int Env.t= 
    match co with
    |(e1, com, e2) -> vars_expr e1 (vars_expr e2 env)
;;

(*Met à jour l'environnement en indiquant l'initialisation de la variable *)
let vars_set (set:instr) (env : (int) Env.t) : int Env.t=
    match set with
    |Set (n , e) -> add_vars n 0 (vars_expr e env)
    | _ -> failwith "vars_set"
;;

(*Met à jour l'environnement en indiquant l'initialisation de la variable *)
let vars_read (read:instr) (env : (int) Env.t) : int Env.t=
    match read with
    |Read(n) -> add_vars n 0 env
    |_ -> failwith "vars_read"
;;

(*Met à jour l'environnement en fonction de l'expression du print*)
let vars_print (print:instr) (env : (int) Env.t) : int Env.t=
    match print with
    |Print(e) -> vars_expr e env
    | _ -> failwith "vars_print"
;;

(*Appel la fonction vars_instr à sur chaque élément du bloc *)
let rec vars_block (bloq:block) (env : (int) Env.t) : int Env.t=
    match bloq with
    | [] -> env
    | (num,ins):: tail -> let env =vars_instr ins env in
        vars_block tail env

(*Appel les fonctions qui mettront à jour l'environnement  *)
and vars_instr (ins:instr) (env : (int) Env.t) : int Env.t=
    match ins with 
    |Set(_) -> vars_set ins env
    |Read(_) -> vars_read ins env
    |Print(_) -> vars_print ins env
    |While(_) -> vars_while ins env
    |If(_) -> vars_if ins env

(*Met à jour l'environnement en créant un nouvel environnement pour le bloc
du while et fait l'union des deux*)
and vars_while (wil:instr) (env : (int) Env.t) : int Env.t=
    match wil with
    |While(con,bloc) -> union_map (vars_cond con env) (Env.map (fun num-> if num = 0 then 2
    else num) (vars_block bloc env))
    |_ -> failwith "vars_while"

(*Met à jour l'environnement en créant un environnement pour le bloc du if et du else
puis en fait l'intersection pour enfin faire l'union de cet environnement 
avec le principal *)
and vars_if (i:instr) (env : (int) Env.t) : int Env.t=
    match i with
    |If(con,bloc1,bloc2) -> let env = vars_cond con env in
                            let vars_bloc1 = vars_block bloc1 env in
                            let vars_bloc2 = vars_block bloc2 env in
    union_map (inter_map vars_bloc1 vars_bloc2) (Env.map (fun num-> if num = 0 then 2 
    else num) (union_map vars_bloc1 vars_bloc2))
    |_ -> failwith "vars_if"
;;
    
(*Fonction qui permet de lancer le programme avec l'option "vars" 
et qui va donc afficher d'abords toutes les variable de l'environnement 
puis celle qui peuevtn être accédé avant leur initialisation*)
let vars_polish (b:block) : unit =
    let env = vars_block b Env.empty in
    let pb = Env.filter  ( fun n k-> k = 1 ) env in
    print_map_int env; print_string "\n"; print_map_int pb; print_string "\n";
    ;;