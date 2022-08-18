/* Please feel free to modify any content */

/* Definition section */
%{
    #include "compiler_hw_common.h" //Extern variables that communicate with lex
    // #define YYDEBUG 1
    // int yydebug = 1;

    extern int yylineno;
    extern int yylex();
    extern FILE *yyin;

    int yylex_destroy ();
    void yyerror (char const *s)
    {
        printf("error:%d: %s\n", yylineno, s);
    }

    struct element{
        int pos;
        int ival;
        float fval;
        char sval[20];
        int scope;
        char type;
        char var_name[20];   
    };

    struct element reg[100];

    int scopelevel = 0;
    int reg_count=0;

    char stack[20][20];
    int stack_idx = 0;

    extern int yylineno;
    extern int yylex();
    extern FILE *yyin;

    int print_type;
    char type;
    int tmp_pos;
    int label_idx=0;
    int tmp_assign_pos;
    int flag=0;
    int forloop_idx;
    int forloop=0;
    int notvar=0;
    int switch_start;
    int switchcase[100];
    char func_type[100];
    int func_type_idx=0;
    char ident_tmp[20];
    /* Used to generate code */
    /* As printf; the usage: CODEGEN("%d - %s\n", 100, "Hello world"); */
    /* We do not enforce the use of this macro */
    #define CODEGEN(...) \
        do { \
            for (int i = 0; i < g_indent_cnt; i++) { \
                fprintf(fout, "\t"); \
            } \
            fprintf(fout, __VA_ARGS__); \
        } while (0)

    /* Symbol table function - you can add new functions if needed. */
    /* parameters and return type can be changed */
    // static void create_symbol(/* ... */);
    // static void insert_symbol(/* ... */);
    // static void lookup_symbol(/* ... */);
    // static void dump_symbol(/* ... */);
    static void addtoreg(char *);
    static int findpos(char *);
    static int exist(char *);
    /* Global variables */
    bool g_has_error = false;
    FILE *fout = NULL;
    int g_indent_cnt = 0;
%}

//%error-verbose

/* Use variable or self-defined structure to represent
 * nonterminal and token type
 *  - you can add new fields if needed.
 */
%union {
    int i_val;
    float f_val;
    bool b_val;
    char *s_val;
    /* ... */
}

/* Token without return */
%token VAR NEWLINE PACKAGE 
%token INT FLOAT BOOL STRING 
%token ASSIGN
%token ADD_ASSIGN SUB_ASSIGN MUL_ASSIGN QUO_ASSIGN REM_ASSIGN
%token IF ELSE FOR SWITCH CASE DEFAULT SEMICOLON COMMA COLON
%token PRINT PRINTLN RETURN FUNC 
%token LPAREN RPAREN LBRACE RBRACE LBRACK RBRACK 

%left LOR
%left LAND
%left GTR LSS GEQ LEQ EQL NEQ
%left ADD SUB
%left MUL QUO REM
%left INC DEC NOT

/* Token with return, which need to sepcify type */
%token <i_val> INT_LIT
%token <f_val> FLOAT_LIT
%token <b_val> BOOL_LIT
%token <s_val> STRING_LIT  
%token <s_val> IDENT
/* Nonterminal with return, which need to sepcify type */
%type <s_val> Type DeclarationStmt FunctionDeclStmt
%type <s_val> FuncOpen PrimaryExpr Operand Literal
%type <s_val> ConversionExpr  PrintStmt UnaryExpr Expression
%type <s_val> Multiplication Addition Comparison Logicand Logicor

/* Yacc will start at this nonterminal */
%start Program

/* Grammar section */
%%

Program
    : GlobalStatementList
;

GlobalStatementList 
    : GlobalStatementList GlobalStatement
    | GlobalStatement
;

GlobalStatement
    : PackageStmt NEWLINE
    | FunctionDeclStmt
    | NEWLINE
;


PackageStmt
    : PACKAGE IDENT 
;

FunctionDeclStmt 
    : FuncOpen  LPAREN ParameterList  RPAREN { func_type[func_type_idx++]=')'; func_type[func_type_idx++]=(type-97+65); 
                                        CODEGEN(".method public static %s(", ident_tmp); 
                                        for(int i=0;i<func_type_idx;i++)
                                            CODEGEN("%c", func_type[i]);
                                        CODEGEN("\n.limit stack 100\n"); CODEGEN(".limit locals 100\n");
    
                                        }Type LBRACE { scopelevel++; } StatementList { scopelevel--; } RBRACE { CODEGEN("  return\n"); forloop=0; CODEGEN(".end method\n"); }
    | FuncOpen  LPAREN ParameterList RPAREN LBRACE RBRACE 
    | FuncOpen  LPAREN RPAREN Type LBRACE StatementList RBRACE 
    | FuncOpen  LPAREN RPAREN LBRACE { reg_count=0; if(!strcmp(ident_tmp, "main")){ CODEGEN(".method public static %s([Ljava/lang/String;)V\n", ident_tmp);  
                                        CODEGEN(".limit stack 100\n"); CODEGEN(".limit locals 100\n"); } 
                                        else { CODEGEN(".method public static %s()V\n", ident_tmp); CODEGEN(".limit stack 100\n"); CODEGEN(".limit locals 100\n");}
                                scopelevel++; } StatementList { scopelevel--; } RBRACE    
                { if(forloop==1) CODEGEN("label_for_end_%d:\n", forloop_idx); CODEGEN("  return\n"); forloop=0; CODEGEN(".end method\n"); }
;

FuncOpen
    : FUNC IDENT { strcpy(ident_tmp, $2); }
    ; 
;
ParameterList
    : IDENT Type { if(type=='i' || type=='b') { func_type[func_type_idx]=('i'-97+65); func_type_idx++;}
                                        else if (type=='f') { func_type[func_type_idx]=('f'-97+65); func_type_idx++;}
                     addtoreg($2); } 
    | IDENT 
    | ParameterList COMMA IDENT Type { if(type=='i' || type=='b') { func_type[func_type_idx]=('i'-97+65); func_type_idx++;}
                                        else if (type=='f') { func_type[func_type_idx]=('f'-97+65); func_type_idx++;}
                                         addtoreg($3); } 
    | ParameterList COMMA Literal
;

ReturnStmt 
    : RETURN Expression { CODEGEN("  ireturn\n"); }
    | RETURN { CODEGEN("  return\n"); }
;

PrimaryExpr
    : Operand 
    //|IndexExpr 
    | ConversionExpr
;

Expression
    : UnaryExpr 
    | Multiplication
;

Multiplication
    : Expression MUL Expression { if(type == 'i') CODEGEN("  imul\n"); else CODEGEN("  fmul\n"); }
    | Expression QUO Expression { if(type == 'i') CODEGEN("  idiv\n"); else CODEGEN("  fdiv\n"); }
    | Expression REM Expression { CODEGEN("  irem\n"); if(type=='f') g_has_error=true; }
    | Addition
;

Addition
    : Expression ADD Expression { if(type == 'i') CODEGEN("  iadd\n"); else CODEGEN("  fadd\n"); }
    | Expression SUB Expression { if(type == 'i') CODEGEN("  isub\n"); else CODEGEN("  fsub\n"); }
    | Comparison
;

Comparison
    : Expression EQL Expression 
    | Expression NEQ Expression 
    | Expression LSS Expression 
    | Expression LEQ Expression 
    | Expression GTR Expression { if(type=='i')CODEGEN("  isub\n"); else CODEGEN("  fcmpl\n");CODEGEN("  ifgt label_%d\n",label_idx); CODEGEN("  iconst_0\n"); CODEGEN("  goto label_%d\n",label_idx+1); 
                        CODEGEN("label_%d:\n",label_idx); CODEGEN("  iconst_1\n"); 
                        CODEGEN("label_%d:\n",label_idx+1); if(forloop==1) CODEGEN("  ifeq label_for_end_%d\n", forloop_idx);
                        label_idx+=2;
                }
    | Expression GEQ Expression 
    | Logicand
;

Logicand
    : Expression LAND Expression { CODEGEN("  iand\n"); }
    | Logicor
;

Logicor
    :Expression LOR Expression { CODEGEN("  ior\n"); }
;

UnaryExpr
    : PrimaryExpr 
    | ADD UnaryExpr 
    | SUB UnaryExpr { if(type == 'i') CODEGEN("  ineg\n"); else CODEGEN("  fneg\n"); }
    | NOT UnaryExpr { CODEGEN("  iconst_1\n"); CODEGEN("  ixor\n"); }
;

Operand
    : Literal 
    | IDENT {   tmp_pos=findpos($1);  if(tmp_pos!=-1){if(type=='i' || type=='b') CODEGEN("  iload %d\n", tmp_pos); else if(type=='f') CODEGEN("  fload %d\n", tmp_pos);
                else if(type=='s') CODEGEN("  aload %d\n", tmp_pos);  } 
            }
    | LPAREN Expression RPAREN 
    | IDENT LPAREN RPAREN { CODEGEN("  invokestatic Main/%s()V\n", $1);  }
    | IDENT LPAREN {tmp_pos=findpos($1);  if(type=='i' || type=='b'){ if(!strcmp(ident_tmp, "main")) CODEGEN("  iload %d\n", tmp_pos+1); }else if(type=='f') CODEGEN("  fload %d\n", tmp_pos);
                else if(type=='s') CODEGEN("  aload %d\n", tmp_pos);   }  
                ParameterList RPAREN { CODEGEN("  invokestatic Main/%s(", $1); for(int i=0;i<func_type_idx;i++)
                                            CODEGEN("%c", func_type[i]); CODEGEN("\n"); }
;

Literal
    : INT_LIT   { if(tmp_assign_pos!=-1){ type = 'i'; print_type = 0; CODEGEN("  ldc %d\n", yylval.i_val); }}
    | FLOAT_LIT { type = 'f';print_type = 1; CODEGEN("  ldc %f\n", yylval.f_val); }
    | BOOL_LIT  { type = 'b';print_type = 2; if(yylval.b_val == true) CODEGEN("  iconst_1\n"); else CODEGEN("  iconst_0\n"); }
    | STRING_LIT { type = 's'; print_type = 3; CODEGEN("  ldc \"%s\"\n", yylval.s_val); }
;   

ConversionExpr
    : Type LPAREN Expression RPAREN { if(type=='f') {CODEGEN("  f2i\n"); type='i'; print_type=0;}else{ CODEGEN("  i2f\n"); type='f'; print_type=1;}}
;

Type
    : INT   { type = 'i'; }
    | FLOAT { type = 'f'; }
    | BOOL  { type = 'b'; }
    | STRING { type = 's'; }
;

Statement
    : DeclarationStmt NEWLINE 
    | SimpleStmt NEWLINE
    | Block
    | IfStmt
    | ForStmt 
    | SwitchStmt 
    | CaseStmt 
    | PrintStmt NEWLINE
    | ReturnStmt NEWLINE
    | NEWLINE
;

SimpleStmt
    : AssignmentStmt {flag=0;}
    | ExpressionStmt 
    | IncDecStmt
;

DeclarationStmt 
    : VAR IDENT Type { if(exist($2)==1) g_has_error=true; if(tmp_pos!=-1&&exist($2)==0){if(type=='i'){ CODEGEN("  ldc 0\n"); CODEGEN("  istore %d\n", reg_count); addtoreg($2); } 
                        else if(type=='f'){ CODEGEN("  ldc 0.0\n"); CODEGEN("  fstore %d\n", reg_count); addtoreg($2); }
                        else if(type=='b'){ CODEGEN("  istore %d\n", reg_count); addtoreg($2);}
                                            else { CODEGEN("  ldc \"\"\n"); CODEGEN("  astore %d\n", reg_count); addtoreg($2); }
    }
                    }
    | VAR IDENT Type ASSIGN Expression  {   if(type=='i'){ CODEGEN("  istore %d\n", reg_count); addtoreg($2); } 
                                            else if(type=='f'){ CODEGEN("  fstore %d\n", reg_count); addtoreg($2); }
                                            else if(type=='b'){ CODEGEN("  istore %d\n", reg_count); addtoreg($2); }
                                            else { CODEGEN("  astore %d\n", reg_count); addtoreg($2);}
                                        }
;

AssignmentStmt
    : IDENT {tmp_assign_pos=findpos($1); if(tmp_assign_pos!=-1){ if(type=='i' || type=='b') CODEGEN("  iload %d\n", tmp_assign_pos); else if(type=='f') CODEGEN("  fload %d\n", tmp_assign_pos);
                else if(type=='s') CODEGEN("  aload %d\n", tmp_assign_pos); }}
        ASSIGN Expression { if(tmp_assign_pos!=-1){if(print_type==0||type=='i') CODEGEN("  istore %d\n", tmp_assign_pos); else if(print_type==1||type=='f') CODEGEN("  fstore %d\n", tmp_assign_pos); 
                                        else if(print_type==2) CODEGEN("  istore %d\n", tmp_assign_pos); else CODEGEN("  astore %d\n", tmp_assign_pos);
        }}
    | Expression ADD_ASSIGN Expression  { if(tmp_pos!=-1){if(type == 'i') {CODEGEN("  iadd\n"); CODEGEN("  istore %d\n", tmp_pos); } else {CODEGEN("  fadd\n"); CODEGEN("  fstore %d\n", tmp_pos); }}}
    | Expression SUB_ASSIGN Expression  { if(type == 'i') {CODEGEN("  isub\n"); CODEGEN("  istore %d\n", tmp_pos); } else {CODEGEN("  fsub\n"); CODEGEN("  fstore %d\n", tmp_pos); }}
    | Expression MUL_ASSIGN Expression  { if(type == 'i') {CODEGEN("  imul\n"); CODEGEN("  istore %d\n", tmp_pos); } else {CODEGEN("  fmul\n"); CODEGEN("  fstore %d\n", tmp_pos); }}
    | Expression QUO_ASSIGN Expression  { if(type == 'i') {CODEGEN("  idiv\n"); CODEGEN("  istore %d\n", tmp_pos); } else {CODEGEN("  fdiv\n"); CODEGEN("  fstore %d\n", tmp_pos); }}
    | Expression REM_ASSIGN Expression  { CODEGEN("  irem\n"); CODEGEN("  istore %d\n", tmp_pos); }
;

ExpressionStmt
    : Expression
;

IncDecStmt
    : Expression INC   { if(type=='i'){CODEGEN("  ldc 1\n"); CODEGEN("  iadd\n"); CODEGEN("  istore %d\n", tmp_pos);} else {CODEGEN("  ldc 1.0\n"); CODEGEN("  fadd\n"); CODEGEN("  fstore %d\n", tmp_pos);} }
    | Expression DEC   { if(type=='i'){CODEGEN("  ldc 1\n"); CODEGEN("  isub\n"); CODEGEN("  istore %d\n", tmp_pos); if(forloop==1) CODEGEN("  goto label_for_start_%d\n", forloop_idx); } else {CODEGEN("  ldc 1.0\n"); CODEGEN("  fsub\n"); CODEGEN("  fstore %d\n", tmp_pos);} }
;

Block
    : LBRACE { scopelevel++; } StatementList {  scopelevel--; } RBRACE
;

StatementList
    : Statement StatementList
    | Statement
;

IfStmt
    : IF Condition Block ELSE IfStmt 
    | IF Condition Block ELSE Block
    | IF Condition Block 
;

Condition
    : Expression 
;

ForStmt
    : FOR {CODEGEN("label_for_start_%d:\n", label_idx); forloop_idx=label_idx; forloop=1; label_idx++;} Condition Block 
;

// ForClause 
//     :InitStmt SEMICOLON Condition SEMICOLON PostStmt
// ;

// InitStmt
//     : SimpleStmt
// ;

// PostStmt
//     : SimpleStmt
// ;

SwitchStmt
    : SWITCH Expression { CODEGEN("  goto label_switch_start_%d\n",label_idx); switch_start=label_idx;} Block { CODEGEN("label_switch_start_%d:\n", switch_start);
                                                                                                                CODEGEN("lookupswitch\n"); for(int i=switch_start;i<label_idx;i++){
                                                                                                                    if(i==label_idx-1) CODEGEN("  default: label_case_%d\n", i);
                                                                                                                    else CODEGEN("  %d: label_case_%d\n", switchcase[i], i);
                                                                                                                }CODEGEN("label_switch_end_%d:\n", switch_start); }
;

CaseStmt
    : CASE INT_LIT { CODEGEN("label_case_%d:\n", label_idx); switchcase[label_idx]=yylval.i_val; label_idx++; } COLON Block { CODEGEN("  goto label_switch_end_%d\n", switch_start); }
    | DEFAULT { CODEGEN("label_case_%d:\n", label_idx); label_idx++; } COLON Block { CODEGEN("  goto label_switch_end_%d\n", switch_start); }
;

PrintStmt 
    : PRINT LPAREN Expression RPAREN {if(type=='b'){  CODEGEN("  ifne label_%d\n",label_idx); CODEGEN("  ldc \"false\"\n"); CODEGEN("  goto label_%d\n",label_idx+1); 
                                                                CODEGEN("label_%d:\n",label_idx); CODEGEN("  ldc \"true\"\n"); 
                                                                CODEGEN("label_%d:\n",label_idx+1);
                                                                label_idx+=2;
                                            }
                                            CODEGEN("  getstatic java/lang/System/out Ljava/io/PrintStream;\n"); CODEGEN("  swap\n"); 
                                            if(type=='i')CODEGEN("  invokevirtual java/io/PrintStream/print(I)V\n"); 
                                            else if(type=='f')CODEGEN("  invokevirtual java/io/PrintStream/print(F)V\n");
                                        
                                            else CODEGEN("  invokevirtual java/io/PrintStream/print(Ljava/lang/String;)V\n"); }
    | PRINTLN  LPAREN Expression RPAREN { 
                                            if(type=='b'){  CODEGEN("  ifne label_%d\n",label_idx); CODEGEN("  ldc \"false\"\n"); CODEGEN("  goto label_%d\n",label_idx+1); 
                                                                CODEGEN("label_%d:\n",label_idx); CODEGEN("  ldc \"true\"\n"); 
                                                                CODEGEN("label_%d:\n",label_idx+1);
                                                                label_idx+=2;
                                                }
                                            CODEGEN("  getstatic java/lang/System/out Ljava/io/PrintStream;\n"); CODEGEN("  swap\n"); 
                                            if(type=='i')CODEGEN("  invokevirtual java/io/PrintStream/println(I)V\n"); 
                                            else if(type=='f')CODEGEN("  invokevirtual java/io/PrintStream/println(F)V\n");
                                        
                                            else CODEGEN("  invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V\n");
                                        }
;

%%

/* C code section */
int main(int argc, char *argv[])
{
    if (argc == 2) {
        yyin = fopen(argv[1], "r");
    } else {
        yyin = stdin;
    }
    if (!yyin) {
        printf("file `%s` doesn't exists or cannot be opened\n", argv[1]);
        exit(1);
    }

    /* Codegen output init */
    char *bytecode_filename = "hw3.j";
    fout = fopen(bytecode_filename, "w");
    CODEGEN(".source hw3.j\n");
    CODEGEN(".class public Main\n");
    CODEGEN(".super java/lang/Object\n");

    /* Symbol table init */
    // Add your code

    yylineno = 0;
    yyparse();

    /* Symbol table dump */
    // Add your code

	printf("Total lines: %d\n", yylineno);
    fclose(fout);
    fclose(yyin);

    if (g_has_error) {
        remove(bytecode_filename);
    }
    yylex_destroy();
    return 0;
}

// static void create_symbol() {
//     printf("> Create symbol table (scope level %d)\n", 0);
// }

// static void insert_symbol() {
//     printf("> Insert `%s` (addr: %d) to scope level %d\n", "XXX", 0, 0);
// }

// static void lookup_symbol() {
// }

// static void dump_symbol() {
//     printf("\n> Dump symbol table (scope level: %d)\n", 0);
//     printf("%-10s%-10s%-10s%-10s%-10s%-10s\n",
//            "Index", "Name", "Type", "Addr", "Lineno", "Func_sig");
//     printf("%-10d%-10s%-10s%-10d%-10d%-10s\n",
//             0, "name", "type", 0, 0, "func_sig");
// }

static void addtoreg(char *str){
    if(type=='i'){
        reg[reg_count].pos=reg_count;
        reg[reg_count].ival=yylval.i_val;
        reg[reg_count].scope=scopelevel;
        reg[reg_count].type='i';
        strcpy(reg[reg_count].var_name, str);
    }
    else if(type=='f'){
        reg[reg_count].pos=reg_count;
        reg[reg_count].fval=yylval.f_val;
        reg[reg_count].scope=scopelevel;
        reg[reg_count].type='f';
        strcpy(reg[reg_count].var_name, str);

    }
    else if(type=='b'){
        reg[reg_count].pos=reg_count;
        reg[reg_count].ival=yylval.b_val;
        reg[reg_count].scope=scopelevel;
        reg[reg_count].type='b';
        strcpy(reg[reg_count].var_name, str);

    }
    else if(type=='s'){
        reg[reg_count].pos=reg_count;
        strcpy(reg[reg_count].sval, yylval.s_val);
        reg[reg_count].scope=scopelevel;
        reg[reg_count].type='s';
        strcpy(reg[reg_count].var_name, str);

    }

    reg_count++;
}

static int findpos(char *str){
    for(int i=reg_count-1;i>=0;i--){
        if(!strcmp(reg[i].var_name, str) && reg[i].scope==scopelevel){
            type=reg[i].type;
            return reg[i].pos;
        }
    }
    
    for(int i=reg_count-1;i>=0;i--){
        if(!strcmp(reg[i].var_name, str)){
            type=reg[i].type;
            return reg[i].pos;
        }
    }
    return -1;
}

static int exist(char *str){
    for(int i=reg_count-1;i>=0;i--){
        if(!strcmp(reg[i].var_name, str) && reg[i].scope==scopelevel){
            type=reg[i].type;
            return 1;
        }
    }
    return 0;
}
