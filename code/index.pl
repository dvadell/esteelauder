use Mojolicious::Lite -signatures;
use Data::Dumper;
use lib '/code/lib';
use Transactions qw/get_transactions create_transaction get_transaction_by_id/;
# 
my $transaction_list_error_message = "invalid status value";
my $transaction_list_error_code    = 404;
my $transaction_create_error_code    = 400; # missing required field - Bad Request
my $transaction_create_successful    = 201; # Created TODO check
my $invalid_id_error_code            = 400; # missing required field - Bad Request

# Fetches the transaction history. No arguments. 
# Response: A list of transactions.
get '/api/transactions' => sub {
    my $c = shift;
    my @transaction_list = get_transactions();
    $c->log->debug("Transaction list: " . Dumper(@transaction_list));

    $c->render(json => \@transaction_list);  # Important: must be a ref
};

post '/api/transactions' => sub {
    my $c = shift;
    $c->log->debug("Estoy en /transactions POST");
    my $params = $c->req->json;
    $c->log->debug("Params: " . Dumper($params));
    my ($status, $message) = create_transaction($params);
    if ($status eq "ERROR") {
        $c->log->debug("Error Status: $message");
        $c->render(text => $message, status => $transaction_create_error_code);
    } else {
        $c->log->debug("Status: $status");
        $c->render(text => $message, status => $transaction_create_successful);
    }
};

# Get the information of a single transaction.
get '/api/transactions/:id' => sub {
    my $c = shift;
    my $id = $c->stash->{id};

    my $transaction = get_transaction_by_id($id);
    if (! defined($transaction) || ! $transaction) {
        $c->render(json => "Error: no such id ($id)", status => $invalid_id_error_code);
    } else {
        $c->render(json => $transaction);
    }
};

# Render template "index.html.ep" from the DATA section
get '/' => sub ($c) {
  $c->render(template => 'index');
};

app->start;
