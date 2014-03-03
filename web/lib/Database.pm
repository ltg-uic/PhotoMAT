package Database;

use strict;
use warnings;
use DBI;
use Data::Dumper;


sub connectToDb {
    my $r           = shift;
    my $hostName    = $r->dir_config('dbHost');
    my $port        = $r->dir_config('dbPort');
    my $dbName      = $r->dir_config('dbName');
    my $userName    = $r->dir_config('dbUser');
    my $pass        = $r->dir_config('dbPass');
    my $data_source = qq[dbi:Pg:database=$dbName;host=$hostName;port=$port];
    my $dbh         = DBI->connect_cached($data_source, $userName, $pass, { AutoCommit => 0, RaiseError => 0 });

    if (!defined $dbh) {
        $r->log->crit($DBI::errstr);
        exit 1;
    }
    

    return $dbh;
}

sub disconnectFromDb {
    my ($r, $dbh) = @_;
    $dbh->disconnect();
}

sub prepare { 
    my ($r, $dbh, $sql) = @_;
    my $st = $dbh->prepare($sql);
    if (!$st) { 
        $dbh->disconnect();
        $r->log->crit($DBI::errstr);
        exit 1;
    }
    return $st;
}

sub getResultSet { 
    my ($r, $dbh, $st) = @_;
    my $resultSet = $st->fetchall_arrayref({});
    if ($dbh->err) { 
        $dbh->disconnect();
        $r->log->crit($DBI::errstr);
        exit 1;
    }
    if (@$resultSet) { 
        #my $n = 0;
        #my $oe = 0;
        #foreach my $h (@$resultSet) {
        #    $h->{n0} = $n;
        #    $n++;
        #    $h->{n1} = $n;
        #    $h->{oe} = $oe;
        #    $oe ^= 1;
        #}
    }
    else { 
        return undef;
    }
    return $resultSet;
}

sub execute { 
    my ($r, $dbh, $st, @rest) = @_;

    if (@rest) { 
        $st->execute(@rest) || dbDie($r, $dbh);
    }
    else { 
        $st->execute() || dbDie($r, $dbh);
    }
}


sub getRows { 
    my ($r, $dbh, $sql, @rest) = @_;
    print STDERR "getRows: $sql\n";
    my $st = prepare($r, $dbh, $sql);
    if ( (!defined $st) || $dbh->err) { 
        $dbh->disconnect();
        $r->log->crit($DBI::errstr);
        exit 1;
    }

    if (@rest) {
        $st->execute(@rest) || dbDie($r, $dbh);
    } 
    else { 
        $st->execute() || dbDie($r, $dbh);
    }
    my $resultSet = getResultSet($r, $dbh, $st);
    $st->finish;
    return $resultSet;
}

sub getRow { 
    my $resultSet = getRows(@_);

    if ($resultSet) {
        return $resultSet->[0];
    }
    
    return undef;
}

sub dbDie { 
    my ($r, $dbh) = @_;
    $dbh->disconnect();
    $r->log->crit($DBI::errstr);
    exit 1;
}

sub testDatabase {
    my $r = shift;
    my $dbh = shift;
    my $resultSet = getRows($r, $dbh, "select password from slUser");
    print Dumper($resultSet);
}

sub do { 
    my ($r, $dbh, $sql, @rest) = @_;
    { 
        print STDERR "do: $sql\n";
        my $restStr = "With ";
        foreach my $token (@rest){ 
            if (defined ($token)) { 
                $restStr .= ", $token";
            }
            else { 
                $restStr .= ', [undef]';
            }
        }
        $restStr .= "\n";
        print STDERR "  $restStr";
    }
    my $st = prepare($r, $dbh, $sql);
    if ( (!defined $st) || $dbh->err) { 
        $dbh->disconnect();
        $r->log->crit($DBI::errstr);
        exit 1;
    }

    if (@rest) {
        $st->execute(@rest) || dbDie($r, $dbh);
    } 
    else { 
        $st->execute() || dbDie($r, $dbh);
    }
    $st->finish;
}


sub deleteCookie {
    my ($r, $dbh, $cookieFromBrowser) = @_;
    &Database::do($r, $dbh, "delete from slCookie where cookieString=?", $cookieFromBrowser);
}

sub deleteCookieForUserId {
    my ($r, $dbh, $userId) = @_;
    &Database::do($r, $dbh, "delete from slCookie where fkUserId=?", $userId);
}

sub getCookie {
    my ($r, $dbh, $cookieFromBrowser) = @_;

    my $row = &Database::getRow($r, $dbh, "select fkUserId, email, username from slCookie where cookieString=?", $cookieFromBrowser);
    if ($row) { 
        my $userId = $row->{fkuserid};
        $userId = 0 unless $userId;
        return { cookieString => $cookieFromBrowser, userId => $userId, email => $row->{email}, username => $row->{username}};
    }
    else {
        # not on disk - probably because the person logged off
        # the userId of 0 tells Web that a login is needed
        return undef;
    }
}

sub saveCookie {
    my ($r, $dbh, $hash) = @_;
    
    &deleteCookieForUserId($r, $dbh, $hash->{userId});
    &Database::do($r,
                  $dbh,
                  "insert into slCookie(cookieString, fkUserId, email, username) values(? , ?, ?, ?)",
                  $hash->{cookieString},
                  $hash->{userId},
                  $hash->{email},
                  $hash->{username});
        
}

1;
