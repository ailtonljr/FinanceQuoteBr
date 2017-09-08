#
# tesouro.pm
#http://www3.tesouro.gov.br/tesouro_direto/consulta_titulos_novosite/consultatitulos.asp
#
#
# Version 0.3
# Change URL and codes
# 2016.10.21

# Version 0.2
# Change URL and codes
# 2016.03.12

# Version 0.1
# Update to new layout of site
# 2015.12.18


package Finance::Quote::tesouro;
require 5.004;

use strict;
use vars qw /$VERSION/ ;

use LWP::UserAgent;
use HTTP::Request::Common;
use HTML::TableExtract;
use HTML::Tree;
use Data::Dumper;
use Date::Manip::Date;

$VERSION = '1.17';

my $DEBUG = 0;

my $TESOURO_MAINURL = ("http://www3.tesouro.gov.br/");
my $TESOURO_URL = ("http://www.bmfbovespa.com.br/pt_br/produtos/tesouro-direto/titulos-disponiveis-para-compra.htm");

sub methods {
    return (tesouro => \&bmfbovespa);
}


sub labels {
    my @labels = qw/method source name symbol currency last date /;
    return (bmfbovespa => \@labels);
}

sub convert_price {
        $_ = shift;
	s/R//g;
	s/\$//g;
        s/\.//g;
        s/,/\./g;
        return $_;
}

sub clean_title {
	$_ = shift;
	s/-//g;
	s/ //g;
	s/\t//g;
	s/Tesouro//g;
	s/rincipal//g;
	s/.*\(//;
	s/\)//;
	s/\n//g;
	s/\r//g;
	return $_;
}


sub bmfbovespa {

    my $quoter = shift;
    my @symbols = @_;
    my %info;
    my ($te, $ts, $row);
    my @rows;
    my $name;

    return unless @symbols;

    my $ua = $quoter->user_agent;
    my $url = $TESOURO_URL;
    if ($DEBUG) {
        print "[debug]: ", $url , "\n";
    }

    my $response = $ua->request(GET $url);#"?Mod=0&Tit=Todos&Venc=TODOS&dtInicio=28/09/2016&dtFim=28/09/2016&site=");
    if ($DEBUG) {
	        print "[debug]: ", $response->as_string, "\n";
    }

    foreach my $symbol (@symbols) {
    if (!$response->is_success) {
        $info{$symbol, "success"} = 0;
        $info{$symbol, "errormsg"} = "Error contacting URL";
        next;
    } }

# Buscando a Data da cotação.
    $te = new HTML::TreeBuilder();
    $te->parse($response->content);
    my $posicao= $te->find_by_attribute('class','legenda text-right');
    my $dia = substr $posicao->as_text, -10;


    $te = new HTML::TableExtract();# headers => [qw(Título Vencimento Venda)]);
    $te->parse($response->content);


# foreach $ts ($te->table_states) {
#   print "Table (", join(',', $ts->coords), "):\n";
#   foreach $row ($ts->rows) {
#      print join(',', @$row), "\n";
#   }
# }


    foreach my $symbol (@symbols) {

	if ($DEBUG) {
        print "[debug]: (parsed HTML)",$te, "\n";
  	}

#	unless ($te->first_table_found()) {
#	  print STDERR  "no tables on this page\n";
	  $info{$symbol, "success"}  = 0;
	  $info{$symbol, "errormsg"} = "Parse error";
#	  next;
#	}

# Debug to dump all tables in HTML...
       if ($DEBUG) {
	print "[debug]: Lookfor $symbol \n";

           print "\n \n \n \n[debug]: ++++ ==== ++++ ==== ++++ ==== ++++ ==== START OF TABLE DUMP ++++ ==== ++++ ==== ++++ ==== ++++ ==== \n \n \n \n";
           print "[debug]: " . $te::count ." \n \n \n ";
#
        foreach $ts ($te->table_states) {
               printf "%d,%d " . $ts ."\n",   $ts->depth, $ts->count; }
}

	 $ts = $te->table(0,0);
#
#
	 #          foreach $row ($ts->rows) {
	 #	$dia = $row->[0];
	 #	$dia =~ s/^\s+|\s+$//g;
	 #	next unless ($dia =~ /Atualizado/);
	 # }

           foreach $row ($ts->rows) {
		next unless (substr($row->[0],0,2) eq 'Te');
		#next unless !($row->[1] eq 'Vencimento');
		if ($DEBUG) {
		     printf $row,"\n ---->>>><<<<<------ \n";
		}
		my $venc = new Date::Manip::Date;
		$venc->config('DateFormat','non-US');
		my $err = $venc->parse_date($row->[1]);
		my $titulo = clean_title($row->[0]) . $venc->printf('%d%m%Y');
		if ($DEBUG) {
		print "\n[debug]: $titulo == $symbol \n";
		}
		if($titulo eq $symbol){
	  	$quoter->store_date(\%info, $symbol, {eurodate => $dia });
          	$info{$symbol, "last"}  = convert_price(clean_title($row->[6]));
          	$info{$symbol, "name"} = $row->[0] ." " . $row->[1];
		$info{$symbol, "price"} = $info{$symbol, "last"};
		$info{$symbol, "success"} = 1;
        	$info{$symbol, "method"} = "BMFBOVESPA";
#
        	$info{$symbol, "symbol"} = $symbol;
        	$info{$symbol, "currency"} = "BRL";
        	$info{$symbol, "source"} = $TESOURO_URL;
	#	print Dumper($row);
		}
           }
       #  }

#
#           print "\n \n \n \n[debug]: ++++ ==== ++++ ==== ++++ ==== ++++ ==== END OF TABLE DUMP ++++ ==== ++++ ==== ++++ ==== ++++ ==== \n \n \n \n";


# GENERAL FIELDS

    }

    return wantarray() ? %info : \%info;
}

1;

=head1 NAME

Finance::Quote::Tesouro - Obtain brazilian papers from
www.bmvbovespa.com.br

=head1 SYNOPSIS

    use Finance::Quote;

    $q = Finance::Quote->new;

    # Don't know anything about failover yet...

=head1 DESCRIPTION

This module obtains information about brazilian debentures from
www.bmvbovespa.com.br

=head1 LABELS RETURNED

Information available from sharenet may include the following labels:

method source name symbol currency date nav last price

=head1 SEE ALSO

BMFBovespa website - http://www.bmvbovespa.com.br

Finance::Quote

=cut
