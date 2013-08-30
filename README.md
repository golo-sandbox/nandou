#Nandou

>>http dsl to create Golo web applications

##Install Nandou

	git clone --q --depth 0 git@github.com:k33g/nandou.git <your web app directory>

or :

	git clone --q --depth 0 https://github.com/k33g/nandou.git <your web app directory>

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

**Run it :** `./g.sh libs main.golo`
