#-*- perl -*-
# Copyright (C) 2000,2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Config.pm,v 1.72 2002/09/22 14:56:39 fukachan Exp $
#

package FML::Config;

my $debug = 0;

use strict;
use Carp;
use vars qw($need_expansion_variables
	    %_fml_config_result
	    %_fml_config
	    %_default_fml_config
	    $object_id
	    $_fml_user_hooks
	    );
use ErrorStatus qw(error_set error error_clear);


=head1 NAME

FML::Config -- manipulate fml8 configuration file

=head1 SYNOPSIS

    $config = new FML::Config;

    # get the current value
    $config->{recipient_maps};

    # set the new value
    $config->{recipient_maps} = 'mysql:toymodel';

    # function style to get/set the value for the key "recipient_maps"
    $config->get('recipient_maps');
    $config->set('recipient_maps', 'mysql:toymodel');


=head1 DESCRIPTION

=head2 DATA STRUCTURE

C<$curproc> hash holds the CURrent PROCess information.
It contains several references to other data structures.

    $curproc = {
	# configurations
	config => {
	    key => value,
	},

	# struct incoming_message holds the mail input from STDIN.
	incoming_message => $r_msg,
	article          => $r_msg,
    };

where we use r_variable_name syntax where "r_" implies "reference to"
here.

For exapmle, this C<$r_msg> is the reference to a hash to represent a
mail message. It composes of header, body and several information.

    $r_msg = {
	r_header => \$header,p
	r_body   => \$body,
	info   => {
	    mime-version => 1.0,
	    content-type => {
		charset      => ISO-2022-JP,
	    },
	    size         => $size,
	},
    };

where $header is the object returned by Mail::Header class (CPAN
module) and the $body is the reference to the mail body region on
memory which locates within FML::Parse name space.

=head2 DELAYED VALUE EXPANSION

data manipulation of set() and get() is assymetric and asynchronous.

C<set(key,value)> saves the value for a key in C<%fml_config>.

C<get(key)> returns the value for a key in C<%fml_config_result>,
which is value expanded C<%fml_config>.
The expansion is done when C<get()> is called not when C<set()> is
called.

=head1 METHODS

=head2  C<new( ref_to_curproc )>

special method used only in the fml initialization phase.
This method binds $curproc and the %_fml_config hash on memory.

Internally this method uses C<tie()> to get and set a key to a value.
For example, C<get()> and C<set()> described below is a wrapper for
tie() IO.

C<NOTE:>
pseudo variable C<_pid> is reserved for process id reference.

=cut


# Descriptions: constructor.
#               newly blessed object is binded to internal variable
#               %_fml_config. So changes are shared among all objects.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: object is binded to common %_fml_config area
# Return Value: OBJ
sub new
{
    my ($self, $args) = @_;

    unless (defined %_fml_config) { %_fml_config = ( _pid => $$ );}

    # prepare the tied hash to %_fml_config;
    # to support $config->{ variable } syntax.
    my $me = {};
    tie %$me, $self;

    # import variables
    if (defined $args) {
	my ($k, $v);
	while (($k, $v) = each %$args) {
	    set($me, $k, $v);
	}
    }

    # unique object identifier
    set($me, "_object_id", $object_id++);

    return bless $me, $self;
}


=head2  C<get( key )>

get value for key.

=head2  C<get_as_array_ref( key )>

get value for key as an array reference.

=head2  C<set( key, value )>

set value for key.

=cut


# Descriptions: get vaule for $key
#    Arguments: OBJ($self) STR($key)
# Side Effects: update internal area
# Return Value: STR
sub get
{
    my ($self, $key) = @_;

    if (defined $key) {
	if (defined $self->{ $key }) {
	    return $self->{ $key };
	}
    }

    return '';
}


# Descriptions: get vaule for $key
#    Arguments: OBJ($self) STR($key)
# Side Effects: update internal area
# Return Value: ARRAY_REF
sub get_as_array_ref
{
    my ($self, $key) = @_;

    if (defined($key) && defined($self->{ $key })) {
	my $x = $self->{ $key };
	$x =~ s/^\s*//;
	$x =~ s/\s*$//;
	my (@x) = split(/\s+/, $x);
	return \@x;
    }
    else {
	return [];
    }
}


# Descriptions: set vaule for $key
#               flag on we need to re-evaludate variable expansion.
#    Arguments: OBJ($self) STR($key)
# Side Effects: update internal area
# Return Value: STR
sub set
{
    my ($self, $key, $value) = @_;

    if (defined $key && defined $value) {
	$self->{ $key } = $value;
	$need_expansion_variables = 1;

	if ($debug > 1) {
	    my (@c) = caller;
	    print "XXX $c[1] $c[2] ($key = $value)<br>\n";
	}
    }
}


# Descriptions: inform we need to expand variables again.
#    Arguments: OBJ($self)
# Side Effects: update internal area
# Return Value: NUM(1)
sub update
{
    my ($self) = @_;
    $need_expansion_variables = 1;
}


=head2  C<overload( filename )>

alias of C<load_file( filename )>.

=head2  C<load_file( filename )>

read the configuration file, split keys and the values in it and set
them to %_fml_config.

=cut


# Descriptions: load file
#    Arguments: OBJ($self) STR($file)
# Side Effects: none
# Return Value: none
sub overload
{
    my ($self, $file) = @_;
    $self->load_file($file);
}


# Descriptions: load file
#    Arguments: OBJ($self) STR($file)
# Side Effects: none
# Return Value: none
sub load_file
{
    my ($self, $file) = @_;
    my $config = \%_fml_config;

    # read configuration file
    $self->_read_file({
	file   => $file,
	config => $config,
    });

    # At the first time, save $config to another hash, which is used
    # as a default value at variable comparison.
    unless (%_default_fml_config) {
	%_default_fml_config = %_fml_config;
    }

    # flag on: we need $config->{ key } needs variable expansion
    $need_expansion_variables = 1;
}


# Descriptions: read configuration file and the keys and values to
#               $config (REF HASH).
#
#               XXX we should not reset $config since we permit
#               XXX $config can be overwritten.
#
#    Arguments: OBJ($self) HASH_REF($args)
#                     $file = configuration file
#                   $config = area to store {key => value } hash
# Side Effects: $config changes
# Return Value: none
sub _read_file
{
    my ($self, $args) = @_;
    my $file    = defined $args->{ 'file' }    ? $args->{ 'file' }    : '';
    my $config  = defined $args->{ 'config' }  ? $args->{ 'config' }  : {};
    my $comment = defined $args->{ 'comment' } ? $args->{ 'comment' } : {};
    my $order   = defined $args->{ 'order' }   ? $args->{ 'order' }   : [];
    my $mode    = defined $args->{ 'mode' }    ? $args->{ 'mode' } : 'default';

    # sanity
    return unless $file;

    # open the $file by using FileHandle.pm
    use FileHandle;
    my $fh = new FileHandle $file;

    if (defined $fh) {
	my ($key, $value, $curkey, $comment_buffer);
	my ($after_cut, $hook);
	my $name_space = ''; # by default

	# For example
	#    var = key1         (case 1.)
	#    var = key1 key2    (case 1.)
	#    var = key1         (case 1.)
	#          key2         (case 2.)
	#
	# [mysql:fml]
	#    var = key1 ...
	#
	while (<$fh>) {
	    # Example: [mysql:fml]
	    #   switched to the new name space.
	    if (/^\[([\w\d\:]+)\]\s*$/) {
		$name_space = "[$1]";
	    }

	    if ($after_cut) {
		$hook     .= $_ unless /^=/;
		$after_cut = 0  if /^=\w+/;
		next;
	    }
	    $after_cut = 1 if /^=cut/; # end of postfix format

	    if (/^=/) { # ignore special keywords of pod formats
		$name_space = '';
		next;
	    }

	    if ($mode eq 'raw') { # save comment buffer
		if (/^\s*\#/) { $comment_buffer .= $_;}
	    }
	    else { # by default, nuke trailing "\n"
		chomp;
	    }

	    # case 1. "key = value1"
	    if (/^([A-Za-z0-9_]+)\s*(=)\s*(.*)/   ||
		/^([A-Za-z0-9_]+)\s*(\+=)\s*(.*)/ ||
		/^([A-Za-z0-9_]+)\s*(\-=)\s*(.*)/) {
		my ($key, $xmode, $value) = ($1, $2, $3);
		$xmode  =~ s/=//;
		$value  =~ s/\s*$//o;
		$curkey = $key;

		# rewrite/update $config
		__update_config($config, $key, $value, $name_space, $xmode);

		# save variable order for re-construction e.g. used in write()
		if ($mode eq 'raw') {
		    $comment->{ $key } = $comment_buffer;
		    undef $comment_buffer;

		    print STDERR "push(@$order, $key);\n" if $debug;
		    push(@$order, $key);
		}
	    }
	    # case 2. "^\s+value2"
	    elsif (/^\s+(.*)/ && defined($curkey)) {
		my $value = $1;
		__append_config($config, $curkey, $value, $name_space);
	    }
	}
	$fh->close;

	# save hook configuration in FML::Config name space (global).
	$_fml_user_hooks .= $hook if defined $hook;
    }
    else {
	$self->error_set("Error: cannot open $file");
    }
}


# Descriptions: update $config
#    Arguments: OBJ($obj) STR($key) STR($value) STR($name_space) STR($mode)
# Side Effects: update $config
# Return Value: none
sub __update_config
{
    my ($config, $key, $value, $name_space, $mode) = @_;

    if ($mode) {
	if ($name_space) {
	    $config->{ $name_space }->{ $key } =
		_evaluate($config, $key, $mode, $value, $name_space);
	}
	else {
	    $config->{ $key } = _evaluate($config, $key, $mode, $value, 0);
	}
    }
    else { # by default
	if ($name_space) {
	    $config->{ $name_space }->{ $key } = $value;
	}
	else {
	    $config->{ $key } = $value;
	}
    }
}


# Descriptions: append $value into $config
#    Arguments: OBJ($obj) STR($key) STR($value) STR($name_space) STR($mode)
# Side Effects: update $config
# Return Value: none
sub __append_config
{
    my ($config, $key, $value, $name_space, $mode) = @_;

    $value =~ s/\s*$//o;

    if ($name_space) {
	$config->{ $name_space }->{ $key } .= " ". $value;
    }
    else {
	$config->{ $key } .= " ". $value;
    }
}


# Descriptions: fml special hack to read/write configuration
#               If key = "value1 value2 value3" and
#                  key -= value2 is given (mode = '-'),
#                  key becomes "value1 value3".
#               If "key += value4, key becomes
#                  "value1 value2 value3 value4".
#    Arguments: OBJ($config) STR($key) STR($mode) STR($value)
# Side Effects: update $config by $mode
# Return Value: STR(new value for $config{ $key })
sub _evaluate
{
    my ($config, $key, $mode, $value, $name_space) = @_;
    my @buf = ();

    if ($name_space) {
	if (defined $config->{ $name_space }->{ $key }) {
	    @buf = split(/\s+/, $config->{ $name_space }->{ $key });
	}
    }
    else {
	if (defined $config->{ $key }) {
	    @buf = split(/\s+/, $config->{ $key });
	}
    }

    # + value = append
    if ($mode eq '+') {
	push(@buf, $value);
    }
    # - $value = remove $value from the values of $key
    elsif ($mode eq '-') {
	my @newbuf = ();

      BUF:
	for my $s (@buf) {
	    next BUF unless defined $s;
	    next BUF unless $s;
	    push(@newbuf, $s) if $value ne $s;
	}

	@buf = @newbuf;
    }

    if (@buf) {
	return join(" ", @buf);
    }
    else {
	return '';
    }
}


=head2 C<read(file)>

read configuration from the specified file.
Internally it holds configuration and comment information in
appearing order.

=head2 C<write(file)>

=cut


# allocate space to hold
my $config_hold_space = {};


# Descriptions: read $file and push the content into $config
#    Arguments: OBJ($self) STR($file)
# Side Effects: open file
# Return Value: none
sub read
{
    my ($self, $file) = @_;
    my $config  = {};
    my $comment = {};
    my $order   = [];

    $self->_read_file({
	file    => $file,
	config  => $config,
	comment => $comment,
	order   => $order,
	mode    => 'raw',
    });

    # XXX debug: removed in the future
    if ($debug) {
	my ($k, $v);
	while (($k, $v) = each %$config) {
	    print STDERR "\nconfig{ $k } =>\n";
	    print STDERR "          $v\n";
	    if (defined $comment->{ $k }) {
		my $comment = $comment->{ $k };
		print STDERR " comment\n{$comment}\n";
	    }
	}
    }

    # save the value in the object
    my $object_id = $self->{ _object_id };
    $config_hold_space->{ $object_id }->{ config }  = $config;
    $config_hold_space->{ $object_id }->{ comment } = $comment;
    $config_hold_space->{ $object_id }->{ order  }  = $order;
}


# Descriptions: save $config into $file
#    Arguments: OBJ($self) STR($file)
# Side Effects: rewrite $file
# Return Value: none
sub write
{
    my ($self, $file) = @_;
    my $object_id = $self->{ _object_id };
    my $config  = $config_hold_space->{ $object_id }->{ config };
    my $comment = $config_hold_space->{ $object_id }->{ comment };
    my $order   = $config_hold_space->{ $object_id }->{ order  };

    # 1. check whether I can open $file or not in atomic way.
    #    XXX get handle to update $file
    my $fh = IO::Adapter::AtomicFile->open($file);

    # 2. back up config.cf firstly
    my $status = IO::Adapter::AtomicFile->copy($file, $file.".bak");
    unless ($status) {
	croak "cannot backup $file";
    }

    # 3. write config
    if (defined $fh) {
	$fh->autoflush(1);

	# XXX it works not well ??? ( regist() not works ??)
	# XXX get variable list modified in this process
	my $newkeys = $self->{ _newly_added_keys };
	for my $k (@$order, @$newkeys) {
	    if ($debug && defined $comment->{$k}) {
		print STDERR "write.config{ ", $comment->{$k}, " }";
		print STDERR join("\n\t", split(/\s+/, $config->{$k})), "\n";
	    }

	    print $fh $comment->{$k} if defined $comment->{$k};
	    print $fh "$k = ";
	    if (defined $config->{$k}) {
		print $fh join("\n\t", split(/\s+/, $config->{$k}));
	    }
	    print $fh "\n";
	    print $fh "\n";
	}

	$fh->close; # XXX $fh is atomic open.
    }
    else {
	use Carp;
	carp("cannot open > $file");
    }
}


=head2 C<expand_variables()>

expand all variables in C<%_default_fml_config> and C<%_fml_config>.
The expanded result is saved in the same hash.

  XXX obsolete ? This method is used before hook is introduced.
  XXX Consider a hook may change the variable.
  XXX We should expand variables on demand in that case

=cut


my $debug_sql = 0;


# Descriptions: expand variable name
#               e.g. $dir/xxx -> /var/spool/ml/elena/xxx
#    Arguments: OBJ($self)
# Side Effects: update config
# Return Value: none
sub expand_variables
{
    my ($self) = @_;

    # always expand variables within itself.
    _expand_variables( \%_default_fml_config );
    # _expand_nextlevel( \%_default_fml_config ); # XXX looks not needed ?

    # XXX 2001/05/05
    # XXX %_fml_config        has variables before expansion.
    # XXX %_fml_config_result has variables after expansion.
    # XXX copying is important here.
    __hash_copy(\%_fml_config_result, \%_fml_config);

    _expand_variables( \%_fml_config_result );
    _expand_nextlevel( \%_fml_config_result );
}


# Descriptions: copy hash (HASH_REF)
#    Arguments: HASH_REF($dst) HASH_REF($src)
# Side Effects: none
# Return Value: none
sub __hash_copy
{
    my ($dst, $src) = @_;
    my ($key, $value);

    while (($key, $value) = each %$src) {
	if (ref($value) eq 'HASH') {
	    my $hash_ref = $value;
	    my $newhash  = {};
	    my ($k, $v);
	    while (($k, $v) = each %$hash_ref) { $newhash->{ $k } = $v;}
	    $dst->{ $key } = $newhash;
	}
	else {
	    $dst->{ $key } = $src->{ $key };
	}
    }
}


# Descriptions: update config in the next level name space e.g. [mysql:xxx]
#    Arguments: OBJ($config)
# Side Effects: update config
# Return Value: none
sub _expand_nextlevel
{
    my ($config) = @_;

    for my $ns (keys %$config) {
	# only for the special map such as '[mysql:fml']
	if ($ns =~ /^\[/o) {
	    # XXX variable expansion within the next level.
	    my $hash = $config->{ $ns };
	    _expand_variables( $hash, $config );
	}
    }
}


# Descriptions: variable expansion
#    Arguments: OBJ($config)
# Side Effects: variable expansion in $config
# Return Value: none
sub _expand_variables
{
    my ($config, $hints) = @_;
    my @order  = keys %$config;

    # check whether the variable definition is recursive.
    # For example, definition "var_a = $var_a/b/c" causes a loop.
    for my $x ( @order ) {
	if (defined $config->{ $x } &&
	    $config->{ $x } =~ /\$$x/) {
	    croak("loop1: definition of $x is recursive\n");
	}
    }

    # main expansion loop
    my $org = '';
    my $max = 0;
  KEY:
    for my $x ( @order ) {
	next KEY unless defined $config->{ $x };
	next KEY if $config->{ $x } !~ /\$/o;

	# we need a loop to expand nested variables, for example,
	# "a = $x/y" and "b = $a/c/0" would be "b = $x/y/c/0"

	$max = 0;
      EXPANSION_LOOP:
	while ($max++ < 16) {
	    $org = $config->{ $x };

	    $config->{$x} =~
		s/\$([a-z_]+[a-z0-9])/(defined $config->{$1} ?
				       $config->{$1} :
				       (defined $hints->{$1} ?
					$hints->{$1} :
					''
					))/ge;

	    __expand_special_macros( $config, $x );

	    last EXPANSION_LOOP if $config->{ $x } !~ /\$/o;
	    last EXPANSION_LOOP if $org eq $config->{ $x };

	    if ($config->{ $x } =~ /\$$x/) {
		croak("loop2: definition of $x is recursive\n");
	    }
        }

	if ($max >= 16) {
	    croak("variable expansion of $x causes infinite loop\n");
	}
    }
}


# Descriptions: expand READ_ONLY(a b c) -> READ_ONLY(a) READ_ONLY(b) ...
#    Arguments: OBJ($config) STR($x)
# Side Effects: rewrite $config
# Return Value: none
sub __expand_special_macros
{
    my ( $config, $x ) = @_;

    return unless defined $config;
    return unless defined $x;
    return unless defined $config->{ $x };

    if ($config->{ $x } =~ /READ_ONLY\((.*)\)/) {
	my (@x) = split(/\s+/, $1);
	my $v   = '';
	for my $key (@x) { $v .= " READ_ONLY($key)";}

	$config->{ $x } =~ s/READ_ONLY\((.*)\)/$v/;
    }
}


=head2 C<expand_variable_in_buffer($rbuf)>

expand $varname to $config->{ varname } in C<$rbuf>.

=cut


# Descriptions: expand $varname to $config->{ varname }
#    Arguments: OBJ($config) STR_REF($rbuf) HASH_REF($args)
# Side Effects: $ref_buffer is rewritten.
# Return Value: none
sub expand_variable_in_buffer
{
    my ($config, $rbuf, $args) = @_;
    my $loop_max = 16;
    my $loop     = 0;

  EXPAND:
    while ($$rbuf =~ /\$([\w\d\_]+)/) {
	# in some case, we cannot expand ;)
	# for example, $FML which is not defined in config.cf.
	last EXPAND if $loop++ > $loop_max;

	my $varname = $1;
	if (defined $config->{ $varname }) {
	    my $x = $config->{ $varname };
	    $$rbuf =~ s/\$$varname/$x/;
	}
	if (defined $args->{ $varname }) {
	    my $x = $args->{ $varname };
	    $$rbuf =~ s/\$$varname/$x/;
	}
    }
}


=head2 C<yes( key )>

useful method to return 1 or 0 according the value to the given key.

=head2 C<no( key )>

useful method to return 1 or 0 according the value to the given key.

=head2 C<has_attribute( key, attribute )>

Some types of C<key> has a list as a value.
If C<key> has the C<attribute> in the list, return 1.
return 0 if not.

=cut


# Descriptions: return 1 if the value of the key is "yes"
#    Arguments: OBJ($self) STR($key)
# Side Effects: none
# Return Value: 1 or 0
sub yes
{
    my ($self, $key) = @_;

    if (defined $_fml_config{$key}) {
	$_fml_config{$key} eq 'yes' ? 1 : 0;
    }
    else {
	0;
    }
}


# Descriptions: return 1 if the value of the key is "no"
#    Arguments: OBJ($self) STR($key)
# Side Effects: none
# Return Value: 1 or 0
sub no
{
    my ($self, $key) = @_;

    if (defined $_fml_config{$key}) {
	$_fml_config{$key} eq 'no' ? 1 : 0;
    }
    else {
	0;
    }
}


# Descriptions: check the attribute for $key
#               e.g. has_attribute( "available_command_list" , "help" );
#    Arguments: OBJ($self) STR($key) STR($attribute)
# Side Effects: none
# Return Value: 1 or 0
sub has_attribute
{
    my ($self, $key, $attribute) = @_;

    # sanity
    return 0 unless defined $attribute;

    if (defined $_fml_config_result{$key}) {
	my (@attribute) = split(/\s+/, $_fml_config_result{$key});

      ATTR:
	for my $k (@attribute) {
	    next ATTR unless defined $k;

	    return 1 if $k eq $attribute;
	}
    }

    return 0;
}


=head2  C<dump_variables()>

show all {key => value} for debug.

=cut


# Descriptions: dump all variables
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub dump_variables
{
    my ($self, $args) = @_;
    my ($k, $v);
    my $len     = 0;
    my $use_sql = 0;
    my $mode    = $args->{ mode } || 'all';

    $self->expand_variables();

    for $k (keys %_fml_config_result) {
	$len = $len > length($k) ? $len : length($k);
    }

    my $format = '%-'. $len. 's = %s'. "\n";
    for $k (sort keys %_fml_config_result) {
	$use_sql = 1 if $k =~ /^\[/o;

	next unless $k =~ /^[a-z0-9]/io;
	$v = $_fml_config_result{ $k };

	# print out all keys
	if ($mode eq 'all') {
	    printf $format, $k, $v;
	}
	# compare the value with the default one
	# print key if values for the key differs.
	else {
	    if (defined $_default_fml_config{ $k }) {
		if ($v ne $_default_fml_config{ $k }) {
		    printf $format, $k, $v;
		}
	    }
	    else {
		printf $format, $k, $v;
	    }
	}
    }

    if ($use_sql) {
	for $k (sort keys %_fml_config_result) {
	    if ($k =~ /^\[/o) {
		my $hash_ref = $_fml_config_result{ $k };

		print "\n$k\n";
		my ($k, $v);
		for $k (sort keys %$hash_ref) {
		    $v = $hash_ref->{ $k };
		    printf $format, $k, $v;
		}
	    }
	}
    }
}


=head1 HOOK manipulations

    $config->is_hook_defined( 'START_HOOK' );
    $config->get_hook( 'START_HOOK' );

=head2 is_hook_defined( $hook_name )

whether hook named as $hook_name is defined or not?

=cut


# Descriptions: $hook_name is defined ?
#    Arguments: OBJ($self) STR($hook_name)
# Side Effects: update FML::Config::Hook name space.
# Return Value: NUM(1 or 0)
sub is_hook_defined
{
    my ($self, $hook_name) = @_;

    return undef unless $_fml_user_hooks;

    eval qq{
	package FML::Config::Hook;
	no strict;
	$FML::Config::_fml_user_hooks;
	package FML::Config;
    };
    print STDERR $@ if $@;

    my $is_defined = 0;
    my $hook = sprintf("%s::%s::%s::%s", 'FML', 'Config', 'Hook', $hook_name);

    eval qq{
	if (defined( $hook )) {
	    \$is_defined = 1;
	}
    };
    print STDERR $@ if $@;

    return $is_defined;
}


# Descriptions: return hook content named as $hook_name.
#               XXX $hook_name as a parameter is case insensitive.
#    Arguments: OBJ($self) STR($hook_name)
# Side Effects: update FML::Config::Hook name space.
# Return Value: STR
sub get_hook
{
    my ($self, $hook_name) = @_;

    return undef unless defined $_fml_user_hooks;
    return undef unless $_fml_user_hooks;

    my $eval = qq{
	package FML::Config::Hook;
	no strict;
	$FML::Config::_fml_user_hooks;
	package FML::Config;
    };
    eval $eval;
    print STDERR $@ if $@;

    my $r    = ''; # return value;
    my $namel = $hook_name; $namel =~ tr/A-Z/a-z/; # lowercase
    my $nameu = $hook_name; $nameu =~ tr/a-z/A-Z/; # uppercase
    my $hookl = sprintf("\$%s::%s::%s::%s", 'FML', 'Config', 'Hook', $namel);
    my $hooku = sprintf("\$%s::%s::%s::%s", 'FML', 'Config', 'Hook', $nameu);

    # check both lower and upper case e.g. start_hook and START_HOOK.
    eval qq{
	if (defined( $hookl )) {
	    \$r = $hookl;
	}
	elsif (defined( $hooku )) {
	    \$r = $hooku;
	}
    };
    print STDERR $@ if $@;

    return "no strict;\n". $r;
}


=head1 TIEED HASH

tie() operations for hash are binded to \%_fml_config.
For example, C<get()> and C<set()> described above is a wrapper for
tie() IO.

=cut


# Descriptions: begin op for tie() with %_fml_config
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: OBJ
sub TIEHASH
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = \%_fml_config;
    return bless $me, $type;
}



# Descriptions: FETCH op for tie() with %_fml_config
#    Arguments: OBJ($self) STR($key)
# Side Effects: none
# Return Value: STR or UNDEF
sub FETCH
{
    my ($self, $key) = @_;

    if ($need_expansion_variables) {
	$self->expand_variables();
	$need_expansion_variables = 0;
    }

    if (defined($_fml_config_result{$key})) {
	my $x = $_fml_config_result{$key};

	# HASH_REF such as [mysql:fml] => { ... }
	if (ref($x)) {
	    return $x;
	}
	# scalar variables
	else {
	    $x =~ s/\s*$//;
	    return $x;
	}
    }
    else {
	undef;
    }
}


# Descriptions: STORE op for tie() with %_fml_config
#    Arguments: OBJ($self) STR($key) STR($value)
# Side Effects: update %_fml_config
# Return Value: STR or UNDEF
sub STORE
{
    my ($self, $key, $value) = @_;

    # inform fml we need to expand variable again when FETCH() is
    # called.
    if (defined $value && $value =~ /\$/) {
	$need_expansion_variables = 1;
    }

    if (defined $key && defined $value) {
	$_fml_config{$key} = $value;
    }
}


# Descriptions: DELETE op for tie() with %_fml_config
#    Arguments: OBJ($self) STR($key)
# Side Effects: update %_fml_config
# Return Value: none
sub DELETE
{
    my ($self, $key) = @_;

    delete $_fml_config_result{$key};
    delete $_fml_config{$key};
}


# Descriptions: CLEAR op for tie() with %_fml_config
#    Arguments: OBJ($self)
# Side Effects: update %_fml_config
# Return Value: none
sub CLEAR
{
    my ($self) = @_;

    undef %_fml_config_result;
    undef %_fml_config;
}


# Descriptions: FIRSTKEY op for tie() with %_fml_config
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub FIRSTKEY
{
    my ($self) = @_;
    my @keys = keys %_fml_config_result;
    $self->{ '_keys' } = \@keys;

    my $keys = $self->{ _keys };
    shift @$keys;
}


# Descriptions: NEXTKEY op for tie() with %_fml_config
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub NEXTKEY
{
    my ($self) = @_;
    my $keys = $self->{ '_keys' };
    shift @$keys;
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2000,2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Article first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
