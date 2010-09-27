#!/usr/bin/perl -w

use strict;
use Test::More tests => 1;
use Project::Bot::Command::JIRA::Response;

my $c = Project::Bot::Command::JIRA::Response->new(
    file => 't/data/10.command.jira.status.basic.xml'
);
is($c->issues->[0]->title, "[ABCT-32] Main Template");

