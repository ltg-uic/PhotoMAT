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


# additions - param to POST

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
        my $expand_path  = undef;
        $http_status = get($parent_hash, $h, $r, $dbh, $table, $hash, $column_name, $membership_table, $parent_column, $expand_path);
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
    my $result = to_json($hash, {pretty=>1});
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
                    $parent_hash->{http_content} = to_json({ message => "Required field $tableColumn->{column_name} not specified"}, {pretty=>1});
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

    $parent_hash->{http_content} = to_json($existingRow, {pretty=>1});
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

    my $count = $parent_hash->{path};
    $count *= 1;

    my $sequenceName = $table."_id_seq";

    if ($count && $count > 1) { 
        my $ids = [];
        my $sequence;
        my $value;
        for (my $n = 0; $n < $count; $n++) { 
            $sequence = &Database::getRow($r, $dbh, qq[select nextval('$sequenceName')]);
            $value = $sequence->{nextval};

            push (@$ids, $value);
        }
        $parent_hash->{http_content} = to_json({ ids => $ids}, {pretty=>1});
    }
    else { 
        my $sequence = &Database::getRow($r, $dbh, qq[select nextval('$sequenceName')]);
        my $value = $sequence->{nextval};

        $parent_hash->{http_content} = to_json({ id => $value}, {pretty=>1});
    }
    return HTTP_OK;
}

sub get { 
    my ($parent_hash, $h, $r, $dbh, $table, $hash, $column_name, $membership_table, $parent_column, $expand_path) = @_;
    my $http_status = NOT_FOUND;

    my $path;
    if (defined $hash->{id}) { 
        $path = $hash->{id};
    }
    elsif (defined $parent_hash->{path}) { 
        $path = $parent_hash->{path};
        $path =~ s/\D//g;
    }

    if ($expand_path) { 
        $hash->{$table} = &Database::getRow($r, $dbh, qq[select * from $table where $column_name=?], $expand_path);
    }
    elsif ($path) { 
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
    # as defined cascade go from 1 to many
    my $children = &Database::getRows($r, $dbh, qq[select child_table, membership_table from get_cascade where parent_table=?], $table);
    foreach my $child (@$children) { 
        my $cascade_column_name = $table."_id";
        if ($child->{membership_table}) { 
            $cascade_column_name = $child->{child_table}."_id";
        }
        foreach my $row (@{$hash->{$table}}) { 
            get($parent_hash, $h, $r, $dbh, $child->{child_table}, $row, $cascade_column_name, $child->{membership_table}, $table."_id", undef);
        }
    }

    if ($hash->{$table}) { 
        $http_status = HTTP_OK;
        if (ref ($hash->{$table}) eq 'HASH') { 
            delete $hash->{$table}->{password};
            delete $hash->{$table}->{owner};
        }
        else { 
            foreach my $row (@{$hash->{$table}}) { 
                delete ($row->{password});
                delete ($row->{owner});
            }
        }
    }

    # now expand
    $children = &Database::getRows($r, $dbh, qq[select child_table from get_expand where parent_table=?], $table);
    foreach my $child (@$children) { 
        my $expand_column_name = 'id';
        my $childTableName = $child->{child_table};
        foreach my $row (@{$hash->{$table}}) { 
            get($parent_hash, $h, $r, $dbh, $childTableName, $row, $expand_column_name, undef, undef, $row->{$childTableName."_id"});
        }
    }

    return $http_status;
}


1;


