use MooseX::Declare;
namespace Project::Bot;

role ::Command {
    
    requires 'on_message';
    
    has 'bot' => ( is => 'ro', does => 'Project::Bot', handles => [qw/register_callback/] );
}

role ::SimpleCommand with ::Command {
    
    has 'keyword' => (is => 'ro', required => 1, isa => 'Str');

    requires 'callback';
    
    method on_message(Project::Bot::Message $msg) {
        if ($msg->msg eq $self->keyword) {
            $self->callback($msg);
        }
    }
    sub BUILD {
        
    }
    around BUILD {
        $orig->($self, @_);
        $self->register_callback('message_recieved' => sub {
            my $events = shift;
            $self->on_message(@_);
        });
    }
}
1;
