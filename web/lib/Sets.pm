package Sets;

use strict;
use warnings;
use HTTP::Status;
use Data::Dumper;
use Database;
use JSON;
use Apache2::Const qw(FORBIDDEN HTTP_OK NOT_FOUND HTTP_CONFLICT);
use Net::SMTP;
use Convert::UU qw(uudecode);
use CGI;

sub handle {
    my ($q, $parent_hash, $h, $session) = @_;
    my $r     = $parent_hash->{request};
    my $dbh   = $parent_hash->{dbh};
    my $hash = {  };
    my $person = &Auth::getPerson($r, $dbh);

    if (!$person) { 
        $parent_hash->{http_status} = HTTP_CONFLICT;
        return $hash;
    }

    my $myUserId = $person->{id};

    my $method = $parent_hash->{method};

    if ($method eq 'GET') { 
        $parent_hash->{FILE} = "/usr/local/apache2/trap/images/$table"."_$id.jpg";
    }

    return $hash;
}



1;


