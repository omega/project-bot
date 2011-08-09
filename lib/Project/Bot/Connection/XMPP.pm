use MooseX::Declare;
namespace Project::Bot;
class ::Connection::XMPP with ::Connection {
    use MooseX::MultiMethods;

    use AnyEvent::XMPP::IM;
    use AnyEvent::XMPP::Util qw/new_message/;

    $AnyEvent::XMPP::IM::DEBUG     = 1;
    $AnyEvent::XMPP::Stream::DEBUG = 1;
    use Project::Bot::Message;

    has 'conn' => (
        is => 'ro', default => sub { AnyEvent::XMPP::IM->new; },
        handles => [qw/reg_cb send_srv send_chan/]
    );
    has 'muc' => (
        is => 'ro', lazy => 1, builder => '_build_muc',
    );
    method _build_muc() {
        my $muc = $self->conn->get_ext('MUC');
    }
    has 'pres' => (
        is => 'ro', lazy => 1, builder => '_build_presence'
    );
    method _build_presence() {
        my $pres = $self->conn->get_ext('Presence');
        $pres->set_default('available', "I'm just frinedly bot");
        $pres;
    }


    has [qw/room jid password/] => (is => 'ro', required => 1);
#    has 'port' => (is => 'ro', default => 6667);
#    has 'options' => (is => 'ro', isa => 'HashRef');

    method BUILD($args) {
        $self->_setup_hooks();
    }
    method establish_connection() {
        # Can't delegate connect, as it is a signal method
        $self->conn->add_account( $self->jid, $self->password );

        # $self->send_srv( "JOIN", $self->channel );
        $self->muc->join($self->jid, $self->room);
    }
    method demolish_connection() {
        $self->disconnect;

    }
    method _setup_hooks() {
        foreach my $hook_method ( qw/recv_message connected disconnected/ ) {
            $self->reg_cb(
                $hook_method => sub {
                    $self->$hook_method(@_);
                }
            ) if $self->can($hook_method);
        }
        foreach my $hook_method ( qw/entered message/ ) {
            my $mtd = "muc_" . $hook_method;
            $self->muc->reg_cb(
                $hook_method => sub {
                    $self->$mtd(@_);
                }
            ) if $self->can($mtd);
        }
    }
    multi method send_message_str(Str $text) {
        print "Should say something! $text";

        #$self->send_chan( $self->channel, "NOTICE", $self->channel, $text );
        $self->conn->send(
            new_message(
                'groupchat',
                $text,
                src => $self->jid,
                to  => $self->room,
            )
        );
    }

    ## All our hooked methods

    method muc_entered($muc, $resjid, $roomjid) {
        print "entered something: $roomjid $resjid\n";
    }
    method muc_message($muc, $resjid, $roomjid, $others, $node) {
        print "got message: $roomjid, $others, $node\n";
        print "   - " . $node->attr('from') . "\n";
        $self->conn->send (
            new_message (
                'groupchat',
                "Hello there, got your message: " . $node->meta->{body},
                src => $node->meta->{dest},   # src specifies the resource to
                # send the message from.
                #to => $node->attr ('from')
                to => $roomjid,
            )
        ); # to where to send the message to.
    }

    #method privatemsg($nick, $ircmsg) {
    #}

    method recv_message($node) {

        #$self->bubble(Project::Bot::Message->new(
            #to => $channel,
            #from => (split("!", $ircmsg->{prefix}))[0],
            #msg => $ircmsg->{params}->[1],
            #connection => $self,
            #reply => sub {
                #my ($txt) = @_;
                #my @lines = grep { !/^\s*$/ } split("\n", $txt);
                #foreach (@lines) {
                    #$self->send_chan( $channel, "PRIVMSG", $channel, $_ );

                #}

            #},
        #));
    }

    method connected($con, $jid?, $ip?, $port?) {
        $self->is_connected(1);
        print "connected ;)\n";
    }

    method disconnected() {
        print "I’m out!\n";
    }
}
1;

