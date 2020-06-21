# Subrotinas utilizadas para analise de ponto de parada de parser do log

# Verifica a existencia do arquivo com o ponteiro da ultima analise
sub check_offset_file {
	my $last_offset_file = shift;
	unless ( -e $last_offset_file ) {
		open (FILE , ">" , "$last_offset_file") or die "0";
		print FILE "0";
		close (FILE);
	}
}


# Recupera a posicao da ultima analise do arquivo de log
sub get_last_offset {
        my $file = shift;
        open (FILE,"<", $file) or die "Erro durante a tentativa de leitura do arquivo: $!\n";
        chomp(my $last_offset = <FILE>);
        close FILE;
        return $last_offset;
}

# Subrotina que aponta para a ultima posicao lida no arquivo
sub seek_file {
	my ($logfile,$last_offset,$lock_file) = @_;
	seek ($logfile, 0, 2);

	# Se a posicao lida for menor que a ultima armazenada significa que o arquivo eh novo
	if (tell ($logfile) < $last_offset) { $last_offset = 0; }

	# Se a posicao lida for igual a ultima armazenada significa que nao houve alteracao no arquivo
	if (tell ($logfile) == $last_offset) {
		print "fail 0\n";
	# Remove o lock file
		system ('rm','-f',$lock_file);
		return  0;
	}

	# Aponta para a posicao da ultima leitura
	seek ($logfile, $last_offset, 0);
}

# Escreve no arquivo a ultima posicao analisada
sub save_seek_file {
	my ($logfile,$last_offset_file) = @_;
	open (CURR_OFFSET, ">", $last_offset_file) or die $!;
	print CURR_OFFSET tell($logfile);
	close CURR_OFFSET;
}
1;
