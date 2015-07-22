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
	
		if(array[i][0] == '.') {
		
			if(arg[0] == '.') {

			Command::_currentSimpleCommand->insertArgument(array[i]);
			
			}

		}
		else {
		Command::_currentSimpleCommand->insertArgument(array[i]);
		
		}
		
	}
	
	free(array);


}

void expandWildcard(char * prefix, char *suffix) {
if (suffix[0]== 0) {
// suffix is empty. Put prefix in argument.
Command::_currentSimpleCommand->insertArgument(strdup(prefix));
return;
}
// Obtain the next component in the suffix
// Also advance suffix.
char * s = strchr(suffix, /);
char component[MAXFILENAME];
if (s!=NULL){ // Copy up to the first /
strncpy(component,suffix, s-suffix);
suffix = s + 1;
}
else { // Last part of path. Copy whole thing.
strcpy(component, suffix);
suffix = suffix + strlen(suffix);
}

// Now we need to expand the component
char newPrefix[MAXFILENAME];
if (strchr(component,'*')==NULL && strchr(component,'?')==NULL) {
// component does not have wildcards
sprintf(newPrefix,"%s/%s", prefix, component);
expandWildcard(newPrefix, suffix);
return;
}
// Component has wildcards
// Convert component to regular expression
char * reg = (char*)malloc(2*strlen(component)+10); 
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
        


char * expbuf = (char*)malloc(strlen(reg));
compile(reg, expbuf, &expbuf[strlen(expbuf)+1], '$');
	if(expbuf == NULL)
	{
		perror("compile");
		return;
	}

char * dir;
// If prefix is empty then list current directory
if (prefix == NULL) dir ="."; 
else if(!strcmp("", prefix))
	{
		dir = strdup("/");
	}
else dir=prefix;

DIR * d=opendir(dir);
if (d==NULL) {
//perror("opendir"); 
return;
}


// Now we need to check what entries match
while ((ent = readdir(d))!= NULL) {
// Check if name matches
	if (advance(ent->d_name, expbuf) ) {
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





//		sprintf(newPrefix,"%s/%s", prefix, ent->d_name);
//		expandWildcard(newPrefix,suffix);
	}
}

close(d);
return;

}

#if 0
main()
{
	yyparse();
}
#endif
