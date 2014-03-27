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

    my $path = $parent_hash->{path};

    my $sql;

    if ($path eq 'class') { 
        $sql = qq[
            select d.*, p.first_name as person_name, c.name as class_name, s.name as school_name
            from deployment d 
            join person p on p.id = d.person_id  
            join person q on q.class_id=p.class_id  
            join class c on c.id=p.class_id 
            join school s on s.id = c.school_id 
            where q.id=?
            order by d.deployment_date desc
        ];
        $hash->{sets} = &Database::getRows($r, $dbh, $sql, $myUserId);
    }
    elsif ($path eq 'school') { 
        $sql = qq[
            select d.*, p.first_name as person_name, c.name as class_name, s.name as school_name
            from deployment d 
            join person p on p.id = d.person_id  
            join class c on c.id=p.class_id 
            join school s on s.id = c.school_id
            join class c2 on c2.school_id = s.id
            join person q on q.class_id = c2.id
            where q.id = ?
            order by d.deployment_date desc
        ];
        $hash->{sets} = &Database::getRows($r, $dbh, $sql, $myUserId);
    }
    else { 
        $sql = qq[
            select d.*, p.first_name as person_name, c.name as class_name, s.name as school_name
            from deployment d 
            join person p on p.id = d.person_id  
            join class c on c.id=p.class_id 
            join school s on s.id = c.school_id
            order by d.deployment_date desc
        ];
        $hash->{sets} = &Database::getRows($r, $dbh, $sql);
    }

    $parent_hash->{http_content} = to_json($hash);
    return $hash;
}



1;


