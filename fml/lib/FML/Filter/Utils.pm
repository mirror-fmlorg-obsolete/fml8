#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Utils.pm,v 1.7 2001/12/23 13:46:14 fukachan Exp $
#

package FML::Filter::Utils;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Filter::Utils - useful subroutines for filtering

=head1 SYNOPSIS

collection of utility functions

=head1 DESCRIPTION

=head1 METHODS

=head2 C<is_valid_mail_address($string)>

1. check C<$strings> contains no Japanese string.

=cut


# Descriptions: $s is valid email address ?
#    Arguments: STR($s)
# Side Effects: none
# Return Value: 1 or 0
sub is_valid_mail_address
{
    my ($s) = @_;

    ($s !~ /\s|\033\$[\@B]|\033\([BJ]/ &&
     $s =~ /^[\0-\177]+\@[\0-\177]+$/) ? 1 : 0;
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Filter::Utils appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
