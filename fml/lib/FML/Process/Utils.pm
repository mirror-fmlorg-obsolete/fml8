#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004,2005,2006,2008 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Utils.pm,v 1.153 2008/09/09 09:47:57 fukachan Exp $
#

package FML::Process::Utils;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use File::Spec;
use File::stat;

my $debug = 0;


=head1 NAME

FML::Process::Utils - convenient utilities for FML::Process:: classes.

=head1 SYNOPSIS

See L<FML::Process::Kernel>.

=head1 DESCRIPTION

See FML:: classes, which uses these function everywhere.

=head1 access METHODS to handle configuration space

=head2 config()

return FML::Config object.

=head2 pcb()

return FML::PCB object.

=head2 schduler()

return FML::Process::Scheduler object.

=cut


# Descriptions: return FML::Config object.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub config
{
    my ($curproc) = @_;

    if (defined $curproc->{ config }) {
	return $curproc->{ config };
    }
    else {
	return undef;
    }
}


# Descriptions: return FML::PCB object.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub pcb
{
    my ($curproc) = @_;

    if (defined $curproc->{ pcb }) {
	return $curproc->{ pcb };
    }
    else {
	return undef;
    }
}


# Descriptions: return FML::Process::Scheduler object.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub scheduler
{
    my ($curproc) = @_;

    if (defined $curproc->{ scheduler }) {
	return $curproc->{ scheduler };
    }
    else {
	return undef;
    }
}


# Descriptions: return credential object.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub credential
{
    my ($curproc) = @_;

    if (defined $curproc->{ credential }) {
	return $curproc->{ credential };
    }
    else {
	return undef;
    }
}


=head1 access METHODS to handle incoming_message

available all processes which eats message via STDIN.

The following functions return the whole or a part of the incoming
message corresponding to the current process.

The message is a chain of C<Mail::Message> objects such as

   header -> body

   header -> multipart-preamble -> multipart-separator -> part1 -> ...

See L<Mail::Message> for more details.

=head2 incoming_message_header()

return the header part for the incoming message.
It is the head of a chain of Mail::Message objects.

=head2 incoming_message_body()

return the body part for the incoming message.
It is the 2nd part of a chain of Mail::Message objects and after.
For example,

   body

   multipart-preamble -> multipart-separator -> part1 -> ...

=head2 incoming_message()

return the whole message for the incoming message.
It is the whole parts of a chain.

=cut


# Descriptions: return incoming_message header object if could.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub incoming_message_header
{
    my ($curproc) = @_;

    if (defined $curproc->{ incoming_message }->{ header }) {
	return $curproc->{ incoming_message }->{ header };
    }
    else {
	return undef;
    }
}


# Descriptions: return incoming_message body object if could.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub incoming_message_body
{
    my ($curproc) = @_;

    if (defined $curproc->{ incoming_message }->{ body }) {
	return $curproc->{ incoming_message }->{ body };
    }
    else {
	return undef;
    }
}


# Descriptions: return incoming_message message object if could.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub incoming_message
{
    my ($curproc) = @_;

    if (defined $curproc->{ incoming_message }->{ message }) {
	return $curproc->{ incoming_message }->{ message };
    }
    else {
	return undef;
    }
}


# Descriptions: set the incoming_message cached file path.
#    Arguments: OBJ($curproc) STR($path)
# Side Effects: none
# Return Value: none
sub incoming_message_set_cache_file_path
{
    my ($curproc, $path) = @_;
    my $pcb = $curproc->pcb();
    if ($path) {
	$pcb->set("incoming_message", "file_path", $path);
    }
}


# Descriptions: get the incoming_message cached file path.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub incoming_message_get_cache_file_path
{
    my ($curproc) = @_;
    my $pcb  = $curproc->pcb();
    my $path = $pcb->get("incoming_message", "file_path");
    return( $path || '' );
}


=head2 incoming_message_set_current_queue($queue)

save object of incoming queue.

=head2 incoming_message_get_current_queue()

get object of incoming queue.

=cut


# Descriptions: save object of incoming queue.
#    Arguments: OBJ($curproc) OBJ($queue)
# Side Effects: update pcb.
# Return Value: none
sub incoming_message_set_current_queue
{
    my ($curproc, $queue) = @_;
    my $pcb = $curproc->pcb();

    if (defined $pcb) {
	$pcb->set("incoming_smtp_transaction", "queue_object", $queue);
    }
    else {
	$curproc->logerror("no pcb");
	return undef;
    }
}


# Descriptions: get object of incoming queue.
#    Arguments: OBJ($curproc)
# Side Effects: update pcb.
# Return Value: OBJ
sub incoming_message_get_current_queue
{
    my ($curproc) = @_;
    my $pcb = $curproc->pcb();

    if (defined $pcb) {
	$pcb->get("incoming_smtp_transaction", "queue_object") || undef;
    }
    else {
	$curproc->logerror("no pcb");
	return undef;
    }
}


# Descriptions: stack queue object for later removal. removal is done
#               when incoming_message_mark_cache_file_for_removal() runs.
#    Arguments: OBJ($curproc) OBJ($queue)
# Side Effects: none
# Return Value: STR
sub incoming_message_stack_queue_for_removal
{
    my ($curproc, $queue) = @_;
    my $shm = $curproc->shared_hash_get("incoming_message",
					"queue_stack_for_removal");

    if (defined $queue) {
	my $qid = $queue->id();
	$curproc->logdebug("push qid=$qid for removal");
	my $a = $shm->{ stack } || [];
	push(@$a, $queue);
	$shm->{ stack } = $a;
    }
}


# Descriptions: remove files marked as later removal.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub incoming_message_remove_queue
{
    my ($curproc) = @_;

    # 1. remove current incoming queue.
    my $queue = $curproc->incoming_message_get_current_queue() || undef;
    if (defined $queue) {
	$queue->remove();
    }

    # 2. additional todo (e.g. fetchfml requests).
    my $shm = $curproc->shared_hash_get("incoming_message",
					"queue_stack_for_removal");

    my $rmlist = $shm->{ stack } || [];
    for my $q (@$rmlist) {
	if (defined $q) {
	    my $qid = $q->id();
	    $curproc->logdebug("remove qid=$qid");
	    $q->remove();
	}
    }
}


=head2 incoming_message_print_body_as_file()

dupliate the body part into a temporary file.
return a newly created temporary file path.

=cut


# Descriptions: dupliate the body part into a temporary file.
#    Arguments: OBJ($curproc) OBJ($queue)
# Side Effects: create a temporary file.
# Return Value: STR
sub incoming_message_print_body_as_file
{
    my ($curproc, $queue) = @_;
    my $cache_file = $curproc->incoming_message_get_cache_file_path();
    my $tmp_file   = $curproc->tmp_file_path();

    if (-f $cache_file) {
	my $rh = new FileHandle $cache_file;
	my $wh = new FileHandle "> $tmp_file";
	if (defined $rh && defined $wh) {
	    my $found = 0;
	    my $buf;
	  LINE:
	    while ($buf = <$rh>) {
		unless ($found) {
		    if ($buf =~ /^$/o) {
			$found = 1;
		    }
		    next LINE;
		}
		print $wh $buf;
	    }
	    $wh->close();
	    $rh->close();

	    return $tmp_file;
	}
	else {
	    my $myname = "incoming_message_dup_body";
	    unless (defined $rh) {
		$curproc->logerror("$myname: cannot open $cache_file");
	    }
	    unless (defined $wh) {
		$curproc->logerror("$myname: cannot open $tmp_file");
	    }

	    return undef;
	}
    }
    else {
	$curproc->logerror("incoming_message_dup_body: no cache");
	return undef;
    }
}


=head2 incoming_message_dup_content($new_class)

dupliate the incoming queue at $new_class.

=head2 incoming_message_isolate_content()

dupliate the incoming queue at isolated queue.

=cut


# Descriptions: dupliate the queue in $new_class.
#    Arguments: OBJ($curproc) STR($new_class)
# Side Effects: create another queue file.
# Return Value: STR
sub incoming_message_dup_content
{
    my ($curproc, $new_class) = @_;

    # ASSERT
    unless ($new_class) {
	return undef;
    }

    my $queue = $curproc->incoming_message_get_current_queue();
    if (defined $queue) {
	if ($new_class) {
	    my $cur_class = "incoming";
	    my $new_qid = $queue->dup_content($cur_class, $new_class);
	    if ($new_qid) {
		return $new_qid;
	    }
	    else {
		return undef;
	    }
	}
    }
    else {
	$curproc->logerror("no incoming queue");
    }

    return undef;
}


# Descriptions: isolate the incoming queue to isolated queue.
#    Arguments: OBJ($curproc)
# Side Effects: create another queue file.
# Return Value: STR
sub incoming_message_isolate_content
{
    my ($curproc) = @_;

    my $new_class = "isolated";
    $curproc->incoming_message_dup_content($new_class);
}


=head1 access METHODS to handle article

available only in C<libexec/distribute> process.

The usage of these functions is same as that of incoming_message_*()
methods but article_*() hanldes the article object to distribute now.
So, incoming_message_*() handles input but article_message_*() handles
output.

=head2 article_message_header()

=head2 article_message_body()

=head2 article_message()

=cut


# Descriptions: return article header object if could.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub article_message_header
{
    my ($curproc) = @_;

    if (defined $curproc->{ article }->{ header }) {
	return $curproc->{ article }->{ header };
    }
    else {
	$curproc->logerror("\$curproc->{ article }->{ header } not defined");
	return undef;
    }
}


# Descriptions: return article body object if could.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub article_message_body
{
    my ($curproc) = @_;

    if (defined $curproc->{ article }->{ body }) {
	return $curproc->{ article }->{ body };
    }
    else {
	$curproc->logerror("\$curproc->{ article }->{ body } not defined");
	return undef;
    }
}


# Descriptions: return article message object if could.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub article_message
{
    my ($curproc) = @_;

    if (defined $curproc->{ article }->{ message }) {
	return $curproc->{ article }->{ message };
    }
    else {
	$curproc->logerror("\$curproc->{ article }->{ message } not defined");
	return undef;
    }
}


=head1 OUR POLICY UTILITY

=head2 policy_ignore_this_message($reason)

ignore this message by our policy.

=head2 policy_reject_this_message($reason)

reject this message by our policy. It returns error message to the
sender.

=cut


# Descriptions: ignore this message by our policy.
#    Arguments: OBJ($curproc) STR($reason)
# Side Effects: none
# Return Value: none
sub policy_ignore_this_message
{
    my ($curproc, $reason) = @_;
    $curproc->stop_this_process($reason);
}


# Descriptions: reject this message by our policy.
#               return error message to the sender.
#    Arguments: OBJ($curproc) STR($reason)
# Side Effects: none
# Return Value: none
sub policy_reject_this_message
{
    my ($curproc, $reason) = @_;
    $curproc->stop_this_process($reason);
    $curproc->reply_message_nl('error.reject', 'reject your message');
}


=head1 misc METHODS

=head2 mkdir($dir, $mode)

create directory $dir if needed.

=cut


#
# XXX-TODO: $curproc->mkdir() is strange.
# XXX-TODO: hmm, we create a new subcleass such as $curproc->util->mkdir() ?
# XXX-TODO: or $utils = $curproc->utils(); $utils->mkdir(dir, mode); ?
# XXX-TODO: we need FML::Utils class ?
#


# Descriptions: create directory $dir if needed.
#    Arguments: OBJ($curproc) STR($dir) STR($mode)
# Side Effects: create directory $dir
# Return Value: NUM(1 or 0)
sub mkdir
{
    my ($curproc, $dir, $mode) = @_;
    my $config  = $curproc->config();
    my $dirmode = $config->{ directory_default_mode } || '0700';

    # back up umask
    my $curmask = umask( 077 ); # full open for readability

    unless (-d $dir) {
	if (defined $mode) {
	    if ($mode =~ /^\d+$/o) { # NUM 0700
		$curproc->_mkpath_num($dir, $mode);
	    }
	    elsif ($mode =~ /mode=(\S+)/o) {
		my $xmode = "directory_${1}_mode";
		if (defined $config->{ $xmode } && $config->{ $xmode }) {
		    $curproc->_mkpath_str($dir, $config->{ $xmode });
		}
		else {
		    $curproc->logerror("mkdir: invalid mode");
		}
	    }
	    else {
		$curproc->logerror("mkdir: invalid mode");
	    }
	}
	elsif ($dirmode =~ /^\d+$/o) { # STR 0700
	    $curproc->_mkpath_str($dir, $dirmode);
	}
	else {
	    $curproc->logerror("mkdir: invalid mode");
	}
    }

    return( -d $dir ? 1 : 0 );
}


# Descriptions: mkdir with the specified dir mode.
#    Arguments: OBJ($curproc) STR($dir) NUM($mode)
# Side Effects: mkdir && chmod
# Return Value: none
sub _mkpath_num
{
    my ($curproc, $dir, $mode) = @_;
    my $cur_mask = umask();

    umask(0);

    if ($mode =~ /^\d+$/o) {   # NUM 0700
	$mode = oct("$mode");  # STR -> OCTal
	eval q{ use File::Path;};
	mkpath([ $dir ], 0, $mode);
	chmod $mode, $dir;
	$curproc->log(sprintf("mkdir %s mode=0%o", $dir, $mode));
    }
    else {
	$curproc->logerror("mkdir: invalid mode (N)");
    }

    umask($cur_mask);
}


# Descriptions: mkdir with the specified dir mode.
#    Arguments: OBJ($curproc) STR($dir) STR($mode)
# Side Effects: mkdir && chmod
# Return Value: none
sub _mkpath_str
{
    my ($curproc, $dir, $mode) = @_;
    my $cur_mask = umask();

    umask(0);

    if ($mode =~ /^\d+$/o) { # STR 0700
	eval qq{
	    use File::Path;
	    mkpath([ \$dir ], 0, $mode);
	    chmod $mode, \$dir;
	    \$curproc->log(\"mkdir \$dir mode=$mode\");
	};
	$curproc->logerror($@) if $@;
    }
    else {
	$curproc->logerror("mkdir: invalid mode (S)");
    }

    umask($cur_mask);
}


# XXX-TODO: $curproc->mkfile() is strange.

# Descriptions: create a file.
#    Arguments: OBJ($curproc) STR($file)
# Side Effects: none
# Return Value: none
sub mkfile
{
    my ($curproc, $file) = @_;

    unless (-f $file) {
	use IO::Adapter;
	my $obj = new IO::Adapter $file;
	$obj->touch();

	# verify
	unless (-f $file) {
	    $curproc->logerror("fail to create file: $file");
	}
    }
}


# XXX-TODO: $curproc->touch() is strange.

# Descriptions: create a file.
#    Arguments: OBJ($curproc) STR($file)
# Side Effects: none
# Return Value: none
sub touch
{
    my ($curproc, $file) = @_;
    $curproc->mkfile($file);
}


# XXX-TODO: $curproc->copy() is strange.

# Descriptions: copy $dst to $src in atomic way.
#    Arguments: OBJ($curproc) STR($src) STR($dst)
# Side Effects: $dst file created.
# Return Value: none
sub copy
{
    my ($curproc, $src, $dst) = @_;

    use IO::Adapter::AtomicFile;
    my $obj = new IO::Adapter::AtomicFile;
    $obj->new->copy($src, $dst);
}


# XXX-TODO: $curproc->append() is strange.

# Descriptions: append content within $src file into $dst file.
#    Arguments: OBJ($curproc) STR($src) STR($dst)
# Side Effects: $dst file created or updated.
# Return Value: none
sub append
{
    my ($curproc, $src, $dst) = @_;

    use FileHandle;
    my $rh = new FileHandle $src;
    my $wh = new FileHandle ">> $dst";
    if (defined($rh) && defined($wh)) {
	$wh->autoflush(1);

	my $buf = '';
	while ($buf = <$rh>) {
	    print $wh $buf;
	}

	$wh->close();
	$rh->close();
    }
    else {
	croak("fail to open $src") unless defined $rh;
	croak("fail to open $dst") unless defined $wh;
    }
}


# XXX-TODO: $curproc->cat() is strange.

# Descriptions: concantenate files to STDOUT.
#    Arguments: OBJ($curproc) ARRAY_REF($files) HANDLE($out)
# Side Effects: none
# Return Value: none
sub cat
{
    my ($curproc, $files, $out) = @_;
    $out ||= \*STDOUT;

    for my $file (@$files) {
	_cat($file, $out);
    }
}


# Descriptions: cat file to STDOUT.
#    Arguments: STR($file) HANDLE($out)
# Side Effects: none
# Return Value: none
sub _cat
{
    my ($file, $out) = @_;

    use FileHandle;
    my $fh = new FileHandle $file;
    if (defined $fh) {
	my $buf = '';
	while (sysread($fh, $buf, 4096)) {
	    syswrite($out, $buf);
	}
	$fh->close();
    }
}


# Descriptions: chown utility.
#    Arguments: OBJ($curproc) STR($owner) STR($group) VAR_ARG(@argv)
# Side Effects: change owner and group of $dir
# Return Value: none
sub chown
{
    my ($curproc, $owner, $group, @argv) = @_;

    use User::pwent;
    my $pw  = getpwnam($owner) || croak("no such user: $owner");
    my $uid = $pw->uid;

    use User::grent;
    my $gr  = getgrnam($group) || croak("no such group: $group");
    my $gid = $gr->gid;

    for my $file (@argv) {
	print STDERR "chown $uid, $gid, $file\n" if $debug;
	chown $uid, $gid, $file;
    }
}


=head2 unique( $array )

make components in $array unique.

=cut


# Descriptions: make components in $array unique.
#    Arguments: OBJ($self) ARRAY_REF($array)
# Side Effects: none
# Return Value: ARRAY_REF
sub unique
{
    my ($self, $array) = @_;
    my $x     = [];
    my $cache = {};

    if (ref($array) eq 'ARRAY' && @$array) {
      COMPONENT:
	for my $k (@$array) {
	    next COMPONENT if $cache->{ $k };
	    push(@$x, $k);
	    $cache->{ $k } = 1;
	}
    }

    return $x;
}


=head1 ml_home_dir handling

=head2 ml_home_dir_deleted_path($ml_home_prefix, $ml_name)

return ml_home_dir to be removed. If mupltiple directories are
matched, return the latest removed one by using
ml_home_dir_find_latest_deleted_path().

=head2 ml_home_dir_find_latest_deleted_path($ml_home_prefix, $ml_name)

find the latest removed ml_home_dir and return it.

=cut


# Descriptions: return ml_home_dir to be removed.
#    Arguments: OBJ($curproc) STR($ml_name) STR($ml_domain)
# Side Effects: none
# Return Value: STR
sub ml_home_dir_deleted_path
{
    my ($curproc, $ml_name, $ml_domain) = @_;
    my $ml_home_prefix = $curproc->ml_home_prefix($ml_domain);
    my $count  = 0;
    my $result = '';

    use Mail::Message::Date;
    my $date  = new Mail::Message::Date time;
    my $yymd  = $date->{ YYYYMMDD };

    use File::Spec;

  TRY:
    for (;;) {
	my $x = sprintf("%s%s.%d.%d", '@', $ml_name, $yymd, $count);
	my $y = File::Spec->catfile($ml_home_prefix, $x);
	if (-d $y) {
	    $count++;
	}
	else {
	    $result = $y;
	    last TRY;
	}
    }

    return $result;
}


# Descriptions: find the latest removed $ml_home_dir.
#    Arguments: OBJ($curproc) STR($ml_name) STR($ml_domain)
# Side Effects: none
# Return Value: STR
sub ml_home_dir_find_latest_deleted_path
{
    my ($curproc, $ml_name, $ml_domain) = @_;
    my $ml_home_prefix = $curproc->ml_home_prefix($ml_domain);
    my ($entry) = [];

    use DirHandle;
    my $dh = new DirHandle $ml_home_prefix;
    if (defined $dh) {
	my $x;

      ENTRY:
	while ($x = $dh->read()) {
	    next ENTRY if $x =~ /^\./o;

	    if ($x =~ /^\@$ml_name$/ || $x =~ /^\@$ml_name[\..\d]+$/) {
		push(@$entry, $x);
	    }
	}
	$dh->close();
    }

    my $name = $curproc->_sort_ml_name($ml_home_prefix, $ml_name, $entry);
    if ($name) {
	return File::Spec->catfile($ml_home_prefix, $name);
    }
    else {
	return '';
    }
}


# Descriptions: sort ml_name entries (@$entry) and return the latest.
#    Arguments: OBJ($curproc)
#               STR($ml_home_prefix) STR($ml_name) ARRAY_REF($entry)
# Side Effects: none
# Return Value: STR
sub _sort_ml_name
{
    my ($curproc, $ml_home_prefix, $ml_name, $entry) = @_;
    my $latest   = 0;
    my $is_found = 0;
    my $max_id   = -1;

    for my $x (@$entry) {
	# 1. current style: "@$ml_name.$date.$count" form.
	if ($x =~ /^\@$ml_name\.(\d+)\.(\d+)$/) {
	    $latest = $1 > $latest ? $1 : $latest;
	    $max_id = $2 > $max_id ? $2 : $max_id;
	}
	# 2. old style (< 20050817)
	elsif ($x =~ /^\@$ml_name\.(\d+)$/) {
	    $latest = $1 > $latest ? $1 : $latest;
	}
	# 3. very old style.
	elsif ($x =~ /^\@$ml_name$/) {
	    $is_found = $x;
	}
    }

    print "($ml_name, $latest, $max_id);\n";

    # adjusted for case 2. and 3. (not needed for case 1.)
    my $latest_name = undef;
    if ($max_id >= 0) {
	$latest_name = sprintf("%s%s.%d.%d", '@', $ml_name, $latest, $max_id);
    }
    else {
	$latest_name = sprintf("%s%s.%d", '@', $ml_name, $latest);
    }

    # when case 1 or 2 and 3 are matched.
    if ($latest && $is_found) {
	my $mtime_latest = _mtime($ml_home_prefix, $latest_name);
	my $mtime_exact  = _mtime($ml_home_prefix, $is_found);
	return( ($mtime_latest > $mtime_exact) ? $latest_name : $is_found );
    }
    # case 1 and 2.
    elsif ($latest) {
	return $latest_name;
    }
    # case 3.
    elsif ($is_found) {
	return $is_found;
    }
    else {
	return '';
    }
}


# Descriptions: return mtime of $prefix/$x file/dir.
#    Arguments: STR($prefix) STR($x)
# Side Effects: none
# Return Value: NUM
sub _mtime
{
    my ($prefix, $x) = @_;
    my $p  = File::Spec->catfile($prefix, $x);
    my $st = stat($p);
    return $st->mtime;
}


# Descriptions: return the list of valid ml_name(s) in the specified domain.
#    Arguments: OBJ($curproc) STR($ml_domain)
# Side Effects: none
# Return Value: ARRAY_REF
sub ml_name_list
{
    my ($curproc, $ml_domain) = @_;
    my ($ml_domain_base_dir)  = $curproc->ml_home_prefix($ml_domain);
    my (@r_list) = ();

    use DirHandle;
    my $dh = new DirHandle $ml_domain_base_dir;
    if (defined $dh) {
	my $entry;

      ENTRY:
	while ($entry = $dh->read()) {
	    next ENTRY if $entry =~ /^\./;
	    next ENTRY if $entry =~ /^\@/;

	    my $config_cf = File::Spec->catfile($ml_domain_base_dir, 
						$entry, 
						"config.cf");
	    if (-f $config_cf) {
		push(@r_list, $entry);
	    }
	}

	$dh->close();
    }
    else {
	$curproc->logerror("cannot opendir $ml_domain_base_dir");
    }

    return(\@r_list);
}


=head1 METHODS for convenience

=head2 fml_version()

return fml version.

=head2 fml_owner()

return fml owner.

=head2 fml_group()

return fml group.

=head2 myname()

return the current process name.

=head2 command_line_raw_argv()

return @ARGV before getopts() analyze.

=head2 command_line_argv()

return @ARGV after getopts() analyze.

=head2 command_line_argv_find(pat)

return the matched pattern in @ARGV and return it if found.

=head2 command_line_options()

return options, result of getopts() analyze.

=cut


# Descriptions: return fml version.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub fml_version
{
    my ($curproc) = @_;
    my $args = $curproc->{ __parent_args };

    return $args->{ main_cf }->{ fml_version };
}


# Descriptions: return fml owner.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub fml_owner
{
    my ($curproc) = @_;
    my $args = $curproc->{ __parent_args };

    return $args->{ main_cf }->{ fml_owner };
}


# Descriptions: return fml owner mail address.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub fml_owner_address
{
    my ($curproc)  = @_;
    my $owner      = $curproc->fml_owner();
    my $ml_domain  = $curproc->ml_domain();

    return sprintf("%s%s%s", $owner, '@', $ml_domain);
}


# Descriptions: return fml group.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub fml_group
{
    my ($curproc) = @_;
    my $args = $curproc->{ __parent_args };

    return $args->{ main_cf }->{ fml_group };
}


# Descriptions: return the current process name.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub myname
{
    my ($curproc) = @_;
    my $args = $curproc->{ __parent_args };

    return $args->{ myname };
}


# Descriptions: check if $ml_name is mandatory in this process?
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub is_need_ml_name
{
    my ($curproc) = @_;
    my $args = $curproc->{ __parent_args };

    return( $args->{ need_ml_name } ? 1 : 0 );
}


# Descriptions: return raw @ARGV of the current process,
#               where @ARGV is before getopts() applied
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: ARRAY_REF
sub command_line_raw_argv
{
    my ($curproc) = @_;
    my $args = $curproc->{ __parent_args };

    return $args->{ argv };
}


# Descriptions: return @ARGV of the current process,
#               where @ARGV is after getopts() applied
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: ARRAY_REF
sub command_line_argv
{
    my ($curproc) = @_;
    my $args = $curproc->{ __parent_args };

    return $args->{ ARGV };
}


# Descriptions: return a string matched with the specified pattern and
#               return it.
#    Arguments: OBJ($curproc) STR($pat)
# Side Effects: none
# Return Value: STR
sub command_line_argv_find
{
    my ($curproc, $pat) = @_;
    my $argv = $curproc->command_line_argv();

    if (defined $pat) {
	for my $x (@$argv) {
	    if ($x =~ /^$pat/) {
		return $1;
	    }
	}
    }

    return undef;
}


# Descriptions: return options, which is the result by getopts() analyze.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: ARRAY_REF
sub command_line_options
{
    my ($curproc) = @_;
    my $args = $curproc->{ __parent_args };

    return $args->{ options };
}


=head2 config_cf_files_set_list($cf_file_path_array)

set configuration file (.cf) to internal list.

=head2 config_cf_files_append($cf_file_path)

append configuration file (.cf) to internal list.

=head2 config_cf_files_get_list()

get configuration files (*.cf) list as ARRAY_REF.

=cut


# Descriptions: set configuration file (.cf) to internal list.
#    Arguments: OBJ($curproc) ARRAY_REF($path)
# Side Effects: none
# Return Value: ARRAY_REF
sub config_cf_files_set_list
{
    my ($curproc, $path) = @_;
    my $args = $curproc->{ __parent_args };

    if (ref($path) eq 'ARRAY') {
	$args->{ cf_list } = $path || [];
    }
    else {
	$curproc->logerror("config_cf_files_set_list: invalid input");
    }
}

# Descriptions: append configuration file (.cf) to internal list.
#    Arguments: OBJ($curproc) STR($path)
# Side Effects: none
# Return Value: ARRAY_REF
sub config_cf_files_append
{
    my ($curproc, $path) = @_;
    my $args = $curproc->{ __parent_args };

    my $p = $args->{ cf_list } || [];
    push(@$p, $path);
    $args->{ cf_list } = $p;
}

# Descriptions: get configuration files (*.cf) list as ARRAY_REF.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: ARRAY_REF
sub config_cf_files_get_list
{
    my ($curproc) = @_;
    my $args = $curproc->{ __parent_args };

    return( $args->{ cf_list } || [] );
}


=head2 ml_name()

not yet implemenetd properly. (?)

=cut


# Descriptions: return ml_name.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub ml_name
{
    my ($curproc) = @_;
    my $config = $curproc->config();

    if (defined $config->{ ml_name } && $config->{ ml_name }) {
	return $config->{ ml_name };
    }
    else {
	croak("\$ml_name not defined.");
    }
}


=head2 ml_domain()

return the domain handled in the current process. If not defined
properly, return the default domain defined in /etc/fml/main.cf.

=cut


# Descriptions: return my domain.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub ml_domain
{
    my ($curproc) = @_;
    my $config = $curproc->config();

    if (defined $config->{ ml_domain } && $config->{ ml_domain }) {
	return $config->{ ml_domain };
    }
    else {
	return $curproc->default_domain();
    }
}


=head2 default_domain()

return the default domain defined in /etc/fml/main.cf.

=cut


# Descriptions: return the default domain defined in /etc/fml/main.cf.
#    Arguments: OBJ($curproc) STR($domain)
# Side Effects: none
# Return Value: STR
sub default_domain
{
    my ($curproc, $domain) = @_;
    my $main_cf = $curproc->{ __parent_args }->{ main_cf };

    return $main_cf->{ default_domain };
}


# Descriptions: check if $domain is the default one or not.
#               This is used to check $domain is a virtual domain or not.
#    Arguments: OBJ($curproc) STR($domain)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub is_default_domain
{
    my ($curproc, $domain) = @_;
    my $default_domain = $curproc->default_domain();

    # XXX domain name is case insensitive.
    if ("\L$domain\E" eq "\L$default_domain\E") {
	return 1;
    }
    else {
	return 0;
    }
}


=head2 executable_prefix()

return executable prefix such as "/usr/local".

=cut


# Descriptions: return the path where executables exist.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub executable_prefix
{
    my ($curproc) = @_;
    my $main_cf = $curproc->{ __parent_args }->{ main_cf };

    return $main_cf->{ executable_prefix };
}


=head2 newml_command_template_files_dir()

return the path where template files used in "newml" method exist.

=cut


# Descriptions: return the path where template files used
#               in "newml" method exist.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub newml_command_template_files_dir
{
    my ($curproc) = @_;
    my $main_cf = $curproc->{ __parent_args }->{ main_cf };

    return $main_cf->{ default_config_dir };
}


=head2 ml_home_prefix([domain])

return $ml_home_prefix in main.cf.

=cut

# XXX-TODO: __ml_home_prefix_from_main_cf() is not needed.
# XXX-TODO: since FML::Process::Switch calculate this variable and
# XXX-TODO: set it to $curproc->{ main_cf }.


# Descriptions: front end wrapper to retrieve $ml_home_prefix (/var/spool/ml).
#               return $ml_home_prefix defined in main.cf (/etc/fml/main.cf).
#               return $ml_home_prefix for $domain if $domain is specified.
#               return default one if $domain is not specified.
#    Arguments: OBJ($curproc) STR($domain)
# Side Effects: none
# Return Value: STR
sub ml_home_prefix
{
    my ($curproc, $domain) = @_;
    my $main_cf = 
	$curproc->{ __parent_args }->{ main_cf } || $curproc->{ main_cf };
    $curproc->__ml_home_prefix_from_main_cf($main_cf, $domain);
}


# Descriptions: return $ml ML's home directory.
#    Arguments: OBJ($curproc) STR($ml) STR($domain)
# Side Effects: none
# Return Value: STR
sub ml_home_dir
{
    my ($curproc, $ml, $domain) = @_;
    my $prefix = $curproc->ml_home_prefix($domain);

    use File::Spec;
    return File::Spec->catfile($prefix, $ml);
}


# Descriptions: return $ml_home_prefix defined in main.cf (/etc/fml/main.cf).
#               return $ml_home_prefix for $domain if $domain is specified.
#               return default one if $domain is not specified.
#    Arguments: OBJ($curproc) HASH_REF($main_cf) STR($domain)
# Side Effects: none
# Return Value: STR
sub __ml_home_prefix_from_main_cf
{
    my ($curproc, $main_cf, $domain) = @_;

    if (defined $domain) {
	my $found = '';

	my ($prefix_maps) = __get_ml_home_prefix_maps($main_cf);
	if (@$prefix_maps) {
	    $found = $curproc->___search_in_ml_home_prefix_maps($main_cf,
								$domain,
								$prefix_maps);
	}

	if ($found) {
	    return $found;
	}
	else {
	    my $default_domain = $curproc->default_domain();
	    if ("\L$domain\E" eq "\L$default_domain\E") {
		return $main_cf->{ default_ml_home_prefix };
	    }
	    else {
		croak("ml_home_prefix: unknown domain ($domain)");
	    }
	}
    }
    else {
	# if the domain is given as a hint (CGI)
	if (defined $main_cf->{ _hints }->{ ml_domain }) {
	    # XXX-TODO: ?
	    ;
	}
	elsif (defined $main_cf->{ ml_home_prefix }) {
	    return $main_cf->{ ml_home_prefix };
	}
	elsif (defined $main_cf->{ default_ml_home_prefix }) {
	    return $main_cf->{ default_ml_home_prefix };
	}
	else {
	    croak("\${default_,}ml_home_prefix is undefined.");
	}
    }
}


# Descriptions: search domain in $prefix_maps.
#               return $ml_home_prefix for the domain if found.
#    Arguments: OBJ($curproc)
#               HASH_REF($main_cf)
#               STR($domain)
#               ARRAY_REF($prefix_maps)
#         bugs: currently support the only file type of IO::Adapter.
#               This limit comes from the architecture
#               since this function may be used
#               before $curproc and $config is allocated.
#
#               SUPPORT ONLY FILE TYPE MAPS NOT SQL NOR LDAP.
# Side Effects: none
# Return Value: STR
sub ___search_in_ml_home_prefix_maps
{
    my ($curproc, $main_cf, $domain, $prefix_maps) = @_;
    my $cred = $curproc->credential();

    if (@$prefix_maps) {
	my $dir  = '';
	my $dirs = ();
	eval q{ use IO::Adapter; };
	unless ($@) {
	  MAP:
	    for my $map (@$prefix_maps) {
		# XXX only support file:// map
		my $obj = new IO::Adapter $map;
		if (defined $obj) {
		    $obj->open();

		    my $_domain = quotemeta($domain);
		    my ($domainlist) = $obj->find($_domain, { all => 1 });
		  DIR:
		    for my $_dom (@$domainlist) {
			my ($_domain) = split(/\s+/, $_dom);
			if ($cred->is_same_domain($_domain, $domain)) {
			    $dir = $_dom; # DOMAIN PREFIX
			    last DIR;
			}
		    }
		}
		last MAP if $dir;
	    }

	    if ($dir) {
		($domain, $dir) = split(/\s+/, $dir);
		$dir =~ s/[\s\n]*$// if defined $dir;

		# found
		if ($dir) {
		    return $dir; # == $ml_home_prefix
		}
	    }
	}
	else {
	    croak("cannot load IO::Adapter");
	}
    }

    return '';
}


=head2 config_cf_filepath($ml, $domain)

return config.cf path for this $ml ($ml@$domain).

=head2 is_config_cf_exist($ml, $domain)

return 1 if config.cf exists. 0 if not.

=cut


# Descriptions: return $ml ML's config.cf path.
#    Arguments: OBJ($curproc) STR($ml) STR($domain)
# Side Effects: none
# Return Value: STR
sub config_cf_filepath
{
    my ($curproc, $ml, $domain) = @_;
    my $prefix = $curproc->ml_home_prefix($domain);

    unless (defined $ml) {
	$ml = $curproc->config()->{ ml_name };
    }

    use File::Spec;
    return File::Spec->catfile($prefix, $ml, "config.cf");
}


# Descriptions: return whether $ml ML's config.cf file exists or not.
#    Arguments: OBJ($curproc) STR($ml) STR($domain)
# Side Effects: none
# Return Value: STR
sub is_config_cf_exist
{
    my ($curproc, $ml, $domain) = @_;
    my $status = 0;

    eval {
	my $f = $curproc->config_cf_filepath($ml, $domain);
	$status = ( -f $f ? 1 : 0 );
    };
    if ($@) { return 0;}

    return $status;
}


# Descriptions: return default config.cf path.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub default_config_cf_filepath
{
    my ($curproc) = @_;
    my $main_cf   = $curproc->{ __parent_args }->{ main_cf };

    return $main_cf->{ default_config_cf };
}


=head2 menu_get_cui_config_file_path()

return menu configuration path for CUI.

=head2 menu_get_gui_config_file_path()

return menu configuration path for GUI.

=cut


# Descriptions: return whether $ml ML's config.cf file exists or not.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub menu_get_cui_config_file_path
{
    my ($curproc) = @_;
    my $main_cf   = $curproc->{ __parent_args }->{ main_cf };
    return $main_cf->{ default_cui_menu };
}


# Descriptions: return whether $ml ML's config.cf file exists or not.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub menu_get_gui_config_file_path
{
    my ($curproc) = @_;
    my $main_cf   = $curproc->{ __parent_args }->{ main_cf };
    return $main_cf->{ default_gui_menu };
}


# Descriptions: return ml_home_prefix maps as array reference.
#    Arguments: HASH_REF($main_cf)
# Side Effects: none
# Return Value: ARRAY_REF
sub __get_ml_home_prefix_maps
{
    my ($main_cf) = @_;

    if (defined $main_cf->{ ml_home_prefix_maps } &&
	$main_cf->{ ml_home_prefix_maps }) {
	my (@r) = ();
	my (@maps) = split(/\s+/, $main_cf->{ ml_home_prefix_maps });
	for my $map (@maps) {
	    if (-f $map) { push(@r, $map);}
	}
	return \@r;
    }
    else {
	return undef;
    }
}


=head2 is_cui_process()

inform whether this process runs as CUI (fml/makefml) ?

=head2 is_cgi_process()

inform whether this process runs as cgi ?

=head2 is_under_mta_process()

inform whether this process runs under MTA ?

=cut


# Descriptions: whether this process runs as CUI ?
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub is_cui_process
{
    my ($curproc) = @_;
    my $name = $curproc->myname() || '';

    # XXX-TODO: HARD CODED
    if ($name eq 'fml' || $name eq 'makefml') {
	return 1;
    }

    return 0;
}


# Descriptions: whether this process runs as cgi ?
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub is_cgi_process
{
    my ($curproc) = @_;
    my $name = $curproc->myname() || '';

    # XXX-TODO: HARD CODED
    if ($name =~ /\.cgi$/) {
	return 1;
    }

    return 0;
}


# Descriptions: whether this process runs as cgi ?
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub is_under_mta_process
{
    my ($curproc) = @_;
    my $name = $curproc->myname() || '';

    # XXX-TODO: HARD CODED
    if ($name eq 'distribute' ||
	$name eq 'command'    ||
	$name eq 'digest'     ||
	$name eq 'error'      ||
	$name eq 'fml.pl'     ) {
	return 1;
    }

    return 0;
}


=head2 is_allow_reply_message()

return 1 if we can send messages to the sender or specified address.
return 0 if not.

For example, processes running under MTA e.g. libexec/distribute,
libexec/command receives a mail and reply it if needed.
But makefml command do not.

=cut


# Descriptions: check if we can send messages to the sender or
#               specified address.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub is_allow_reply_message
{
    my ($curproc) = @_;
    my $option    = $curproc->command_line_options();
    my $myname    = $curproc->myname();

    if ($curproc->_is_allow_reply_message()) {
	return 1;
    }
    elsif ($curproc->is_under_mta_process()) {
	return 1;
    }
    elsif (defined $option->{ 'allow-reply-message' }) {
	return 1;
    }
    elsif (defined $option->{ 'allow-send-message' }) {
	return 1;
    }
    elsif ($myname eq 'loader') {
	return 1;
    }

    return 0;
}


# Descriptions: enable that reply_message*() functions work.
#    Arguments: OBJ($curproc)
# Side Effects: update PCB.
# Return Value: none
sub set_allow_reply_message
{
    my ($curproc) = @_;
    my ($pcb) = $curproc->pcb();

    $pcb->set("reply_message", "allow", 1);
}


# Descriptions: check if that reply_message*() functions work.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub get_allow_reply_message
{
    my ($curproc) = @_;
    my ($pcb) = $curproc->pcb();
    $pcb->get("reply_message", "allow") ? 1 : 0;
}


# Descriptions: check if that reply_message*() functions work.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub _is_allow_reply_message
{
    my ($curproc) = @_;
    $curproc->get_allow_reply_message();
}


=head2 is_fml8_managed_address($address)

check if $address is one of valid ml address fml8 on this host
manages.

=cut


# Descriptions: check if $address is one of valid ml address fml8 on
#               this host manages.
#    Arguments: OBJ($curproc) STR($address)
# Side Effects: none
# Return Value: NUM(0 or 1)
sub is_fml8_managed_address
{
    my ($curproc, $address)   = @_;
    my ($ml_name, $ml_domain) = split(/\@/, $address);

    return $curproc->is_config_cf_exist($ml_name, $ml_domain);
}


=head2 map_to_term($map)

which this $map belongs to ?

=cut


# Descriptions: which member of maps this $map belongs to ?
#    Arguments: OBJ($curproc) STR($map)
# Side Effects: none
# Return Value: STR
sub map_to_term
{
    my ($curproc, $map) = @_;
    my $config = $curproc->config();
    my $found  = '';

    # XXX try longer term firstly.
  SEARCH_MAPS:
    for my $mode (qw(digest_member    digest_recipient
		     admin_member     admin_recipient
		     moderator_member moderator_recipient
		     member recipient
		     )) {
	my $maps = $config->get_as_array_ref("${mode}_maps");
	for my $m (@$maps) {
	    if ($map eq $m) {
		# XXX-TODO: first match ok?
		$found = $mode;
		last SEARCH_MAPS;
	    }
	}
    }

    my $term = $found;
    $term =~ s/[\s\n]*$//;
    return $term;
}


=head2 map_to_term_nl($map)

return which member of maps is this $map as natural language.

=cut


# Descriptions: return which member of maps is this $map as natural language.
#    Arguments: OBJ($curproc) STR($map)
# Side Effects: none
# Return Value: STR
sub map_to_term_nl
{
    my ($curproc, $map) = @_;

    my $found = $curproc->map_to_term($map);
    my $term  = $curproc->message_nl("term.$found", $found) || $found;
    $term =~ s/[\s\n]*$//;
    return $term;
}


=head2 address_resolve($list)

address_resolve() converts $list to mail addresses.
For example

    maitainer	=>	$maintainer
    sender	=>	sender of the current message (From: in header)

=cut


# Descriptions: convert to mail addresses.
#    Arguments: OBJ($curproc) ARRAY_REF($list)
# Side Effects: none
# Return Value: ARRAY_REF
sub address_resolve
{
    my ($curproc, $list) = @_;
    my $config = $curproc->config();
    my $cred   = $curproc->credential();
    my $result = [];

    for my $rcpt (@$list) {
	if ($rcpt eq 'maintainer') {
	    push(@$result, $config->{ maintainer });
	}
	elsif ($rcpt eq 'sender') {
	    my $sender = $cred->sender();
	    push(@$result, $sender);
	}
	else {
	    $curproc->logerror("unknown recipient type $rcpt");
	}
    }

    return $result;
}


=head2 article_get_max_id()

return the current article number (sequence number).

=cut


# Descriptions: return the current article number (sequence number).
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: NUM
sub article_get_max_id
{
    my ($curproc) = @_;

    use FML::Article;
    my $article = new FML::Article $curproc;
    return $article->id();
}


=head2 output_set_print_style(mode)

=head2 output_get_print_style()

=cut


# Descriptions: set print style.
#    Arguments: OBJ($curproc) STR($mode)
# Side Effects: none
# Return Value: STR
sub output_set_print_style
{
    my ($curproc, $mode) = @_;

    $curproc->{ __print_style } = $mode;
}


# Descriptions: get print style.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub output_get_print_style
{
    my ($curproc) = @_;

    return( $curproc->{ __print_style } || 'text');
}


# Descriptions: language used in html files.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub _language_of_html_file
{
    my ($curproc) = @_;
    my $config    = $curproc->config();
    my $language  = $config->{ html_archive_default_charset } || 'us-ascii';

    return $language;
}


# Descriptions: set the current charset hint.
#    Arguments: OBJ($curproc) STR($category) STR($charset)
# Side Effects: none
# Return Value: none
sub langinfo_set_language_hint
{
    my ($curproc, $category, $charset) = @_;
    my $pcb = $curproc->pcb();

    $pcb->set("language_hint", $category, $charset);
}


# Descriptions: get the current charset hint.
#    Arguments: OBJ($curproc) STR($category)
# Side Effects: none
# Return Value: none
sub langinfo_get_language_hint
{
    my ($curproc, $category) = @_;
    my $pcb = $curproc->pcb();

    $pcb->get("language_hint", $category);
}


# Descriptions: set the current charset.
#    Arguments: OBJ($curproc) STR($category) STR($charset)
# Side Effects: none
# Return Value: none
sub langinfo_set_charset
{
    my ($curproc, $category, $charset) = @_;
    my $pcb = $curproc->pcb();

    $pcb->set("charset", $category, $charset);
}


# Descriptions: get the current charset defined by fml8 in this context.
#               This value is NOT one speculated by Content-Type: et.al.
#               but use information of Accept-Language field if could.
#               The default value is given by $template_file_charset.
#    Arguments: OBJ($curproc) STR($category)
# Side Effects: none
# Return Value: STR
sub langinfo_get_charset
{
    my ($curproc, $category) = @_;
    my $config  = $curproc->config();
    my $pcb     = $curproc->pcb();
    my $keyword = sprintf("%s_default_charset", $category);
    my $default = $config->{ $keyword } || 'us-ascii';
    my $charset = $default;

    # if overwritten by some module, we use it always.
    if (defined($pcb) && $pcb->get("charset", $category)) {
	$curproc->logdebug("charset: pcb hit");
	$charset = $pcb->get("charset", $category);
    }
    # search charset most preferred by Accpet-Language: in our templates.
    else {
	my $found = 0;

	# XXX Accept-Language: affets $reply_message_charset and $cgi_charset.
	# XXX $reply_mesage_charset indirectly affets $template_file_charset.
	# XXX So, we need to check Accept-Language: information.
	my $acpt_lang_list = $curproc->langinfo_get_accept_language_list()||[];

	if (@$acpt_lang_list) {
	    $curproc->logdebug("charset: search Accept-Language: list");

	  ACCEPT_LANGUAGE:
	    for my $a (@$acpt_lang_list) {
		if ($a eq 'ja' || $a eq 'en') {
		    my $key  = sprintf("%s_charset_%s", $category, $a);
		    $charset = $config->{ $key } || undef;
		    $found   = 1;
		    last ACCEPT_LANGUAGE;
		}
		elsif ($a eq '*') { # any charset is o.k.
		    last ACCEPT_LANGUAGE;
		}
	    }
	}
	else {
	    $curproc->log("debug: no Accpet-Language:") if $debug;
	}

	unless ($found) {
	    # Content-Type:
	    use Mail::Message::Charset;
	    my $c    = new Mail::Message::Charset;
	    my $hint = $curproc->langinfo_get_language_hint($category);
	    $charset = $c->language_to_message_charset($hint);
	}
    }

    $charset ||= $default;
    $curproc->logdebug("category=$category charset=$charset");
    $curproc->log("debug: category=$category charset=$charset") if $debug;
    return $charset;
}


=head2 langinfo_get_accept_language_list($list)

set preferred language candidates requested by sender.
$list is ARRAY_REF.

=head2 langinfo_get_accept_language_list()

return preferred language candidates requested by sender.
The type of return value is ARRAY_REF.

=cut


# Descriptions: return language candidates requested by sender.
#    Arguments: OBJ($curproc) ARRAY_REF($list)
# Side Effects: none
# Return Value: ARRAY_REF
sub langinfo_set_accept_language_list
{
    my ($curproc, $list) = @_;
    my $pcb = $curproc->pcb();

    if (defined $pcb) {
	if (ref($list) eq 'ARRAY') {
	    $pcb->set('incoming_message', 'accept-language', $list);
	}
	else {
	    $curproc->logerror("langinfo_set_accept_language_list: invalid data");
	}
    }
}


# Descriptions: return language candidates requested by sender.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: ARRAY_REF
sub langinfo_get_accept_language_list
{
    my ($curproc) = @_;
    my $pcb = $curproc->pcb();

    if (defined $pcb) {
	return( $pcb->get('incoming_message', 'accept-language') || [] );
    }
    else {
	return [ ];
    }
}


=head2 article_thread_init()

prepare and return information (HASH_REF) needed to manipulate thread
database.

=cut


# Descriptions: return information (HASH_REF) needed for thread database.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: HASH_REF
sub article_thread_init
{
    my ($curproc)    = @_;
    my $config       = $curproc->config();
    my $ml_name      = $config->{ ml_name };
    my $html_dir     = $config->{ html_archive_dir };
    my $udb_dir      = $config->{ udb_base_dir };
    my $index_order  = $config->{ html_archive_index_order_type };
    my $subject_tag  = $config->{ article_subject_tag };
    my $cur_lang     = $curproc->_language_of_html_file();

    # whether we should mask address?
    my $use_address_mask  = 'no';
    my $address_mask_type = '';
    if ($config->yes('use_html_archive_address_mask')) {
	$use_address_mask = 'yes';
	$address_mask_type
	    = $config->{ html_archive_address_mask_type } || 'all';
    }

    unless (-d $udb_dir) { $curproc->mkdir($udb_dir);}

    # hints
    use FML::Header::Subject;
    my $subj = new FML::Header::Subject;
    my $subject_tag_regexp = $subj->regexp_compile($subject_tag);

    # XXX-TODO: care for non Japanese.
    return {

	charset      => $cur_lang,

	output_dir   => $html_dir, # ~fml/public_html/mlarchive/$domain/$ml/
	db_base_dir  => $udb_dir,  # /var/spool/ml/@udb@
	db_name      => $ml_name,  # elena

	index_order  => $index_order,  # normal/reverse

	# address mask = yes/no, _type = all
	use_address_mask  => $use_address_mask,
	address_mask_type => $address_mask_type,

	# hints
	hints        => {
	    subject_tag        => $subject_tag,
	    subject_tag_regexp => $subject_tag_regexp,
	},
    };
}


=head2 hints()

return hints as HASH_REF.
It is useful to switch process behabiour based on this hints.
This function is used in CGI processes typically to verify
whether the current process runs in admin mode or user mode ? et.al.

=cut


# Descriptions: return hints on this process.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: HASH_REF
sub hints
{
    my ($curproc) = @_;
    my $main_cf = $curproc->{ __parent_args }->{ main_cf };

    return $main_cf->{ _hints };
}


=head2 shared_hash_get($category, $key)

return HASH_REF allocated on global memory area.

This memory area is shared by plural "fml processes" running on this
one (operatiing system's) process. In other words plural $curproc are
possible on one process. For example, both parent and child $curproc
can access this memory area.

=cut


# Descriptions: return HASH_REF allocated on global memory area.
#    Arguments: OBJ($curproc) STR($category) STR($key)
# Side Effects: none
# Return Value: HASH_REF
sub shared_hash_get
{
    my ($curproc, $category, $key) = @_;
    my $memory = $curproc->{ __parent_args }->{ ___shared_memory___ };
    $memory->{ $category }->{ $key } ||= {};
    return $memory->{ $category }->{ $key };
}


=head1 CUI specific

=cut


# Descriptions: return comman specific options (-O key=value) as HASH_REF.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: HASH_REF
sub command_line_cui_specific_options
{
    my ($curproc) = @_;
    my $args = $curproc->{ __parent_args };

    return( $args->{ options }->{ O } || {} );
}


# Descriptions: return sender or recipient specified by --send-to option.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub command_line_cui_specific_recipient
{
    my ($curproc) = @_;
    my $args      = $curproc->{ __parent_args };
    my $rcpt      = $args->{ options }->{ 'send-to' } || '';
    my $cred      = $curproc->credential();
    my $sender    = $cred->sender() || '';

    return( $rcpt || $sender || '' );
}


=head1 CURPROC UTILITY

=head2 dup_curproc_args()

duplicate $args corresponding to $curproc.

=cut


# Descriptions: duplicate $args corresponding to $curproc.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: HASH_REF
sub dup_curproc_args
{
    my ($curproc) = @_;
    my $args      = $curproc->{ __parent_args };
    my $hash      = {};

    # XXX-TODO: incomplete duplication
    my ($k, $v);
    while (($k, $v) = each %$args) {
	$v = $args->{ $k };
	if (ref($v)) {
	    $hash->{ $k } = $v;
	}
	else {
	    $hash->{ $k } = sprintf("%s", $v);
	}
    }

    return $hash;
}


# Descriptions: set process title (setproctitle()).
#    Arguments: OBJ($curproc) STR($title)
# Side Effects: none
# Return Value: none
sub set_process_title
{
    my ($curproc, $title) = @_;
    $0 = $title;
}


# Descriptions: return process title.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub get_process_title
{
    my ($curproc) = @_;
    return $0;
}


=head2 context_switch_get_context()

return saved context information.

=head2 context_switch_set_context($context)

replace context information with the specified one.

=cut


# Descriptions: return saved context.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: HASH_REF
sub context_switch_get_context
{
    my ($curproc)     = @_;
    my $config        = $curproc->config();
    my $config_saved  = $config->get_context();
    my $pcb           = $curproc->pcb();
    my $pcb_saved     = $pcb->get_context();
    my $process_title = $curproc->get_process_title();
    my $context       = {
	config_saved_context => $config_saved,
	pcb_saved_context    => $pcb_saved,
	process_title        => $process_title,
    };

    return $context;
}


# Descriptions: reset the context.
#    Arguments: OBJ($curproc) HASH_REF($context)
# Side Effects: none
# Return Value: STR
sub context_switch_set_context
{
    my ($curproc, $context)= @_;
    my $config             = $curproc->config();
    my $config_context     = $context->{ config_saved_context };
    my $pcb                = $curproc->pcb();
    my $pcb_context        = $context->{ pcb_saved_context };
    my $process_title      = $context->{ process_title };

    # context switch: back again.
    $config->set_context($config_context);
    $pcb->set_context($pcb_context);
    $curproc->set_process_title($process_title);
}


=head1 FAULT

=cut


# Descriptions: set address fault.
#    Arguments: OBJ($curproc)
# Side Effects: set shared memory
# Return Value: none
sub set_address_fault
{
    my ($curproc) = @_;
    my $shm = $curproc->shared_hash_get("system", "fault");
    $shm->{ "address_fault" } = "yes";
}


# Descriptions: get address fault value.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub get_address_fault
{
    my ($curproc) = @_;
    my $shm       = $curproc->shared_hash_get("system", "fault");
    return( $shm->{ "address_fault" } || 'no' );
}


# Descriptions: check if the address fault requested.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: NUM
sub is_address_fault
{
    my ($curproc) = @_;
    my $is_fault  = $curproc->get_address_fault();

    return( $is_fault eq 'yes' ? 1 : 0 );
}


# Descriptions: set address fault list.
#    Arguments: OBJ($curproc) ARRAY_REF($list)
# Side Effects: set shared memory
# Return Value: none
sub set_address_fault_list
{
    my ($curproc, $list) = @_;
    my $shm = $curproc->shared_hash_get("system", "fault_list");
    $shm->{ "address_fault_list" } = $list;
}


# Descriptions: get address fault list as ARRAY_REF.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: ARRAY_REF
sub get_address_fault_list
{
    my ($curproc) = @_;
    my $shm       = $curproc->shared_hash_get("system", "fault_list");
    return( $shm->{ "address_fault_list" } || [] );
}


=head1 LOG ROTATION

=head2 log_rorate()

rotate log files.

=cut


# Descriptions: rotate log files.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub log_rorate
{
    my ($curproc) = @_;
    my $config    = $curproc->config();

    if ($config->yes('use_log_rotate')) {
	# XXX LOCK_CHANNEL: log_file_modify
	my $lock_channel = "log_file_modify";

	$curproc->lock($lock_channel);

	my $log = undef;
	eval q{
	    use FML::File::Rotate;
	    $log = new FML::File::Rotate $curproc;
	};
	my $r = $@;

	if (defined $log) {
	    my $log_file = $config->{ log_file };
	    my $size     = $config->{ log_rotate_size_limit };
	    my $total    = $config->{ log_rotate_archive_file_total };

	    $log->set_size_limit($size);
	    $log->set_archive_log_total($total);
	    if ($log->is_time_to_rotate($log_file)) {
		$log->rotate($log_file);
		$curproc->log("log files rotated.");
	    }
	}
	else {
	    $curproc->logerror("cannot attach log rotate object");
	    $curproc->logerror($r);
	}

	$curproc->unlock($lock_channel);
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003,2004,2005,2006,2008 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Utils first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
