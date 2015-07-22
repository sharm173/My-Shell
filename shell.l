
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
#include<wait.h>
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

[\"][^\t\n\"]*[\"]  {

char * temp = (char *)malloc(sizeof(char) * strlen(yytext));
char *t = temp;
int i = 0;
while(yytext[i] != '\0') {
if(yytext[i] != '\"') {*t = yytext[i];
t++;
}
i++;
}
*t = '\0';

yylval.string_val  = strdup(temp);
	free(temp); 
   return WORD;
}

[`][^\t\n`]*[`] {

char  *buffer = (char*)malloc(sizeof(char) * 4096);
char *b = buffer;
char * temp = (char *)malloc(sizeof(char) * (strlen(yytext) +7 ));
char *t = temp;
int i = 0;
while(yytext[i] != '\0') {
if(yytext[i] != '\'') {
*t = yytext[i];
t++;
}
i++;
}
*t = '\n';
t++;
*t='\0';
strcat(temp,"exit\n");
int len = 0;
int defin = dup(0);
int defout = dup(1);

int parent[2];
        
if(pipe(parent) == -1){
            perror("pipe");
            exit(2);
        }

int child[2];

if(pipe(child) == -1){
            perror("pipe");
            exit(2);
        }

dup2(child[1],1);
close(child[1]);
dup2(parent[0],0);
close(parent[0]);


int ret = fork();

if(ret < 0) {
perror("fork");
exit(1);
}

else if(ret == 0) {
dup2(child[0],0);
dup2(parent[1],1);
close(child[0]);
close(parent[1]);

char *args[2];
args[0] = "shell";
args[1] = NULL;
execvp(args[0], args);
perror("execvp");
_exit(1);

}
else {
while(*temp != '\0') {
write(1,temp,1);
temp++;
}

char c;
while(read(0,&c,1) != NULL) {
	if(c != '\n') {
		*b = ' ';
		b++;
		len++;
		continue;
	}
*b = c;
b++;
len++;
}
*b = '\0';

//restore std in/ out
dup2(defin,0);
close(defin);
dup2(defout,1);
close(defout);

close(parent[0]);
close(parent[1]);
close(child[0]);
close(child[1]);
}

waitpid(ret,0,0);

for(int i = 0; i < len; i++) {
b--;
unput(*b);
}




}

[^ \t\n]*[\\][^ \t\n]* {
int count = 1;
char * temp = (char *)malloc(sizeof(char) * strlen(yytext));
char *t = temp;
int i = 0;
while(yytext[i] != '\0') {
if(yytext[i] != '\\') {
*t = yytext[i];
t++;
count = 0;
}

else if(yytext[i] == '\\' && count >= 1) {
if(count == 1) {
*t = yytext[i];
t++;
count++;
}
else {
count++;
}
}

else {
//t++;
count = 1;
}
i++;
}
*t = '\0';
yylval.string_val  = strdup(temp);
        free(temp);
   return WORD;

}


[^ \t\n][^ \t\n]*  {
		/* Assume that file names have only alpha chars */
		yylval.string_val = strdup(yytext);
		return WORD;
	}

