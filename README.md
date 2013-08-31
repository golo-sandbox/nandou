#Nandou

>>http dsl to create Golo web applications

##Install Nandou

	git clone --q --depth 0 git@github.com:k33g/nandou.git <your web app directory>

or :

	git clone --q --depth 0 https://github.com/k33g/nandou.git <your web app directory>

and :

	chmod +x g.sh

##Create your first static http server < 1 minute

First, go into your web app directory : `<your web app directory>` and create a `public` directory with an html page `index.html` (inside `/public`) :

```html
<!DOCTYPE html>
<html>
<head>
    <title>Nandou</title>
</head>
<body>
    <h1>Hello WORLD!</h1>
</body>
</html>
```

Now, create a new golo file, ie : `<your web app directory>/main.golo` with this content :

```coffeescript
module mywebapp

import nandou.Http
import nandou.File
import nandou.Json
import nandou.String

function main = |args| {

    let public = currentWorkingDirectory() + "/public"

    let httpServer = http():server(|httpExchange|{

        # Route for Home page : index.html
        httpExchange:GET("/",|req, res|{
            res:html():load(public + "/index.html"):send()
        })

        #------------------------------------
        # Static assets
        #------------------------------------
        httpExchange:serveStaticFiles(public)

    }):listen(8081)

    println("start listening to %s":format(httpServer:port()))
}
```

**Run it :** Type `./g.sh libs main.golo` and go to [http://localhost:8081/](http://localhost:8081/) with your browser

##Create a json service (GET request)

add this code inside `let httpServer = http():server(|httpExchange|{ ...` and `... }):listen(8081)` :

```coffeescript
httpExchange:GET("/humans", |req, res|{

    let humans = list[
        DynamicObject():id("001"):firstName("Bob"):lastName("Morane"),
        DynamicObject():id("002"):firstName("John"):lastName("Doe"),
        DynamicObject():id("003"):firstName("Jane"):lastName("Doe")
    ]

    res:json():send(Json.stringify(humans))            
})
```

**Stop server and run it again :** Type `./g.sh libs main.golo` and go to [http://localhost:8081/humans](http://localhost:8081/humans) with your browser. You'll get this :

	[{"id":"001","lastName":"Morane","firstName":"Bob"},{"id":"002","lastName":"Doe","firstName":"John"},{"id":"003","lastName":"Doe","firstName":"Jane"}]

**Note :** if content type is `application/json` you have to do `res:json():send(jsonString)`, if `plain/html` : `res:html():send("<b>hello</b>")`, if `plain/text` : `res:text():send("hello")`, ...

##Display html and string interpolation

```coffeescript
httpExchange:GET("/allhumans", |req, res|{

    let humans = list[
        DynamicObject():id("001"):firstName("Bob"):lastName("Morane"),
        DynamicObject():id("002"):firstName("John"):lastName("Doe"),
        DynamicObject():id("003"):firstName("Jane"):lastName("Doe")
    ]

    res:html():send(
        """
        <b>Humans List</b>
        <hr>
        <% foreach human in humans { %>
            <p>
                <%= human:firstName() %> <%= human:lastName() %> <%= human:id() %>
            </p>
        <% } %>
        """:fitin("humans", humans)
    )           
})
```

**Stop server and run it again :** Type `./g.sh libs main.golo` and go to [http://localhost:8081/allhumans](http://localhost:8081/allhumans) with your browser.

##Parse parameters for a GET request

You have to use the `:var` keyword at the end of the uri :

```coffeescript
httpExchange:GET("/humans/:var", |req, res|{
    var query = ""
    foreach parameter in req:parameters() {
        query = query + ":" + parameter   
    }

    res:json():send(
        Json.stringify(map[["query",query]])
    )
})
```

- if you go to [http://localhost:8081/humans/bob](http://localhost:8081/humans/bob), you'll obtain `{"query":":humans:bob"}`
- if you go to [http://localhost:8081/humans/name/bob/age/42](http://localhost:8081/humans/name/bob/age/42), you'll obtain `{"query":":humans:name:bob:age:42"}`

`req:parameters()` returns an array, so you can do : `req:parameters():get(0)` to get the first part of uri. If you use `req:parameter()`, you'll get last parameter.

##Parse json data of a POST request (only json data)

First, you need jQuery : create a `js` dirctory inside `public`, copy `jquery-1.9.1.min.js` to `/public/js/`. Declare it into `index.html` : `<script src="js/jquery-1.9.1.min.js"></script>`. (see `samples/quick/public/js` directory if you want the file).

Then add this route to `main.golo`

```coffeescript
httpExchange:POST("/humans", |req, res|{

    let humanMap = Json.parse(req:data()) # it's a map
    
    humanMap:put("id",java.util.UUID.randomUUID():toString())

    res:json():send(Json.stringify(humanMap))
})
```

**Stop server and run it again :** Type `./g.sh libs main.golo` and go to [http://localhost:8081](http://localhost:8081) with your browser. Open the web console and try this :

```javascript
$.ajax({
  type: "POST",
  url:"/humans", 
  data:'{"firstName":"Bob","lastName":"Morane"}',
  success: function(data){console.log(data)}
});
```

and you'll obtain this :

```javascript
Object {firstName: "Bob", lastName: "Morane", id: "984e072e-2e87-4dda-a624-7acf1d3233c9"}
```

**Note :** `req:data()` returns POST data, `Json.parse(something)` transforms a json string to hashmap or list

##Other "REST" requests

You can make `PUT` and `DELETE` requests too :

```coffeescript
httpExchange:PUT("/humans:var", |req, res|{ ... })
httpExchange:DELETE("/humans:var", |req, res|{ ... })
```

##IMPORTANT : `:var` & POST & PUT & DELETE

You can use `:var` keyword with `POST`, `PUT` and `DELETE` requests


##Redirection

```coffeescript
# Redirection to google
httpExchange:GET("/redirect",|req, res|{
    res:redirect("http://www.google.com")
})
```

##Templating (thx to Golo)

First create a `views` dirctory inside `<your web app directory>` with an html file `humans.golo.tpl.html` :

```html
<!DOCTYPE html>
<html>
    <head>
        <title><%= params:title() %></title>
    </head>
    <body>
        <b>:)</b>
        <hr>
        <h1><%= params:message() %></h1>
        <hr>
        <h3>Fruits</h3>
        <ul><% foreach human in params:humans() { %>
            <li>
                <%= human:firstName() %> <%= human:lastName() %> <%= human:id() %>
            </li>
        <% } %></ul>

    </body>
</html>
```

And add a new route to `main.golo` :

```coffeescript
# Templating
httpExchange:GET("/all/humans", |req, res|{

    let humans = list[
        DynamicObject():id("001"):firstName("Bob"):lastName("Morane"),
        DynamicObject():id("002"):firstName("John"):lastName("Doe"),
        DynamicObject():id("003"):firstName("Jane"):lastName("Doe")
    ]

    res:renderView(
          currentWorkingDirectory() + "/views/humans.golo.tpl.html"
        , "params"
        , DynamicObject()
            :title("Humans List")
            :message("Hello world!")
            :humans(humans)
    )
})     
```

**Stop server and run it again :** Type `./g.sh libs main.golo` and go to [http://localhost:8081/all/humans](http://localhost:8081/all/humans) with your browser.

##Session cookie

```coffeescript
if req:session():current("gologolo"):id() is null {
    req:session():create("gologolo")
}
println("Current Session id : " + req:session():current("gologolo"):id())
```

**Note :** you can delete session cookie : `req:session():delete("gologolo")`

##Futures

###Simple future : "compute Fibonacci"

It's very easy to write a future with **Nandou**

```coffeescript
import nandou.Future

function fibonacci = |n| {
  if n <= 1 {
    return n
  } else {
    return fibonacci(n - 1) + fibonacci(n - 2)
  }
}

function main = |args| {

    let executor = getExecutor() # you need an "executor"

    let callableFibonacciComputation = |iterations| {
      let result = fibonacci(iterations)
      println(">>> " + result)
    }

    let future = executor:getFuture(callableFibonacciComputation, 43)

    println("computation in progress ...")
}
```
See `samples/fibonacci/main.golo` for a complete example.

###Scheduled future

This code save the humans list to a json file every 20 seconds (and after 10 seconds the first time) :

```coffeescript
    var humans = list[]

    # Save data
    println("Scheduling saving ...")
    # Save project each 20 seconds after previous save
    
    let scheduler = getScheduler() # you need a scheduler (kind of executor)

    scheduler:getScheduleFutureWithFixedDelay(
        futureArgs():command(|humans| {
            try {
                textToFile(Json.stringify(humans), currentWorkingDirectory() + "/" + "humans.json")
            } catch(e) {
                println("Error : " + e:toString())
            }
        })
        :message(humans)
        :initialDelay(10_L) # first run after 10 seconds
        :delay(20_L)        # then run it each 20 seconds
    )
```



