---
layout: post
title: "Designing Asynchronous Functions With Go"
date: 2018-04-02 20:34:00
image: '/assets/img/2018-04-02-designing-asynchronous-functions-with-go/banner.jpg'
description: A tutorial on asynchronous function design in Golang.
category: 'distributed systems'
tags:
- software
- design
- golang
twitter_text: Designing Asynchronous Functions With Go.
introduction: A tutorial on asynchronous function design in Golang.
---

Who doesn't love fully controllable asynchronous APIs? This post is about crafting asynchronous functions using Golang's [Context](https://godoc.org/context), [Channels](https://gobyexample.com/channels), and [Goroutines](https://gobyexample.com/goroutines).

## Introduction

For the purpose of this post, let's consider a user who is searching for a few flights on a flight search engine. The user has a complex query, and therefore, must be handled at two levels:

1\. The search engine must query third-party APIs to obtain broad flight listings.<br>
2\. The search engine then has to apply complex filters and stream flights to the user.

## The Design

Let's dive right in to the asynchronous design. The following function promises to return `Flight` or `error` instances via the returned channels. The `Context` object can be used to explicitly stop the asynchronous function.

```go
func AsyncListFlights(ctx context.Context, q SimpleQuery) (<-chan Flight, <-chan error) {
    flightsChan := make(chan Flight, 10) // Channel buffers 10 Flight objects
    errorsChan := make(chan error, 1) // Channel buffers only a single error
    go asyncListFlights(ctx, q, flightsChan, errorsChan) // Create a goroutine here
    return flightsChan, errorsChan // Return immediately
}
```

Fetching flights from third-party APIs could be done as below.

```go
func asyncListFlights(ctx context.Context, q SimpleQuery,
        flightsChan chan<- Flight, errorsChan chan<- error) {

    defer close(flightsChan) // Signal the end of stream
    defer close(errorsChan) // Signal the end of stream

    for { // Fetch third-party results as long as is necessary
        select {
        case <-ctx.Done(): // Context was done (timeout, cancel, etc.)
            errorschan <- ctx.Err() // If canceled, ctx.Err() would return the context.Canceled error
            return
        default:
        }

        flights, err := fetchResultsFromThirdParty(q, 5) // Fetch 5 results from third-party
        if err != nil {
            errorsChan <- err // Publish any error
            return
        }
        if len(flights) == 0 { // Close channels and exit
            return
        }
        for _, flight := range flights { // Publish Flight instances
            flightsChan <- flight
        }
    }
}
```

Briefly, the `asyncListFlights` function is fetching `Flight` instances from third-party APIs in small batches, and publishing results/errors over channels. It's also listening to the `ctx.Done()` channel, and would stop fetching more results if the `Context` was explicitly canceled.

That's it! We've already addressed challenge 1. Let's apply the complex filters to these `Flight` instances, and publish them to the user now.

```go
func streamFlights(q ComplexQuery, numFlights int) {
    ctx, cancel := context.WithCancel(context.Background()) // Create a cancelable context
    defer cancel() // Prevent context from leaking

    flightsChan, errorsChan := AsyncListFlights(ctx, simplifyQuery(q)) // Start the async func

    var numPublished int32 // Counter to count published flights
    var wg sync.WorkGroup // Create a synchronizing WorkGroup

    for i := 0; i < numWorkers; i++ { // Spawn worker goroutines
        wg.Add(1) // Increment WorkGroup counter
        go func() {
            defer wg.Done() // Decrement WorkGroup counter

            for { // Until desired number of Flights are fetched, or the channels are closed
                select {
                case err, ok := <-errorsChan:
                    if !ok { // AsyncListFlights finished, so exit
                        return
                    }
                    if err == context.Canceled { // Another goroutine instance canceled, so exit
                        return
                    }
                    log.Fatal(err) // Log the error and continue

                case flight, ok := <-flightsChan:
                    if !ok { // AsyncListFlights finished, so exit
                        return
                    }
                    if matchesComplexQuery(flight, q) { // If flight matches complex query
                        publishFlightToUser(flight) // Publish the flight to user
                        atomic.AddInt32(&numPublished, 1) // Increment counter atomically
                        if atomic.LoadInt32(&numPublished) ==  numFlights { // Published enough flights
                            cancel() // Stop fetching flights
                            return
                        }
                    }
                }
            }
        }()
    }
    wg.Wait() // Wait for all worker goroutines to finish
}
```

The `streamFlights` function calls `AsyncListFlights` to start the third-party querying. It then spawns a few worker goroutines, which use `sync.WaitGroup` to synchronize themselves in `wg.Wait()` when finishing. Each worker listens to `flightsChan` and `errorsChan` channels, and exit when these channels are closed. If a `Flight` instance is received, it is further matched with the `ComplexQuery` and published via `publishFlightToUser` if it does match. Once published, the `numPublished` counter is incremented atomically, and once it equals the desired `numFlights`, the `Context` is canceled. Once the `Context` is canceled, no more third-party API calls are made by `asyncListFlights`, and it exits after closing the channels, which, in turn, causes the workers to stop.

And, there you have it - fully controllable asynchronous functions in Golang.

## Conclusion

Context, Channels, and Goroutines are powerful concepts in Golang, and together, they can create amazing experiences.

-----

Thoughts are appreciated. :)
