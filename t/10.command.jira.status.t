#!/usr/bin/perl -w

use strict;
use Test::More tests => 1;
use Project::Bot::Command::JIRA::Status;

my $c = Project::Bot::Command::JIRA::Status->new()
ok(assertion);
