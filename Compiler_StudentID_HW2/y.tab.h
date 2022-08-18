/* A Bison parser, made by GNU Bison 3.5.1.  */

/* Bison interface for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015, 2018-2020 Free Software Foundation,
   Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* Undocumented macros, especially those whose name start with YY_,
   are private implementation details.  Do not rely on them.  */

#ifndef YY_YY_Y_TAB_H_INCLUDED
# define YY_YY_Y_TAB_H_INCLUDED
/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif
#if YYDEBUG
extern int yydebug;
#endif

/* Token type.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
  enum yytokentype
  {
    VAR = 258,
    NEWLINE = 259,
    PACKAGE = 260,
    INT = 261,
    FLOAT = 262,
    BOOL = 263,
    STRING = 264,
    ASSIGN = 265,
    ADD_ASSIGN = 266,
    SUB_ASSIGN = 267,
    MUL_ASSIGN = 268,
    QUO_ASSIGN = 269,
    REM_ASSIGN = 270,
    IF = 271,
    ELSE = 272,
    FOR = 273,
    SWITCH = 274,
    CASE = 275,
    DEFAULT = 276,
    SEMICOLON = 277,
    COMMA = 278,
    COLON = 279,
    PRINT = 280,
    PRINTLN = 281,
    RETURN = 282,
    FUNC = 283,
    LPAREN = 284,
    RPAREN = 285,
    LBRACE = 286,
    RBRACE = 287,
    LBRACK = 288,
    RBRACK = 289,
    LOR = 290,
    LAND = 291,
    GTR = 292,
    LSS = 293,
    GEQ = 294,
    LEQ = 295,
    EQL = 296,
    NEQ = 297,
    ADD = 298,
    SUB = 299,
    MUL = 300,
    QUO = 301,
    REM = 302,
    INC = 303,
    DEC = 304,
    NOT = 305,
    INT_LIT = 306,
    FLOAT_LIT = 307,
    BOOL_LIT = 308,
    STRING_LIT = 309,
    IDENT = 310
  };
#endif
/* Tokens.  */
#define VAR 258
#define NEWLINE 259
#define PACKAGE 260
#define INT 261
#define FLOAT 262
#define BOOL 263
#define STRING 264
#define ASSIGN 265
#define ADD_ASSIGN 266
#define SUB_ASSIGN 267
#define MUL_ASSIGN 268
#define QUO_ASSIGN 269
#define REM_ASSIGN 270
#define IF 271
#define ELSE 272
#define FOR 273
#define SWITCH 274
#define CASE 275
#define DEFAULT 276
#define SEMICOLON 277
#define COMMA 278
#define COLON 279
#define PRINT 280
#define PRINTLN 281
#define RETURN 282
#define FUNC 283
#define LPAREN 284
#define RPAREN 285
#define LBRACE 286
#define RBRACE 287
#define LBRACK 288
#define RBRACK 289
#define LOR 290
#define LAND 291
#define GTR 292
#define LSS 293
#define GEQ 294
#define LEQ 295
#define EQL 296
#define NEQ 297
#define ADD 298
#define SUB 299
#define MUL 300
#define QUO 301
#define REM 302
#define INC 303
#define DEC 304
#define NOT 305
#define INT_LIT 306
#define FLOAT_LIT 307
#define BOOL_LIT 308
#define STRING_LIT 309
#define IDENT 310

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
union YYSTYPE
{
#line 71 "compiler_hw2.y"

    int i_val;
    float f_val;
    bool b_val;
    char *s_val;
    /* ... */

#line 175 "y.tab.h"

};
typedef union YYSTYPE YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif


extern YYSTYPE yylval;

int yyparse (void);

#endif /* !YY_YY_Y_TAB_H_INCLUDED  */
