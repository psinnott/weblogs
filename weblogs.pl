#!/usr/bin/perl -w

use warnings;
use strict;

use Data::Dumper;

my @keys = ("log","host","ip","q","r","date","type" , "url" , "httpversion" ,"status","length","ref","ua");
my %keys_lookup = map { $_ => 1 } @keys;
my %interested = ();
my %filter = ();
my %unfilter = ();

foreach my $param (@ARGV)
{
	if( $param =~ /^([a-z]+)[+=](.+)$/ )
	{
		if( exists( $keys_lookup{$1} ) )
		{
			push( @{$filter{$1}} , $2 );
		}
		else
		{
			die( "unknown key $1" );
		}
	}
	elsif( $param =~ /^([a-z]+)[-](.+)$/ )
        {
                if( exists( $keys_lookup{$1} ) )
                {
                        push( @{$unfilter{$1}} , $2 );
                }
                else
                {
                        die( "unknown key $1" );
                }
        }
	elsif( exists( $keys_lookup{$param} ) )
	{
		$interested{$param} = 1;
	}
	else
	{
		die( "unknown key $param" );
	}
}

if( scalar(keys(%interested)) == 0 && scalar(keys(%filter)) == 0 && scalar(keys(%unfilter)) == 0 )
{
	print join(",",@keys) . "\n";
	exit;
}

my %output = ();

RECORD: while( my $line = <STDIN> )
{
	my $record = parse($line);

	unless($record)
	{
		next;
	}

	foreach my $filter_field ( keys( %filter ) )
	{
		foreach my $one_filter ( @{$filter{$filter_field}} )
		{
			my $regexp = $one_filter;
			unless( $record->{$filter_field} =~ /$regexp/ )
			{
				next RECORD;
			}
		}
	}

	foreach my $unfilter_field ( keys( %unfilter ) )
        {
	 	foreach my $one_filter ( @{$unfilter{$unfilter_field}} )
		{
                	my $regexp = $one_filter;
               		if( $record->{$unfilter_field} =~ /$regexp/ )
                	{
                        	next RECORD;
                	}
		}
        }

	if( scalar(keys(%interested)) == 0 )
	{
		print $record->{"record"} . "\n";
	}
	else
	{
		my $answer = "";
		foreach my $interesting_key( sort keys %interested)
		{
			if( exists($record->{$interesting_key}) )
			{
				$answer .= "$interesting_key - " . $record->{$interesting_key} . " ";
			}
			else
			{
				die("unknown key $interesting_key\n");
			}
		}
		$output{$answer}++;
	}
}

if( scalar(keys(%interested)) != 0 )
{
	foreach ( sort { $output{$a} <=> $output{$b} } keys %output )
	{
		print $output{$_} . "\t" . $_ . "\n";
	}
}


sub parse
{
	my ( $line ) = @_;

	chomp($line);

	if( $line =~ /^(\d{1,2}-combined_log)?:?(\S+ |)([0-9.:a-z]+|::1) ([^ ]+) ([^ ]+) \[([^]]+)\] (("([A-Z]+) ([^ ]+?)\s+(HTTP[^"]+)")|"") ([^ ]+) ([^ ]+) "([^"]*[^\\]|f{0})" "(.*)"$/ )
        {
                #14-combined_log:65.214.44.96 - - [14/Jul/2006:04:35:48 +0100] "GET /~link HTTP/1.0" 301 400 "-" "Mozilla/2.0 (compatible; Ask Jeeves/Teoma; +http://sp.ask.com/docs/about/tech_crawling.html)"
                #208.17.184.59 - - [16/Jul/2006:00:11:36 +0100] "GET / HTTP/1.1" 302 - "" "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.7.12) Gecko/20050922 Fedora/1.0.7-1.1.fc4 Firefox/1.0.7"
                #65.10.0.57 - - [15/Jul/2006:22:01:33 +0100] "GET /~casso/homepage/files/475.jpg\" HTTP/1.1" 404 731 "-" "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; .NET CLR 1.1.4322)"
                my %hash;
                @hash{ @keys } = ($1,$2,$3,$4,$5,$6,$9,$10,$11,$12,$13,$14,$15);
		unless( defined( $hash{"url"} ) )
		{
			$hash{"url"} = "";
		}
		$hash{"host"} =~ s/ +$//;
		$hash{"record"} = $line;
		return \%hash;
        }
        else
        {
                warn("No match - $line");
		return undef;
        }

}
