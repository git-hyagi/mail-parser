#!/usr/bin/perl -w

#
# Programa que mapeia quantidade de tentativas invalidas de envio de email
# Script em execucao no crontab (/etc/cron.d/check_mail) de 5 em 5 minutos  
#

# Recomenda-se primeiro executar a script somente para imprimir os arquivos que estao comprometendo a fila de email.
# Para isso modificar as linhas da script:
#
#       foreach(sort @list_files) {     
# ++++         print "$_\n"; 
#       ## Altera permissoes do arquivo para evitar uso
# ----  ##        system ("chmod","000",$_);
# ----  ##        system ("ls","-l",$_);
#       }
#
# Para fazer com que a script releia todo o maillog novamente, remover o arquivo /tmp/mail_offset.stat.


use strict;
use POSIX qw(strftime);

require "lock_file.pl";
require "seek_log_file.pl";

my $count=0;
my $lock_file = "/var/run/mail_parser.lock"; # arquivo de lock para evitar execucao de mais de uma instancia da aplicacao
my $maillog = "/var/log/maillog"; # arquivo de log que sera parseado
my $last_offset_file = "/tmp/mail_offset.stat"; # posicao de ultima analise do arquivo
my $last_offset; # ponteiro para ultima posicao analisada do arquivo de log
my $check_mail_log = "/var/log/check_mail.log"; # relacao dos arquivos modificados
my $date = strftime "%d-%m-%Y", localtime;
my @list_files;



# Verifica se ja existe outra instancia da script em execucao
if (!runlock($lock_file)) { exit 0; }

# Leitura do maillog
open (LOGFILE ,"<",$maillog) or die "Houve um erro durante a tentativa de leitura do arquivo de log: $!\n";

# Log dos arquivos modificados
open (MAILCHECKLOG,">>",$check_mail_log) or die "$!\n";


if (!check_offset_file($last_offset_file))  { print "Erro na leitura do arquivo de offset\n";exit 0; }
$last_offset = get_last_offset($last_offset_file);

# Vai ate o final do arquivo e compara o offset com o ultimo offset salvo
if (!seek_file(\*LOGFILE,$last_offset,$lock_file)) { exit 0; }


# Contabiliza somente as entradas que excederam o limite maximo de envio de mensagens.
while(<LOGFILE>) {
	 if ( $_ =~ /^((.+)Exceeded(.+)user(.+)\((.+)for(.+)\))$/ ) {
		 $_ = $5;
		 my $user = $4; # Coleta o user
		 $user =~ s/\s(.+)\s/$1/;  # Remove os espacos da string

		 my ($full,$domain,$object) = /^((.+?[com|com\.br|net|org|org\.br]\/)(.+))$/;
		 $domain =~ s/\s(www\.)?([\w\d-]+?)\..*?\//$2/;  # Retira o www e o tld do dominio
		 $object =~ s/(.+?)\s/$1/; # Coleta o objeto requisitado

		 my $doc_root = `grep $domain /etc/httpd/conf.d/websites/$user\_1.conf -A 4 | grep DocumentRoot `; # Trata casos de diversos dominios para um mesmo usuario
		 my @doc_root = split (" ",$doc_root); # Coleta somente o document root
		 push(@list_files,"$doc_root[1]/$object");
	} 
}

# remove ocorrências duplicadas em um rray
sub uniq {
  my %seen;
  return grep { !$seen{$_}++ } @_;
}
 

@list_files = uniq  @list_files;
foreach(sort @list_files) {	
#	print "$_\n"; 
	# Altera permissoes do arquivo para evitar uso
	system ("chmod","000",$_);
	system ("ls","-l",$_);
	print MAILCHECKLOG "[$date] $_\n";
}

# Salva o ultimo offset.
save_seek_file(\*LOGFILE,$last_offset_file);

close LOGFILE;
close MAILCHECKLOG;


# Remove o lock file
remove_lock_file($lock_file);
