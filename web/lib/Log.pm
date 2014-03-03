package Log;

use strict;
use warnings;
use HTTP::Status;
use Data::Dumper;
use Database;
use JSON;
use Apache2::Const  qw(:http :common :log);
use Net::SMTP;
use Convert::UU qw(uudecode);
use Apache2::Connection;

sub log {
    my ($r, $dbh, $session, $detail) = @_;

    &Database::do($r, $dbh, "INSERT INTO ptpLog(userid, groupid, ip, isadmin, detail) values(?, ?, ?, ?, ?)", 
        $session->{userid}, $session->{groupid}, $session->{ip}, $session->{isadmin}, $detail);
    
}

sub rlog { 
    my ($r, $dbh, $token, $detail) = @_;

    if ($token) { 
        my $userRow = &Database::getRow($r, $dbh, "select id from ptpuser where token=?", $token);
        &Database::do($r, $dbh, "INSERT INTO ptpLog(ip, userid, detail) values(?, ?, ?)", 
            $r->connection()->remote_ip(), $userRow->{id}, $detail);
    }
    else { 
        &Database::do($r, $dbh, "INSERT INTO ptpLog(ip, detail) values(?, ?)", 
            $r->connection()->remote_ip(), $detail);
    }
}



1;


