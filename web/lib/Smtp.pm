package Smtp;

use strict;
use warnings;

use MIME::Entity;

use File::Basename;
use Log;
use Email::Address;
use Template;
use Data::Dumper;

sub sendEmail {
    my ($r, $dbh, $from, $email, $subject, $body) = @_;

    my $siteDomain = $r->dir_config('siteDomain');
    if ($siteDomain) { 
        $body =~ s/(www\.)?pix2doc\.com/$siteDomain/ogi;
    }

    $r->log->debug("Sending email"); 
    if (open (MAIL, "|/var/qmail/bin/qmail-inject")) {
        print MAIL join("\n",
            "From: $from",
            "To: $email",
            "Subject: $subject\n",
            "$body\n");
        close MAIL;
    }
    else {
        $r->log->error("Couldn't send email");
    }
}

sub sendEmailWithAttachments {
    my ($r, $dbh, $from, $email, $subject, $body, $jobName, @attachments) = @_;

    my $siteDomain = $r->dir_config('siteDomain');
    if ($siteDomain) { 
        $body =~ s/(www\.)?pix2doc\.com/$siteDomain/ogi;
    }
    
    my $top = MIME::Entity->build(From    => $from,
      To      => $email,
      Subject => $subject,
      Data    => $body);

    my $mimeTypes = { 
        ".pdf" => "application/pdf",
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
    };
    ### Attach stuff to it:
    foreach my $attachment (@attachments) { 
        my ($name, $path, $suffix) = fileparse($attachment, qr{\..*});
        my $type = $mimeTypes->{$suffix};
        $top->attach(Path     => $attachment,
            Type     => $type,
            Filename => "$jobName.$suffix",
            Encoding => "base64");
    }

    my $string = $top->stringify;

    $r->log->debug("Sending email"); 
    if (open (MAIL, "|/var/qmail/bin/qmail-inject")) {
        print MAIL $string;
        close MAIL;
    }
    else {
        $r->log->error("Couldn't send email");
    }
}


sub sendInvitationEmail {
    my ($r, $dbh, $from, $userName, $email, $group, $code, $body) = @_;

    $r->log->debug("Sending email"); 

    my $senderEmail = $email->address;
    my $name = $email->name;

    my $hash = { 
        name => $name, 
        inviter => $userName, 
        code => $code, 
        group => $group
    };

    my $realBody = &Template::explode(undef, $body, $hash, {}, {});

    if (open (MAIL, "|/var/qmail/bin/qmail-inject")) {
        print MAIL join("\n",
            "From: $from",
            "To: $email",
            "Subject: $name has invited you to join them on Pix2Doc\n",
            "$realBody\n");
        close MAIL;
    }

    

     # aijaz
    #&Database::do($r, $dbh, "INSERT INTO slEmail(recipient, sender, emailType, cookie, body) values(?, ?, ?, ?, ?)", $email, $from, 'I', $cookie, $body); 
}



sub sendAcceptEmail {
    my ($r, $dbh, $from, $owner, $body, $hash) = @_;

    $r->log->debug("Sending email"); 


    my $realBody = &Template::explode(undef, $body, $hash, {}, {});

    if (open (MAIL, "|/var/qmail/bin/qmail-inject")) {
        print MAIL join("\n",
            "From: $from",
            "To: $owner",
            "Subject: $hash->{invitee} has has asked to join group $hash->{group}\n",
            "$realBody\n");
        close MAIL;
    }

     # aijaz
    #&Database::do($r, $dbh, "INSERT INTO slEmail(recipient, sender, emailType, cookie, body) values(?, ?, ?, ?, ?)", $email, $from, 'I', $cookie, $body); 
}

sub sendAcceptedOrRejectedEmail {
    my ($r, $dbh, $from, $requestor, $body, $hash) = @_;

    $r->log->debug("Sending email"); 


    my $realBody = &Template::explode(undef, $body, $hash, {}, {});

    if (open (MAIL, "|/var/qmail/bin/qmail-inject")) {
        print MAIL join("\n",
            "From: $from",
            "To: $requestor",
            "Subject: $hash->{subject}\n",
            "$realBody\n");
        close MAIL;
    }


     # aijaz
    #&Database::do($r, $dbh, "INSERT INTO slEmail(recipient, sender, emailType, cookie, body) values(?, ?, ?, ?, ?)", $email, $from, 'I', $cookie, $body); 
}



1;
