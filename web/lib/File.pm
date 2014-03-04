package File;

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
    my $person = &Auth::getPerson($r, $dbh);

    my $method = $parent_hash->{method};
    my $path = $parent_hash->{path} ;
    my ($table, $id) = split(/\//, $path);

    print STDERR "table is $table and id is $id\n";

    my $pictureRow = &Database::getRow($r, $dbh, qq[select * from $table where id=?], $id);
    my $owner = $pictureRow->{owner};
    print STDERR "owner is $owner and personid is $person->{id}\n";

    if ($method eq 'POST') { 
        if (1 || $owner == $person->{id}) { 
            # authorized to put
            uploadFile($r, $id, $table, $parent_hash->{cgi});
        }
    }
    elsif ($method eq 'GET') { 
        $parent_hash->{REDIRECT} = "/usr/local/apache2/trap/images/$table"."_$id.jpg";
    }
    elsif ($method eq 'DELETE') { 
        if ($owner == $person->{id}) { 
            # authorized to delete
        }
    }

    return $hash;
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


1;


