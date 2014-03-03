package CSRF;

use strict;
use warnings;
use HTTP::Status;
use Data::Dumper;
use Database;
use JSON;
use Apache2::Const  qw(:http :common :log);
use Net::SMTP;
use Convert::UU qw(uudecode);
use Smtp;
use Session;
use BusinessStripe;
use Token;

sub handle {
    my ($q, $parent_hash, $h, $session) = @_;
    my $r     = $q->{request};
    my $dbh   = $q->{dbh};
    my $hash = {  };

    my $token = &Token::getToken();
    $hash->{csrfToken} = $token;

    &Database::do($r, $dbh, "update ptpSession set csrfToken=? where token=?", $token, $session->{token});

    return $hash;
}

sub consumeToken { 
    my ($r, $dbh, $session, $h) = @_;
    if (!$session->{csrftoken} ) { 
        return 0;
    }
    my $ok = 0;
    if ($session->{csrftoken} eq $h->{csrfToken}) { 
        $ok = 1;
    }
    &Database::do($r, $dbh, "update ptpSession set csrfToken=NULL where token=?", $session->{token});
    return $ok;
}



1;


