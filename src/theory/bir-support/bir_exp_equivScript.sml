open HolKernel Parse boolLib bossLib;

(* From /core: *)
open bir_immTheory bir_expTheory bir_exp_immTheory
     bir_typing_expTheory bir_valuesTheory;

(* From /theories: *)
open bir_bool_expTheory;

open HolBACoreSimps;

val _ = new_theory "bir_exp_equiv";

(* If BIR And evaluates to BIR True, both conjuncts must have been
 * BIR True, assuming both conjuncts are of the same Immtype. *)
val bir_exp_and_true = store_thm("bir_exp_and_true",
  ``!b b'.
      (type_of_bir_imm b = type_of_bir_imm b') ==>
      (bir_bin_exp BIExp_And b' b = Imm1 1w) ==>
      ((b' = Imm1 1w) /\ (b = Imm1 1w))``,

Cases >> Cases >- (
  RW_TAC (std_ss++wordsLib.WORD_ss++wordsLib.WORD_BIT_EQ_ss)
         [bir_bin_exp_REWRS, bir_bin_exp_GET_OPER_def] >>
  METIS_TAC []
) >>
SIMP_TAC (std_ss++holBACore_ss) [type_of_bir_imm_def,
                                 bir_bin_exp_REWRS,
                                 bir_bin_exp_GET_OPER_def]
);

(* BIR And is equivalent to HOL conjunction of two propositions. *)
val bir_and_equiv = store_thm("bir_and_equiv",
  ``!env ex1 ex2.
      (bir_eval_exp ex1 env = bir_val_true) /\
        (bir_eval_exp ex2 env = bir_val_true) <=>
      (bir_eval_exp (BExp_BinExp BIExp_And ex1 ex2) env =
         bir_val_true
      )``,

REPEAT GEN_TAC >>
EQ_TAC >| [
  REPEAT STRIP_TAC >>
  ASM_SIMP_TAC (std_ss++wordsLib.WORD_ss++wordsLib.WORD_BIT_EQ_ss)
               [bir_eval_exp_def, bir_val_true_def,
                bir_eval_bin_exp_def, bir_bin_exp_def,
                bir_bin_exp_GET_OPER_def],

  REPEAT STRIP_TAC >> (
    FULL_SIMP_TAC std_ss [bir_eval_exp_def, bir_val_true_def] >>
    Cases_on `(bir_eval_exp ex1 env)` >>
    Cases_on `(bir_eval_exp ex2 env)` >> (
      FULL_SIMP_TAC (std_ss++holBACore_ss)
                    [bir_eval_bin_exp_REWRS]
    ) >>
    rename1 `type_of_bir_imm b <> type_of_bir_imm b'` >>
    Cases_on `type_of_bir_imm b <> type_of_bir_imm b'` >> (
      FULL_SIMP_TAC (std_ss++holBACore_ss) []
    ) >>
    METIS_TAC [bir_exp_and_true]
  )
]
);

(* A BIR disjunction implies the equivalent HOL disjunction. *)
val bir_disj_impl = store_thm("bir_disj_impl",
  ``!env ex1 ex2.
      ((bir_eval_exp (BExp_BinExp BIExp_Or ex1 ex2) env =
        bir_val_true) ==>
      ((bir_eval_exp ex1 env = bir_val_true) \/
       (bir_eval_exp ex2 env = bir_val_true))
      )``,

REPEAT STRIP_TAC >>
FULL_SIMP_TAC (std_ss++holBACore_ss++wordsLib.WORD_ss++
               wordsLib.WORD_BIT_EQ_ss)
              [bir_val_true_def, bir_eval_exp_def,
               bir_eval_bin_exp_def, bir_bin_exp_def,
               bir_bin_exp_GET_OPER_def, type_of_bir_imm_def] >>
Cases_on `bir_eval_exp ex1 env` >>
Cases_on `bir_eval_exp ex2 env` >> (
  FULL_SIMP_TAC (std_ss++holBACore_ss)
                [bir_eval_bin_exp_def]
) >>
Cases_on `type_of_bir_imm b <> type_of_bir_imm b'` >> (
  FULL_SIMP_TAC (std_ss++holBACore_ss)
                [bir_eval_bin_exp_def]
) >>
Cases_on `b` >> Cases_on `b'` >> (
  FULL_SIMP_TAC (std_ss++holBACore_ss)
                [bir_eval_bin_exp_def] >>
  blastLib.FULL_BBLAST_TAC
)
);

(* BIR negation is equivalent to HOL negation, under the
 * circumstances of the expression being Boolean and all its
 * variables being initialised. *)
val bir_not_equiv = store_thm("bir_not_equiv",
  ``!env ex.
      bir_is_bool_exp_env env ex ==>
      (~(bir_eval_exp ex env = bir_val_true) <=>
        (bir_eval_exp (BExp_UnaryExp BIExp_Not ex) env =
          bir_val_true)
      )``,

REPEAT STRIP_TAC >>
IMP_RES_TAC bir_bool_values >>
FULL_SIMP_TAC (std_ss++holBACore_ss++wordsLib.WORD_ss++
               wordsLib.WORD_BIT_EQ_ss)
              [bir_eval_exp_def, bir_val_true_def,
               bir_val_false_def, bir_eval_unary_exp_def,
               bir_unary_exp_def, bir_unary_exp_GET_OPER_def]
);
val bir_not_equiv_alt = store_thm("bir_not_equiv_alt",
  ``!ex env.
    bir_is_bool_exp_env env ex ==>
    ((bir_eval_unary_exp BIExp_Not (bir_eval_exp ex env) 
       = bir_val_true) <=>
    ((bir_eval_exp ex env) = bir_val_false))
  ``,

REPEAT STRIP_TAC >>
IMP_RES_TAC bir_bool_values >> (
  IMP_RES_TAC bir_not_equiv >>
  FULL_SIMP_TAC (std_ss++holBACore_ss) [] >>
  REV_FULL_SIMP_TAC std_ss [] >>
  FULL_SIMP_TAC std_ss [bir_val_TF_dist]
)
);

(* If the BIR negation of a value evaluates to BIR True, then said
 * value itself must evaluate to BIR False. *)
val bir_neg_val_true = store_thm("bir_neg_val_true",
  ``!env ex.
      (bir_eval_exp (BExp_UnaryExp BIExp_Not ex) env =
        bir_val_true) <=>
      (bir_eval_exp ex env = bir_val_false)``,

REPEAT STRIP_TAC >>
FULL_SIMP_TAC std_ss [bir_eval_exp_def,
                      bir_val_true_def, bir_val_false_def] >>
Cases_on `(bir_eval_exp ex env)` >| [
  FULL_SIMP_TAC (std_ss++holBACore_ss) [],

  Cases_on `b` >> (
    FULL_SIMP_TAC (std_ss++holBACore_ss) [] >>
    SIMP_TAC (bool_ss++wordsLib.WORD_ss++wordsLib.WORD_BIT_EQ_ss) []
  ),

  FULL_SIMP_TAC (std_ss++holBACore_ss) []
]
);

val bir_disj1_false = store_thm("bir_disj1_false",
  ``!ex env.
      (bir_eval_bin_exp BIExp_Or bir_val_false (bir_eval_exp ex env)
        = bir_val_true) ==>
      (bir_eval_exp ex env = bir_val_true)``,

REPEAT STRIP_TAC >>
FULL_SIMP_TAC (std_ss++holBACore_ss) [bir_val_true_def,
                                      bir_val_false_def] >>
Cases_on `(bir_eval_exp ex env)` >> (
  FULL_SIMP_TAC (std_ss++holBACore_ss) []
) >>
Cases_on `type_of_bir_imm b` >> (
  FULL_SIMP_TAC (std_ss++holBACore_ss) []
) >>
Cases_on `b` >> (
  FULL_SIMP_TAC (std_ss++holBACore_ss) [bir_bin_exp_def]
) >>
blastLib.FULL_BBLAST_TAC
);

(* BIR disjunction is equivalent to HOL disjunction provided the
 * variables are initialised and the subexpressions are Boolean. *)
val bir_disj_equiv = store_thm("bir_disj_equiv",
  ``!env ex1 ex2.
    bir_is_bool_exp_env env ex1 ==>
    bir_is_bool_exp_env env ex2 ==>
    (((bir_eval_exp ex1 env = bir_val_true) \/
      (bir_eval_exp ex2 env = bir_val_true)
     ) <=>
      (bir_eval_exp (BExp_BinExp BIExp_Or ex1 ex2) env =
         bir_val_true
      )
    )
  ``,

REPEAT STRIP_TAC >>
IMP_RES_TAC bir_bool_values >>
FULL_SIMP_TAC (std_ss++holBACore_ss++wordsLib.WORD_ss++
               wordsLib.WORD_BIT_EQ_ss)
              [bir_val_false_def, bir_val_true_def,
               bir_eval_exp_def, bir_eval_bin_exp_def,
               bir_bin_exp_def, bir_bin_exp_GET_OPER_def,
               type_of_bir_imm_def]
);

(* BIR (~a \/ b) is equivalent to HOL material conditional
 * a ==> b  provided the variables in a and b are initialised and
 * the subexpressions are Boolean. *)
val bir_vars_init_not = prove(
  ``!ex. (bir_vars_of_exp ex) =
         (bir_vars_of_exp (BExp_UnaryExp BIExp_Not ex))
  ``,
  SIMP_TAC std_ss [bir_vars_of_exp_def]
);
val bir_is_bool_exp_not = prove(
  ``!ex. (bir_is_bool_exp ex) =
         (bir_is_bool_exp (BExp_UnaryExp BIExp_Not ex))
  ``,
  SIMP_TAC std_ss [bir_is_bool_exp_def, type_of_bir_exp_def] >>
  Cases_on `type_of_bir_exp ex` >| [
    SIMP_TAC std_ss [],
    rename1 `SOME x` >>
    Cases_on `x` >| [
      rename1 `BType_Imm b` >>
      Cases_on `b` >> (
        SIMP_TAC (std_ss++holBACore_ss)
                 [bir_type_is_Imm_def]
      ),

      SIMP_TAC (std_ss++holBACore_ss) [bir_type_is_Imm_def]
    ]
  ]
);
val bir_impl_equiv = store_thm("bir_impl_equiv",
  ``!env ex1 ex2.
    bir_is_bool_exp_env env ex1 ==>
    bir_is_bool_exp_env env ex2 ==>
    (((bir_eval_exp ex1 env = bir_val_true) ==>
      (bir_eval_exp ex2 env = bir_val_true)
     ) <=> (bir_eval_exp (BExp_BinExp BIExp_Or
                                       (BExp_UnaryExp BIExp_Not ex1)
                                       ex2
                          ) env = bir_val_true
           )
    )
  ``,

METIS_TAC [bir_disj_equiv, bir_not_equiv, bir_is_bool_exp_env_def,
           bir_is_bool_exp_not,
           bir_vars_init_not]
);

val _ = export_theory();
