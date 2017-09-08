#
# DebBrasil.pm
# http://bvmf.bmfbovespa.com.br/rendafixa/FormDetalhePUEmissor.asp
#

# Version 0.1.3 -
# New URL  
# 2016.12.03
#
# Version 0.1.2 -
# Adapt the new code from the site.
# 2015.18.12

# Version 0.1.1 - 
# This version corrects the data downloaded by removing spaces and converting
# cent values into Rand values  this ensures that the Price Editor in GNUCash 
# can import the data. The rest of the module and all the hard work 
# remains that of Stephen Langenhoven!
# Rafael Casali
# 2010.06.01


package Finance::Quote::DebBrasil;
require 5.004;

use strict;
use vars qw /$VERSION/ ;

use LWP::UserAgent;
use HTTP::Request::Common;
use HTML::TableExtract;

$VERSION = '1.17';

my $BMFBOVESPA_MAINURL = ("http://bvmf.bmfbovespa.com.br/");
my $BMFBOVESPA_URL = ($BMFBOVESPA_MAINURL."rendafixa/FormDetalhePUEmissor.asp");

sub methods {
    return (debbrasil => \&bmfbovespa);
}


sub labels {
    my @labels = qw/method source name symbol currency last date /;
    return (bmfbovespa => \@labels);
}   

sub convert_price {
        $_ = shift;
        s/\.//g;
        s/,/\./g;
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

    my $url = $BMFBOVESPA_URL;
#   print "[debug]: ", $url, "\n";
    my $response = $ua->request(GET $url);
    #print "[debug]: ", $response->content, "\n";

    $te = new HTML::TableExtract();
    $te->parse($response->content);

    foreach my $symbol (@symbols) {

        if (!$response->is_success) {
            $info{$symbol, "success"} = 0;
            $info{$symbol, "errormsg"} = "Error contacting URL";
            next;
        }
    }
 
    $te = new HTML::TableExtract();
    $te->parse($response->content);

    foreach my $symbol (@symbols) {
        #print "[debug]: (parsed HTML)",$te, "\n";

#	unless ($te->first_table_found()) {
#	  print STDERR  "no tables on this page\n";
	  $info{$symbol, "success"}  = 0;
	  $info{$symbol, "errormsg"} = "Parse error";
#	  next;
#	}

# Debug to dump all tables in HTML...
#	print "[debug]: $symbol \n";

#          print " \n \n[debug]: ++++ ==== ++++ ==== ++++ ==== ++++ ==== START OF TABLE DUMP ++++ ==== ++++ ==== ++++ ==== ++++ ==== \n \n ";
#
         foreach $ts ($te->table_states) {;
#
#           printf "\n \n[debug]: //// \\\\ //// \\\\ //// \\\\ //// \\\\ START OF TABLE %d,%d //// \\\\ //// \\\\ //// \\\\ //// \\\\ \n \n ",
#	     $ts->depth, $ts->count;
#
           foreach $row ($ts->rows) {
		if(substr($row->[1],0,-1) eq $symbol){ 		
	  	$quoter->store_date(\%info, $symbol, {eurodate => $row->[2]});
          	$info{$symbol, "last"}  = convert_price($row->[3]);
          	$info{$symbol, "name"} = $row->[0];
		$info{$symbol, "success"} = 1;
        	$info{$symbol, "method"} = "BMFBOVESPA";

        	$info{$symbol, "symbol"} = $symbol;
        	$info{$symbol, "currency"} = "BRL";
        	$info{$symbol, "source"} = $BMFBOVESPA_MAINURL;
           #  print "[debug]: ", $row->[0], " | ", $row->[1], " | ", $row->[2], " | ", $row->[3], "\n";
             }
           }
         }

#
#           print "\n \n \n \n[debug]: ++++ ==== ++++ ==== ++++ ==== ++++ ==== END OF TABLE DUMP ++++ ==== ++++ ==== ++++ ==== ++++ ==== \n \n \n \n";


# GENERAL FIELDS

    }

    return wantarray() ? %info : \%info;
}

1;

=head1 NAME

Finance::Quote::DebBrasil - Obtain brazilian debentures from
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

