
/*
 *
 * CS-252
 * shell.l: lexical analyzer for shell
 * You have to extend it.
 *
 */

%{

#include <string.h>
#include "y.tab.h"

static  void yyunput (int c,char *buf_ptr  );

void myunputc(int c) {
    unput(c);
}

%}

%%

\n 	{
		return NEWLINE;
	}

[ \t] 	{
		/* Discard spaces and tabs */
     	}	

">&"	{
	return GREATAMPERSAND;
	}

">>"	{
	return GREATGREAT;
	}

">>&"	{
	return GREATGREATAMPERSAND;
	}
"&"	{
		return AMPERSAND;
	}

"|"     {
                return PIPE;
        }

"<"     {
 		return LESS;        
        }

">" 	{
		return GREAT;
	}

[^ \t\n][^ \t\n]*  {
		/* Assume that file names have only alpha chars */
		yylval.string_val = strdup(yytext);
		return WORD;
	}

["][^"]*["]  {
    yylval.string_val = strdup(yytext+1);
    if (yylval.string_val[yyleng-2] == '"')
        yylval.string_val[yyleng-2] = 0;
    return WORD;
}
