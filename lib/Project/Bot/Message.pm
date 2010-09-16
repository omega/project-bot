use MooseX::Declare;
namespace Project::Bot;
class ::Message {

    has 'to' => (is => 'ro', isa => 'Str');
    has 'from' => (is => 'ro', isa => 'Str');
    has 'msg' => (is => 'ro', isa => 'Str');
    
    has '_reply_cb' => ( is => 'ro', isa => 'CodeRef', init_arg => 'reply' );
    has '_connection' => ( 
        is => 'ro', does => 'Project::Bot::Connection', handles => [qw/render/], init_arg => 'connection'
    );
    
    method reply(Str $txt) {
        $self->_reply_cb->($txt);
    }
}
1;