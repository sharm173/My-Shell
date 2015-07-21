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
#include <dirent.h>
#include <stdio.h>
#include "command.h"
#include<string.h>
#include <regex.h>
#include <assert.h>
void yyerror(const char * s);
void expandWildcardsIfNecessary(char*);
int yylex();

%}

%%

goal:
	 command_list
	;

arg_list:
	arg_list argument
	| /*empty*/
//	{
//	Command::_currentCommand.insertSimpleCommand(Command::_currentSimpleCommand);
//	} 
	;

argument: 
	WORD
	{
	
	expandWildcardsIfNecessary($1);
	
//	Command::_currentSimpleCommand->insertArgument($1);
	}
	;
cmd_and_args:
	command_word arg_list {
	Command::_currentCommand.insertSimpleCommand(Command::_currentSimpleCommand);
	}
	;
command_word:
	WORD {
	   Command::_currentSimpleCommand = new SimpleCommand();
           Command::_currentSimpleCommand->insertArgument($1);
	}
	;

pipe_list:
	pipe_list PIPE cmd_and_args 
	| cmd_and_args
	;

io_modifier:
	GREATGREAT WORD 
	{
//	printf("   Yacc: append output \"%s\"\n", $2);
	Command::_currentCommand._append = 1;
//	Command::_numOut++;
	if (Command::_currentCommand._outFile)
		yyerror("Ambiguous output redirect.\n");
	Command::_currentCommand._outFile = strdup($2); 
	}
	| GREAT WORD
	{
  //      printf("   Yacc: insert output \"%s\"\n", $2);
       // Command::_numOut++;
	Command::_currentCommand._append = 0;
	        if (Command::_currentCommand._outFile)
                yyerror("Ambiguous output redirect.\n");
	Command::_currentCommand._outFile = strdup($2);
        }
	| GREATGREATAMPERSAND WORD
	{
    //    printf("   Yacc: append output and stderr \"%s\"\n", $2);
        Command::_currentCommand._append = 1;
        //Command::_numOut++;
        if (Command::_currentCommand._outFile)
                yyerror("Ambiguous output redirect.\n");
	Command::_currentCommand._outFile = strdup($2);
	Command::_currentCommand._errFile = strdup($2);
        }
	| GREATAMPERSAND WORD
	{
	Command::_currentCommand._append = 0;
//	printf("   Yacc: insert output and stderr \"%s\"\n", $2);
        //Command::_numOut++;
        if (Command::_currentCommand._outFile)
                yyerror("Ambiguous output redirect.\n");
	Command::_currentCommand._outFile = strdup($2);
	Command::_currentCommand._errFile = strdup($2);	
	}
	| LESS WORD
	{
  //      printf("   Yacc: get input \"%s\"\n", $2);
       //Command::_numIn++;
        if (Command::_currentCommand._inputFile)
                yyerror("Ambiguous input redirect.\n");
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
//	printf("   Yacc: Execute command\n");
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
//ADD FUNCTIONS

void expandWildcardsIfNecessary(char *arg) {

	if(strchr(arg,'*') == NULL && strchr(arg,'?') == NULL) {
		Command::_currentSimpleCommand->insertArgument(arg);
		return;
	}
	
	char * reg = (char*)malloc(2*strlen(arg)+10);
	char * a = arg;
	char * r = reg;
	*r = '^'; 
	r++; // match beginning of line
	while (*a) {

		if (*a == '*') {
			 *r='.';
			 r++;
			 *r='*';
			 r++; 
		}

		else if (*a == '?') {
			 *r='.';
			 r++;
		}


		else if (*a == '.') {
			 *r='\\';
			 r++; 
			 *r='.';
			 r++;
		}

		else { 
			*r=*a;
			r++;
		}

		a++;
	}

	*r='$';
	r++;
	*r=0;   // match end of line and add null char

// 2. compile regular expression. See lab3-src/regular.cc
	
	char regExpComplete[ 1024 ];
        sprintf(regExpComplete, "^%s$", reg );
	regex_t re;
	//char * instead of int originally

	int expbuf = regcomp(&re, regExpComplete, REG_EXTENDED|REG_NOSUB);

	if (expbuf!=0) {
		perror("compile");
		return;
	}

// 3. List directory and add as arguments the entries
// that match the regular expression

	DIR * dir = opendir(".");
	if (dir == NULL) {
		perror("opendir");
		return;
	}



	struct dirent * ent;
	int nEntries = 0;
	int maxEntries = 20;
	char ** array = (char**) malloc(maxEntries*sizeof(char*));	
	while ( (ent = readdir(dir))!= NULL) {
		// Check if name matches
		regmatch_t match;   
        	expbuf = regexec( &re, ent->d_name, 1, &match, 0 );
        
		if (expbuf ==0 ) {
			// Add argument
		if (nEntries == maxEntries) {
			maxEntries *=2;
			array = (char**)realloc(array, maxEntries*sizeof(char*));
			assert(array!=NULL);
		}

	array[nEntries]= strdup(ent->d_name);
	nEntries++;
		

		//Command::_currentSimpleCommand->insertArgument(strdup(ent->d_name));
		}
		
		else {
		//does not match
		
		}
		
	}
	regfree(&re);
	closedir(dir);
//BUBBLE SORT ARRAY

	for (int i=0; i < nEntries; i++) {
	
		for(int j = 0; j < nEntries-1; j++) {
			if(strcmp(array[j],array[j+1]) > 0) {
				//swap
				char *temp = array[j];
				array[j] = array[j+1];
				array[j+1] = temp;
			
			}
		
		
		}
	
	}
	

	
	// Add arguments
	for (int i = 0; i < nEntries; i++) {
		Command::_currentSimpleCommand->insertArgument(array[i]);
	}
	
	free(array);


}

#if 0
main()
{
	yyparse();
}
#endif
