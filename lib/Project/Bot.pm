use MooseX::Declare;

role Project::Bot {
        
    use AnyEvent;
    use AnyEvent::Strict;
    use Project::Bot::Types qw/BotConnectionSet MyFeed Topic/;
    use Project::Bot::Feed;
    use Project::Bot::Topic;
    use Project::Bot::Message;
    use Project::Bot::Event;
    use Project::Bot::Command;
    
    has 'events' => (is => 'ro', isa => 'Project::Bot::Event', lazy => 1, builder => '_setup_events', handles => {
        'register_callback' => 'reg_cb',
        'emit_event' => 'event',
    },);
    method _setup_events() {
        Project::Bot::Event->new();
    }
    has 'connections' => ( is => 'ro', isa => 'Maybe[ArrayRef]', required => 0, predicate => 'has_connections' );
    
    has '_connections' => (
        traits => [qw/Array/],
        is => 'ro',
        isa => BotConnectionSet,
        lazy => 1,
        builder => '_build_connections',
        handles => {
            'all_connections' => 'elements'
        }
    );
    
    method _build_connections() {
        my @cons;
        return \@cons unless $self->has_connections and ref($self->connections);
        foreach (@{ $self->connections }) {
            my $class = 'Project::Bot::Connection::' . delete $_->{module} or die "cannot connect Connection with a module argument";
            Class::MOP::load_class($class);
            push(@cons, $class->new(%$_, bot => $self ));
        }
        return \@cons;
    }
    
    has 'commands' => ( is => 'ro', isa => 'Maybe[ArrayRef]', required => 0, predicate => 'has_commands' );
    has '_commands' => ( 
        traits => [qw/Array/],
        is => 'ro',
        isa => 'ArrayRef',
        lazy => 1,
        builder => '_register_commands',
    );
    method _register_commands() {
        my @commands;
        return \@commands unless $self->has_commands and ref($self->commands);
        foreach (@{ $self->commands }) {
            my $class = 'Project::Bot::Command::' . delete $_->{type} or die "Cannot load a command without a type";
            Class::MOP::load_class($class);
            push(@commands, $class->new(%$_, bot => $self));
        }
        \@commands;
    }
    has 'interval' => (is => 'ro', isa => 'Int');
    
    has 'condvar' => (
        is => 'ro', default => sub { AnyEvent->condvar }, handles => [qw/wait broadcast/] 
    );
    
    has 'topic' => (is => 'ro', isa => Topic, coerce => 1, required => 0, predicate => 'has_topic', );
    
    has 'feeds' => (is => 'ro', isa => 'Maybe[ArrayRef]', required => 0, predicate => 'has_feeds', );
    has '_feeds' => (
        is => 'ro', isa => 'ArrayRef', lazy => 1, builder => '_build_feeds',
    );
    method _build_feeds() {
        my @feeds;
        return \@feeds unless $self->has_feeds and ref($self->feeds);
        foreach (@{ $self->feeds }) {
            my $feed = Project::Bot::Feed->new(
                url => delete $_->{url},
                interval => delete ($_->{interval}) || $self->interval,
                on_fetch => sub {
                    $self->new_entries(@_);
                },
                %$_, # Lets just bring in everything else!
            );
            $feed->conn; # XXX: ugly, but I'm tired!
            push(@feeds, $feed);
        }
        return \@feeds;
    }
    

    method start_bot() {
        # Need to make sure all connections get connected, and set up properly
        foreach my $con ($self->all_connections) {
            $con->establish_connection();
        }
        if ($self->has_feeds) {
            $self->_feeds;
        }

        # Lets set up our topic
        if ($self->has_topic) {
            $self->topic->on_fail(sub {
                $self->topic_fail
            });
            $self->topic->on_unfail(sub {
                $self->topic_recover
            });
        }
        $self->_commands;
        $self->wait;
        
        
        #$self->broadcast;
        
        
    }

    method new_entries($feed_reader, $new_entries, $feed) {
        for (reverse @$new_entries) { # We want oldest first
            my ($hash, $entry) = @$_;
            # Should here send a message
            foreach my $con ($self->all_connections) {
                $con->send_message($entry)
            }
        }
        
    }
    
    method topic_fail() {
        foreach my $con ($self->all_connections) {
            $con->topic_fail() if $con->can('topic_fail');
        }
    }
    method topic_recover() {
        foreach my $con ($self->all_connections) {
            $con->topic_recover() if $con->can('topic_recover');
        }
    }
    
    
    method bubble(Project::Bot::Message $msg) {
        # Now we should just send an event right, on_message event
        unless ($self->emit_event('message_recieved' => $msg) and $self->has_commands) {
            warn "no handlers for message_recieved $msg\n";
        }
    }
    
    
}




1;
