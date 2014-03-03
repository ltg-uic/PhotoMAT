package PassThrough;

use strict;
use warnings;
use HTTP::Status;
use Data::Dumper;
use Database;
use JSON;
use Apache2::Const  qw(:http :common :log);
use Net::SMTP;
use Convert::UU qw(uudecode);

sub handle {
    my ($q, $parent_hash, $h, $session) = @_;
    my $r     = $q->{request};
    my $hash = {  };

    foreach (keys (%$session)) { $hash->{"session_$_"} = $session->{$_} }

    foreach (keys (%$h)) { 
        $hash->{"$_"} = $h->{$_};
        if ($_ eq 'email') { 
            $hash->{$_} =~ s/[^a-zA-Z0-9_\-\+\.\@]//g;
        }
        else { 
            $hash->{$_} =~ s/[^a-zA-Z0-9_,: \$\-\+\.\@]//g;
        }
    }
#    $hash->{stripePubKey} = $r->dir_config()->{stripePubKey};


    return $hash;
}




1;


