module quick

import nandou.Http
import nandou.File
import nandou.Json
import nandou.String
import nandou.Future


function main = |args| {

    let executor = getExecutor()
    let memory = DynamicObject()

    let httpServer = http():server(|httpExchange|{

        #=================================
        # Futures Fibonacci computation
        #================================= 
        httpExchange:GET("/fibo", |req, res|{

            let callableFibonacciComputation = |iterations| {

                let fibonacci = |n| {
                    if n <= 1 {
                        return n
                    } else {
                        return fibonacci(n - 1) + fibonacci(n - 2)
                    }
                }


                let result = fibonacci(iterations)
                println(">>> " + result)

                memory:result(result)

                #return result
            }

            let future = executor:getFuture(callableFibonacciComputation, 43)

            res:html():send(
                """
                <h1>Hourra !</h1>
                <h2>Fibonacci computation is ignited ...</h2>
                <h3>Please wait ...</h3>
                <a href="/getfiboresult">Try this link to read result</a>
                """
            )
        }) 

        httpExchange:GET("/getfiboresult", |req, res|{

            if memory:result() isnt null {
                res:html():send("<h1>Fibonacci computation result : %s</h1>":format(memory:result():toString()))   
            } else {
                res:html():send("<h1>Fibonacci computation isn't finished, please refresh me ...</h1>")  
            }
        })

        httpExchange:GET("/",|req, res|{
            res:html():send("<h1>HOME</h1>")
        })


    }):listen(8081)

    println("start listening to %s":format(httpServer:port()))

}