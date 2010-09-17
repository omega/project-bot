use MooseX::Declare;
namespace Project::Bot;
class ::HTTP {
    use AnyEvent::HTTP;
    use MIME::Base64;

    has 'url' => (is => 'ro', isa => 'Str', required => 1);
#    has 'interval' => (is => 'ro', isa => 'Int', default => 0);
    has 'on_fetch' => (is => 'ro', isa => 'CodeRef', required => 0);
    has 'username' => (is => 'ro', isa => 'Str', predicate => 'has_username');
    has 'password' => (is => 'ro', isa => 'Str');

    method get_headers() {
        return {
            ($self->has_username 
                ? (Authorization => "Basic "
                    . encode_base64 (join ':', $self->username, $self->password)
                ) : ()
            )
        }
    }
    method get_callback(CodeRef $real_cb) {
        return sub {
            my ($body, $hdr) = @_;
            # We do error checking here, yay
            warn "amg, got smt: " . $hdr->{Status} . "\n";
            if ($hdr->{Status} =~ m/^2/) {
                # XXX: Should we do more here? Like content detection and parsing?
                $real_cb->(@_);
            } else {
                warn "ERROR in GET: \n "
                    . "ended up at: " . $hdr->{URL} 
                    . "\n Error: " . $hdr->{Status} . " " . $hdr->{Reason}
                    . "\n";
            }
        };
    }
    method get(CodeRef $real_cb) {
        warn "gettign!\n";
        http_get $self->url, headers => $self->get_headers, $self->get_callback($real_cb);
    }

    method fetch($extra) {
        
        $self->get(sub { $self->on_fetch->(@_, $extra) });
    }

}

class ::HTTP::XML extends ::HTTP {
    
    use XML::LibXML;
    
    override get_headers() {
        my $hdr = super();
        #$hdr->{Accept} = 'text/xml; charset=utf-8,application/rss+xml';
        $hdr;
    }
    
    around get_callback(CodeRef $real_cb) {
        return $orig->($self, sub {
            my ($body, $hdr) = (shift, shift);
            warn "in XML callback!";
            my $xml = XML::LibXML->load_xml( string => $body );
            $real_cb->($xml, $hdr, @_);
        });
    }
    
}
1;