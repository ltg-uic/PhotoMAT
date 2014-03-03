package Token;

use strict;
use warnings;
use HTTP::Status;
use Data::Dumper;
use Database;
use JSON;
use Apache2::Const qw(FORBIDDEN HTTP_OK NOT_FOUND DECLINED);
use Net::SMTP;
use Convert::UU qw(uudecode);
use CGI;

sub handle {
    my ($q, $parent_hash, $h, $session) = @_;
    my $r     = $parent_hash->{request};
    my $dbh   = $parent_hash->{dbh};
    my $hash = {  };

    my $method = $parent_hash->{method};

    if ($method eq 'POST') { 
        my $body = $parent_hash->{content_in};
        my $form = from_json($body);
        my $auth = &Database::getRow($r, $dbh, qq[select id from person where email=? and password=crypt(?, password)], $form->{email}, $form->{password});      
        if ($auth->{id}) { 
            &Database::do($r, $dbh, qq[delete from token where person_id=?], $auth->{id});
            my $token = createToken();
            &Database::do($r, $dbh, qq[insert into token (person_id, token) values(?, ?)], $auth->{id}, $token);
            $parent_hash->{http_content} = to_json({ token => $token});
        }        
        else { 
            $parent_hash->{http_content} = to_json( { message => "Login Failure"});
            $parent_hash->{http_status} = FORBIDDEN;
        }
    }
    elsif ($method eq 'DELETE') { 
        my $token = $r->headers_in->{"X-Trap-Token"};
        print STDERR "token is $token\n";
        &Database::do($r, $dbh, qq[delete from token where token=?], $token);
        $parent_hash->{http_content} = to_json( { message => "Logged Out"});
    }

    return $hash;
}



sub createToken {
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


