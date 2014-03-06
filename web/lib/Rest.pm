package Rest;

use strict;
use warnings;
use HTTP::Status;
use Data::Dumper;
use Database;
use JSON;
use Net::SMTP;
use Convert::UU qw(uudecode);
use Apache2::Const qw(FORBIDDEN HTTP_OK NOT_FOUND HTTP_CONFLICT);
use Auth;


sub handleRest {
    my ($parent_hash, $h, $adminRequired) = @_;
    my $r     = $parent_hash->{request};
    my $dbh   = $parent_hash->{dbh};
    my $table  = $parent_hash->{table};
    my $hash = {  };
    my $http_status = HTTP_OK;
    my $method = $parent_hash->{method};

    if ($method eq 'GET') { 
        my $column_name = 'id';
        my $membership_table = undef;
        my $parent_column = undef;
        $http_status = get($parent_hash, $h, $r, $dbh, $table, $hash, $column_name, $membership_table, $parent_column);
    }
    elsif ($method eq 'POST') { 
        $http_status = post($parent_hash, $h, $adminRequired, $table, $r, $dbh);
    }
    elsif ($method eq 'PUT') { 
        $http_status = put($parent_hash, $h, $adminRequired, $table, $r, $dbh);
    }
    elsif ($method eq 'DELETE') { 
        $http_status = del($parent_hash, $h, $adminRequired, $table, $r, $dbh);
    }


    $parent_hash->{http_status} = $http_status;
    my $result = to_json($hash);
    print STDERR "RETURNING $http_status and hash is $result\n";
    return $result;
}

sub del { 
    my ($parent_hash, $h, $adminRequired, $table, $r, $dbh) = @_;
    my $person = &Auth::getPerson($r, $dbh);
    my $owner = " and owner = $person->{id}";
    if (!defined $person) { 
        return FORBIDDEN;
    }
    if ($adminRequired->{$table}) { 
        unless ($person->{is_admin}) { 
            return FORBIDDEN;
        }
    }
    if ($person->{is_admin}) { 
        $owner = "";
    }

    my $id = $parent_hash->{path};

    print STDERR "DELETE FROM $table where id=$id\n";

    &Database::do($r, $dbh, qq[delete from $table where id=? $owner], $id);

    return HTTP_OK;
}

sub put { 
    my ($parent_hash, $h, $adminRequired, $table, $r, $dbh) = @_;
    my $person = &Auth::getPerson($r, $dbh);
    my $owner = " and owner = $person->{id}";
    if (!defined $person) { 
        return FORBIDDEN;
    }
    if ($adminRequired->{$table}) { 
        unless ($person->{is_admin}) { 
            return FORBIDDEN;
        }
    }
    if ($person->{is_admin}) { 
        $owner = "";
    }

    my $body = $parent_hash->{content_in};
    my $form = from_json($body);
    if (defined ($form->{id})) { 
        delete $form->{id};
    }
    my $id = $parent_hash->{path};

    my $existingRow = &Database::getRow($r, $dbh, qq[select * from $table where id = ?], $id);

    print STDERR "Existing row is ", Dumper ($existingRow);

    if ($existingRow) { 

        my @columns;
        my @values;
        my $hasFile = 0;

        my $tableColumns = &Database::getRows($r, $dbh, qq[select column_name, is_nullable from information_schema.columns where table_name=?], $table);

        foreach my $tableColumn (@$tableColumns) { 
            next if ($tableColumn->{column_name} eq 'id');
            next if ($tableColumn->{column_name} eq 'owner');
            if ($tableColumn->{column_name} eq 'file_name') { 
                $hasFile = 1;
            }
            if (defined ($form->{$tableColumn->{column_name}})) {
                push (@columns, $tableColumn->{column_name});
                push (@values, $form->{$tableColumn->{column_name}});
            }
        }

        my $columnString = join (", ",  (map { "$_ = ?" }  @columns));

        &Database::do($r, $dbh, qq[UPDATE $table set $columnString where id = ? $owner], @values, $id);

        $existingRow = &Database::getRow($r, $dbh, qq[select * from $table where id = ?], $id);
    }
    else { 
        my @columns = ('id', 'owner');
        my @values = ($id, $person->{id});
        my $hasFile = 0;
        my $tableColumns = &Database::getRows($r, $dbh, qq[select column_name, is_nullable from information_schema.columns where table_name=?], $table);

        foreach my $tableColumn (@$tableColumns) { 
            next if ($tableColumn->{column_name} eq 'id');
            next if ($tableColumn->{column_name} eq 'owner');
            if ($tableColumn->{column_name} eq 'file_name') { 
                $hasFile = 1;
            }
            if ($tableColumn->{is_nullable} eq 'NO') {
                if (!defined ($form->{$tableColumn->{column_name}})) {
                    $parent_hash->{http_content} = to_json({ message => "Required field $tableColumn->{column_name} not specified"});
                    return HTTP_CONFLICT;
                }
            }
            if (defined ($form->{$tableColumn->{column_name}})) {
                push (@columns, $tableColumn->{column_name});
                push (@values, $form->{$tableColumn->{column_name}});
            }
        }


        my $columnString = join (", ",  (map { "$_" }  @columns));
        my $valueString = join (", ",  (map { "?"} @columns));

        &Database::do($r, $dbh, qq[INSERT INTO $table ($columnString) values ($valueString)], @values);

        $existingRow = &Database::getRow($r, $dbh, qq[select * from $table where id = ?], $id);
    }

    delete ($existingRow->{owner}); 

    $parent_hash->{http_content} = to_json($existingRow);
    return HTTP_OK;
}


sub post { 
    my ($parent_hash, $h, $adminRequired, $table, $r, $dbh) = @_;
    my $person = &Auth::getPerson($r, $dbh);
    if (!defined $person) { 
        return FORBIDDEN;
    }
    if ($adminRequired->{$table}) { 
        unless ($person->{is_admin}) { 
            return FORBIDDEN;
        }
    }

    my $sequenceName = $table."_id_seq";
    my $sequence = &Database::getRow($r, $dbh, qq[select nextval('$sequenceName')]);
    my $value = $sequence->{nextval};

    $parent_hash->{http_content} = to_json({ id => $value});
    return HTTP_OK;
}

sub get { 
    my ($parent_hash, $h, $r, $dbh, $table, $hash, $column_name, $membership_table, $parent_column) = @_;
    my $http_status = NOT_FOUND;

    my $path = undef;
    if (defined $hash->{id}) { 
        $path = $hash->{id};
    }
    elsif (defined $parent_hash->{path}) { 
        $path = $parent_hash->{path};
    }
    $path *= 1;

    if ($path) { 
        if ($membership_table) {
            $hash->{$table} = &Database::getRows($r, $dbh, qq[select t.* from $table t join $membership_table m ON t.id = m.$column_name where m.$parent_column=?], $path);
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
        $http_status = HTTP_OK;
        foreach my $row (@{$hash->{$table}}) { 
            delete ($row->{password});
            delete ($row->{owner});
        }
    }

    return $http_status;
}


1;


