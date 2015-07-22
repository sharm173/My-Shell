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

#define MAXFILENAME 1024
void returnerr();

#include <dirent.h>
#include <stdio.h>
#include "command.h"
#include<string.h>
#include <regex.h>
#include <assert.h>

void yyerror(const char * s);
void expandWildcard(char*, char*);
int yylex();
char** array;
int maxEntries = 10;
int nEntries = 0;
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
	
//	expandWildcardsIfNecessary($1);
if(strchr($1,'*') == NULL && strchr($1,'?') == NULL) {
Command::_currentSimpleCommand->insertArgument($1);
}

else {

expandWildcard(NULL,strdup($1));

if(nEntries == 0) {
array[nEntries] = strdup($1);
nEntries++;
}

//bubble sort

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
        

//ADD Arguments
        for (int i = 0; i < nEntries; i++) {
        
                if(array[i][0] == '.') {
        		char *arg = strdup($1);
                        if(arg[0] == '.') {

                        Command::_currentSimpleCommand->insertArgument(array[i]);
        
                        }
                //free(arg);
		arg = NULL;
                }
                else {
                Command::_currentSimpleCommand->insertArgument(array[i]);
                                
                }

        }
        
        free(array);
	nEntries = 0;
	maxEntries = 10;
}

		
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


void expandWildcard(char * prefix, char *suffix) {
	if(array == NULL)
		array = (char**)malloc(maxEntries*sizeof(char*));

if (suffix[0]== 0) {
// suffix is empty. Put prefix in argument.
//Command::_currentSimpleCommand->insertArgument(strdup(prefix));
if(nEntries >= maxEntries)
		{
			maxEntries *= 2;
			array = (char**)realloc(array, maxEntries*sizeof(char*));
		}
		
		array[nEntries] = strdup(prefix);
		nEntries++;
return;
}

// Obtain the next component in the suffix
// Also advance suffix.

	char * s = strchr(suffix, '/');
	char component[MAXFILENAME];
	
	if (s!=NULL){          				// Copy up to the first /
		//modify
		if(s-suffix != 0) {
		strncpy(component,suffix, s-suffix);
	//	suffix = s + 1;
	//new code
		component[strlen(suffix)-strlen(s)] = 0;
	}

	else {
	component[0] = '\0';
	
	}	
	suffix = s + 1;
	}

	else {		 // Last part of path. Copy whole thing.
	strcpy(component, suffix);
	suffix = suffix + strlen(suffix);
	}

// Now we need to expand the component
char newPrefix[MAXFILENAME];
if (strchr(component,'*')==NULL && strchr(component,'?')==NULL) {
// component does not have wildcards
/*
sprintf(newPrefix,"%s/%s", prefix, component);
expandWildcard(newPrefix, suffix);
return;
*/
//modify

//TEST CODE
		if(prefix == NULL && component[0] != '\0')
			sprintf(newPrefix, "%s", component);
		else if(component[0] != '\0')
			sprintf(newPrefix,"%s/%s", prefix, component);

		if(component[0] != '\0')
			expandWildcard(newPrefix, suffix);
		else
			expandWildcard("", suffix);
		
		return;
}
// Component has wildcards
// Convert component to regular expression

char * reg = (char*)malloc(2*strlen(component)+10); 
char * a = component;
char * r = reg;
        *r = '^';
        r++; // match beginning of line
        while (*a) {
                if (*a == '*') {  *r='.'; r++; *r='*'; r++;}
                else if (*a == '?') {*r='.';r++; }
                else if (*a == '.') { *r='\\'; r++; *r='.'; r++; }
		else { *r=*a; r++;}
		 a++;   
        }                
        *r='$'; r++; *r=0;   // match end of line and add null char

//complie regex

	char regExpComplete[ 1024 ];
        sprintf(regExpComplete, "^%s$", reg );
        regex_t re;

	int expbuf = regcomp(&re, regExpComplete, REG_EXTENDED|REG_NOSUB);

	if(expbuf != 0)
	{
		perror("compile");
		return;
	}

	char * dir;
	// If prefix is empty then list current directory
	
	if (prefix == NULL) dir ="."; 
	else if(!strcmp("", prefix)) dir = strdup("/");
	else dir=prefix;
	//printf("\naaaa   %s   aaaa\n", dir);
	DIR * d=opendir(dir);
	if (d==NULL) {
	perror("opendir"); 
	return;
	}

	struct dirent *ent;
	// Now we need to check what entries match
	while ((ent = readdir(d))!= NULL) {
		// Check if name matches
		regmatch_t match;
                expbuf = regexec( &re, ent->d_name, 1, &match, 0 );
//	if(advance(ent->d_name, expbuf)) {
		if (expbuf == 0 ) {
		// Entry matches. Add name of entry
		// that matches to the prefix and
		// call expandWildcard(..) recursively
			if(ent->d_name[0] == '.')
			{
				if(component[0] == '.')
				{
					if(prefix == NULL)
					{
						sprintf(newPrefix,"%s",ent->d_name);
					}
					else
					{
						sprintf(newPrefix,"%s/%s", prefix, ent->d_name);
					}
					expandWildcard(newPrefix,suffix);
				}
			}
			else
			{
				if(prefix == NULL)
				{
					sprintf(newPrefix,"%s",ent->d_name);
				}
				else
				{
					sprintf(newPrefix,"%s/%s", prefix, ent->d_name);
				}
				expandWildcard(newPrefix,suffix);
			}
		}		

	}

closedir(d);
return;

}
void returnerr() {
return;
}


#if 0
main()
{
	yyparse();
}
#endif
