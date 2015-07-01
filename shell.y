/*
 * CS-252
 * shell.y: parser for shell
 *
 * This parser compiles the following grammar:
 *
 *	cmd [arg]* [> filename]
 *
 * you must extend it to understand the complete shell grammar
 *
 */

%token	<string_val> WORD

%token 	NOTOKEN GREAT AMPERSAND LESS GREATGREAT GREATAMPERSAND GREATGREATAMPERSAND PIPE NEWLINE

%union	{
		char   *string_val;
	}

%{
//#define yylex yylex
#include <stdio.h>
#include "command.h"
#include<string.h>
void yyerror(const char * s);
int yylex();

%}

%%

goal:
	 command_list
	;

arg_list:
	arg_list WORD{
Command::_currentSimpleCommand = new SimpleCommand();
fprintf(stderr,"%p\n",Command::_currentSimpleCommand );
Command::_currentSimpleCommand->insertArgument($2);}
	| /*empty*/
	;

cmd_and_args:
	WORD arg_list {Command::_currentCommand.insertSimpleCommand(Command::_currentSimpleCommand);}
	;

pipe_list:
	pipe_list PIPE cmd_and_args 
	| cmd_and_args
	;

io_modifier:
	GREATGREAT WORD 
	{
	printf("   Yacc: append output \"%s\"\n", $2);
	Command::_currentCommand._outFile = strdup($2); 
	}
	| GREAT WORD
	{
        printf("   Yacc: insert output \"%s\"\n", $2);
        Command::_currentCommand._outFile = strdup($2);
        }
	| GREATGREATAMPERSAND WORD
	{
        printf("   Yacc: append output and stderr \"%s\"\n", $2);
        Command::_currentCommand._outFile = strdup($2);
	Command::_currentCommand._errFile = strdup($2);
        }
	| GREATAMPERSAND WORD
	{
	printf("   Yacc: insert output and stderr \"%s\"\n", $2);
        Command::_currentCommand._outFile = strdup($2);
	Command::_currentCommand._errFile = strdup($2);	
	}
	| LESS WORD
	{
        printf("   Yacc: get input \"%s\"\n", $2);
        Command::_currentCommand._inputFile = strdup($2);
        }
	;

io_modifier_list:
	io_modifier_list io_modifier
	| /*empty*/
	;

background_optional:
	AMPERSAND 
	{
	Command::_currentCommand._background = 1;
	}
	| /*empty*/
	;

command_line:
	pipe_list io_modifier_list background_optional NEWLINE 
	{
	printf("   Yacc: Execute command\n");
	Command::_currentCommand.execute();
	}
	| NEWLINE /*accept empty cmd line*/
	| error NEWLINE{yyerrok;}
	;
	/*error recovery*/
command_list :
        command_list command_line
	| command_line        
	;/* command loop*/


%%

void
yyerror(const char * s)
{
	fprintf(stderr,"%s", s);
}

#if 0
main()
{
	yyparse();
}
#endif
