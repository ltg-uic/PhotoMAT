#!/usr/local/bin/perl


use strict;
use warnings;
use lib qw ( /usr/local/apache2/trap/lib );
use Data::Dumper;
use Database;
use JSON;
use Apache2::Const qw(FORBIDDEN HTTP_OK NOT_FOUND DECLINED);
use Net::SMTP;
use Convert::UU qw(uudecode);
use CGI;




use Data::Dumper;
use CGI;


my $cgi = new CGI;
print "Content-type: text/plain\n\nHello\n";

my $dbh           = &Database::connectToDbCGI;
my $r = undef;

my $hash = {  };
my $person = getPerson($r, $dbh, $cgi);

my $method = $cgi->request_method();

my $path = $cgi->path_info();

my ($junk, $table, $id) = split(/\//, $path);

print STDERR "path is '$path' and table is $table and id is $id\n";

my $pictureRow = &Database::getRow($r, $dbh, qq[select * from $table where id=?], $id);
my $owner = $pictureRow->{owner};
print STDERR "owner is $owner and personid is $person->{id}\n";

if (1 || $method eq 'PUT') { 
    if (1 || $owner == $person->{id}) { 
        # authorized to put
        uploadFile($r, $id, $table, $cgi);
    }
}
elsif ($method eq 'GET') { 
    # $parent_hash->{REDIRECT} = "/usr/local/apache2/trap/images/$table"."_$id.jpg";
}
elsif ($method eq 'DELETE') { 
    if ($owner == $person->{id}) { 
        # authorized to delete
    }
}

sub uploadFile { 
    my ($r, $id, $table, $cgi) = @_;

    my $params = $cgi->Vars;
    my $filePath = "/usr/local/apache2/trap/images/$table"."_$id.jpg";
    print STDERR "filePath is $filePath\n";
    #print STDERR "params is ", Dumper($params);

    my $lightweight_fh  = $cgi->upload('file');

    if (defined $lightweight_fh) {
        print STDERR "fh defined\n";
        my $io_handle = $lightweight_fh->handle;
        my $buffer;
        open (OUTFILE,'>', $filePath);
        while (my $bytesread = $io_handle->read($buffer,1024)) {
            print OUTFILE $buffer;
        }
        close OUTFILE;
    }
    return $filePath;
}


sub getPerson {
    my ($r, $dbh, $cgi) = @_;

    my $token = $cgi->http("X-Trap-Token");
    print STDERR "token is $token\n";
    if (!defined $token) { 
        return undef;
    }

    my $person;

    if ($token eq 'AijazAuthToken') { 
        $person = &Database::getRow($r, $dbh, qq[select p.* from person p where id = 1]);
    }
    else { 
        $person = &Database::getRow($r, $dbh, qq[select p.* from person p join token t on t.person_id = person.id where t.token = ?], $token);
    }
    
    print STDERR Dumper($token);
    return $person;
}



