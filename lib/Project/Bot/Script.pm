use MooseX::Declare;

class Project::Bot::Script with MooseX::SimpleConfig with MooseX::Getopt with Project::Bot {

    use MooseX::Types::Path::Class qw( File );
    has configfile => (
        is => 'ro',
        isa => File,
        coerce => 1,
        predicate => 'has_configfile',
        default => 'etc/project-bot.yaml',
    );
    
    sub run {
        my ($self) = @_;

        $self->start_bot();
    }
    
}



1;