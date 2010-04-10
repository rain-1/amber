(%
 % rowl - generation 1
 % Copyright (C) 2010 nineties
 %
 % $Id: pprint.rl 2010-04-10 12:36:28 nineties $
 %);

include(stddef,code);

export(put_prog, put_item, put_type, put_tyscheme);

ppfuncs: [put_prog, put_integer, put_string, put_dontcare, put_identifier,
    put_array, put_tuple, put_code, put_decl, put_lambda, put_subsop, put_codeop, put_unexpr,
    put_binexpr, put_assign, put_export, put_import, put_external, put_ret, put_retval,
    put_syscall, put_field, put_fieldref, put_typedecl, put_variant, put_unit, put_typedexpr,
    put_if, put_ifelse, put_sarray, put_cast, put_new, put_while, put_for, put_newarray
];

(% priority of expressions %);
PRI_PRIMARY        => 0;
PRI_POSTFIX        => 1;
PRI_ELSE           => 2;
PRI_PREFIX         => 3;
PRI_MULTIPLICATIVE => 4;
PRI_ADDITIVE       => 5;
PRI_SHIFT          => 6;
PRI_RELATIONAL     => 7;
PRI_EQUALITY       => 8;
PRI_AND            => 9;
PRI_XOR            => 10;
PRI_OR             => 13;
PRI_SEQAND         => 14;
PRI_SEQOR          => 15;
PRI_ASSIGNMENT     => 16;
PRI_FIELD          => 16;
PRI_TYPEDEXPR      => 17;
PRI_COMMAND        => 18;
PRI_DECLARATION    => 19;
PRI_REWRITE        => 20;
PRI_TYPEDECL       => 21;
PRI_EXTERNAL       => 22;


priority: [0, 0, 0, 0, 0, 0, 0, 0, 19, 1, 1, 1, 3, 0, 16, 22, 18, 18, 18, 16, 1, 21, 0, 0, 17
, 0, 17, 18, 18, 0, 0, 0, 18, 18, 0
];
binexpr_priority: [0, 5, 5, 4, 4, 4, 13, 10, 9, 6, 6, 8, 8, 7, 7, 7, 7, 15, 14];

get_priority: (p0) {
    if (p0[0] == NODE_BINEXPR) {
        return binexpr_priority[p0[2]];
    };
    return priority[p0[0]];
};

indent_depth : 0;
put_indent: (p0) {
    allocate(1);
    x0 = 0;
    while (x0 < indent_depth) {
        fputc(p0, ' ');
        x0 = x0 + 1;
    };
};

(% p0: output channel p1: item %);
put_item: (p0, p1) {
    return ppfuncs[p1[0]](p0, p1, 0);
};

(% p0: output channel, p1: item, p2: priority %);
put_subitem: (p0, p1, p2) {
    allocate(2);
    x0 = get_priority(p1);
    if (x0 > p2) { fputc(p0, '('); };
    put_item(p0, p1);
    if (x0 > p2) { fputc(p0, ')'); };
};

(% p0: output channel, p1: program %);
put_prog: (p0, p1) {
    allocate(1);
    indent_depth = 0;
    x0 = p1[1];
    while (x0 != NULL) {
        put_item(p0, ls_value(x0));
        fputs(p0, ";\n");
        x0 = ls_next(x0);
    };
    indent_depth = 0;
};

put_integer: (p0, p1) {
    fputi(p0, p1[3]);
};

put_string: (p0, p1) {
    fputc(p0, '"');
    fputs(p0, p1[2]);
    fputc(p0, '"');
};

put_dontcare: (p0, p1) {
    fputc(p0, '_');
};

put_identifier: (p0, p1) {
    fputs(p0, p1[2]);
};

put_symbol: (p0, p1) {
    fputs(p0, p1[2]);
};

put_array: (p0, p1) {
    allocate(3);
    fputc(p0, '[');
    x0 = 0;
    x1 = p1[2];
    while (x0 < x1) {
        x2 = p1[3];
        put_item(p0, x2[x0]);
        if (x0 < x1 - 1) {
            fputc(p0, ',');
        };
        x0 = x0 + 1;
    };
    fputc(p0, ']');
};

put_code: (p0, p1) {
    allocate(1);

    x0 = p1[2];

    if (x0 == NULL) {
        fputs(p0, "{}");
        return;
    };

    fputc(p0, '{');
    indent_depth = indent_depth + 4;
    while (x0 != NULL) {
        fputc(p0, '\n');
        put_indent(p0);
        put_item(p0, ls_value(x0));
        fputc(p0, ';');
        x0 = ls_next(x0);
    };
    indent_depth = indent_depth - 4;

    fputc(p0, '\n');
    put_indent(p0);
    fputc(p0, '}');
};

put_tuple: (p0, p1) {
    allocate(3);
    fputc(p0, '(');
    x0 = 0;
    x1 = p1[2];
    while (x0 < x1) {
        x2 = p1[3];
        put_item(p0, x2[x0]);
        if (x0 < x1 - 1) {
            fputc(p0, ',');
        };
        x0 = x0 + 1;
    };
    fputc(p0, ')');
};

put_pattern: (p0, p1) {
    allocate(2);
    fputc(p0, '(');
    fputs(p0, p1[1]);
    x0 = 0;
    x1 = p1[2];
    while (x0 < x1) {
        fputc(p0, ' ');
        put_subitem(p0, p1[x0+3], PRI_PRIMARY);
        x0 = x0 + 1;
    };
    fputc(p0, ')');
};

put_decl: (p0, p1) {
    put_subitem(p0, p1[2], PRI_COMMAND);
    fputc(p0, ':');
    put_subitem(p0, p1[3], PRI_DECLARATION);
};

put_lambda: (p0, p1) {
    put_subitem(p0, p1[2], PRI_PRIMARY);
    put_subitem(p0, p1[3], PRI_PRIMARY);
};

put_subsop: (p0, p1) {
    put_subitem(p0, p1[2], PRI_POSTFIX);
    fputc(p0, '[');
    put_subitem(p0, p1[3], PRI_PRIMARY);
    fputc(p0, ']');
};

put_codeop: (p0, p1) {
    put_subitem(p0, p1[2], PRI_POSTFIX);
    put_subitem(p0, p1[3], PRI_PRIMARY);
};

unop_string: ["+", "-", "~", "!", "&", "*", "++", "--", "++", "--"];
unop_arg_priority: [PRI_POSTFIX, PRI_POSTFIX, PRI_POSTFIX, PRI_POSTFIX, PRI_POSTFIX,
    PRI_POSTFIX, PRI_POSTFIX, PRI_POSTFIX, PRI_POSTFIX, PRI_POSTFIX];

binop_string: ["", "+", "-", "*", "/", "%", "|", "^", "&", "<<", ">>", "==", "!=", "<", ">",
    "<=", ">=", "||", "&&"];
binop_lhs_priority: [0, PRI_ADDITIVE, PRI_ADDITIVE, PRI_MULTIPLICATIVE, PRI_MULTIPLICATIVE,
    PRI_MULTIPLICATIVE, PRI_OR, PRI_XOR, PRI_AND, PRI_SHIFT, PRI_EQUALITY, PRI_EQUALITY,
    PRI_RELATIONAL, PRI_RELATIONAL, PRI_RELATIONAL, PRI_RELATIONAL, PRI_SEQOR, PRI_SEQAND];
binop_rhs_priority: [0, PRI_MULTIPLICATIVE, PRI_MULTIPLICATIVE, PRI_PREFIX, PRI_PREFIX,
    PRI_PREFIX, PRI_XOR, PRI_AND, PRI_EQUALITY, PRI_ADDITIVE, PRI_ADDITIVE, PRI_RELATIONAL,
    PRI_RELATIONAL, PRI_SHIFT, PRI_SHIFT, PRI_SHIFT, PRI_SHIFT, PRI_SEQAND, PRI_OR];


put_unexpr: (p0, p1) {
    allocate(1);
    x0 = p1[2]; (% operator %);
    if (x0 == UNOP_POSTINCR) {
        put_subitem(p0, p1[3], unop_arg_priority[x0]);
        fputs(p0, unop_string[x0]);
        return;
    };
    if (x0 == UNOP_POSTDECR) {
        put_subitem(p0, p1[3], unop_arg_priority[x0]);
        fputs(p0, unop_string[x0]);
        return;
    };
    fputs(p0, unop_string[x0]);
    put_subitem(p0, p1[3], unop_arg_priority[x0]);
};

put_binexpr: (p0, p1) {
    allocate(1);
    x0 = p1[2]; (% operator %);
    put_subitem(p0, p1[3], binop_lhs_priority[x0]);
    fputc(p0, ' ');
    fputs(p0, binop_string[x0]);
    fputc(p0, ' ');
    put_subitem(p0, p1[4], binop_rhs_priority[x0]);
};

put_assign: (p0, p1) {
    allocate(1);
    x0 = p1[2]; (% operator %);
    put_subitem(p0, p1[3], PRI_SEQOR);
    fputc(p0, ' ');
    fputs(p0, binop_string[x0]);
    fputs(p0, "= ");
    put_subitem(p0, p1[4], PRI_ASSIGNMENT);
};

put_export: (p0, p1) {
    fputs(p0, "export ");
    put_subitem(p0, p1[1], PRI_TYPEDECL);
};

put_import: (p0, p1) {
    fputs(p0, "import ");
    fputs(p0, p1[1]);
};

put_external: (p0, p1) {
    fputs(p0, "external ");
    put_subitem(p0, p1[1], PRI_TYPEDEXPR);
};

put_ret: (p0, p1) {
    fputs(p0, "return");
};

put_retval: (p0, p1) {
    fputs(p0, "return ");
    put_subitem(p0, p1[2], PRI_ASSIGNMENT);
};

put_syscall: (p0, p1) {
    fputs(p0, "syscall");
    put_subitem(p0, p1[2], PRI_PRIMARY);
};

put_field: (p0, p1) {
    put_item(p0, p1[2]);
    putc(p0, ':');
    put_item(p0, p1[3]);
};

put_fieldref: (p0, p1) {
    put_subitem(p0, p1[2], PRI_PRIMARY);
    fputc(p0, '.');
    fputs(p0, p1[3]);
};

(% p1: (constructor name, id, arg type) %);
put_variant_row: (p0, p1) {
    fputs(p0, p1[0]);
    if (p1[2] != NULL) {
        fputc(p0, ' ');
        put_type(p0, p1[2]);
    };
};

put_typedecl: (p0, p1) {
    allocate(1);
    fputs(p0, "type ");
    fputs(p0, p1[1]);
    if (p1[2][0] == NODE_ABSTRACT_T) {
	return;
    };
    if (p1[2][0] != NODE_VARIANT_T) {
        fputs(p0, ": ");
        put_type(p0, p1[2]);
        return;
    };
    x0 = p1[2][2]; (% rows %);
    if (ls_next(x0) == NULL) {
        fputs(": ");
        put_variant_row(p0, ls_value(x0));
        return;
    };
    fputc(p0, '\n');
    indent_depth = indent_depth + 4;
    put_indent(p0);
    fputs(p0, ": ");
    put_variant_row(p0, ls_value(x0));
    x0 = ls_next(x0);
    while (x0 != NULL) {
        fputc(p0, '\n');
        put_indent(p0);
        fputs(p0, "| ");
        put_variant_row(p0, ls_value(x0));
        x0 = ls_next(x0);
    };
    fputc(p0, '\n');
    put_indent(p0);
    indent_depth = indent_depth - 4;
};

put_variant: (p0, p1) {
    fputs(p0, p1[2]);
    if (p1[4] != NULL) {
        fputc(p0, ' ');
        put_subitem(p0, p1[4], PRI_PRIMARY);
    };
};

put_unit: (p0, p1) {
    fputs(p0, "()");
};

put_typedexpr: (p0, p1) {
    put_subitem(p0, p1[2], PRI_ASSIGNMENT);
    fputc(p0, '@');
    put_type(p0, p1[1]);
};

put_if: (p0, p1) {
    fputs(p0, "if (");
    put_item(p0, p1[2]);
    fputs(p0, ") ");
    put_item(p0, p1[3]);
};

put_ifelse: (p0, p1) {
    fputs(p0, "if (");
    put_item(p0, p1[2]);
    fputs(p0, ") ");
    put_item(p0, p1[3]);
    fputs(p0, " else ");
    put_item(p0, p1[4]);
};

put_sarray: (p0, p1) {
    fputs(p0, "static_array(");
    put_item(p0, p1[2]);
    fputc(p0, ',');
    put_item(p0, p1[3]);
    fputc(p0, ')');
};

put_cast: (p0, p1) {
    fputs(p0, "cast(");
    put_type(p0, p1[1]);
    fputs(p0, ") ");
    put_subitem(p0, p1[2], PRI_PRIMARY);
};

put_new: (p0, p1) {
    fputs(p0, "new ");
    put_subitem(p0, p1[2], PRI_PRIMARY);
};

put_while: (p0, p1) {
    fputs(p0, "while(");
    put_item(p0, p1[2]);
    fputs(p0, ") ");
    put_item(p0, p1[3]);
};

put_for: (p0, p1) {
    fputs(p0, "for(");
    put_item(p0, p1[2]);
    fputc(p0, ',');
    put_item(p0, p1[3]);
    fputc(p0, ',');
    put_item(p0, p1[4]);
    fputs(p0, ") ");
    put_item(p0, p1[5]);
};

put_newarray: (p0, p1) {
    fputs(p0, "new_array(");
    put_item(p0, p1[2]);
    fputs(p0, ") ");
    put_subitem(p0, p1[3], PRI_PRIMARY);
};

pptype_funcs: [ put_unit_t, put_char_t, put_int_t, put_float_t, put_double_t,
    put_pointer_t, put_array_t, put_tuple_t, put_lambda_t, put_tyvar, put_namedty,
    put_variant_t, put_void_t, put_sarray_t, put_abstract_t
];

put_type: (p0, p1) {
    allocate(1);
    x0 = pptype_funcs[p1[0]];
    x0(p0, p1);
};

put_unit_t: (p0, p1) {
    fputs(p0, "()");
};

put_char_t: (p0, p1) {
    fputs(p0, "char");
};

put_int_t: (p0, p1) {
    fputs(p0, "int");
};

put_float_t: (p0, p1) {
    fputs(p0, "float");
};

put_double_t: (p0, p1) {
    fputs(p0, "double");
};

put_void_t: (p0, p1) {
    fputs(p0, "void");
};

put_pointer_t: (p0, p1) {
    put_type(p0, p1[POINTER_T_BASE]);
    fputc(p0, '*');
};

put_array_t: (p0, p1) {
    put_type(p0, p1[ARRAY_T_ELEMENT]);
    fputc(p0, '[');
    fputc(p0, ']');
};

put_code_t: (p0, p1) {
    fputc(p0, '{');
    put_type(p0, p1[1]);
    fputc(p0, '}');
};

put_tuple_t: (p0, p1) {
    allocate(2);
    fputc(p0, '(');
    x0 = p1[TUPLE_T_LENGTH]; (% length %);
    x1 = 0;
    while (x1 < x0) {
        put_type(p0, (p1[TUPLE_T_ELEMENTS])[x1]);
        x1 = x1 + 1;
        if (x1 < x0 ) { fputc(p0, ','); };
    };
    fputc(p0, ')');
};

put_lambda_t: (p0, p1) {
    put_type(p0, p1[1]);
    fputs(p0, " -> ");
    put_type(p0, p1[2]);
};

put_tyvar: (p0, p1) {
    fputc(p0, 't');
    fputi(p0, p1[1]);
};

put_namedty: (p0, p1) {
    fputs(p0, "<");
    fputs(p0, p1[1]);
    fputs(p0, ">");
    put_type(p0, p1[2]);
};

put_variant_t: (p0, p1) {
    fputs(p0, p1[1]);
};

put_sarray_t: (p0, p1) {
    fputs(stderr, "ERROR: not implemented\n");
    exit(1);
};

put_abstract_t: (p0, p1) {
    fputc(p0, '*');
};

put_tyscheme: (p0, p1) {
    allocate(1);
    x0 = p1[0]; (% id set %);
    if (x0 == NULL) { return put_type(p0, p1[1]); };
    while (x0 != NULL) {
        fputc(p0, 't');
        fputi(p0, ls_value(x0));
        x0 = ls_next(x0);
        if (x0 != NULL) { fputc(p0, ' '); };
    };
    fputc(p0, '.');
    put_type(p0, p1[1]);
};

