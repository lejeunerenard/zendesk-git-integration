#!/usr/bin/env perl

use strict;
use warnings;

use LWP::UserAgent;
use MIME::Base64;
use JSON;

# Allow only master pushes to send a notification
exit 0 unless $ARGV[0] eq 'refs/heads/master';

# Get params
my $from_hash = $ARGV[1];
my $to_hash   = $ARGV[2];

my $commits = `git rev-list $from_hash..$to_hash`;

my ( $subdomain, $token );

foreach my $commit_hash ( split $/, $commits ) {
    my $git_content = `git log -n 1 --pretty=format:"%s%n%b" $commit_hash`;

    # Check if the commit mentions a ticket number
    if ( $git_content =~ /\bTicket[:\s]\s*\#(\d{4})/ ) {

        # Zendesk ticket id
        my $id = $1;

        # Let the end user know that we are processing a commit
        print "Posting Commit to ticket: #" . $1;

        # Get the configured subdomain
        if ( not defined $subdomain ) {
            $subdomain = `git config zendesk.subdomain`;
            $subdomain =~ s/\n//g;
        }

        # @TODO figure out the proper way to generate the token
        #my $token = 'Basic '
        #  . encode_base64( join ':', 'zendesk@email.com', 'secretz', '' );

        if ( not defined $token ) {
            my $git_token = `git config zendesk.token`;
            $git_token =~ s/\n//g;
            $token = "Basic " . $git_token;
        }

        # Bail if zendesk credentials were not found
        exit 0 unless defined $subdomain and defined $token;

        # Get the commit message in a fairly standard format
        # @TODO allow the message to be configurable via git config
        my $git_message = `git log -n 1 --format=full $commit_hash`;

        # @TODO get this from the git config params
        my $server_endpoint =
          "https://$subdomain.zendesk.com/api/v2/tickets/$id.json";

        my $ua = LWP::UserAgent->new;

        # Set the request method and authentication headers
        my $req = HTTP::Request->new( PUT => $server_endpoint );

        $req->header( 'content-type' => 'application/json' );
        $req->header( 'Authorization' => $token );

        ## Comment payload
        my $put_data = {
            ticket => {
                comment => {
                    public => 'false',
                    body =>
                      "This ticket was mentioned in the git message below:\n"
                      . $git_message,
                }
            }
        };
        $req->content( JSON::to_json($put_data) );

        my $resp = $ua->request($req);
        if ( $resp->is_success ) {

            # Finish response STDOUT
            print " : success\n";
        }
        else {
            print " : failed\n";

            # Check for most common error ( Not Found )
            if ( $resp->code eq '404' ) {
                print "Ticket not found\n";
            }

            # Otherwise just let them know about the random error
            else {
                print "HTTP POST error code: ",    $resp->code,    "\n";
                print "HTTP POST error message: ", $resp->message, "\n";
            }
        }
    }
}
