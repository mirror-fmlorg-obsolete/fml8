#!/usr/local/bin/perl
#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: cachedir.pl,v 1.1 2001/04/04 03:10:09 fukachan Exp $
#

-d "/tmp/b" || mkdir("/tmp/b", 0755);


use File::CacheDir;

my $obj = new File::CacheDir {
    directory => "/tmp/b"
    };


&simple_write_to_ring_buffer($obj);

my $obj = new File::CacheDir {
    directory => "/tmp/b",
    file_name => "_smtplog.",
};

&simple_write_to_ring_buffer($obj);


my $obj = new File::CacheDir {
    directory  => "/tmp/b",
    cache_type => 'temporal',
};

&simple_write_to_ring_buffer($obj);


sub simple_write_to_ring_buffer
{
    my ($obj) = @_;

    if (defined $obj) {
	my $fh = $obj->open;
	$_ = `date`;
	print $fh $_;
	close($fh);
	$obj->close;
	system "ls -lR /tmp/b";
    }
    else {
	print "Error: undefined object: ";
	print $@, "\n";
    }
}
