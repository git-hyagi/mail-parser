# Subrotina que verifica a existencia de outra instancia da script em execucao
# Se nao existir, cria o arquivo com o pid do processo
sub runlock {

	my ($lock_file) = shift;
	if ( -e $lock_file ) {
		print "Erro! Ja existe outra instancia da script em execucao!\n"; 
		return 0;
	}

	open( FILE , ">" ,$lock_file);	
	print FILE "$$";
	close(FILE);
	return 1;
}

# Subrotina que remove o lockfile
sub remove_lock_file {
	my $lock_file = shift;
	system ('rm','-f',$lock_file);
}
1;
