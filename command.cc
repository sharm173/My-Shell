
/*
 * CS252: Shell project
 *
 * Template file.
 * You will need to add more code here to execute the command table.
 *
 * NOTE: You are responsible for fixing any bugs this code may have!
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <string.h>
#include <signal.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <pwd.h>
#include "command.h"
int *bgp;
extern char ** environ;

extern "C" void disp( int sig )
{
//	fprintf( stderr, "\n");
    printf("\n");
    Command::_currentCommand.prompt();
}

extern "C" void zomboy( int sig )
{
int pid = wait3(0, 0, NULL);
while(waitpid(-1, NULL, WNOHANG) > 0);

for(int i = 0; i < 2048; i++) {

	if(pid == bgp[i])
		printf("[%d] exited.\n", pid);

}
Command::_currentCommand.prompt(); 
}

SimpleCommand::SimpleCommand()
{
	// Creat available space for 5 arguments
	_numberOfAvailableArguments = 5;
	_numberOfArguments = 0;
	_arguments = (char **) malloc( _numberOfAvailableArguments * sizeof( char * ) );
}

void
SimpleCommand::insertArgument( char * argument )
{
	if ( _numberOfAvailableArguments == _numberOfArguments  + 1 ) {
		// Double the available space
		_numberOfAvailableArguments *= 2;
		_arguments = (char **) realloc( _arguments,
				  _numberOfAvailableArguments * sizeof( char * ) );
	}
	

	if(strstr(argument,"$")!=NULL) {
	char *newarg = (char*)malloc(10000);
	char *a = argument;
	while(*a != '\0') {
	if(*a == '$') {
		//expand and copy to newarg
		char *temp = (char*) malloc(1000);
		char *t = temp;
		a++;
		a++;
		
		while(*a != '}') {
			*t = *a;
			a++;
			t++;
		}
		*t = '\0';
	
		strcat(newarg,getenv(temp));
		free(temp);
		a++;	
	}
	
	else {
		//copy to newarg
		char *temp2 = (char*) malloc(strlen(argument));
		char *t2 = temp2;
		
		while(*a != '$' && *a != '\0') {
			*t2 = *a;
			t2++;
			a++;
		}
	*t2 = '\0';
	strcat(newarg,temp2);
	free(temp2);
	
	}
	
	
	}
argument = strdup(newarg);
	free(newarg);

	}


if (strstr(argument,"~") != NULL)
    {
        if ((argument[1]) == '\0')
        {
            argument = strdup(getenv("HOME"));
        }
        else
        {
	char *a = argument;
	a++;

	struct passwd *pwd = getpwnam(a);
            argument = strdup(pwd->pw_dir);
        }
    }

	_arguments[ _numberOfArguments ] = argument;

	// Add NULL argument at the end
	_arguments[ _numberOfArguments + 1] = NULL;
	
	_numberOfArguments++;
}

Command::Command()
{
	// Create available space for one simple command
	_numberOfAvailableSimpleCommands = 1;
	_simpleCommands = (SimpleCommand **)
		malloc( _numberOfSimpleCommands * sizeof( SimpleCommand * ) );

	_numberOfSimpleCommands = 0;
	_outFile = 0;
	_inputFile = 0;
	_errFile = 0;
	_background = 0;
}

void
Command::insertSimpleCommand( SimpleCommand * simpleCommand )
{
	if ( _numberOfAvailableSimpleCommands == _numberOfSimpleCommands ) {
		_numberOfAvailableSimpleCommands *= 2;
		_simpleCommands = (SimpleCommand **) realloc( _simpleCommands,
			 _numberOfAvailableSimpleCommands * sizeof( SimpleCommand * ) );
	}
	
	_simpleCommands[ _numberOfSimpleCommands ] = simpleCommand;
	_numberOfSimpleCommands++;
}

void
Command:: clear()
{
	for ( int i = 0; i < _numberOfSimpleCommands; i++ ) {
		for ( int j = 0; j < _simpleCommands[ i ]->_numberOfArguments; j ++ ) {
			free ( _simpleCommands[ i ]->_arguments[ j ] );
		}
		
		free ( _simpleCommands[ i ]->_arguments );
		free ( _simpleCommands[ i ] );
	}

	if ( _outFile ) {
		free( _outFile );
	}

	if ( _inputFile ) {
		free( _inputFile );
	}

	if ( _errFile ) {
		free( _errFile );
	}

	_numberOfSimpleCommands = 0;
	_outFile = 0;
	_inputFile = 0;
	_errFile = 0;
	_background = 0;
}

void
Command::print()
{
	printf("\n\n");
	printf("              COMMAND TABLE                \n");
	printf("\n");
	printf("  #   Simple Commands\n");
	printf("  --- ----------------------------------------------------------\n");
	
	for ( int i = 0; i < _numberOfSimpleCommands; i++ ) {
		printf("  %-3d ", i );
		for ( int j = 0; j < _simpleCommands[i]->_numberOfArguments; j++ ) {
			printf("\"%s\" \t", _simpleCommands[i]->_arguments[ j ] );
		}
	printf("\n");
	}

	printf( "\n\n" );
	printf( "  Output       Input        Error        Background\n" );
	printf( "  ------------ ------------ ------------ ------------\n" );
	printf( "  %-12s %-12s %-12s %-12s\n", _outFile?_outFile:"default",
		_inputFile?_inputFile:"default", _errFile?_errFile:"default",
		_background?"YES":"NO");
	printf( "\n\n" );
	
}

void
Command::execute()
{
	// Don't do anything if there are no simple commands
	if ( _numberOfSimpleCommands == 0 ) {
		
		prompt();
		return;
	}

	if(strcmp(_simpleCommands[0]->_arguments[0],"exit") == 0) {
	
		printf("Ciao\n\n");
		exit(1);
	
	}
	if (strcmp(_simpleCommands[0]->_arguments[0], "setenv") == 0) {
	int set =setenv(_simpleCommands[0]->_arguments[1], _simpleCommands[0]->_arguments[2], 1);
	
	if(set != 0) perror("setenv");
	clear();
	prompt();
	return;
	}

	if (strcmp(_simpleCommands[0]->_arguments[0], "unsetenv") == 0) {
	if(unsetenv(_simpleCommands[0]->_arguments[1]) != 0) return perror("unsetenv");
        clear();
        prompt();
        return;
	}

	if (strcmp(_simpleCommands[0]->_arguments[0], "cd") == 0) {
	
	char *home = getenv("HOME");
	int errcd;
	if(_simpleCommands[0]->_numberOfArguments > 1){
	errcd = chdir(_simpleCommands[0]->_arguments[1]);
		
	}
	
	else {
	errcd = chdir(home);
	}

	if(errcd != 0 ) perror("chdir");
        clear();
        prompt();
        return;
	}	
//print("\n");
	// Print contents of Command data structure
//	print();

	// Add execution here
	// For every simple command fork a new process
	// Setup i/o redirection
	// and call exec


	int tmpin=dup(0);
	int tmpout=dup(1);
	int tmperr = dup(2);
	int fdin;

	if(_inputFile) {
	   fdin = open(_inputFile,O_RDONLY|O_CREAT,0777);
	}

	else {
	fdin=dup(tmpin);
	}
	
	int ret;
	int fdout;
	int fderr;	
	for(int i = 0; i < _numberOfSimpleCommands; i++) {
	
	//redirect input
	dup2(fdin, 0);
	close(fdin);
	
	//setup output
	if(i == _numberOfSimpleCommands -1) {
	//Last simple command
	if(_outFile && !_append) {
	fdout=open(_outFile,O_WRONLY|O_CREAT|O_TRUNC,0777);
	}
	else if(_outFile && _append) {
	fdout=open(_outFile,O_WRONLY|O_CREAT|O_APPEND,0777);
	}
	else {
	//Use default output
	fdout=dup(tmpout);
	}
	
	if(_errFile && !_append) {
	fderr=open(_errFile,O_WRONLY|O_CREAT|O_TRUNC,0777);
	}
	else if(_errFile && _append) {
	fderr=open(_errFile,O_WRONLY|O_CREAT|O_APPEND,0777);
	}
	else {
	fderr=dup(tmperr);
	}
	dup2(fderr, 2);
	close(fderr);	
	}
	
	else {
	//Not last
	//create pipe
	int fdpipe[2];
	pipe(fdpipe);
	fdout=fdpipe[1];
	fdin=fdpipe[0];
	
	}// if/else
	//Redirect output
	dup2(fdout,1);
	close(fdout);
	
	//create child process
	ret=fork();	
//        dup2(fdout,1);
  //      dup2(fderr,2);
    //    close(fdout);
      //  close(fderr);
	if(ret==0) {
		if (strcmp(_simpleCommands[i]->_arguments[0],"printenv")==0) {
			char **p=environ;
			while (*p!=NULL) {
			printf("%s\n",*p);
			p++;
			}
		exit(0);
		}
	execvp(_simpleCommands[i]->_arguments[0], _simpleCommands[i]->_arguments); //possible bug
	perror("execvp");
	_exit(1);

	}
//        dup2(fdout,1);
  //      dup2(fderr,2);
    //    close(fdout);
      //  close(fderr);
	}//for
	
	//restore in/out 
	dup2(tmpin,0);
	dup2(tmpout,1);
	close(tmpin);
	close(tmpout);
	close(tmperr);

	if(!_background) {
	waitpid(ret,0, 0);
	
	clear();
	prompt();
	}
	
	else {
	int k = 0;
	while(k < 2048 && bgp[k] != 0) k++;

	bgp[k] = ret;
	prompt();
	}
	// Clear to prepare for next command
//	clear();
//	sleep(.1);		
	// Print new prompt
//	prompt();
}

// Shell implementation

void
Command::prompt()
{
if ( isatty(0) ) {
//  Print prompt

	printf("myshell>");
	fflush(stdout);
}
}

Command Command::_currentCommand;
SimpleCommand * Command::_currentSimpleCommand;

int yyparse(void);

main()
{

bgp = new int[2048];
struct sigaction ctrlc;
ctrlc.sa_handler = disp;
sigemptyset(&ctrlc.sa_mask);
ctrlc.sa_flags = SA_RESTART;
int error =
sigaction(SIGINT, &ctrlc, NULL );
if ( error ) {
perror( "sigaction" );
exit( -1 );
} 

struct sigaction zombie;
zombie.sa_handler = zomboy;
sigemptyset(&zombie.sa_mask);
zombie.sa_flags = SA_RESTART;
int error2 =
sigaction(SIGCHLD, &zombie, NULL );
if ( error ) {
perror( "sigaction" );
exit( -1 );
} 
	Command::_currentCommand.prompt();
//	signal( SIGINT, disp );
//	signal(SIGCHILD, zombie);
//fprintf(stderr, "KHGLJKSERGHJLERHGL\n");
	yyparse();

}

