#----------------------
package P2PH;

use strict;
use warnings;

use Apache2::RequestRec ();
use Apache2::RequestUtil ();
use Apache2::RequestIO ();
use Data::Dumper;
use Globals;
use Database;
use Template;
use File::Basename;
use Session;
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

    my $q;
    my $orig_method;
    my $content_type = "text/html";
    my $session;

    if ($path) { $path =~ s/\///; }
    my $docRoot                = $r->document_root();
    my $mappedFilename         = $r->filename();
    $mappedFilename            = "$mappedFilename/index.html" if -d $mappedFilename;
    $mappedFilename            =~ s/^$docRoot//;
    $mappedFilename            = '/index.html' if $mappedFilename eq '/';

    my $file                   = "$docRoot$mappedFilename";

    if (!-e $file) { 
        $dbh->commit();
        $dbh->disconnect();
        return NOT_FOUND;
    }

    # print STDERR "mappedFilename is $mappedFilename\n";
    $session = retrieveSession($r, $dbh);  # Always get a session
    # print STDERR "For $mappedFilename, session is ", Dumper($session); 


    my $dir_config  = $r->dir_config();
    
    my ($need_session, $need_login) = ($dir_config->{'NEED_SESSION'},
                                       $dir_config->{'NEED_LOGIN'});
    if ($need_session) { 

        if (0
            || (!$need_login)
            || $session->{email} =~ /\S/
            || $mappedFilename eq "/login.html"
            || $mappedFilename eq "/processLogin.html"
            ) {
            ; # do nothing
        }
        else {
            # login needed
            $r->status(HTTP_SEE_OTHER);
            $resp_headers->set("Location" => "/login.html");
            $dbh->commit();
            $dbh->disconnect();
            return HTTP_SEE_OTHER;
        }
    }


    if ($mappedFilename !~ /\.html$/) { 
        $dbh->commit();
        $dbh->disconnect();
        return handleFile ($r, { FILE => "$file" });
    }

    $content_type      = "text/html";

    $r->log->debug("mappedFilename = $mappedFilename and file is $file and docRoot is $docRoot and path is $path");
    $Template::doc_root = $docRoot;
    

    my $content;
    my $cgi;

    if ($method eq 'HEAD' or $method eq 'GET') { 
        # $q = new CGI($uri->query);
        # $h = $q->Vars;
        $content = getContent($r);;
    }
    elsif ($method eq 'POST') {
        # get POSTed data and put int into hash
        #my $ph = getQueryStringHash($content);
        #foreach my $k (keys %$ph) { 
        #    $h->{$k} = $ph->{$k};
        #}
        
        $cgi = CGI->new($r);

        my $params = $cgi->Vars;
        foreach my $k (keys (%$params)) {
            $h->{$k} = $params->{$k};
        }

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
              email            => $session->{email},
              cgi              => $cgi,
          };

    $text = &Template::readFile ($hash, $file, $hash, $h, $session);

    if (defined($hash->{http_content})) { $text = $hash->{http_content}; }
    if (defined($hash->{content_type})) { $content_type = $hash->{content_type};  }
    my $cookie = $session->{cookie};

    if ($cookie) { 
        $r->headers_out->add('Set-Cookie' => $cookie);
        $r->err_headers_out->add('Set-Cookie' => $cookie);
    }

    if (defined $hash->{REDIRECT}) {
        $r->status(HTTP_SEE_OTHER);
        $resp_headers->set("Location" => $hash->{REDIRECT});
        $dbh->commit();
        $dbh->disconnect();
        return HTTP_SEE_OTHER;
    }
    elsif (defined $hash->{FILE}) {
        $dbh->commit();
        $dbh->disconnect();
        return handleFile($r, $hash);
    }

    my $status = $hash->{http_status} || OK;


    if ($status == OK) { 
        $r->content_type($content_type);
        $r->print($text);
    }

    $dbh->commit();
    $dbh->disconnect();
    return $status;
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

sub getMatchingMimeType { 
    my ($suffix) = @_;

    my %mime_types             = ( ".pdf" => "application/pdf",
                                   ".txt" => "text/plain",
                                   ".html" => "text/html",
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
                                   ".css" => "text/css",
                                   ".min.css" => "text/css",
                                   ".js" => "text/javascript",
                                   ".min.js" => "text/javascript",
                                   ".ico" => "image/x-icon",
        );
    $suffix =~ s/^\.+/\./;

    my $mime_type              = $mime_types{$suffix};

    return $mime_type;
}

sub handleFile {
    my ($r, $hash) = @_;
    my $file = $hash->{FILE};
    my $resp_headers  = $r->headers_out();
    
    return OK if $file eq "__DONE__";

    my $content_length         = -s $file;
    my ($name, $path, $suffix) = fileparse($file, qr{\..*});
    my $file_name              = "$name$suffix";
    my $mime_type = getMatchingMimeType ( $suffix );


    if (!$mime_type) {
        $r->status(500);
        $resp_headers->set("expires", "-1d");
        $r->content_type("text/plain");
        $r->print("500 Unrecognized File Type for suffix $suffix for file $file\n");
        return 500;
    }

    if (open (FILE, $file)) {
        my ($buffer, $length);
        $resp_headers->set("expires"             => "-1d");
        $resp_headers->set("Content-Length"      => $content_length);
        $resp_headers->set("Content-Disposition" => "inline; filename=\"$file_name\"");
        $r->content_type($mime_type);


        while (1) {
            $length = read(FILE, $buffer, 8192);
            if (defined ($length)) {
                if ($length) {
                    $r->print($buffer);
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
        $r->status(NOT_FOUND);
        $resp_headers->set("expires", "-1d");
        $r->content_type("text/plain");
        $r->print("ERROR: Cannot open file\n");
        return NOT_FOUND;
    }
}



1;

