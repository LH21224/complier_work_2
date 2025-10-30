%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>
#define yylval cool_yylval
#define yylex  cool_yylex
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
  if ((result = fread((char*)buf, sizeof(char), max_size, fin)) < 0) \
    YY_FATAL_ERROR("read() in flex scanner failed");
extern FILE *fin;
extern int curr_lineno;
extern YYSTYPE cool_yylval;
char string_buf[MAX_STR_CONST];
char *string_buf_ptr;
static int comment_level = 0;
%}
%option noyywrap
%option yylineno
%x COMMENT
%x STRING
DIGIT  [0-9]
LOWER  [a-z]
UPPER  [A-Z]
LETTER [a-zA-Z]
DARROW "=>"
ASSIGN "<-"
LE     "<="
%%
[cC][lL][aA][sS][sS]  { return CLASS;   }
[iI][fF]              { return IF;      }
[tT][hH][eE][nN]      { return THEN;    }
[eE][lL][sS][eE]      { return ELSE;    }
[fF][iI]              { return FI;      }
[wW][hH][iI][lL][eE]  { return WHILE;   }
[lL][oO][oO][pP]      { return LOOP;    }
[pP][oO][oO][lL]      { return POOL;    }
[iI][nN]              { return IN;      }
[iI][nN][hH][eE][rR][iI][tT][sS] { return INHERITS; }
[lL][eE][tT]          { return LET;     }
[cC][aA][sS][eE]      { return CASE;    }
[oO][fF]              { return OF;      }
[eE][sS][aA][cC]      { return ESAC;    }
[nN][eE][wW]          { return NEW;     }
[iI][sS][vV][oO][iI][dD] { return ISVOID; }
[nN][oO][tT]          { return NOT;     }
t[rR][uU][eE]         { cool_yylval.boolean = 1;  return BOOL_CONST; }
f[aA][lL][sS][eE]     { cool_yylval.boolean = 0;  return BOOL_CONST; }
{UPPER}({LETTER}|{DIGIT}|_)* {
  cool_yylval.symbol = stringtable.add_string(yytext);
  return TYPEID;
}
{LOWER}({LETTER}|{DIGIT}|_)* {
  cool_yylval.symbol = stringtable.add_string(yytext);
  return OBJECTID;
}
{DIGIT}+ {
  cool_yylval.symbol = stringtable.add_string(yytext);
  return INT_CONST;
}
{DARROW} { return DARROW; }
{ASSIGN} { return ASSIGN; }
{LE}       { return LE;     }
"="      { return '=';    }
"<"      { return '<';    }
"+"      { return '+';    }
"-"      { return '-';    }
"*"      { return '*';    }
"/"      { return '/';    }
"~"      { return '~';    }
"("      { return '(';    }
")"      { return ')';    }
"{"      { return '{';    }
"}"      { return '}';    }
";"      { return ';';    }
":"      { return ':';    }
","      { return ',';    }
"."      { return '.';    }
"@"      { return '@';    }
\" {
  BEGIN(STRING);
  string_buf_ptr = string_buf;
}
<STRING>\" {
  *string_buf_ptr = '\0';
  if (string_buf_ptr - string_buf >= MAX_STR_CONST - 1) {
    cool_yylval.error_msg = "String constant too long";
    BEGIN(INITIAL);
    return ERROR;
  }
  cool_yylval.symbol = stringtable.add_string(string_buf);
  BEGIN(INITIAL);
  return STR_CONST;
}
<STRING>\n {
  curr_lineno++;
  cool_yylval.error_msg = "Unterminated string constant";
  BEGIN(INITIAL);
  return ERROR;
}
<STRING><<EOF>> {
  cool_yylval.error_msg = "EOF in string constant";
  BEGIN(INITIAL);
  return ERROR;
}
<STRING>\\n { *string_buf_ptr++ = '\n'; }
<STRING>\\t { *string_buf_ptr++ = '\t'; }
<STRING>\\b { *string_buf_ptr++ = '\b'; }
<STRING>\\f { *string_buf_ptr++ = '\f'; }
<STRING>\\\" { *string_buf_ptr++ = '\"'; }
<STRING>\\\\ { *string_buf_ptr++ = '\\'; }

<STRING>. {
  if (yytext[0] == '\0') {
    cool_yylval.error_msg = "String contains null character";
    BEGIN(INITIAL);
    return ERROR;
  }
  if (string_buf_ptr - string_buf >= MAX_STR_CONST - 1) {
    cool_yylval.error_msg = "String constant too long";
    BEGIN(INITIAL);
    return ERROR;
  }
  *string_buf_ptr++ = yytext[0];
}
"(*" { BEGIN(COMMENT); comment_level = 1;}

<COMMENT>"(*" { comment_level++; }
<COMMENT>"*)" { comment_level--;  if (comment_level == 0) BEGIN(INITIAL);}
<COMMENT>.    {/**/}
<COMMENT>\n { curr_lineno++; }
<COMMENT><<EOF>> {
  cool_yylval.error_msg = "EOF in comment";
  BEGIN(INITIAL);
  return ERROR;
}

[ \f\r\t\v]+ { }
\n { curr_lineno++; }
. {
  cool_yylval.error_msg = yytext;
  return ERROR;
}
%%
