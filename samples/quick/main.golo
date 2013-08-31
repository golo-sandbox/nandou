module quick

import nandou.Http
import nandou.File
import nandou.Json
import nandou.String
import nandou.Future


struct human = { id, firstName, lastName }


function main = |args| {

    let public = currentWorkingDirectory() + "/samples/quick/public"

    var humans = list[]

    # Load data if exist
    println("Loading data ...")
    try {
        let jsonHumans = fileToText(currentWorkingDirectory() + "/" + "humans.json", "UTF-8")
        let tmp_humans = Json.parse(jsonHumans)

        tmp_humans:each(|hash|{
            humans:add(
                human():id(hash:get("id"))
                    :firstName(hash:get("firstName"))
                    :lastName(hash:get("lastName"))
            )
        })

        println("Data loaded.")
        
    } catch(e) {
        println("humans.json doesn't exist!")
    }

    # Save data
    println("Scheduling saving ...")
    # Save project each 20 seconds after previous save
    let scheduler = getScheduler()

    scheduler:getScheduleFutureWithFixedDelay(
        futureArgs():command(|humans| {
            try {
                textToFile(Json.stringify(humans), currentWorkingDirectory() + "/" + "humans.json")
            } catch(e) {
                println("error : " + e:toString())
            }
        })
        :message(humans)
        :initialDelay(10_L) # first run after 10 seconds
        :delay(20_L)        # then run it each 20 seconds
    )

    #let humans = list[
    #    human():id("001"):firstName("Bob"):lastName("Morane"),
    #    human():id("002"):firstName("John"):lastName("Doe"),
    #    human():id("003"):firstName("Jane"):lastName("Doe")
    #]


    let httpServer = http():server(|httpExchange|{

        # Home page : index.html
        httpExchange:GET("/",|req, res|{
            res:html():load(public + "/index.html"):send()
        })

        # Redirection to google
        httpExchange:GET("/redirect",|req, res|{
            res:redirect("http://www.google.com")
        })

        # String interpolation thx Golo templating
        httpExchange:GET("/allhumans", |req, res|{

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
   
        # Templating
        httpExchange:GET("/all/humans", |req, res|{
            res:renderView(
                  currentWorkingDirectory() + "/samples/quick/views/humans.golo.tpl.html"
                , "params"
                , DynamicObject()
                    :title("Humans List")
                    :message("Hello world!")
                    :humans(humans)
            )
        })           

        httpExchange:GET("/humans/:var", |req, res|{

            if req:parameters():length() is 2 {
                # this is a model fetching
                # url:"/humans/6e59f59d-0dde-4d2e-a420-07b2acbb5fc1"
                # get the id :
                println("last parameter (id of model) : " + req:parameter())

                let h = humans:filter(|human|-> human:id():equals(req:parameter())):get(0)

                res:json():send(Json.stringify(h)) 

            } else {
                # it could be a query, ie :
                # url:"/humans/query/name/equals/bob"

                var query = ""

                foreach parameter in req:parameters() {
                    println(parameter) 
                    query = query + " : " + parameter   
                }

                res:json():send(
                    Json.stringify(map[["query",query]])
                ) 
            }

        })

        # Backbone sample :
        # --------------------------------------------------------------
        # var humans = new Humans()
        # humans.fetch()
        httpExchange:GET("/humans", |req, res|{

            res:json():send(Json.stringify(humans))            
        })

        # Backbone sample :
        # --------------------------------------------------------------
        # var sam = new Human({firstName:"Sam", lastName:"LePirate"})
        # sam.save({},{success:function(data){console.log(data)},error:function(err){console.log(err)}})
        
        httpExchange:POST("/humans", |req, res|{

            println("=== SIMPLE POST ====")

            let humanMap = Json.parse(req:data()) # it's a map
            humanMap:put("id",java.util.UUID.randomUUID():toString())

            let humanInst = human()
                :id(humanMap:get("id"))
                :firstName(humanMap:get("firstName"))
                :lastName(humanMap:get("lastName"))

            humans:add(humanInst)

            res:json():send(Json.stringify(humanMap))
        })

        # Backbone sample : === EXPERIMENTS ===
        # --------------------------------------------------------------
        # var sam = new Human({firstName:"Sam", lastName:"LePirate"})
        # sam.urlRoot = sam.urlRoot + "/hello/sam/infos"
        # sam.save({},{success:function(data){console.log(data)},error:function(err){console.log(err)}})

        httpExchange:POST("/humans/:var", |req, res|{

            let humanMap = Json.parse(req:data()) # it's a map
            humanMap:put("id",java.util.UUID.randomUUID():toString())

            let humanInst = human()
                :id(humanMap:get("id"))
                :firstName(humanMap:get("firstName"))
                :lastName(humanMap:get("lastName"))

            humans:add(humanInst)


            println("+++ VARIABLE POST +++")
            var query = ""
            foreach parameter in req:parameters() {
                println(parameter) 
                query = query + " : " + parameter   
            }

            res:json():send(Json.stringify(humanMap))
        })


        #------------------------------------
        # Static assets
        #------------------------------------
        httpExchange:serveStaticFiles(public)

    }):listen(8081)

    println("start listening to %s":format(httpServer:port()))
    println("public directory : " + public)

    #http://docs.oracle.com/javase/6/docs/api/java/net/URLEncoder.html
    ##java.net.URLEncoder.encode(path)


}