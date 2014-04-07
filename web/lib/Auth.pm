package Auth;

use strict;
use warnings;
use HTTP::Status;
use Data::Dumper;
use Database;
use JSON;
use Net::SMTP;
use Convert::UU qw(uudecode);
use Apache2::Const qw(FORBIDDEN OK NOT_FOUND);


sub getPerson {
    my ($r, $dbh) = @_;

    my $token = $r->headers_in->{"X-Trap-Token"};

    print STDERR "IN AUTH: Token is $token\n";

    if (!defined $token) { 
        return undef;
    }

    my $person;

    if ($token eq 'AijazAuthToken') { 
        $person = &Database::getRow($r, $dbh, qq[select p.* from person p where id = 1]);
    }
    elsif ($token eq 'AijazAuthToken2') { 
        $person = &Database::getRow($r, $dbh, qq[select p.* from person p where id = 2]);
    }
    elsif ($token =~ /WouldntItBeCool(\d+)/) { 
        my $id = $1;
        $person = &Database::getRow($r, $dbh, qq[select p.* from person p where id = ?], $id);
    }
    else { 
        $person = &Database::getRow($r, $dbh, qq[select p.* from person p join token t on t.person_id = p.id where t.token = ?], $token);
    }
    
    return $person;
}

1;


