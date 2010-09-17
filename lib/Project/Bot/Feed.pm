use MooseX::Declare;

class Project::Bot::Feed {
    use AnyEvent::Feed;
    use Project::Bot::Types qw(FilterList);
    
    has 'url' => (is => 'ro', isa => 'Str', required => 1);
    has 'interval' => (is => 'ro', isa => 'Int', default => 30);
    has 'on_fetch' => (is => 'ro', isa => 'CodeRef', required => 0);
    has 'username' => (is => 'ro', isa => 'Str', predicate => 'has_username');
    has 'password' => (is => 'ro', isa => 'Str');
    has 'filter'   => (is => 'ro', isa => FilterList, coerce => 1);
    
    has 'conn' => (
        is => 'ro', isa => 'AnyEvent::Feed', lazy => 1, builder => '_build_conn',
    );
    
    method _build_conn() {
        AnyEvent::Feed->new(
            url => $self->url,
            ($self->interval ? (interval => $self->interval) : ()),
            on_fetch => sub { $self->_got_items([@_]) },
            ( $self->has_username ? ( username => $self->username, password => $self->password) : ())
        );
    }
    method fetch($msg) {
        $self->conn->fetch(sub { $self->_got_items([@_], $msg) });
    }
#    method _got_items(ArrayRef[] [$reader, $new_entries, $feed, $error?], $extra? ) {
    method _got_items(ArrayRef $args, $extra?) {
        my ($reader, $new_entries, $feed, $error) = (@$args);
        if (defined $error) {
            warn "ERROR: $error\n";
            return;
        }
        if ($self->filter and scalar(@$new_entries)) {
            foreach (@$new_entries) {
                foreach my $f (@{$self->filter}) {
                    $f->filter(@$_);
                }
            }
        }
        $self->on_fetch->($reader, $new_entries, $feed, $extra);
    }

}
1;
