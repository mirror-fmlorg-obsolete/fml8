#!/usr/bin/env perl
#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: .track_relation.pl,v 1.4 2001/10/08 06:40:18 fukachan Exp $
#

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

my $debug = $ENV{'debug'} ? 1 : 0;

# %rfc         rfc => rfc description
# %rfc_exists  rfc in this directory
# %rfc_prev    double link list
# %rfc_next    double link list 
my (%rfc_exists, %rfc, %rfc_prev, %rfc_next);
my ($result) = {};

check_rfc_here( \%rfc_exists );
read_rfc_index( "./rfc-index.txt", \%rfc );
analyze( $result );
show( $result );


sub check_rfc_here
{
    my ($rfc_exists) = @_;

    for (<rfc*txt>) {
	if (/RFC(\d+)/i) {
	    my $x = sprintf("RFC%04d", $1);
	    $rfc_exists->{$x} = $x;
	}
    }
}


sub read_rfc_index
{
    my ($f, $rfc) = @_;

    use FileHandle;
    my $fh  = new FileHandle $f;
    my $cur = undef;

    if (defined $fh) {
	while (<$fh>) {
	    if (/^(\d+)/) {
		$cur = $1;
	    }

	    if (defined $cur) {
		$rfc->{ "RFC$cur" } .= $_;
	    }
	}
	close($fh);
    }
}


sub analyze
{
    my ($rfc_link) = @_;

    # check link list for specified $rfc.
    # result: $rfc_prev{$rfc} <- $rfc -> $rfc_next{$rfc}
    for my $rfc (sort {$a<=>$b} keys %rfc_exists) {
	_analyze_links($rfc, $rfc{$rfc});
    }

    # combine link lists.
    my $r = {};
    _combine( $r );

    # o.k. summalize information as a link to the last component.
    #      
    #     A -> B -> LAST
    #     C -> D -> LAST
    #  =>
    #     A -> B -> C -> D -> LAST
    #      
    # This logic is incomplete, we chck all relation for all components.
    #      
    my ($k, $v);
    while (($k, $v) = each %$r) {
	my $last = _last_rfc($v);
	print "$k => @$v (last=$last)\n" if $debug;

	# add myself to appear in the index.html
	# even if I am in the last node;
	$rfc_link->{ $k } = $k;

	$rfc_link->{ $last } .= " ".join(" ", @$v );
    }
}


sub _last_rfc
{
    my ($ra) = @_;
    my (@rev) = reverse @$ra;
    return $rev[0];
}


sub _combine
{
    my ($result_link) = @_;

    for my $rfc (sort {$a<=>$b} keys %rfc_exists) {
	my (@linklist);
	my (@buf) = split(/\s+/, join(" ", 
				      $rfc_prev{ $rfc }, 
				      $rfc, 
				      $rfc_next{ $rfc }));

	for my $rfc (@buf) {
	    if (defined $rfc_prev{$rfc}) {
		push(@linklist, split(/\s+/, $rfc_prev{$rfc}));
	    }

	    push(@linklist, $rfc);
	}

	my $x = _remove_dup( \@linklist );
	$result_link->{ $rfc } = _remove_dup( \@linklist );
    }
}


sub _sort_links
{
    my ($ra, $rb) = ($a, $b); 
    $ra =~ s/RFC//i;
    $rb =~ s/RFC//i;
    $rb <=> $ra;
}


sub _remove_dup
{
    my ($ra) = @_;
    my (%uniq);
    my (@rbuf);

    for (@$ra) {
	next if $uniq{$_};
	$uniq{$_} = 1;
	push(@rbuf, $_);
    }

    return \@rbuf;
}


sub _analyze_links
{
    my ($rfc, $s) = @_;
    $s =~ s/\n/ /g; # one line

    # Title of RFC.  Author 1, Author 2, Author 3.  Issue date.
    # (Format: ASCII) (Obsoletes xxx) (Obsoleted by xxx) (Updates xxx)
    # (Updated by xxx) (Also FYI ####) (Status: ssssss)

    if ($s =~ /(Obsoletes)([\s\w\d,]+)/i) {
	$rfc_prev{ $rfc } .= _clean_up($2);
	_check_exists($rfc_prev{ $rfc } );
    }

    if ($s =~ /(Updates)([\s\w\d,]+)/i) {
	$rfc_prev{ $rfc } .= _clean_up($2);
	_check_exists($rfc_prev{ $rfc } );
    }
    
    if ($s =~ /(Updated\s+by)([\s\w\d,]+)/i) {
	$rfc_next{ $rfc } .= _clean_up($2);
	_check_exists($rfc_next{ $rfc } );
    }

    if ($s =~ /(Obsoleted\s+by)([\s\w\d,]+)/i) {
	$rfc_next{ $rfc } .= _clean_up($2);
	_check_exists($rfc_next{ $rfc } );
    }
}


sub _rfc2filename
{
    my ($fn) = @_;

    $fn =~ s/RFC/rfc/;
    $fn =~ s/0(\d{3})/$1/;
    $fn .= ".txt";

    return $fn;
}


sub _check_exists
{
    my ($buf) = @_;

    for (split(/\s+/, $buf)) {
	if (/rfc\d+/i) {
	    my $fn = _rfc2filename($_);
	    unless (-f $fn) {
		print STDERR "no $fn, wget ... \n";
		system "wget http://www.ietf.org/rfc/$fn";
	    }
	}
    }
}


sub _clean_up
{
    my ($s) = @_;

    $s =~ s/\n/ /g;
    $s =~ s/,/ /g;
    $s =~ s/^\s+//g;

    return " $s ";
}



=head2 C<show( $result_hash )>

show rfc relation from the given $result_hash.
$result_hash contains the following hash pair.

    RFC-LAST => RFC-A RFC-B RFC-C ... RFC-LAST

=cut


sub show
{
    my ($r) = @_;

    print "<UL>\n";

    for my $last_rfc (sort _sort_links keys %$r) {
	my $v = $r-> { $last_rfc }; 
	my @r = sort _sort_links split(/\s+/, $v);

	my $links = _remove_dup( \@r );

	print "<LI>\n";
	print _href( $last_rfc ), "\n";
	print _who_i_am( $last_rfc );

	my $buf;
	for my $link (@$links) {
	    next if $link eq $last_rfc;
	    if ($link =~ /rfc\d+/i) {
		$buf .= "<A HREF=\"#$link\">$link</A>\n";
	    }
	}

	print "<BR> Updates:\n";
	print $buf ? $buf : "none";
	print "<BR>\n";
    }

    print "</UL>\n";
}


sub _href
{
    my ($rfc) = @_;
    my $fn = _rfc2filename($rfc);

    return "<A NAME=\"$rfc\" HREF=\"$fn\">$rfc</A>";
}


sub _who_i_am
{
    my ($rfc) = @_;
    my $buf = $rfc{ $rfc };

    $buf =~ s/^\d+\s//g;
    $buf =~ s/\n/ /g;
    $buf =~ s/\s+/ /g;

    if ($buf =~ /^(.*?)\.\s+/) {
	return "\"$1\"\n";
    }
}


1;
