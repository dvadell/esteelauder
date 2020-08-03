# Estee Lauder challenge 
* [Description](https://agileengine.gitlab.io/interview/test-tasks/fsNDJmGOAwqCpzZx/)

To run the web app, first clone this repo and run:

```
docker-compose up -d
```

Then run the tests. This will also add some transactions:

```
docker-compose exec tests ./tests.pl
```

Then go to http://localhost:3000/

## Must have

* Service must store the account value of the single user.
* Service must be able to accept credit and debit financial transactions and update the account value correspondingly.

Please see the model at ```code/lib/Transactions.pm```.

* Any transaction, which leads to negative amount within the system, should be refused. Please provide http response code, which you think suits best for this case.

See ```create_transaction()``` in ```code/lib/Transactions.pm```. The response code is 400 Bad Request. It could have been a more descripitive one, but this is an error very dependent on the logic of the app, and I'd rather have those errors separate from the more protocol-related errors of HTTP.

* Application must store transactions history. Use in-memory storage. Pay attention that several transactions can be sent at the same time. The storage should be able to handle several transactions at the same time with concurrent access, where read transactions should not lock the storage and write transactions should lock both read and write operations.

I'm putting all the transactions in a variable (```@_transaction_list``` in ```code/lib/Transactions.pm```), given that I have only 3 hours to complete the task and the emphasis is on not doing it too elaborated. Mojolicious is a non-blocking but single-threaded framework. It will try not to block and multiplex itself to handle multiple requests, but if the code blocks (i.e. ```sleep()```) the whole server will come to a halt (there's a commented sleep() in ```code/lib/Transactions.pm``` just to test that).

So being single-threaded, there's no concurrent access to that variable. Also, the variable is modified only in one part of the code. 

But, just to somehow code something with respect to this requirements, I added a lock (```$_transaction_list_lock```).

* It is necessary to design REST API by your vision in the scope of this task. There are some API recommendations. Please use these recommendations as the minimal scope, to avoid wasting time for not-needed operations.

The three endpoints there are defined in ```code/index.pl```.


* In general, the service will be used programmatically via its RESTful API. For testing purposes Postman or any similar app can be used.

I wrote *quick* tests in ```tests/test.pl```. You can run them with:
```docker-compose exec tests ./test.pl```

## UX/UI requirements

* We need a simple UI application for this web service.
* Please don't spend time for making it beautiful. Use a standard CSS library, like Bootstrap with a theme (or any other).

I used bootstrap. See ```code/templates/index.html.ep``` and ```code/public/main.css```.

* UI application should display the transactions history list only. No other operation is required.
* Transactions list should be done in accordion manner. By default the list shows short summary (type and amount) for each transaction. Full info for a transaction should be shown on user's click.
* It would be good to have some coloring for credit and debit transactions.

Debits get a "debit" css class to show them in a different color.  
