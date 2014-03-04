#!/usr/bin/perl 

use strict;
use warnings;

my $restart = 0;

chdir "/Users/aijaz/CocoaApps/TrapEase/web/htdocs";
#doCmd('/Users/aijaz/local/bin/sass --update css/sass:css');

chdir "/Users/aijaz/CocoaApps/TrapEase/web";

# copy taskforest
# doCmd('rsync -az --stats --exclude=".??*" taskforest/ root@trap.euclidsoftware.com:/usr/local/apache2/trap/taskforest');

# copy docs
# doCmd('rsync -az --stats --exclude=".??*" docs/ root@rest.trap.euclidsoftware.com:/usr/local/apache2/trap/docs');

# copy htdocs
doCmd('rsync -az --stats --exclude=".??*" htdocs/ root@trap.euclidsoftware.com:/usr/local/apache2/trap/htdocs');

doCmd('rsync -az --stats --exclude=".??*" cgi-bin/ root@trap.euclidsoftware.com:/usr/local/apache2/trap/cgi-bin');

# copy lib
my $stats = doCmd('rsync -az --stats --exclude=".??*" lib/ root@trap.euclidsoftware.com:/usr/local/apache2/trap/lib');
($restart) = $stats =~ /Number of files transferred: (\d+)/s;

if ($restart) { 
    doCmd('ssh root@trap.euclidsoftware.com "/usr/local/apache2/bin/apachectl stop"');
    sleep 2;
    doCmd('ssh root@trap.euclidsoftware.com "/usr/local/apache2/bin/apachectl start"');
    sleep 2;
    doCmd('curl -I http://trap.euclidsoftware.com');
}

sub doCmd { 
    my ($cmd) = @_;

    print "Running command $cmd\n";
    my $a = `$cmd`;
    if ($?) { 
        die "Command failed: $? - $@\n"
    }
    return $a;
}
