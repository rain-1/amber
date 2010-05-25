(%
 % rowl - generation 1
 % Copyright (C) 2010 nineties
 %
 % $Id: eval.rl 2010-05-24 01:47:50 nineties $
 %);

include(stddef,code);
export(init_evaluator, assign, deref, check_arity, eval_sexp);

symbol_map: NULL; (% (symbol name, scope id) -> symbol object %);

scopeid: 0;
scopeid_stack: NULL;

(% p0: (symbol name, scope id) %);
symbol_hash: (p0) {
    return strhash(p0[0])*3 + p0[1];
};

symbol_equal: (p0, p1) {
    if (p0[1] != p1[1]) { return FALSE; };
    return streq(p0[0], p1[0]);
};

scope_push: () {
    scopeid = scopeid + 1;
    vec_pushback(scopeid_stack, scopeid);
};

scope_pop: () {
    vec_popback(scopeid_stack);
};


(% p0: symbol name, p1: value %);
assign: (p0, p1) {
    allocate(1);
    x0 = vec_at(scopeid_stack, vec_size(scopeid_stack)-1);
    map_add(symbol_map, mktup2(p0, x0), p1);
};

(% p0: symbol object %);
deref: (p0) {
    allocate(4);
    x0 = vec_size(scopeid_stack)-1;
    x3 = sym_name(p0);
    while (x0 >= 0) {
        x1 = vec_at(scopeid_stack, x0); (% scopeid-id %);
        x2 = map_find(symbol_map, mktup2(x3, x1));
        if (x2 != NULL) { return x2; };
        x0 = x0 - 1;
    };
    return p0;
};

check_arity: (p0, p1, p2) {
    if (length(p0) != p1) {
        fputs(stderr, "ERROR '");
        fputs(stderr, p2);
        fputs(stderr, "': required ");
        fputi(stderr, p1);
        fputi(stderr, " arguments");
        exit(1);
    }
};

eval_args: (p0) {
    if (p0 == nil_sym) { return nil_sym; };
    return mkcons(eval_sexp(car(p0)), eval_args(cdr(p0)));
};

eval_cons: (p0) {
    allocate(2);
    x0 = car(p0);
    if (sym_p(x0) == nil_sym) { goto &eval_cons_error; };
    x1 = eval_sexp(x0);
    if (x1 == var_sym)   { return eval_var(cdr(p0)); };
    if (x1 == set_sym)   { return eval_set(cdr(p0)); };
    if (x1 == quote_sym) { return eval_quote(cdr(p0)); };
    if (x1 == if_sym)    { return eval_if(cdr(p0)); };
    if (x1 == cond_sym)  { return eval_cond(cdr(p0)); };
    if (x1 == while_sym) { return eval_while(cdr(p0)); };
    if (x1 == do_sym)    { return eval_do(cdr(p0)); };
    if (x1 == nil_sym)   { goto &eval_cons_error; };
    if (prim_p(x1) != nil_sym)      { return (prim_funptr(x1))(eval_args(cdr(p0))); };
    return nil_sym;
label eval_cons_error;
    fputs(stderr, "ERROR: invalid application of '");
    pp_sexp(stderr, car(p0));
    fputs(stderr, "'\n");
    exit(1);
};

(% (var <id> <value>) %);
eval_var: (p0) {
    allocate(2);
    check_arity(p0, 2, "var");
    x0 = car(p0);
    x1 = eval_sexp(car(cdr(p0)));
    sym_set(x0, x1);
    assign(sym_name(x0), x0);
    return x0;
};

eval_set: (p0) {
    allocate(2);
    check_arity(p0, 2, "set");
    x0 = deref(car(p0));
    x1 = eval_sexp(car(cdr(p0)));
    if (sym_value(x0) == NULL) {
        fputs(stderr, "ERROR 'eval_set': undefined variable '");
        fputs(stderr, sym_name(x0));
        fputs(stderr, "'\n");
        exit(1);
    };
    sym_set(x0, x1);
    return x0;
};

eval_quote: (p0) {
    check_arity(p0, 1, "quote");
    return car(p0);
};

(% p0 : (cond ifthen ifelse) %);
eval_if: (p0) {
    allocate(2);
    check_arity(p0, 3, "if");
    x0 = eval_sexp(car(p0));
    p0 = cdr(p0);
    if (x0 != nil_sym)  {
        scope_push();
        x1 = eval_sexp(car(p0));
        scope_pop();
        return x1;
    };
    scope_push();
    x1 = eval_sexp(car(cdr(p0)));
    scope_pop();
    return x1;
};

eval_cond: (p0) {
    allocate(1);
    while (p0 != nil_sym) {
        x0 = car(p0);
        check_arity(x0, 2, "cond");
        if (eval_sexp(car(x0)) != nil_sym) {
            return eval_sexp(car(cdr(x0)));
        };
        p0 = cdr(p0);
    };
    fputs(stderr, "ERROR 'eval_cond': any condition was not met\n");
    exit(1);
};

(% p0: (cond body) %);
eval_while: (p0) {
    allocate(3);
    check_arity(p0, 2, "while");
    x0 = car(p0); (% condition %);
    x1 = car(cdr(p0)); (% body %);
    x2 = eval_sexp(x0);
    scope_push();
    while (x2 != nil_sym) {
        eval_sexp(x1);
        x2 = eval_sexp(x0);
    };
    scope_pop();
    if (x2 != nil_sym) {
        fputs(stderr, "ERROR 'while': conditional expression could not evaluated to true/false\n");
        exit(1);
    };
    return nil_sym;
};

eval_do: (p0) {
    allocate(1);
    while (p0 != nil_sym) {
        x0 = eval_sexp(car(p0));
        p0 = cdr(p0);
    };
    return x0;
};

eval_sexp: (p0) {
    allocate(2);
    x0 = p0[0]; (% node code %);
    if (x0 == NODE_CONS)   { return eval_cons(p0); };
    if (x0 == NODE_SYMBOL) {
        x1 = deref(p0);
        if (sym_value(x1) != NULL) {
            return eval_sexp(sym_value(x1));
        };
        return x1;
    };
    return p0;
};

init_evaluator: () {
    symbol_map = mkmap(&symbol_hash, &symbol_equal, 100);
    scopeid_stack = mkvec(0);
    scope_push(); (% global scope %);
};
