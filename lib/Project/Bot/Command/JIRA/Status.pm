use MooseX::Declare;
namespace Project::Bot;
class ::Command::JIRA::Status with ::SimpleCommand {
    use Project::Bot::HTTP;
    
    has 'url' => (is => 'ro', isa => 'Str', );
    has 'http' => (is => 'ro', isa => 'Project::Bot::HTTP|HashRef', initializer => '_init_http', handles => [qw/fetch/] );
    
    method _init_http($args, $setter, $attr) {
        my $feed = Project::Bot::HTTP::XML->new(
            %$args,
            on_fetch => sub { $self->fetched(@_); },
        );
        $setter->($feed);
    }
    method callback($msg) {
        $self->fetch($msg);
    }
    
    method fetched($xml, HashRef $hdr, Project::Bot::Message $msg) {
        # render via $msg->render('jira-status.tt'), 
        warn "in fetched\n";
        # now to make $xml into something remotely useful for the template.
        # For now: Array of Hashes, yay :p
        $msg->reply($msg->render('jira-status.tt', { xml => $self->rewire( $xml ) }));
    }
    
    method rewire($xml) {
        map {
            warn "item: $item";
        } $xml->findnodes('/rss/channel/item');
    }
}
1;