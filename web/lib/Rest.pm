package Rest;

use strict;
use warnings;
use HTTP::Status;
use Data::Dumper;
use Database;
use JSON;
use Net::SMTP;
use Convert::UU qw(uudecode);
use Apache2::Const qw(FORBIDDEN OK NOT_FOUND);


sub handleRest {
    my ($parent_hash, $h, $adminRequired) = @_;
    my $r     = $parent_hash->{request};
    my $dbh   = $parent_hash->{dbh};
    my $table  = $parent_hash->{table};
    my $hash = { id => $parent_hash->{path} };
    my $http_status = OK;

    if ($parent_hash->{method} eq 'GET') { 
        my $column_name = 'id';
        my $membership_table = undef;
        my $parent_column = undef;
        $http_status = get($parent_hash, $h, $r, $dbh, $table, $hash, $column_name, $membership_table, $parent_column);
    }

    $parent_hash->{http_status} = $http_status;
    my $result = to_json($hash);
    return $result;
}


sub get { 
    my ($parent_hash, $h, $r, $dbh, $table, $hash, $column_name, $membership_table, $parent_column) = @_;
    my $http_status = NOT_FOUND;

print STDERR "table is $table\n";
print STDERR "hash is ", Dumper($hash);

    my $path = $hash->{id} || 0;
    $path *= 1;

    if ($path) { 
        if ($membership_table) {
            $hash->{$table} = &Database::getRows($r, $dbh, qq[select t.* from $table t join $membership_table m ON t.id = m.$column_name where m.$parent_column=?], $path);
print STDERR "select t.* from $table t join $membership_table m ON t.id = m.$column_name where m.$parent_column=$path\n";
        } else {
            $hash->{$table} = &Database::getRows($r, $dbh, qq[select * from $table where $column_name=?], $path);
        }
        
    }
    else { 
        $hash->{$table} = &Database::getRows($r, $dbh, qq[select * from $table]);
    }

    # now cascade 
    my $children = &Database::getRows($r, $dbh, qq[select child_table, membership_table from get_cascade where parent_table=?], $table);
    foreach my $child (@$children) { 
        my $cascade_column_name = $table."_id";
        if ($child->{membership_table}) { 
            $cascade_column_name = $child->{child_table}."_id";
        }
        foreach my $row (@{$hash->{$table}}) { 

            get($parent_hash, $h, $r, $dbh, $child->{child_table}, $row, $cascade_column_name, $child->{membership_table}, $table."_id");
        }
    }

    if ($hash->{$table}) { 
        $http_status = OK;
        foreach my $row (@{$hash->{$table}}) { 
            delete ($row->{password});
        }
    }

    return $http_status;
}


1;


