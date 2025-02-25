From Undecidability.L Require Import Tactics.LTactics Datatypes.LBool Tactics.GenEncode.
From Undecidability.L Require Import Functions.EqBool.
Import L_Notations.

(* ** Encoding of option type *)
Section Fix_X.
  Variable X:Type.
  Context {intX : encodable X}.


  MetaCoq Run (tmGenEncode "option_enc" (option X)).
  Hint Resolve option_enc_correct : Lrewrite.

  Global Instance encInj_option_enc {H : encInj intX} : encInj (encodable_option_enc).
  Proof. register_inj. Qed. 
  
  (* now we must register the non-constant constructors*)

  Global Instance term_Some : computableTime' (@Some X) (fun _ _ => (1,tt)).
  Proof.
    extract constructor.
    solverec.
  Defined. (*because next lemma*)

  Lemma oenc_correct_some (s: option X) (v : term) : lambda v -> enc s == ext (@Some X) v -> exists s', s = Some s' /\ v = enc s'.
  Proof.
    intros lam_v H. unfold ext in H;cbn in H. unfold extT in H; cbn in H. redStep in H.
    apply unique_normal_forms in H;[|Lproc..]. destruct s;simpl in H.
    -injection H;eauto.
    -discriminate H.
  Qed.
       


   (*
   Lemma none_equiv_some v : proc v -> ~ none == some v.
   Proof.
     intros eq. rewrite some_correct. Lrewrite. apply unique_normal_forms in eq;[discriminate|Lproc..].
     intros H. assert (converges (some v)) by (eexists; split;[rewrite <- H; cbv; now unfold none| auto]). destruct (app_converges H0) as [_ ?]. destruct H1 as [u [H1 lu]]. rewrite H1 in H.
     symmetry in H. eapply eqTrans with (s := (lam (lam (#1 u)))) in H.
     eapply eq_lam in H. inv H. symmetry. unfold some. clear H. old_Lsimpl.
   Qed.
    *)
End Fix_X.

#[export] Hint Resolve option_enc_correct : Lrewrite.

Section option_eqb.

  Variable X : Type.
  Variable eqb : X -> X -> bool.
  Variable spec : forall x y, reflect (x = y) (eqb x y).

  Definition option_eqb (A B : option X) :=
    match A,B with
    | None,None => true
    | Some x, Some y => eqb x y
    | _,_ => false
    end.

  Lemma option_eqb_spec A B : reflect (A = B) (option_eqb A B).
  Proof using spec.
    destruct A, B; try now econstructor. cbn.
    destruct (spec x x0); econstructor; congruence.
  Qed.
End option_eqb.

Section int.

  Variable X:Type.
  Context {HX : encodable X}.

  Global Instance term_option_eqb : computableTime' (@option_eqb X)
                                                    (fun eqb eqbT => (1, fun a _ => (1,fun b _ => (match a,b with
                                                                                            Some a, Some b => callTime2 eqbT a b + 10
                                                                                          | _,_ => 8 end,tt)))). cbn.
  Proof.
    extract. solverec.
  Qed.

  Global Instance eqbOption f `{eqbClass (X:=X) f}:
    eqbClass (option_eqb f).
  Proof.
    intros ? ?. eapply option_eqb_spec. all:eauto using eqb_spec.
  Qed.

  Global Instance eqbComp_Option `{H:eqbCompT X (R:=HX)}:
    eqbCompT (option X).
  Proof.
    evar (c:nat). exists c. unfold option_eqb. 
    unfold enc;cbn.
    change (eqb0) with (eqb (X:=X)).
    extract. unfold eqb,eqbTime.
    recRel_prettify2. easy.
    [c]:exact (c__eqbComp X + 6).
    all:set (f:=enc (X:=option X)); unfold enc in f;subst f;cbn [size].
    all:unfold c. all:nia. 
  Qed.

End int.

Definition isSome {T} (u : option T) := match u with Some _ => true | _ => false end.

#[global]
Instance term_isSome {T} `{encodable T} : computable (@isSome T).
Proof.
  extract.
Qed.


Lemma size_option X `{encodable X} (l:option X):
  size (enc l) = match l with Some x => size (enc x) + 5 | _ => 3 end.
Proof.
  unfold enc at 1.
  destruct l. all:cbn; nia.
Qed.
