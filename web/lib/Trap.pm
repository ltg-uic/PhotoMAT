#----------------------
package Trap;

use strict;
use warnings;

use Apache2::RequestRec ();
use Apache2::RequestUtil ();
use Apache2::RequestIO ();
use Apache2::Const qw(FORBIDDEN OK);
use Data::Dumper;
use Database;
use Template;
use File::Basename;
use JSON;
use Rest;
use CGI;

use Apache2::Const  qw(:http :common :log);
use Apache2::Log;
use Apache2::Access;
use APR::Table;

sub handler {
    my $r             = shift;
    my $h             = getQueryStringHash($r->args());
    my $path          = $r->path_info() || '';
    my $dbh           = &Database::connectToDb($r);
    my $method        = $r->method();
    my $user          = $r->user() || '';
    my $resp_headers  = $r->headers_out();
    my $cgi = CGI->new();



    my $q;
    my $orig_method;
    my $content_type = "application/json";

    my $adminRequired = { 
        school => 1,
        class => 1, 
        person => 1, 
        person_membership => 1, 
        camera => 1,
    };

    my $tables = { 
        school => 1,
        class => 1, 
        person => 1, 
        person_membership => 1, 
        camera => 1,
        deployment => 1,
        deployment_picture => 1,
        burst => 1, 
        image => 1,
        tag => 1,
    };

    if ($path) { $path =~ s/\///; }
    my $docRoot         = $r->document_root();
    my $mappedFilename  = $r->filename();
    $mappedFilename =~ s/^$docRoot//;
    my $file            = "$docRoot$mappedFilename";
    $r->log->debug("mappedFilename = $mappedFilename and file is $file and docRoot is $docRoot and path is $path");
    $Template::doc_root = $docRoot;
    if (!-e $file) { 
        $dbh->commit();
        $dbh->disconnect();
        return NOT_FOUND;
    }
    

    my $content = getContent($r);
    
    if ($method eq 'HEAD' or $method eq 'GET') { 
        # $q = new CGI($uri->query);
        # $h = $q->Vars;
    }
    else {
        # POST, PUT or DELETE

        #$q = new CGI($content);

        # check for real method
        # if ($method eq 'POST' && $h->{_method}) {
        #     $orig_method = $method;
        #     $method = $h->{_method};
        # }
        # 
        # if ($method eq 'POST') { 
        #     $h = getQueryStringHash($content);
        # }

        $resp_headers->set (expires => "-1d");  # only in the case of non-safe methods



    }

    $h->{path_info} = $path;

    my ($hash, $text);

    $hash = { 
              headers_out      => $resp_headers, 
              headers_in       => $r->headers_in(),
              http_content     => undef , 
              method           => $method, 
              request          => $r, 
              file             => $file, 
              dbh              => $dbh,
              content_in       => $content,
              user             => $user,
              path             => $path,
              cgi              => $cgi,
          };

    my $table = $mappedFilename; 
    $table =~ s/^\///;
    if ($tables->{$table}) {
        # accessing a table
        $hash->{table} = $table;
        $text = &Rest::handleRest ($hash, $h, $adminRequired);
    }
    else { 
        $text = &Template::readFile ($q, $file, $hash, $h);
    }

    if ($hash->{http_content}) { $text = $hash->{http_content}; }
    if ($hash->{content_type}) { $content_type = $hash->{content_type};  }

    if (defined $hash->{REDIRECT}) {
        $r->status(HTTP_SEE_OTHER);
        $resp_headers->set("Location" => $hash->{REDIRECT});
        $dbh->commit();
        $dbh->disconnect();
        return HTTP_SEE_OTHER;
    }
    elsif (defined $hash->{FILE}) {
        return handleFile($r, $hash);
    }

    my $status = $hash->{http_status} || 200;

    if ($status == 200) { 
        $r->content_type($content_type);
        $r->print($text);
    }
    else { 
        if ($hash->{http_content}) { 
            $r->content_type($content_type);
            $r->print($hash->{http_content});
        }
    }

    $dbh->commit();
    $dbh->disconnect();
    $r->status($status);
    return OK;
}


sub getQueryStringHash { 
    my $qs = shift || '';

    my $h;
    my @pairs = split(/&/, $qs);
    foreach my $pair (@pairs){
        my ($name, $value) = split(/=/, $pair);
        $value = '' unless defined $value;
        $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
        $h->{$name} = $value; 
    }
    return $h;
}

sub getContent { 
    my $r = shift;

    my $buffer;
    my $result;
    my $count;
    my $bytesReadTotal = 0;
    my $chunk = 2048;

    while ($count = ($r->read($buffer, $chunk) > 0))  {
        $result .= $buffer;
        $bytesReadTotal += $count;
        last if $bytesReadTotal > 100000;
    }
    return $result;
}


sub handleFile {
    my ($query, $hash) = @_;
    my $file = $hash->{FILE};
    
    return OK if $file eq "__DONE__";

    my $content_length         = -s $file;
    my ($name, $path, $suffix) = fileparse($file, qr{\..*});
    my $file_name              = "$name$suffix";
    my %mime_types             = ( ".pdf" => "application/pdf",
                                   ".txt" => "text/plain",
                                   ".csv" => "application/vnd.ms-excel",
                                   ".xls" => "application/vnd.ms-excel",
                                   ".xlsx" => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                                   ".vsd" => "application/vnd.visio",
                                   ".vsdx" => "application/vnd.ms-visio.drawing, application/vnd.ms-visio.viewer",
                                   ".doc" => "application/msword",
                                   ".docx" => "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                                   ".png" => "image/png",
                                   ".jpg" => "image/jpeg",
                                   ".jpeg" => "image/jpeg",
                                   ".pptx" => "application/vnd.openxmlformats-officedocument.presentationml.presentation",
                                   ".ppt" => "application/vnd.ms-powerpoint",
        );
    $suffix =~ s/^\.+/\./;

    my $mime_type              = $mime_types{$suffix};

    if (!$mime_type) {
        $query->headers_out->set("expires"             => "-1d");
        $query->content_type("text/plain");
        return 500;
    }

    if (open (FILE, $file)) {
        my ($buffer, $length);
        $query->headers_out->set("expires"             => "-1d");
        $query->headers_out->set("Content-Length"      => $content_length);
        $query->headers_out->set("Content-Disposition" => "inline; filename=\"$file_name\"");
        $query->content_type($mime_type);


        while (1) {
            $length = read(FILE, $buffer, 8192);
            if (defined ($length)) {
                if ($length) {
                    $query->print($buffer);
                }
                else {
                    close FILE;
                    return OK;
                }
            }
            else {
                close FILE;
                return OK;
            }
        }
        close FILE;
        return OK;
    }
    else {
        $query->headers_out->set("expires"             => "-1d");
        $query->content_type("text/plain");

        return NOT_FOUND;
    }
}



1;

