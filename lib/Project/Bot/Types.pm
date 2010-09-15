package Project::Bot::Types;

use MooseX::Types
    -declare => [qw/
        BotConnection
        BotConnectionSet
        
        MyFeed
        Topic
        
        Filter
        FilterList
        
        XMLFeedEntry
    /]
;

use MooseX::Types::Moose qw/Undef Object HashRef ArrayRef/;

class_type XMLFeedEntry, { class => 'XML::Feed::Entry::Atom' };

role_type BotConnection, { role => 'Project::Bot::Connection' };

coerce BotConnection,
    from HashRef,
    via {
        my $class = 'Project::Bot::Connection::' . delete $_->{module} or die "cannot coerce Connection with a module argument";
        Class::MOP::load_class($class);
        $class->new(%$_);
    }
;

subtype BotConnectionSet, as ArrayRef[BotConnection];
coerce BotConnectionSet,
    from ArrayRef,
    via {
        map {
            $_ = to_BotConnection($_);
        } @$_;
        $_;
    }
;
coerce BotConnectionSet,
    from Undef,
    via {
        return [];
    }
;

class_type MyFeed, { class => 'Project::Bot::Feed' };

coerce MyFeed,
    from HashRef,
    via {
        Class::MOP::load_class('Project::Bot::Feed');
        Project::Bot::Feed->new(%$_);
    }
;

class_type Topic, { class => 'Project::Bot::Topic' };
coerce Topic,
    from HashRef,
    via {
        Project::Bot::Topic->new(%$_);
    }
;

role_type Filter, { role => 'Project::Bot::Filter' };
coerce Filter,
    from HashRef,
    via {
        my $class = 'Project::Bot::Filter::' . delete $_->{type} or die "cannot coerce Filter without a type argument";
        Class::MOP::load_class('Project::Bot::Filter');
        $class->new(%$_);
    }
;

subtype FilterList, as ArrayRef[Filter];
coerce FilterList,
    from ArrayRef,
    via {
        map {
            $_ = to_Filter($_);
        } @$_;
        $_;
    }
;
1;