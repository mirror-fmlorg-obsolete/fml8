# -*-Perl-*-
#
# FML Configuration File
#
# Copyright (C) 1993-2000 Ken'ichi Fukamachi
#          All rights reserved. 
#               1993-1996 fukachan@phys.titech.ac.jp
#               1996-2000 fukachan@sapporo.iij.ad.jp
# 
# FML is free software; you can redistribute it and/or modify
# it under the terms of GNU General Public License.
# See the file COPYING for more details.
#
# Section Index (cf/MANIFEST 1.104)
#   Fundamental Configuration (CF Version, debug, Language) 
#   Mailing List Policy (for Post, Commands), Maintainer 
#   Directory  
#   Manual Registration 
#   Automatic Registration 
#   Confirmd 
#   Remote Administration 
#   Moderations; moderators check posted articles 
#   Security 
#   Header Customization 
#   Commands, Command Traps, File Operations (e.g. mget) 
#   Digest/Matome Okuri Configurations 
#   Other Files for Configurations and Logs 
#   SMTP and Delivery 
#   MISC 
#   Expire and Archive  
#   Library Commands  
#   Html Configurations 
#   Interface to DataBase Management System 
#   Interface to other Services (http,ftp,gopher,www) 
#   Architecture Dependence 





#####################################################################
# ### Section: Fundamental Configuration (CF Version, debug, Language) ### 
# config.ph configuration version
# define 5.0 for fml 3.0.
# define 6.0 for fml 3.0 + fukui-newconfig.
$CFVersion                     = "6.1";

# global debug option. if non-nil, debug mode.
# In debug mode, fml does not distribute posted articles.
# value: 1/0
$debug                         = 0;

# fml 3.0 generates template files, $DIR/{help,welcome} in $LANGUAGE
# in "makefml newml". You define this variable in installation.
# The value is controlled by /usr/local/fml/.fml/system.
# value: Japanese/English
$LANGUAGE                      = "Japanese";

# Error message language fml returns.
# If $MESSAGE_LANGUAGE is not defined, fml 3.0 uses $LANGUAGE.
# &Mesg() tries to translate the given message to this language.
# value: Japanese/English
$MESSAGE_LANGUAGE              = "";

# ## Sub Section: DNS ##
# fml automatically set up DNS for this host, but check it again by yourself.
#
#    DOMAINNAME the domain name              e.g. fml.org
#    FQDN       Fully Qualified Domain Name  e.g. beth.fml.org
#
# value: string
$DOMAINNAME                    = "home.fml.org";
$FQDN                          = "elena.home.fml.org";

#####################################################################
# ### Section: Mailing List Policy (for Post, Commands), Maintainer ###
#
# $MAIL_LIST is the address for post. For example 'elena@fml.org'.
#
# $PERMIT_POST_FROM is one of "anyone", "members_only" and "moderator".
# It defines who can post to this ML. 
# When post from not a member is rejected,
# fml calls $REJECT_POST_HANDLER.
# $REJECT_POST_HANDLER is one of "reject", "auto_subscribe" and "ignore".
#    HISTORY: you can use "auto_regist" used in fml 2.x.
#
# value: string
$MAIL_LIST                     = "";
$PERMIT_POST_FROM              = "members_only";
$REJECT_POST_HANDLER           = "reject";

# $CONTROL_ADDRESS is the address you send a command request to.
#    For example 'elena-ctl@fml.org'.
#
# $PERMIT_COMMAND_FROM is one of "anyone", "members_only" and "moderator".
# It defines who can post to this ML. 
# When command request from not a member is rejected,
# fml calls $REJECT_COMMAND_HANDLER.
#
# $REJECT_COMMAND_HANDLER is one of "reject", "auto_subscribe" and "ignore".
#   HISTORY: you can use "auto_regist" used in fml 2.x.
#
# Typical Configuration is
#
# (default)
#    $PERMIT_COMMAND_FROM    = "members_only";
#    $REJECT_COMMAND_HANDLER = "reject";
#
# (automatic subscribe: fml automatically handles subscribe request)
#    $PERMIT_COMMAND_FROM    = "members_only";
#    $REJECT_COMMAND_HANDLER = "auto_subscribe";
#
# value: string
$CONTROL_ADDRESS               = "";
$PERMIT_COMMAND_FROM           = "members_only";
$REJECT_COMMAND_HANDLER        = "reject";

# obsolete (though you can use it)
# When $MAIL_LIST_ACCEPT_COMMAND = 1, 
# both $MAIL_LIST and $CONTROL_ADDRESS accept commands
# which format is "# command".
# value: 1/0
$MAIL_LIST_ACCEPT_COMMAND      = "";

# ## Sub Section: Maintainer ##
# mailing list maintainer/administrator address e.g. 'elena-admin@fml.org'.
# $MAINTAINER != $MAIL_LIST IS REQUIRED AGAINST MAIL LOOP!
# value: string
$MAINTAINER                    = "";
$MAINTAINER_SIGNATURE          = "";

# ## Sub Section: ML_FN ##
# obsolete
#
# You can enforce To: field of posted article by rewriting it.
#   To: $MAIL_LIST $ML_FN => To: Elena@fml.org (Elena Lolabrigita ML)
#
# value: string
$ML_FN                         = "";

#####################################################################
# ### Section: Directory  ###
# $*DIR variable is relative under $DIR (defined in fml initialization phase).
# $FP*DIR is fully pathed directory name for each $*DIR variable.
# article spool
# value: directory string
$SPOOL_DIR                     = "spool";

# tmp, after chdir, under DIR
# value: directory string
$TMP_DIR                       = "tmp";

# multi-purpose log, temporary, transient, and spool files (4.4BSD style)
# $LOGFILE and $SPOOL_DIR is exceptional but others is under var/.
# value: directory string
$VAR_DIR                       = "var";
$VARLOG_DIR                    = "var/log";
$VARRUN_DIR                    = "var/run";
$VARDB_DIR                     = "var/db";

#####################################################################
# ### Section: Manual Registration ###
#
# Term "Manual Registration" may be ambiguous but it implies
# ML maintainer needs to do some action to add a new member.
# When the maintainer receives subscribe request, he/she 
#    1. remote login to the fml host and edit actives/members
#    2. remote login to the fml host and run "makefml add ML address"
#    3. send a command to add an address e.g. "admin add address".
#       You need to enable remote administration function to do it.
#       See "remote administration" section for more details.
#
# On contrary, "automatic registration" is fml does everything 
# to add a new member except for some error cases.
#
# only support 'confirmation' or 'forward_to_admin'
# In "confirmation", fml confirms the subscribe request is valid to
# avoid a tricky attack. 
# If "forward_to_admin" is selected, subscribe request is forwarded
# to $MAINTAINER without further check.
#
# value: confirmation/forward_to_admin
$MANUAL_REGISTRATION_TYPE      = "confirmation";

# value: directory string
$MANUAL_REGISTRATION_CONFIRMATION_FILE = "$DIR/confirm.msub";

#####################################################################
# ### Section: Automatic Registration ###
#
# When REJECT_{POST,COMMAND}_HANDLER is "auto_subscribe" or
# "auto_regist", fml does everything to add a new member except for some
# error cases. The subscription request type is as follows.
# 
# value: confirmation/subject/body/no-keyword
$AUTO_REGISTRATION_TYPE        = "confirmation";

# keyword of subscribe request
# $REQUIRE_SUBSCRIBE (CFVersion 2) => $AUTO_REGISTRATION_KEYWORD
# value: string
$AUTO_REGISTRATION_KEYWORD     = "subscribe";

# when automatic registration,
# we apply $AUTO_REGISTRATION_DEFAULT_MODE e.g. "m=3mp s=1" to the address.
# Please see "file operation" in doc/tutorial for more details.
# value: string
$AUTO_REGISTRATION_DEFAULT_MODE = "";

# "confirmation" (default) mode configurations
# please see doc/tutorial for the detail of "confirmation"
# value: string 
$CONFIRMATION_ADDRESS          = "";
$CONFIRMATION_SUBSCRIBE        = "subscribe";
$CONFIRMATION_KEYWORD          = "confirm";
$CONFIRMATION_WELCOME_STATEMENT = "";

# "subscribe" needs no YOUR NAME. 
# value: 1/0
$CONFIRMATION_SUBSCRIBE_NEED_YOUR_NAME = 1;

# file to send back "what is confirmation?" with "confirmation request"
# reply mail in "confirmation" mode.
# value: filename string 
$CONFIRMATION_FILE             = "$DIR/confirm";

# Expire of request queue. The unit is "hour". (default, 168 == 7*24)
# value: number
$CONFIRMATION_EXPIRE           = 168;

# confirmation request queue (you should not manually edit it)
# value: filename string
$CONFIRMATION_LIST             = "";

# In fact, obsolete.
# default keyword for trap
# value: string
$DEFAULT_SUBSCRIBE             = "subscribe";

# In adding a new member, fml sends $WELCOME_FILE to him/her.
# ML maintainer should set up this file as a guide of mailing list.
# This function works in automatic registration.
# value: filename string
$WELCOME_FILE                  = "$DIR/welcome";

# subject of mail ($WELCOME_FILE) sent to a new member 
# value: string
$WELCOME_STATEMENT             = "Welcome to our $ML_FN\n         You are added automatically";

# Enforce file to add a new member address for some purposes.
# In default fml adds it to both $ACTIVE_LIST and $MEMBER_LIST.
# value: filename string
$FILE_TO_REGIST                = "";

# obsolete in fact.
#
# In default if body lines > $AUTO_REGISTRATION_LINES_LIMIT, 
# we forward this mail to $MAIL_LIST. If $AUTO_REGISTERED_UNDELIVER_P is set, 
# we ALWAYS DO NOT Forward it to $MAIL_LIST.
# value: 1/0
$AUTO_REGISTERED_UNDELIVER_P   = 1;
$AUTO_REGISTRATION_LINES_LIMIT = 0;

#####################################################################
# ### Section: Confirmd ###
# confirmd
# value: filename string
$CONFIRMD_ACK_REQ_FILE         = "$DIR/confirmd.ackreq";
$CONFIRMD_ACK_LOGFILE          = "$VARLOG_DIR/confirmd.ack";

# value: number / ( number + month/week/day )
$CONFIRMD_ACK_EXPIRE_UNIT      = "1month";
$CONFIRMD_ACK_WAIT_UNIT        = "2weeks";

#####################################################################
# ### Section: Remote Administration ###
#
# For security, I do not recommend you use remote control of fml.
# If $REMOTE_ADMINISTRATION is set, you can control FML by sending
# a command mail from remote host.
# Another choice from remote host is CGI interface but fml 3.0 does not
# provide it. CGI development is underway.
#
# value: 1/0
$REMOTE_ADMINISTRATION         = 0;

# Of course, the remote control requires some kind of authentication.
# The choice of authentication is $REMOTE_ADMINISTRATION_AUTH_TYPE,
# which is one of 
#    address		From: field
#    crypt		From: field + password (e.g. "#admin pass PASSWORD")
#    md5		From: field + password (e.g. "#admin pass PASSWORD")
#    pgp                PGP(Pretty Good Privacy) signature 
#
# The difference of "crypt" and "md5" is $PASSWD_FILE format.
# HISTORY: $REMOTE_ADMINISTRATION_REQUIRE_PASSWORD <=> "crypt"
#
# value: crypt/address/md5/pgp/pgp2/pgp5/gpgp
$REMOTE_ADMINISTRATION_AUTH_TYPE = "crypt";

# address list of members who can send a command mail from remote
# value: filename string
$ADMIN_MEMBER_LIST             = "$DIR/members-admin";

# help file of admin commands
# value: filename string
$ADMIN_HELP_FILE               = "$DIR/help-admin";

# password file to authenticate members
# The format is "address encrypted-password" and uses one line for one address.
# value: filename string
$PASSWD_FILE                   = "$DIR/etc/passwd";

# "admin add" to add an address to a member list. If it succeeds, fml
# sends back $WELCOME_FILE if this variable is defined. In default fml 
# does not do it, so the maintainer needs to send the success of subscribe
# and guide to the new member.
# value: 1/0
$ADMIN_ADD_SEND_WELCOME_FILE   = 0;

# N, the number of lines, of "tail -N $LOGFILE".
# "admin log" is "tail -100 log" in default to avoid too big mail.
# value: number
$ADMIN_LOG_DEFAULT_LINE_LIMIT  = 100;

# PGP directory path (obsolete in fml 4.0)
# value: filename string 
$PGP_PATH                      = "$DIR/etc/pgp";

# If you enforce the following *KEYRING_DIR in $CFVersion < 6.1,
# set this variable on.
# value: 1/0
$USE_FML40_PGP_PATH            = 1;

# fml 4.0
# value: directory string
$DIST_AUTH_KEYRING_DIR         = "$DIR/etc/dist-auth";
$DIST_ENCRYPT_KEYRING_DIR      = "$DIR/etc/dist-encrypt";
$ADMIN_AUTH_KEYRING_DIR        = "$DIR/etc/admin-auth";
$ADMIN_ENCRYPT_KEYRING_DIR     = "$DIR/etc/admin-encrypt";

#####################################################################
# ### Section: Moderations; moderators check posted articles ###
# "moderator" certification type
# value: 1/2/3
$MODERATOR_FORWARD_TYPE        = 2;

# member list who receives submitted article. 
# If this file does not exist, it is forwarded to only $MAINTAINER.
# A moderator who certificate submitted articles and permit the post
# to mailing list.
#
# fml does not check moderator's addresses. fml check only "moderators
# knows passwords or identifiers (one time password)".
#
# value: filename string 
$MODERATOR_MEMBER_LIST         = "$DIR/moderators";

# expire old submitted but not certified articles 
# default: 2 weeks
# value: number
$MODERATOR_EXPIRE_LIMIT        = 14;

#####################################################################
# ### Section: Security ###
# We reject $REJECT_ADDR@ARBITRARY.DOM.AIN since these are clearly NOT
# individuals. It also may be effective to avoid mail loop since 
# some error or automatic reply comes from not individual addresses.
# This restriction is stronger than $PERMIT_*_FROM variable.
# For example, if $PERMIT_POST_FROM is "anyone", fml does not permit
# post from root@some.domain. If you permit it, please define $REJECT_ADDR.
#
# XXX This variable name is ambiguous. It should be $REJECT_ACCOUNT?
#
# value: regexp string
$REJECT_ADDR                   = "root|postmaster|MAILER-DAEMON|msgs|nobody|news|majordomo|listserv|listproc|\S+\-help|\S+\-subscribe|\S+\-unsubscribe";

# list of addresses fml should reject. fml checks From: field for this but
# it may be ineffective since SMTP has no general authentication method.
# value: filename string
$REJECT_ADDR_LIST              = "$DIR/spamlist";

# check UNIX from to avoid mail loop. check in default.
# value: 1/0
$NOT_USE_UNIX_FROM_LOOP_CHECK  = 0;

# check Message-Id: duplication to avoid mail loop
# value: 1/0
$CHECK_MESSAGE_ID              = 1;

# check mail body content md5 checksum to avoid mail loop
# do not check it in default. 
# value: 1/0
$CHECK_MAILBODY_CKSUM          = 0;

# obsolete today
# Logs the getpeername()
# value: 1/0
$LOG_CONNECTION                = 0;

# address check levels, which level is the tree depth from the root.
# For example
#    fukachan@phys.titech.ac.jp
#    fukachan@axion.phys.titech.ac.jp
#
# fml checks $ADDR_CHECK_MAX level from the name space root. That is
# compare "jp" -> compare "ac" -> titech -> phys -> axion ...
#
# When $ADDR_CHECK_MAX = 3, fml regards these two are the same.
# When $ADDR_CHECK_MAX = 4, fml regards these two are the same.
# When $ADDR_CHECK_MAX = 5, fml regards these two are DIFFERENT!
#
# value: number
$ADDR_CHECK_MAX                = 3;

# fml reject too big mail.
# In-coming mail size > $INCOMING_MAIL_SIZE_LIMIT, fml discards it
# and send a warning only to the maintainer.
# 0 (default) implies infinite (no limit)
# value: number
$INCOMING_MAIL_SIZE_LIMIT      = "";

# When fml reject too big mail, 
# if $NOTIFY_MAIL_SIZE_OVERFLOW is set, notify the rejection to the sender.
# value: 1/0
$NOTIFY_MAIL_SIZE_OVERFLOW     = 1;

# When fml reject too big mail, 
# if $ANNOUNCE_MAIL_SIZE_OVERFLOW is set, announce "too big mail from someone"
# to mailing list (SARASHIMONO:-).
# value: 1/0
$ANNOUNCE_MAIL_SIZE_OVERFLOW   = 0;

# Resource Limit (useful for ISP ?): (default 0 == not check this limit)
# the maximum of ML delivery members when auto registration routine works.
#
# If member > $MAX_MEMBER_LIMIT, auto registration rejects the request. 
# We check actives to permit aliases of post-able addresses. 
# We check @ACTIVE_LIST effective members, not @MEMBER_LIST.
# value: number
$MAX_MEMBER_LIMIT              = "";

# Filter of posted article.
# &EnvelopeFilter is called in the top of &Distribute if you set
# $USE_DISTRIBUTE_FILTER = 1;
# value: 1/0
$USE_DISTRIBUTE_FILTER         = "";

# Filter of posted article.
# You can use $DISTRIBUTE_FILTER_HOOK for advanced customizes.
# value: string
$DISTRIBUTE_FILTER_HOOK        = "";

# $FILTER_NOTIFY_REJECTION enables fml.pl notifies the rejection to
# the sender.
# value: 1/0
$FILTER_NOTIFY_REJECTION       = "";

# Attribute of filter of posted article
# value: 1/0
$FILTER_ATTR_REJECT_NULL_BODY  = 1;

# Attribute of filter of posted article
# When $FILTER_ATTR_REJECT_COMMAND is 1 under distribution mode, 
# rejects "# command" syntax just before distribution (&Distribute;)
# value: 1/0
$FILTER_ATTR_REJECT_COMMAND    = "";

# Attribute of filter of posted article
# reject Japanese "2byes English words"
# value: 1/0
$FILTER_ATTR_REJECT_2BYTES_COMMAND = "";

# Attribute of filter of posted article
# reject command mail sent to the address for posting.
# value: 1/0
$FILTER_ATTR_REJECT_INVALID_COMMAND = 1;

# Attribute of filter of posted article
# reject a mail with "one line" mail body (must be invalid command mail)
# one line means the input mail has one line in the first paragraph
# except for signature (last paragraph).
# Even if it has one line, the paragraph ends with period '.'
# it must be an effective paragraph. So we should not reject it.
# value: 1/0
$FILTER_ATTR_REJECT_ONE_LINE_BODY = 1;

# Attribute of filter of posted article
# reject MIME/multipart mails with Microsoft GUID within it, 
# We intend to reject "Melissa virus" family by it.
# value: 1/0
$FILTER_ATTR_REJECT_MS_GUID    = 1;

# reject not ascii nor ISO-2022-JP
# value: 1/0
$FILTER_ATTR_REJECT_INVALID_JAPANESE = 0;

# cutoff empty message. 
# value: 1/0
$CONTENT_HANDLER_CUTOFF_EMPTY_MESSAGE = 0;

# reject empty message after cut off process.
# value: 1/0
$CONTENT_HANDLER_REJECT_EMPTY_MESSAGE = 0;

# try to convert Japanese HANKAKU chars in the mail body to ZENAKKU
# value: 1/0
$USE_HANKAKU_CONVERTER         = 0;

# reject HTML mails that the same content exist in the form of both
# plain and html. e.g. some versions of M$ outlook, netscape mail
# "AGAINST_HTML_MAIL: 1/0" is old style, which works for compatibility though.
# NULL (default) is "pass through a html mail".
# value: "strip" / "reject" / ""
$HTML_MAIL_DEFAULT_HANDLER     = "";

# Traffic Monitoring Mechanism within fml
# Mail Traffic Information: internal traffic monitor
# value: 1/0
$USE_MTI                       = "";

# MIT warning (mail bomb report) negative cache interval
# to avoid mail bomb of "mail bomb attack report" itself.
# value: number
$MTI_WARN_INTERVAL             = 3600;

$MTI_WARN_LASTLOG              = ""; # value: filename string 


# garbage collection
# how old data (cache) to remove in clean up 
# value: number
$MTI_EXPIRE_UNIT               = 3600;

# low water mark
# value: number
$MTI_BURST_SOFT_LIMIT          = 1;

# high water mark
# value: number
$MTI_BURST_HARD_LIMIT          = 2;

# function name to evaluate the current traffic load
# value: funtion string
$MTI_COST_EVAL_FUNCTION        = "MTISimpleBomberP";

# cache of spammer candidates
# value: filename string
$MTI_MAIL_FROM_HINT_LIST       = "$DIR/mti_mailfrom.hints";

# how to announce the new comer if $AUTO_REGISTERED_UNDELIVER_P is 0.
# value: raw / prepend_info
$SUBSCRIBE_ANNOUNCE_FORWARD_TYPE = "prepend_info";

# Optional. If UNSUBSCRIBE_AUTH_TYPE is 'confirmation', fml sends back
# confirmation against a fake. In default, FML does not do confirmation.
# available type is "confirmation" only.
# value: confirmation
$UNSUBSCRIBE_AUTH_TYPE         = "";

# chaddr checks confirmation
# value: confirmation / ""
$CHADDR_AUTH_TYPE              = "";

# LOGGING THE LATEST IN-COMING MAILS
# Logs an in-coming mail to $LOG_MAIL_DIR/$id 
# where ($id = `cat $LOG_MAIL_SEQ`; $id = $id % $NUM_LOG_MAIL; $id++).
# Latest $NUM_LOG_MAIL files are stored in $LOG_MAIL_DIR and 
# the message size of each file except for the header
# is limited up to $LOG_MAIL_FILE_SIZE_MAX bytes to save disk.
# value: 1/0
$USE_LOG_MAIL                  = 0;

$LOG_MAIL_DIR                  = "$VAR_DIR/Mail"; # value: filename string

$LOG_MAIL_SEQ                  = "$LOG_MAIL_DIR/.seq";

$NUM_LOG_MAIL                  = 100; # value: number

$LOG_MAIL_FILE_SIZE_MAX        = 2048;

# PGP Encrypted ML
# value: 1/0
$USE_ENCRYPTED_DISTRIBUTION    = "";

$ENCRYPTED_DISTRIBUTION_TYPE   = "pgp2"; # value: pgp / pgp2 / pgp5 / gpgp


# obosolete in fml 4.0
# value: 2/5/6
# PGP_VERSION:	2
#####################################################################
# ### Section: Header Customization ###
# In general, you can control fields in header in the following:
#
#   @HdrFieldsOrder 				 Fields Order In Header
#					 	 
#   &DEFINE_FIELD_ORIGINAL('field');             Conserve Original
#   &DEFINE_FIELD_FORCED('field', "contents");   Overwrite
#
# In default, we discard fields not shown in @HdrFieldsOrder.
# Date: definition ("makefml config" can control this)
# 1 original-date			Date:
# * Date: == when distribute() works
# 2 distribute-date+posted		Date: + Posted:
# 3 distribute-date+x-posted		Date: + X-Posted:
# 4 distribute-date+x-original-date	Date: + X-Original-Date:
# * Date: == when fml.pl receives or is kicked off.
# 5 received-date+posted		Date: + Posted:
# 6 received-date+x-posted		Date: + X-Posted:
# 7 received-date+x-original-date	Date: + X-Original-Date:
# value: original-date/distribute-date+posted/distribute-date+x-posted
#	 /distribute-date+x-original-date/received-date+posted
#	 /received-date+x-posted/received-date+x-original-date
$DATE_TYPE                     = "original-date";

# In article header, fml adds following header fields.
#
#   $XMLNAME
#   $XMLCOUNT: sequence-number
#
#   e.g.
#   X-ML-Name: Elena
#   X-Mail-Count: 00007
#
# value: string
$XMLNAME                       = "X-ML-Name: Elena";
$XMLCOUNT                      = "X-Mail-Count";

# In default subject tag does not exist to show more and more effective
# subject and body. Client Interface SHOULD CONTROL subject descriptions.
#
# The available type is [:] [,] [ ] (:) (,) ( ).
# e.g. [:]  => [Elena:00100] format (here $BRACKET is "Elena").
# But you can customize SUBJECT_FREE_* series variables.
# Please see doc/tutorial for the detail
#
# value:  (:) / [:] / () / [] / (,) / [,] / () / [] / (ID) / [ID] / ""
$SUBJECT_TAG_TYPE              = "";

# BRACKET of "Subject: [BRACKET:ID] ..." form
# value: string
$BRACKET                       = "Elena";

# obsolete
# We strip off e.g. [ML:fukachan] form in Subject
# but this operations depends on special forms, so not functional.
# You do not expect a lot on this option.
$STRIP_BRACKETS                = 0;

# You can customize your own bracket by these variables.
# See doc/tutorial and libtagdef.pl on examples.
# value: regexp string
$BRACKET_SEPARATOR             = "";
$SUBJECT_FREE_FORM             = "";
$SUBJECT_FREE_FORM_REGEXP      = "";
$SUBJECT_FORM_LONG_ID          = "";

# obsolete based on RFC1123
# value: 1/0
$USE_ERRORS_TO                 = "";

# obsolete based on RFC1123
# value: string
$ERRORS_TO                     = "";

# Message-Id: use original Message-Id or Server Defined Message-Id ?
# if 1, original and 
# if 0, fml generates a message-id like $day.FMLAAA.$pid.$MAIL_LIST
# value: 1/0
$USE_ORIGINAL_MESSAGE_ID       = 1;

# Precedence: field; 
# value: string
$PRECEDENCE                    = "bulk";

# append STARTREK stardate :-) in article. 
# Stardate calculation algorithm is ambiguous.
# X-Stardate: field
# value: 1/0
$APPEND_STARDATE               = "";

# RFC2369 e.g. list-post: ..
# value: 1/0
$USE_RFC2369                   = 1;

$LIST_SOFTWARE                 = ""; # List-*

$LIST_POST                     = "";
$LIST_OWNER                    = "";
$LIST_HELP                     = "";
$LIST_SUBSCRIBE                = "";
$LIST_UNSUBSCRIBE              = "";
$LIST_ID                       = "";

# obsolete in fml 3.0
# We should force "To: $MAIL_LIST" form "For Eye" or NOT?
# default is "NO".
#
# 0 Pass the original field To: 
# 1 We rewrite "To: $MAIL_LIST, original-to-fields".
# 2 Force "To: $MAIL_LIST".
# 
# REWRITE_TO = 1 if NOT_REWRITE_TO == 0 (2.1 Release)
# value: 0/1/2
$REWRITE_TO                    = "";

# Default values if no value (no field) is given.
# value: string
$Subject                       = "";
$From_address                  = "not.found";
$User                          = "not.found";
$Date                          = "not.found";

# TIME ZONE;  +0900 is RFC822 syntax (I like JST but ... ;-)
# value: +\d{4} / -\d{4} 
$TZone                         = "+0900";

# time zone within summer time if you use summer time.
# thank HIROSHIMA Naoki <naoki@bcrossing.com> on this idea
$TZONE_DST                     = "";

# ## Sub Section: Pass All Header ? ##
# In some cases you need to pass only defined fields of the header
# which is defined in @HdrFieldsOrder (see "sub SetDefaults" in fml.pl).
# All files except $SKIP_FIELDS is passed through 
# when $PASS_ALL_FIELDS_IN_HEADER is set. 
# The old variable name is $SUPERFLUOUS_HEADERS.
# value: 1/0
$PASS_ALL_FIELDS_IN_HEADER     = 1;

# ignore header field irrespective of @HdrFieldsOrder and
# $PASS_ALL_FIELDS_IN_HEADER setting
# value: regexp string
$SKIP_FIELDS                   = "Return-Receipt-To";

# correct a wrong input
# value: 1/0
$ALLOW_WRONG_LINES_IN_HEADER   = 1;

#####################################################################
# ### Section: Commands, Command Traps, File Operations (e.g. mget) ###
# obsolete
# COMMAND format is "#help" == "# help" if $COMMAND_SYNTAX_EXTENSION is set.
# value: 1/0
$COMMAND_SYNTAX_EXTENSION      = 1;

# "Subject: # commands" is available?
# value: 1/0
$USE_SUBJECT_AS_COMMANDS       = 0;

# obsolete
# If NOT "# command" syntax commands is given, ignore or warn to the user?
# Our default is not, since most such cases are "signature".
# value: 1/0
$USE_WARNING                   = 0;

# obsolete: since this is the same as --ctladdr.
# value: 1/0
$COMMAND_ONLY_SERVER           = 0;

# **ATTENTION**
# $PROHIBIT_COMMAND_FOR_STRANGER is obsoletes since 
# $PROHIBIT_COMMAND_FOR_STRANGER equals $PERMIT_COMMAND_FROM = "anyone";
# ## Sub Section: traps ##
# obsolete
# when $MAIL_LIST == $CONTROL_ADDRESS, 
# the first $COMMAND_CHECK_LIMIT lines is checked for commands mail or not?
# $GUIDE_CHECK_LIMIT is the same kind of variable but for "# guide" trap.
# $GUIDE_KEYWORD determines "guide" of "$ guide" trap.
# value: number
$COMMAND_CHECK_LIMIT           = 3;

# obsolete
# value: number
$GUIDE_CHECK_LIMIT             = 3;

# obsolete
# value: string
$GUIDE_KEYWORD                 = "guide";

# The maximum length for each command. 128 bytes by default.
# value: number
$MAXLEN_COMMAND_INPUT          = 128;

# The maximum number of commands in one command mail.
# The variable \$MAXNUM_COMMAND_INPUT controls this.
# If the value is 3, fml permits 3 commands in one command mail.
# 0 or NULL implies infinite (default). 
# value: number
$MAXNUM_COMMAND_INPUT          = "";

# "# chaddr" command name aliases
# value: regexp string
$CHADDR_KEYWORD                = "chaddr|change\-address|change";

# choise of addresses to return for "chaddr" command reply
# value: newaddr curaddr maintainer
$CHADDR_REPLY_TO               = "newaddr curaddr";

# choise of addresses to return for "admin chaddr" command reply
# value: newaddr curaddr maintainer
$ADMIN_CHADDR_REPLY_TO         = "newaddr curaddr";

# ## Sub Section: mget ##
# The default mode of "mget" without mode (default is "tar.gz" form).
# $MGET_TEXT_MODE_DEFAULT is used by &SendFileBySplit
# value: mode string
$MGET_MODE_DEFAULT             = "";
$MGET_TEXT_MODE_DEFAULT        = "";

# The reply for "mget" commands sends long reply mails as splitten mails
# by the unit $MAIL_LENGTH_LIMIT lines once at $SLEEPTIME secs..
# value: number
$MAIL_LENGTH_LIMIT             = 1000;
$SLEEPTIME                     = 60;

# almost obsolete
# special case of "mget" routine uses these variables. 
# It is not user defined variable.
# See doc/tutorial and libfop.pl for the detail. 
# You change MIME/Multipart default.
# value: string
$MIME_VERSION                  = "";
$MIME_CONTENT_TYPE             = "";
$MIME_MULTIPART_BOUNDARY       = "";
$MIME_MULTIPART_CLOSE_DELIMITER = "";
$MIME_MULTIPART_DELIMITER      = "";
$MIME_MULTIPART_PREAMBLE       = "";
$MIME_MULTIPART_TRAILER        = "";

# Japanese specific
# sjis conversion in "mget ish" mode.
# value: 1/0
$USE_SJIS_IN_ISH               = "";

# RFC1153 configurations; see doc/tutorial for the detail
# value: number
$RFC1153_ISSUE                 = "";

$RFC1153_VOL                   = ""; # value: number / string


$RFC1153_SEQUENCE_FILE         = ""; # value: filename string


# ## Sub Section: MTA specific ##
# qmail specific extension
# To send "get 1" to ml-ctl@domain is equivalent to that
# send anything to ml-get-1@domain if this variable is defined.
# value: 1/0
$USE_DOT_QMAIL_EXT             = 0;

# ## Sub Section: Headers of reply from FML ##
# obsolete
# For the reply for commands from fml,
# we force Reply-To: $FORCE_COMMAND_REPLY_TO ?(default is $CONTROL_ADDRESS)
# value: string
$FORCE_COMMAND_REPLY_TO        = "";

# Subject template in "mget" reply. 
# automatic substitute is done before send the reply; For example, 
# Subject: result for mget [last:3 tar + gzip] (1/1) (Elena Lolabrigita ML)
#
#   _DOC_MODE_   <=>    [last:10 tar + gzip]
#   _PART_       <=>    (1/4)
#   _ML_FN_      <=>    $ML_FN (here is "(Elena Lolabrigita ML)") 
#
# $NOT_SHOW_DOCMODE is obsolete, it equals you discard _PART_.
#
# value: string
$MGET_SUBJECT_TEMPLATE         = "result for mget _DOC_MODE_ _PART_ _ML_FN_";

# send error message to Reply-To: ? or From: ?
# (Of course From: if Reply-To: is not defined).
# If $MESSAGE_RETURN_ADDR_POLICY is null, 
# it implies we prefer Reply-To: (by default).
# value: from / reply-to
$MESSAGE_RETURN_ADDR_POLICY    = "reply-to";

#####################################################################
# ### Section: Digest/Matome Okuri Configurations ###
#
# $MSEND_MODE_DEFAULT is the default of msend (when e.g. m=3)
# and the format is the same as $MGET_MODE_DEFAULT.
# which is "tar.gz" format.
# Subject template in Digest/matome okuri.
# automatic substitute is done before send the reply; For example, 
# Digest -Matome Okuri- Article 768 [last:10 tar + gzip] (1/1) (Elena ML)
#
#   _ARTICLE_RANGE_  <=>    Article 768
#   _DOC_MODE_       <=>    [last:10 tar + gzip]
#   _PART_           <=>    (1/4)
#   _ML_FN_          <=>    $ML_FN (here is "(Elena ML)") 
#
# $NOT_SHOW_DOCMODE is obsolete, it equals you discard _PART_.
#
# value: string
$MSEND_SUBJECT_TEMPLATE        = "Digest _ARTICLE_RANGE_ _PART_ _ML_FN_";

# Digest/Matome Okuri rc file
# value: filename string
$MSEND_RC                      = "$VARLOG_DIR/msendrc";

# rfc1153 or rfc934
# obsoletes $USE_RFC1153, $USE_RFC1153_DIGEST, $USE_RFC934
# value: mode string
$MSEND_MODE_DEFAULT            = "";

# Subject:
# value: string
$MSEND_DEFAULT_SUBJECT         = "";

# If no articles to send, we send "no traffic" to the member of $MAIL_LIST
# with the subject $MSEND_NOTIFICATION_SUBJECT if $MSEND_NOTIFICATION is set.
# value: 1/0
$MSEND_NOTIFICATION            = "";

$MSEND_NOTIFICATION_SUBJECT    = ""; # value: string


# not require X-ML-Info: in the "mget";
# value: 1/0
$MSEND_NOT_USE_X_ML_INFO       = "";

# not do newsyslog in the Sundays morning. $NOT_USE_NEWSYSLOG (CFVersion 2)
# value: 1/0
$MSEND_NOT_USE_NEWSYSLOG       = "";

#####################################################################
# ### Section: Other Files for Configurations and Logs ###
# cache file of Message-ID: loop check
# value: filename string
$LOG_MESSAGE_ID                = "$VARRUN_DIR/msgidcache";

# cache size of Message-ID: negative cache
# value: number
$MESSAGE_ID_CACHE_BUFSIZE      = 6000;

# cache file of mailbody cksum mail loop check
# value: filename string
$LOG_MAILBODY_CKSUM            = "$VARRUN_DIR/bodycksumcache";

# $MEMBER_LIST 	member who can post and use commands
# $ACTIVE_LIST 	delivery list
# value: filename string
$MEMBER_LIST                   = "$DIR/members";
$ACTIVE_LIST                   = "$DIR/actives";

# ATTENTION: only "guide" is also send to strangers
#
# $GUIDE_FILE 		sent by "# guide" command, 
# $OBJECTIVE_FILE 	sent by "# objective" command
# $HELP_FILE 		sent by "# help" command
# value: filename string
$GUIDE_FILE                    = "$DIR/guide";
$OBJECTIVE_FILE                = "$DIR/objective";
$HELP_FILE                     = "$DIR/help";

# When fml rejects mail from someone, fml sends back this file to the sender.
# value: filename string
$DENY_FILE                     = "$DIR/deny";

# $LOGFILE		log file
# $MGET_LOGFILE		log file for mget routine, $LOGFILE in default.
# value: filename string
$LOGFILE                       = "$DIR/log";
$MGET_LOGFILE                  = "$DIR/log";

# suffix extension if defined. For example log.2000
# For example $LOGFILE_SUFFIX = ".%C%y", file name is "log.2000".
# See UNIX manual "strftime(3)" for more details on format.
# value: srtings
$LOGFILE_SUFFIX                = "";

# when -d2 ($debug = 2), logs this file for convenience.
# value: filename string
$DEBUG_LOGFILE                 = "$DIR/log.debug";

# article summary file
# value: filename string
$SUMMARY_FILE                  = "$DIR/summary";

# sequence number file
# value: filename string
$SEQUENCE_FILE                 = "$DIR/seq";

# rename(2) lock (liblock.pl)
# value: filename string
$LOCK_FILE                     = "$VARRUN_DIR/lockfile.v7";

#####################################################################
# ### Section: SMTP and Delivery ###
#
# fml sends mail via SMTP to mail server $HOST:$PORT/tcp.
# The default host is one fml runs on itself. 
# $HOST is an arbitrary host (if you can access it) which runs MTA
# (e.g. sendmail). If the Mailing List Server machine is week, 
# you can use the sendmail of another powerful host(host).
# always try IPv6 connection by default
# value: 1/0
$USE_INET6                     = 1;

$HOST                          = "localhost"; # value: string


$PORT                          = 25; # value: number


# enforce MAIL FROM:<$SMTP_SENDER> if defined
# value: address
$SMTP_SENDER                   = "";

# IF $NOT_TRACE_SMTP IS 1 (default 0), we log the SMTP session to $SMTP_LOG
# value: filename string
$SMTP_LOG                      = "$VARLOG_DIR/_smtplog";

# rotate use of var/log/_smtplog.$i (where $i is the number)
# value: 1/0
$USE_SMTP_LOG_ROTATE           = 1;

# expire how old _smtplog.$date
# value: number
$SMTP_LOG_ROTATE_EXPIRE_LIMIT  = 90;

# the number of var/log/_smtplog.$i files. This is the value of modulus.
# value: number
$NUM_SMTP_LOG_ROTATE           = 8;

# type of suffix for _smtplog
# value: number / day
$SMTP_LOG_ROTATE_TYPE          = "number";

# IF $NOT_TRACE_SMTP IS 1 (default 0), we log the SMTP session to $SMTP_LOG
# IF $TRACE_SMTP_DELAY IS 1, we log the delay of response between SMTP server.
# value: 1/0
$NOT_TRACE_SMTP                = 0;
$TRACE_SMTP_DELAY              = "";

# smtp profile for debug
# value: 1/0
$USE_SMTP_PROFILE              = 0;

# You can use plural MTA for parallel delivery.
# $MCI_SMTP_HOSTS is the number of hosts you use.
# @HOSTS is the array of hosts you use.
# value: number
$MCI_SMTP_HOSTS                = "";

# obsolete today
# value: string
$DEFAULT_RELAY_SERVER          = "";

# obsolete today
# CF (by motonori@wide.ad.jp) base relay control if $RELEY_HACK is on. 
# with %RELAY_GW, %RELAY_NGW, %RELAY_NGW_DOM (set in librelayhack.pl)
# $CF_DEF is CF's configuration files; 
# **ATTENTION**; we do not use sendmail.cf but CF's configuration.
# value: 1/0
$RELAY_HACK                    = "";

# obsolete today
# value: filename string
$CF_DEF                        = "";

# list-outgoing@domain is a real distribution address. Fml does not
# sends article to all recipient list to MTA but only this address.
# MTA expands address list and distribute article.
# In default fml does not use this but effective for poor machine like
# 486 16M ;-)
#
#  fml -> list-outgoing -> expanded and distributed to $ACTIVE_LIST members
#
# XXX dedicated to minmin sama:D
#
# value: 1/0
$USE_OUTGOING_ADDRESS          = "";

# list-outgoing@domain is a real distribution address. Fml does not
# sends article to all recipient list to MTA but only this address.
# MTA expands address list and distribute article.
# In default fml does not use this but effective for poor machine like
# 486 16M ;-)
#
#  fml -> list-outgoing -> expanded and distributed to $ACTIVE_LIST members
#
# value: string
$OUTGOING_ADDRESS              = "";

# VERPs: Variable Envelope Return Paths. See qmail documents for more details.
# XXX you need additional configuration so that MTA receives VERPs addresses.
#
# value: 1/0
$USE_VERP                      = "";

# postfix $verp_delimiters
# value: string
$POSTFIX_VERP_DELIMITERS       = "+=";

# try VERPs once a day for efficient delivery.
# value: 1/0
$TRY_VERP_PER_DAY              = "";

# we use ESMTP pipelining mechanism by default.
# value: 1/0
$NOT_USE_ESMTP_PIPELINING      = 0;

# smtpfeed special option which provides VERPs like error track trick.
# value: 1/0
$USE_SMTPFEED_F_OPTION         = "";

#####################################################################
# ### Section: MISC ###
# ## Sub Section: MIME ##
# Mime Decode On if $USE_MIME for ISO-2022-JP statements.
# e.g. Decode $SUMMARY_FILE subject and so on.
# default 1 from 2.1C#13
# value: 1/0
$USE_MIME                      = 1;

# special hack to treat broken MIME ending (e.g. by MacOS X)
# value: 1/0
$MIME_BROKEN_ENCODING_FIXUP    = 0;

# obsolete and Japanese specific 
# NOT RECOMMENDED OPTION: 
# articles in the spool are MIME-DECODED for poor environment users.
# These articles may be insane in strict MIME oriented mail interfaces.
# value: 1/0
$MIME_DECODED_ARTICLE          = "";

# ## Sub Section: Preamble and Trailer for Mail Body ##
# FOR COMMAND RESULT MAIL, 
# you always append some message in the command reply mail body.
# For example, the mail body becomes
#
#    $PREAMBLE_MAILBODY
#    original body
#    $TRAILER_MAILBODY
#
# If you use the article distributed in ML, you must use some hooks.
# For example, append this in the last of config.ph (but before 1;)
# $SMTP_OPEN_HOOK = q# 
#   $e{'Body'} = $PREAMBLE_MAILBODY. $e{'Body'} .$TRAILER_MAILBODY;
# #;
# Please see doc/tutorial for our policy behind this.
#
# value: string
$PREAMBLE_MAILBODY             = "";
$TRAILER_MAILBODY              = "";

# ## Sub Section: Reply Configurations ##
# In the last of e.g. "command status report", we add 
# "$GOOD_BYE_PHRASE $FACE_MARK" :-) in the last of the reply. 
# So the standard form is
#
#    message
#    FYI message generated by the function $PROC_GEN_INFO.
#    $GOOD_BYE_PHRASE $FACE_MARK
#    for example, "	--$MAIL_LIST, Be Seeing You!"
#
# value: string
$GOOD_BYE_PHRASE               = "";
$FACE_MARK                     = "";

$PROC_GEN_INFO                 = "GenInfo"; # value: function name string


# ## Sub Section: Lock Algorithm ##
# use flock for lock algorithm if $USE_FLOCK is on.
# see flock(2), alarm(3). If not, we rename(2) base lock.
# The timeout of rename(2) lock is rand(3) *  $MAX_TIMEOUT secs.
# value: 1/0
$USE_FLOCK                     = 1;

# In rename(2) base lock case,
# the timeout of rename(2) lock is rand(3) *  $MAX_TIMEOUT secs.
# value: number
$MAX_TIMEOUT                   = 200;

# ## Sub Section: misc ##
# Not spooling of articles (default is "spooling")
# It may be used for some secret ML, ML on diskless machihe;-), ISP services
# value: 1/0
$NOT_USE_SPOOL                 = "";

# "$CFVersion < 2" equals "$COMPAT_FML15 = 1;"
# value: 1/0
$COMPAT_FML15                  = 0;

# newsyslog library maximum number. default is 4. 
# log.4 is removed and 
# log.3 -> log.4, log.2 -> log.3, log.1 -> log.2, log.0 -> log.1, log -> log.0
# value: number
$NEWSYSLOG_MAX                 = 4;

# not used generally. This is "cron of fml package" configuration.
# $CRONTAB 	configuratoin file
# $CRON_PIDFILE	pid file
# value: filename string
$CRONTAB                       = "etc/crontab";
$CRON_PIDFILE                  = "var/run/cron.pid";

# not used generally. This is "cron of fml package" configuration.
# cron notifies what is done to $MAINTAINER.
# value: 1/0
$CRON_NOTIFY                   = 1;

# cross operations
# value: 1/0
$USE_CROSSPOST                 = "";

# Under $USE_MEMBER_NAME is set, commands on member lists
# are with Gecos Fields which are extracted from From: field 
# in the time of auto registration.
# Author: Masayuki FUKUI <fukui@sonic.nm.fujitsu.co.jp>
# value: 1/0
$USE_MEMBER_NAME               = "";

#####################################################################
# ### Section: Expire and Archive  ###
# If $USE_EXPIRE is set, we do expire articles in $SPOOL_DIR.
# The default is "no". You need to remove articles if you do so.
# 
# Expiration limit is $EXPIRE_LIMIT, which syntax is
#   e.g. 7days(days) or 100 (articles left in spool)
# If you re-generate $SUMMARY_FILE, set $EXPIRE_SUMMARY
#
# value: 1/0
$USE_EXPIRE                    = 0;

# expire summary file when $USE_EXPIRE is enabled.
# value: 1/0
$EXPIRE_SUMMARY                = "";

# expire how old articles 
# value: number / ( number + day/week/month )
$EXPIRE_LIMIT                  = "7days";

# If $USE_ARCHIVE is on, we do automatically archive, which is 
# spool/articles is aggregated to e.g. "$ARCHIVE_DIR/100.tar.gz"
# by the unit $ARCHIVE_UNIT.
#
# the location of store (when $USE_ARCHIVE on):	$ARCHIVE_DIR
# the search path order                       : $ARCHIVE_DIR @ARCHIVE_DIR
#
# If @ARCHIVE_DIR is set and $ARCHIVE_DIR is not set, 
#    we use $ARCHIVE_DIR[0] as the $ARCHIVE_DIR.
#
# value: 1/0
$USE_ARCHIVE                   = 0;

# spool/articles is aggregated to "$ARCHIVE_DIR/100.tar.gz"
# by the unit $ARCHIVE_UNIT.
# value: number
$ARCHIVE_UNIT                  = 100;
$DEFAULT_ARCHIVE_UNIT          = 100;

# spool/articles is aggregated to "$ARCHIVE_DIR/100.tar.gz"
# value: directory string
$ARCHIVE_DIR                   = "var/archive";

# "index" command
# In default we scan spool and archives and reports, but
# send back $INDEX_FILE if $INDEX_FILE exists.
# value: filename string
$INDEX_FILE                    = "$DIR/index";

# show directory name in "index" command result? default is "no".
# value: 1/0
$INDEX_SHOW_DIRNAME            = 0;

# ### Section: Library Commands  ###
#
# "library" command is a small mailing list within mailing list.
# It is useful to exchange some files.
# You can put and get files by "library" commands.
#
# In default, @DenyProcedure = ('library'); So 'library' command is disabled;
# Set @DenyProcedure = ('') in LOCAL CONFIG part (the last of config.ph).
#
# value: directory string
$LIBRARY_DIR                   = "var/library";
$LIBRARY_ARCHIVE_DIR           = "archive";

# ## Sub Section: newsyslog(8) ##
# to turn over \$DIR/log
# value: number
$LOGFILE_NEWSYSLOG_LIMIT       = "";

# to turn over $ACTIVE_LIST and $MEMBER_LIST if the file size over this value, 
# default 150K = 30*5000
# value: number / (number + K/M)
$AMLIST_NEWSYSLOG_LIMIT        = "150K";

# ### Section: Html Configurations ###
#
# HTML article generator: Please see doc/tutorial for the details.
# AUTO_HTML_GEN == AUTOmatic HTML GENeration
# if $AUTO_HTML_GEN, we generate html'ed articles in $DIR/$HTML_DIR
# value: 1/0
$AUTO_HTML_GEN                 = "";

# use Mail::HTML::Lite in fml-devel (fml next generation).
# value: 1/0
$USE_NEW_HTML_GEN              = "";

$HTML_THREAD                   = 1; # value: 1/0


$HTML_INDEX_REVERSE_ORDER      = 1; # value: 1/0


# generate html articles under htdocs/ 
# value: directory string
$HTML_DIR                      = "htdocs";

# expire old html articles if non-zero value is defined.
# not expire in default since the value is 0 or NULL.
# options: Please see doc/tutorial for the details.
# value: number
$HTML_EXPIRE_LIMIT             = "";

# title of index.html
# value: string
$HTML_INDEX_TITLE              = "";

# cache file
# value: filename string
$HTML_DATA_CACHE               = "";
$HTML_DATA_THREAD              = "";

# filter in generate html file
# value: filename string
$HTML_OUTPUT_FILTER            = "";

# stylesheet file name (see HTML 4.0)
# "fml.css" is default.
# value: filename string
$HTML_STYLESHEET_BASENAME      = "";

# threading algorithm type
# value: default / prefer-in-reply-to
$HTML_THREAD_REF_TYPE          = "prefer-in-reply-to";

# sort type for entries of thread.html
# default is "time" from past to latest, 
# "reverse-number" is from latest to past.
# value: "" / reverse-number
$HTML_THREAD_SORT_TYPE         = "";

# $subdir type of htdocs/$subdir/
# value: number / day / week / month / infinite
$HTML_INDEX_UNIT               = "day";

# threading type
# value: "" / UL
$HTML_INDENT_STYLE             = "UL";

# image file embedding style
# value: A / IMAGE 
$HTML_MULTIPART_IMAGE_REF_TYPE = "";

# html file umask
# value: "" / umask
$HTML_DEFAULT_UMASK            = "";
$HTML_WRITE_UMASK              = "";

# ### Section: Interface to DataBase Management System ###
# value: 1/0
$USE_DATABASE                  = "";

$DATABASE_METHOD               = ""; # value: 


$DATABASE_CACHE_FILE_SUFFIX    = ""; # value:


$DATABASE_DRIVER               = "toymodel.pl"; # value: filename


# attributes to inform database drivers
# value: 
$DATABASE_DRIVER_ATTRIBUTES    = "always_lower_domain";

# ## Sub Section: RDBMS
# value: string 
$SQL_SERVER_HOST               = "";

$SQL_SERVER_PORT               = ""; # value: number


$SQL_SERVER_USER               = ""; # value: string 


# value: string 
# value: string 
$SQL_DATABASE_NAME             = "";

$SQL_SERVER_PASSWORD           = ""; # value: string 


# value: string 
# value: string 
$SQL_DATABASE_NAME             = "";

# ## Sub Section: LDAP
# value: string
$LDAP_SERVER_HOST              = "";
$LDAP_SERVER_PASSWORD          = "";
$LDAP_SEARCH_BASE              = "";
$LDAP_SERVER_BIND              = "";
$LDAP_QUERY_FILTER             = "";

# ### Section: Interface to other Services (http,ftp,gopher,www) ###
# "whois": default is search of local database file 
# If "whois -h host" syntax is given, we connects "host" whois server.
# If $USE_WHOIS set, you can use local database $WHOIS_DB.
# If you have local whois server (inetd), you can also use it.
# If "whois help" is given, send back $WHOIS_HELP_FILE if it exists.
#
# value: 1/0
$USE_WHOIS                     = "";

$DEFAULT_WHOIS_SERVER          = ""; # value: string


# value: filename string
$WHOIS_DB                      = "$VARDB_DIR/whoisdb";
$WHOIS_HELP_FILE               = "";

# do Japanese conversion or not? for the result from whois server
# value: 1/0
$WHOIS_JCODE_P                 = 1;

#####################################################################
# ### Section: Architecture Dependence ###
# cpu-type manufacturer operating-system by GNU config.guess ("makefml")
# value: string
$CPU_TYPE_MANUFACTURER_OS      = "";

# struct sockaddr
# It is system dependent.
# value: string
$STRUCT_SOCKADDR               = "S n a4 x8";

# flock(2) system call; please see "/usr/include/sys/file.h"
# value: number
$LOCK_SH                       = 1;
$LOCK_EX                       = 2;
$LOCK_NB                       = 4;
$LOCK_UN                       = 8;

# enforce solaris 2 compatible
# value: 1/0
$COMPAT_SOLARIS2               = "";

# used in cron of fml package
# we can emulate daemon(3) ?
# value: 1/0
$NOT_USE_TIOCNOTTY             = "";

# On Unix, always yes set 1 in &SetDefaults;
# value: 1/0
$HAS_GETPWUID                  = 1;

# On Unix, always yes set 1 in &SetDefaults;
# value: 1/0
$HAS_GETPWGID                  = 1;

# On Unix, always yes set 1 in &SetDefaults;
# value: 1/0
$HAS_ALARM                     = 1;

# On Unix, always yes set 1 in &SetDefaults;
# value: 1/0
$UNISTD                        = 1;

# program paths fml uses
# Usually "makefml newml" checks and expands this value. 
# value: filename string
$SENDMAIL                      = "/usr/sbin/sendmail";
$TAR                           = "/usr/bin/tar cf -";
$UUENCODE                      = "/usr/bin/uuencode";
$COMPRESS                      = "/usr/bin/gzip -c";
$ZCAT                          = "/usr/bin/gzcat";
$LHA                           = "";
$ISH                           = "";
$ZIP                           = "/usr/pkg/bin/zip";
$BZIP2                         = "/usr/bin/bzip2";
$PGP                           = "";
$PGP5                          = "";
$PGPE                          = "";
$PGPK                          = "";
$PGPS                          = "";
$PGPV                          = "";
$GPG                           = "";
$RCS                           = "/usr/bin/rcs";
$CI                            = "/usr/bin/ci";
$BASE64_DECODE                 = "";
$BASE64_ENCODE                 = "";
$MD5                           = "/usr/bin/md5";


######################################################################
# ### Section: LOCAL CONFIG ###

# ## Sub Section: Available Hooks ##
# You can set customized hooks here. See doc/tutorial's chapter "HOOKS".
# For example available hooks are 
# $START_HOOK, $DISTRIBUTE_START_HOOK, $SMTP_OPEN_HOOK
# $HEADER_ADD_HOOK, $DISTRIBUTE_CLOSE_HOOK, $DISTRIBUTE_END_HOOK
# $ADMIN_COMMAND_HOOK, $RFC1153_CUSTOM_HOOK, $MSEND_OPT_HOOK
# $FML_EXIT_HOOK, $FML_EXIT_PROG, $MSEND_START_HOOK
# $REPORT_HEADER_CONFIG_HOOK, $AUTO_REGISTRATION_HOOK, $MSEND_HEADER_HOOK
# $SMTP_CLOSE_HOOK, $MODE_BIFURCATE_HOOK. $HTML_TITLE_HOOK
# $PROCEDURE_CONFIG_HOOK, $ADMIN_PROCEDURE_CONFIG_HOOK, $COMMAND_HOOK
#
# ## Sub Section: Available Arrays and Assoc-Arrays ##
# Also you can set here arrays and association arrays:
#
# @MEMBER_LIST, @ACTIVE_LIST, @CROSSPOST_CF
# @HOST, @HOSTS, @MAIL_LIST_ALIASES, @HdrFieldsOrder
#
# value: perl statement



1;
