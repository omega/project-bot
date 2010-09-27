use MooseX::Declare;

namespace Project::Bot;

class ::Command::JIRA::Response {
    with 'XML::Rabbit::RootNode';
    has 'issues' => (
        isa => 'ArrayRef[Project::Bot::Command::JIRA::Response::Issue]',
        traits => [qw/XPathObjectList/],
        xpath_query => '//item',
    );
}
1;
