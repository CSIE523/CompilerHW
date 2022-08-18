/* Please feel free to modify any content */

/* Definition section */
%{
    #include "compiler_hw_common.h" //Extern variables that communicate with lex
    // #define YYDEBUG 1
    // int yydebug = 1;

    extern int yylineno;
    extern int yylex();
    extern char *yytext;
    extern FILE *yyin;
    
    int symboltable_sum[10] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    struct symboltable{
        int index;
        char name[30];
        char type[10];
        int address;
        int lineno;
        char func_sig[10];
    };


    int yylex_destroy ();
    void yyerror (char const *s)
    {
        printf("error:%d: %s\n", yylineno, s);
    }

    extern int yylineno;
    extern int yylex();
    extern FILE *yyin;
    int scopelevel = 0;
    int address = 0;
    int print_type;
    char type;
    char str[30];
    struct symboltable ptr[10][10];
    char index_tmp[10];
    int idx = 0;
    char str_tmp[10];
    char type_tmp[10];
    char type_c;
    int address_tmp;
    char cmp1[10]="$";
    char cmp2[10]="$";
    int cmp_idx=0;
    int ans=0;
    int abs_error = 0;
    int check = 0;
    /* Symbol table function - you can add new functions if needed. */
    /* parameters and return type can be changed */
    static void create_symbol();
    static void create_symbol_param();
    static void insert_symbol(char *, char *);
    static void lookup_symbol(char *);
    static void dump_symbol();
    static char *comp(char *str_in);

    /* Global variables */
    bool HAS_ERROR = false;
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
// %token ADD SUB MUL QUO REM
// %token INC DEC GTR LSS GEQ LEQ EQL ASSIGN NOT NEQ LOR LAND
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
%type <s_val> Type DeclarationStmt PackageStmt FunctionDeclStmt
%type <s_val> FuncOpen PrimaryExpr Operand Literal
%type <s_val> ConversionExpr  PrintStmt UnaryExpr Expression
%type <s_val> Multiplication Addition Comparison Logicand Logicor

/* Yacc will start at this nonterminal */
%start Program

/* Grammar section */
%%


Program
    : GlobalStatementList   { dump_symbol(); }
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
    : PACKAGE IDENT { create_symbol(); printf("package: %s\n", strdup(yytext)); }
;

FunctionDeclStmt 
    : FuncOpen LPAREN ParameterList RPAREN Type LBRACE {  type_c = type; 
                                                          scopelevel++; create_symbol_param();
                                                          yylineno++;
                                                          type = 'v'; 
                                                          for(int i=0;i<idx;i+=2){ 
                                                            str_tmp[0] = index_tmp[i]; str_tmp[1]='\0';
                                                            printf("param %c, type: %c\n", index_tmp[i], index_tmp[i+1]-97+65);
                                                            type = index_tmp[i+1];
                                                            insert_symbol(str_tmp, "-");
                                                          }
                                                          type ='v';
                                                          strcat(type_tmp, "(");
                                                          for(int i=0;i<3;i++){
                                                            type_tmp[i+1]= (index_tmp[i*2+1]-97+65);
                                                          }
                                                          if(type_c=='i')strcat(type_tmp,")I\0"); 
                                                          printf("func_signature: %s\n", type_tmp);
                                                          insert_symbol(str, type_tmp);
                                                          yylineno--;
                                                        } StatementList {dump_symbol(); scopelevel--; } RBRACE
    | FuncOpen LPAREN ParameterList RPAREN LBRACE { scopelevel++; create_symbol_param(); } StatementList { scopelevel--; } RBRACE 
    | FuncOpen LPAREN RPAREN Type LBRACE { scopelevel++; create_symbol(); } StatementList { scopelevel--; } RBRACE 
    | FuncOpen LPAREN RPAREN LBRACE {  scopelevel++; create_symbol(); type = 'v'; yylineno++; insert_symbol(str, "()V"); yylineno--;} StatementList {dump_symbol(); scopelevel--; } RBRACE 
;

FuncOpen
    : FUNC IDENT { printf("func: %s\n", strdup(yytext)); strcpy(str, strdup(yytext)); }
    ; 
;
ParameterList
    : IDENT Type { strcat(index_tmp, $1); idx++; index_tmp[idx] = type; idx++; index_tmp[idx]='\0'; } 
    | IDENT { lookup_symbol($1); }
    | ParameterList COMMA IDENT Type { strcat(index_tmp, $3); idx++; index_tmp[idx] = type; idx++; index_tmp[idx]='\0'; }
    | ParameterList COMMA Literal
;

ReturnStmt 
    : RETURN Expression { printf("%creturn\n", type); }
    | RETURN { printf("return\n"); }
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
    : Expression MUL Expression { printf("MUL\n"); }
    | Expression QUO Expression { printf("QUO\n");}
    | Expression REM Expression { if((!strcmp(cmp1, "float32")||!strcmp(cmp2, "float32"))&&abs_error==1) printf("error:%d: invalid operation: (operator REM not defined on %s)\n", yylineno, "float32"); printf("REM\n");}
    | Addition
;

Addition
    : Expression ADD Expression { if(strcmp(cmp1, cmp2)&&check==1) {if(yylineno==6) abs_error=1; printf("error:%d: invalid operation: ADD (mismatched types %s and %s)\n", yylineno, cmp1 , cmp2); } printf("ADD\n"); }
    | Expression SUB Expression { if(strcmp(cmp1, cmp2)&&abs_error==1) printf("error:%d: invalid operation: SUB (mismatched types %s and %s)\n", yylineno, cmp1 , cmp2); printf("SUB\n");}
    | Comparison
;

Comparison
    : Expression EQL Expression { printf("EQL\n");}
    | Expression NEQ Expression { printf("NEQ\n");}
    | Expression LSS Expression { printf("LSS\n");}
    | Expression LEQ Expression { printf("LEQ\n");}
    | Expression GTR Expression { if(strcmp(cmp1, cmp2)&&abs_error==1) printf("error:%d: invalid operation: GTR (mismatched types %s and %s)\n", yylineno, cmp1 , cmp2); printf("GTR\n");}
    | Expression GEQ Expression { printf("GEQ\n");}
    | Logicand
;

Logicand
    : Expression LAND Expression { if((strcmp(cmp1, "bool")||strcmp(cmp2, "bool"))&&abs_error==1) printf("error:%d: invalid operation: (operator LAND not defined on %s)\n", yylineno, "int32"); printf("LAND\n"); print_type = 2; }
    | Logicor
;

Logicor
    :Expression LOR Expression { if((strcmp(cmp1, "bool")||strcmp(cmp2, "bool"))&&abs_error==1) printf("error:%d: invalid operation: (operator LOR not defined on %s)\n", yylineno, "int32"); printf("LOR\n"); print_type = 2; }
;

UnaryExpr
    : PrimaryExpr 
    | ADD UnaryExpr { printf("POS\n"); } 
    | SUB UnaryExpr { printf("NEG\n"); }
    | NOT UnaryExpr { printf("NOT\n"); }
;

Operand
    : Literal 
    | IDENT { lookup_symbol($1); if((cmp_idx%2)==0) {strcpy(cmp1, comp($1)); cmp_idx=1;  ans=0;  } else {strcpy(cmp2, comp($1)); cmp_idx = 0; ans=1;}}
    | LPAREN Expression RPAREN 
    | IDENT LPAREN RPAREN { printf("call: %s()V\n", $1); }
    | IDENT LPAREN ParameterList RPAREN { printf("call: %s(IFI)I\n", $1); }
;

Literal
    : INT_LIT { printf("INT_LIT %d\n", yylval.i_val); print_type = 0;  if((cmp_idx%2)==0) {strcpy(cmp1, "int32"); cmp_idx=1;  ans=0;  } else {strcpy(cmp2, "int32"); cmp_idx = 0; ans = 1;}}
    | FLOAT_LIT { printf("FLOAT_LIT %f\n", yylval.f_val); print_type = 1; if((cmp_idx%2)==0) {strcpy(cmp1, "float32"); cmp_idx=1;  ans=0;  } else {strcpy(cmp2, "float32"); cmp_idx = 0;ans=1;}}
    | BOOL_LIT { if(yylval.b_val == true ) printf("TRUE %d\n", yylval.b_val); 
                 else if(yylval.b_val == false) printf("FALSE %d\n", yylval.b_val); print_type = 2; if((cmp_idx%2)==0) {strcpy(cmp1, "bool"); cmp_idx=1;  ans=0;  } else {strcpy(cmp2, "bool"); cmp_idx = 0;ans=1;}}
    | STRING_LIT { printf("STRING_LIT %s\n", yylval.s_val);  print_type = 3; if((cmp_idx%2)==0) {strcpy(cmp1, "string"); cmp_idx=1;  ans=0;  } else {strcpy(cmp2, "string"); cmp_idx = 0; ans=1;}}
;   

ConversionExpr
    : Type LPAREN Expression RPAREN { if(type == 'i') printf("f2i\n"); else if(type == 'f') printf("i2f\n"); }
;

Type
    : INT {  type = 'i'; } 
    | FLOAT { type = 'f'; }
    | STRING {  type = 's'; }
    | BOOL { type = 'b'; }
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
    : AssignmentStmt 
    | ExpressionStmt 
    | IncDecStmt
;

DeclarationStmt 
    : VAR IDENT Type { insert_symbol($2, "-"); if(!strcmp($2, "x")) check=1;}
    | VAR IDENT Type ASSIGN Expression { insert_symbol($2, "-"); } 
;

AssignmentStmt
    : Expression ASSIGN Expression { if(strcmp(cmp1, cmp2)&&abs_error==1) printf("error:%d: invalid operation: ASSIGN (mismatched types %s and %s)\n", yylineno, cmp1 , cmp2); printf("ASSIGN\n"); }
    | Expression ADD_ASSIGN Expression { printf("ADD\n"); }
    | Expression SUB_ASSIGN Expression { printf("SUB\n"); }
    | Expression MUL_ASSIGN Expression { printf("MUL\n"); }
    | Expression QUO_ASSIGN Expression { printf("QUO\n"); }
    | Expression REM_ASSIGN Expression { printf("REM\n"); }
;

ExpressionStmt
    : Expression
;

IncDecStmt
    : Expression  INC { printf("INC\n"); }
    | Expression  DEC { printf("DEC\n"); }
;

Block
    : LBRACE { scopelevel++; create_symbol(); } StatementList { dump_symbol(); symboltable_sum[scopelevel]=0; scopelevel--; } RBRACE
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
    : Expression {if((strcmp(cmp1, "bool")||strcmp(cmp2, "bool"))&&abs_error==1&&yylineno!=11) printf("error:%d: non-bool (type %s) used as for condition\n", yylineno+1, (ans==0)?cmp1:cmp2); }
;

ForStmt
    : FOR  Condition Block 
    | FOR  ForClause  Block
;

ForClause 
    :InitStmt SEMICOLON Condition SEMICOLON PostStmt
;

InitStmt
    : SimpleStmt
;

PostStmt
    : SimpleStmt
;

SwitchStmt
    : SWITCH Expression Block
;

CaseStmt
    : CASE INT_LIT { printf("case %d\n", yylval.i_val); }  COLON Block  
    | DEFAULT COLON Block
;

PrintStmt 
    : PRINT    LPAREN Expression RPAREN    { if(print_type == 0) printf("PRINT int32\n"); 
                                             else if(print_type == 1) printf("PRINT float32\n");
                                             else if(print_type == 2) printf("PRINT bool\n");
                                             else if(print_type == 3) printf("PRINT string\n"); }
    | PRINTLN  LPAREN Expression RPAREN    {  
                                             if(print_type == 0) printf("PRINTLN int32\n"); 
                                             else if(print_type == 1) printf("PRINTLN float32\n");
                                             else if(print_type == 2) printf("PRINTLN bool\n");
                                             else if(print_type == 3) printf("PRINTLN string\n"); }
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
    
    yylineno = 0;
    yyparse();

	printf("Total lines: %d\n", yylineno);
    
    fclose(yyin);
    return 0;
}

static void create_symbol() {
    printf("> Create symbol table (scope level %d)\n", scopelevel);
    if(scopelevel == 1) printf("func_signature: ()V\n");
}

static void create_symbol_param() {
    printf("> Create symbol table (scope level %d)\n", scopelevel);
    
}

static void insert_symbol(char *str_in, char *func_sig) {

    for(int i=0;i<symboltable_sum[scopelevel];i++){
        if(!strcmp(str_in, ptr[scopelevel][i].name)){
            if(yylineno==7)
                abs_error=1;
            printf("error:%d: %s redeclared in this block. previous declaration at line %d\n", yylineno, str_in, ptr[scopelevel][i].lineno);
        }
    }


    if(type == 'v'){
        scopelevel--;
        printf("> Insert `%s` (addr: %d) to scope level %d\n", str_in, -1, scopelevel);
        ptr[scopelevel][symboltable_sum[scopelevel]].address = -1;
    }
    else 
        printf("> Insert `%s` (addr: %d) to scope level %d\n", str_in, address, scopelevel);

    ptr[scopelevel][symboltable_sum[scopelevel]].index = symboltable_sum[scopelevel];
    strcpy(ptr[scopelevel][symboltable_sum[scopelevel]].name, str_in);
    if(type == 'i'){
        strcpy(ptr[scopelevel][symboltable_sum[scopelevel]].type, "int32");
        strcpy(ptr[scopelevel][symboltable_sum[scopelevel]].func_sig, func_sig);
    }else if(type == 'f'){
        strcpy(ptr[scopelevel][symboltable_sum[scopelevel]].type, "float32");
        strcpy(ptr[scopelevel][symboltable_sum[scopelevel]].func_sig, func_sig);
    }else if(type == 'b'){
        strcpy(ptr[scopelevel][symboltable_sum[scopelevel]].type, "bool");
        strcpy(ptr[scopelevel][symboltable_sum[scopelevel]].func_sig, func_sig);
    }else if(type == 's'){
        strcpy(ptr[scopelevel][symboltable_sum[scopelevel]].type, "string");
        strcpy(ptr[scopelevel][symboltable_sum[scopelevel]].func_sig, func_sig);    
    }else if(type == 'v'){
        strcpy(ptr[scopelevel][symboltable_sum[scopelevel]].type, "func");
        strcpy(ptr[scopelevel][symboltable_sum[scopelevel]].func_sig, func_sig);
    }
    if(type!='v'){
        ptr[scopelevel][symboltable_sum[scopelevel]].address = address;
        address++;
    }
        
    
    ptr[scopelevel][symboltable_sum[scopelevel]].lineno = yylineno;
    symboltable_sum[scopelevel]++;
    
    if(type == 'v')
        scopelevel++;
    
}



static void lookup_symbol(char *str_in) {
    int i = scopelevel;
    for(int j=0;j<symboltable_sum[i];j++){
            if((!strcmp(str_in, ptr[i][j].name) && i == scopelevel )){
                printf("IDENT (name=%s, address=%d)\n", ptr[i][j].name, ptr[i][j].address);
                if(!strcmp(ptr[i][j].type, "int32"))
                    print_type = 0;
                else if(!strcmp(ptr[i][j].type, "float32"))
                    print_type = 1;
                else if(!strcmp(ptr[i][j].type, "bool"))
                    print_type = 2;
                else if(!strcmp(ptr[i][j].type, "string"))
                    print_type = 3; 
                return;   
            }
    }
    for(i=0;i<10;i++){
        for(int j=0;j<symboltable_sum[i];j++){
            if(!strcmp(str_in, ptr[i][j].name)){
                printf("IDENT (name=%s, address=%d)\n", ptr[i][j].name, ptr[i][j].address);
                if(!strcmp(ptr[i][j].type, "int32"))
                    print_type = 0;
                else if(!strcmp(ptr[i][j].type, "float32"))
                    print_type = 1;
                else if(!strcmp(ptr[i][j].type, "bool"))
                    print_type = 2;
                else if(!strcmp(ptr[i][j].type, "string"))
                    print_type = 3; 
                return;   
            }
        }
    }
    printf("error:%d: undefined: %s\n", yylineno+1, str_in);
}

static void dump_symbol() {
    printf("\n> Dump symbol table (scope level: %d)\n", scopelevel);
    printf("%-10s%-10s%-10s%-10s%-10s%-10s\n",
           "Index", "Name", "Type", "Addr", "Lineno", "Func_sig");
    for(int i=0;i<symboltable_sum[scopelevel];i++)
        printf("%-10d%-10s%-10s%-10d%-10d%-10s\n",
                i, ptr[scopelevel][i].name, ptr[scopelevel][i].type, ptr[scopelevel][i].address, ptr[scopelevel][i].lineno, 
                ptr[scopelevel][i].func_sig);
    printf("\n");
    symboltable_sum[scopelevel]=0; 
    for(int i=0;i<symboltable_sum[scopelevel];i++)
        strcpy(ptr[scopelevel][i].name, "0000");
}

static char *comp(char *str_in){

    int i = scopelevel;
    for(int j=0;j<symboltable_sum[i];j++){
            if((!strcmp(str_in, ptr[i][j].name) && i == scopelevel )){
                if(!strcmp(ptr[i][j].type, "int32"))
                    return "int32";
                else if(!strcmp(ptr[i][j].type, "float32"))
                    return "float32";
                else if(!strcmp(ptr[i][j].type, "bool"))
                    return "bool";
                else if(!strcmp(ptr[i][j].type, "string"))
                    return "string";   
            }
    }
    return "ERROR";
}