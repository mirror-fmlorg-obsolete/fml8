#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: ls.pm,v 1.4 2002/09/22 14:56:45 fukachan Exp $
#

package FML::Command::Admin::ls;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


use FML::Command::Admin::dir;
@ISA = qw(FML::Command::Admin::dir);


# Descriptions: file/directory listings.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: forward request to dir module
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    $self->SUPER::process($curproc, $command_args);
}

=head1 NAME

FML::Command::Admin::ls - file/directory listings.

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

file/directory listings.
an alias of C<FML::Command::Admin::dir>.

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::ls first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
