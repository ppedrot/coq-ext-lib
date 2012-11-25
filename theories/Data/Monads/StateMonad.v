Require Import ExtLib.Structures.Monads.
Require Import ExtLib.Structures.Monoid.

Set Implicit Arguments.
Set Strict Implicit.

Section StateType.
  Variable S : Type.

  Record state (t : Type) : Type := mkState
  { runState : S -> t * S }.

  Definition evalState {t} (c : state t) (s : S) : t :=
    fst (runState c s).

  Definition execState {t} (c : state t) (s : S) : S :=
    snd (runState c s).


  Global Instance Monad_state : Monad state :=
  { ret  := fun _ v => mkState (fun s => (v, s))
  ; bind := fun _ c1 _ c2 =>
    mkState (fun s =>
      let (v,s) := runState c1 s in
      runState (c2 v) s)
  }.

  Global Instance MonadState_state : MonadState S state :=
  { get := mkState (fun x => (x,x))
  ; put := fun v => mkState (fun _ => (tt, v))
  }.

  Variable m : Type -> Type.

  Record stateT (t : Type) : Type := mkStateT
  { runStateT : S -> m (t * S)%type }.

  Variable M : Monad m.

  Definition evalStateT {t} (c : stateT t) (s : S) : m t :=
    bind (runStateT c s) (fun x => ret (fst x)).

  Definition execStateT {t} (c : stateT t) (s : S) : m S :=
    bind (runStateT c s) (fun x => ret (snd x)).


  Global Instance Monad_stateT : Monad stateT :=
  { ret := fun _ x => mkStateT (fun s => @ret _ M _ (x,s))
  ; bind := fun _ c1 _ c2 =>
    mkStateT (fun s =>
      @bind _ M _ (runStateT c1 s) _ (fun vs =>
        let (v,s) := vs in
        runStateT (c2 v) s))
  }.

  Global Instance MonadState_stateT : MonadState S stateT :=
  { get := mkStateT (fun x => ret (x,x))
  ; put := fun v => mkStateT (fun _ => ret (tt, v))
  }.

  Global Instance MonadT_stateT : MonadT stateT m :=
  { lift := fun _ c => mkStateT (fun s => bind c (fun t => ret (t, s)))
  }.

  Global Instance State_State_stateT T (MS : MonadState T m) : MonadState T stateT :=
  { get := lift get
  ; put := fun x => lift (put x)
  }.

  Global Instance MonadReader_stateT T (MR : MonadReader T m) : MonadReader T stateT := 
  { ask := mkStateT (fun s => bind ask (fun t => ret (t, s)))
  ; local := fun f _ c => mkStateT (fun s => local f (runStateT c s))
  }.

  Global Instance MonadWriter_stateT T (Mon : Monoid T) (MR : MonadWriter Mon m) : MonadWriter Mon stateT :=
  { tell := fun x => mkStateT (fun s => bind (tell x) (fun v => ret (v, s)))
  ; listen := fun _ c => mkStateT (fun s => bind (listen (runStateT c s))
    (fun x => let '(a,s,t) := x in
    ret (a,t,s)))
  ; pass := fun _ c => mkStateT (fun s => bind (runStateT c s) (fun x =>
    let '(a,t,s) := x in ret (a, s)))
  }.

  Global Instance Exc_stateT T (MR : MonadExc T m) : MonadExc T stateT :=
  { raise := fun _ e => lift (raise e)
  ; catch := fun _ body hnd => 
    mkStateT (fun s => catch (runStateT body s) (fun e => runStateT (hnd e) s))
  }.
  
End StateType.

Arguments evalState {S} {t} (c) (s).
Arguments execState {S} {t} (c) (s).
Arguments evalStateT {S} {m} {M} {t} (c) (s).
Arguments execStateT {S} {m} {M} {t} (c) (s).