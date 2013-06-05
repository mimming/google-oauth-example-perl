#!/usr/bin/perl
# Copyright (C) 2013 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# 
# Author: Jenny Murphy - http://google.com/+JennyMurphy

use HTTP::Request::Common qw(POST); 
use LWP::UserAgent; 
use Data::Dumper;

# Get these values from the Google APIs Console: https://developers.google.com/console
$client_id = "YOUR_CLIENT_ID";
$client_secret = "YOUR_CLIENT_SECRET";
$scope_string = "https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fuserinfo.profile+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fglass.timeline";

# Initiate the OAuth flow
print "Plese open the following in your web browser:\n\nhttps://accounts.google.com/o/oauth2/auth?
scope=$scope_string&redirect_uri=urn:ietf:wg:oauth:2.0:oob&response_type=code&client_id=$client_id";

# get the code from standard input
print "\n\nPaste the code here: ";
$code = <STDIN>; 
chomp($code);


# Disable SSL check since SSL in Perl is complicated. Don't 
#   do this in production or goblins will make your code explode.
$ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0;
my $ua = LWP::UserAgent->new;
$ua->timeout(10);
$ua->env_proxy;

print "Exchanging the code for an access token and refresh token...\n";
my $exchange_response = $ua->request(POST 'https://accounts.google.com/o/oauth2/token',
            'Content_Type'  => 'application/x-www-form-urlencoded',
            'Content'       => [
                'code'         =>  $code,
                'client_id'         =>  $client_id,
                'client_secret'     =>  $client_secret,
                'redirect_uri'     =>  'urn:ietf:wg:oauth:2.0:oob',
                'grant_type'        =>  'authorization_code',
            ],
        );

# very crude parsing of the tokens from the response (mostly because I was too lazy to set up CPAN)
my ($access_token) = ($exchange_response->decoded_content =~ m/access_token".*"(.*)"/);
my ($refresh_token) = ($exchange_response->decoded_content =~ m/refresh_token".*"(.*)"/);

print "access token: $access_token\n";
print "refresh token: $refresh_token\n";

# Refresh the access token
print "Refreshing the access token...\n";
my $auth_response = $ua->request(POST 'https://accounts.google.com/o/oauth2/token',
            'Host'          => 'accounts.google.com',
            'Content_Type'  => 'application/x-www-form-urlencoded',
            'Content'       => [
                'client_id'         =>  $client_id,
                'client_secret'     =>  $client_secret,
                'refresh_token'     =>  $refresh_token,
                'grant_type'        =>  'refresh_token',
            ],
        );

my ($access_token) = ($auth_response->decoded_content =~ m/access_token".*"(.*)"/);

print "New access token: $access_token\n";
