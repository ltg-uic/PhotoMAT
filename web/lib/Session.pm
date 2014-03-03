package Session;

use strict;
use warnings;

use Exporter();
our @ISA = qw(Exporter);
our @EXPORT = qw(retrieveSession deleteSession writeSession);

use CGI::Cookie;
use Data::Dumper;
use Database;

use Apache2::Connection;


my $cookie_exp = '+168h';
my $cookieName = 'TrapSession';

sub getSessionTokenFromBrowser {
    my ($r, $name) = @_;

    my $rawCookieString = $r->headers_in->{Cookie} || '';
    my %cookies = CGI::Cookie->parse($rawCookieString);
    if (%cookies && $cookies{$name}) {
        return $cookies{$name}->value;
    }
    return undef;
}


sub deleteSession {
    my ($r, $dbh) = @_;

    my $sessionTokenFromBrowser = getSessionTokenFromBrowser($r, $cookieName);
    if ($sessionTokenFromBrowser) {
        &Database::do($r, $dbh, "delete from ptpSession where token=?", $sessionTokenFromBrowser);
    }
    # create a new cookie and save it to disk
    my $sessionToken = createSessionToken(); 
    my $cookie        = CGI::Cookie->new(
        -name => $cookieName,
        -value => $sessionToken,
        -expires => $cookie_exp, );
    $r->headers_out->add('Set-Cookie' => $cookie);
    $r->err_headers_out->add('Set-Cookie' => $cookie);
    my $session = {token => $sessionToken, new => 1, email => '', cookie => $cookie, isadmin => 0, userid=>0, username=> " ", 
                    ip => $r->connection()->remote_ip(), groupid => 0, stripeid => '', groupname => ''};
    return $session;

}

sub writeSession {
    my ($r, $dbh, $session) = @_;

    &Database::do($r, $dbh, "delete from PTPSession where email=? or token=?", $session->{email}, $session->{token});


    &Database::do($r, $dbh, "insert into PTPSession(userid, token, email, username, csrftoken, isadmin, ip, groupid, stripeid, groupname) ".
        "values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        $session->{userid}, $session->{token}, $session->{email}, $session->{username}, 
        $session->{csrftoken}, $session->{isadmin}, $session->{ip}, $session->{groupid}, $session->{stripeid},
        $session->{groupname});

}


sub retrieveSession {
    my ($r, $dbh) = @_;

    my $sessionTokenFromBrowser = getSessionTokenFromBrowser($r, $cookieName);
    # if ($sessionTokenFromBrowser) { 
    #     print STDERR "Session Token From Browser is $sessionTokenFromBrowser\n";
    # }
    # else { 
    #     print STDERR "Session Token From Browser is undefined\n";
    # }
    unless ($sessionTokenFromBrowser) {
        # create a new cookie and save it to disk
        my $sessionToken = createSessionToken(); 
        my $cookie        = CGI::Cookie->new(
                                                -name => $cookieName,
                                                -value => $sessionToken,
                                                -expires => $cookie_exp, );
        my $session = {token => $sessionToken, new => 1, email => '', cookie => $cookie, isadmin => 0, 
        userid=>0, username=> " ", ip => $r->connection()->remote_ip(), groupid => 0, stripeid => '',
        groupname => ''};
        return $session;
    }
    
    # retrieved from browser (still valid)
    my $cookie = CGI::Cookie->new(
                                     -name => $cookieName,
                                     -value => $sessionTokenFromBrowser,
                                     -expires => $cookie_exp, );

    # now read session value from disk
    my $session = &Database::getRow($r, $dbh, "select * from ptpSession where token=?", $sessionTokenFromBrowser);

    if (!$session) {
        # Session is not in db.  Probably means person is not logged in.  Create a new one.
        $session = {token => $sessionTokenFromBrowser, new => 1, email => '', cookie => $cookie, isadmin => 0, 
        userid=>0, username=> " ", ip => $r->connection()->remote_ip(), groupid => 0, stripeid => '', groupname => ''};
    }
    else { 
        $session->{cookie} = $cookie;
        # always set the cookie, so we're always 1 hour away from an auto logout
    }
    return $session;
}

sub createSessionToken {
    my @chars = ('a'..'z','0'..'9','A'..'Z');
    my $num_chars = 62;
    my $cookie_length=32;
    my @cookie = ();

    while ($cookie_length) {
        push (@cookie, $chars[rand $num_chars]);
        $cookie_length--;
    }
    return join('', @cookie);
}



1;
