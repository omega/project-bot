use MooseX::Declare;
namespace Project::Bot;

class ::Command::JIRA::Response::Issue {
    with 'XML::Rabbit::Node';

    has 'title' => (
        isa => 'Str',
        traits => [qw/XPathValue/],
        xpath_query => './title',
    );
    has 'link' => (
        isa => 'Str',
        traits => [qw/XPathValue/],
        xpath_query => './link',
    );
    has 'assignee' => (
        isa => 'Str',
        traits => [qw/XPathValue/],
        xpath_query => './assignee/@username'
    );
}
