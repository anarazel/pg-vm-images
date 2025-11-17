#! /bin/sh

set -e

if [ "$(uname)" = "NetBSD" ]
then
    # CPAN fails to use the system Perl installation on NetBSD unless the full
    # directory hierarchy contained in @INC already exists on disk.
    perl -e 'use File::Path qw(make_path); make_path(@INC);'
fi

# Upgrade the IPC::Run version to latest, since the version shipped in an OS
# distribution can lag considerably behind, and tracking down intermittent
# failures for bugs that have already been fixed is no fun.
export MODULE_SIGNATURE_KEYSERVER=pgpkeys.eu
(
 echo;                            # automate first-time setup
 echo o conf check_sigs 1;        # check signatures
 echo o conf init gpg; echo;      # use the default path for gpg
 echo o conf recommends_policy 0; # don't install "recommended" modules
 echo notest install IPC::Run;
) | cpan
