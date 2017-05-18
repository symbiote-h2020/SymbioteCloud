# SymbioteCloud

As a result of the following steps you will setup and run symbIoTe Cloud components for your platform. You will also register your platform and resources in symbIoTe Core offered by symbIoTe project, which collects the metadata for all symbIoTe-enabled platforms. This will allow other symbIoTe users to use the Core to search and access resources that have been shared by you.

## 1. Preparation steps.
#### 1.1 Installation of required tools for symbIoTe platform components
  
  Platform components require the following tools to be installed:
  * [RabbitMQ](https://www.rabbitmq.com/) - message queue server for internal messaging between platform components
  * [MongoDB](https://www.mongodb.com/) - database used by Registration Handler and Interworking Interface
  * [Icinga 2](https://www.icinga.com/products/icinga-2/) - for monitoring the registered resources
  * [Nginx](https://www.nginx.com/resources/admin-guide/installing-nginx-open-source/) - replaced Interworking Interface component of Release 0.1.0
    * Nginx needs to be configured so that it redirects correctly to the various components.  (more instructions [here](http://nginx.org/en/docs/beginners_guide.html))
This can be done by the placing following nginx.conf in `/usr/local/nginx/conf`, `/etc/nginx`, or `/usr/local/etc/nginx`.
(If there are issues, it may be better to simply copy the `server {...}` part in the default config file in `/etc/nginx/nginx.conf` (in Ubuntu/Debian)
  ```
  user  nginx;
worker_processes  1;
 
error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;
 
 
events {
    worker_connections  1024;
}
 
 
http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
 
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';
 
    access_log  /var/log/nginx/access.log  main;
 
    sendfile        on;
    #tcp_nopush     on;
 
    keepalive_timeout  65;
 
    #gzip  on;
 
    #include /etc/nginx/conf.d/*.conf;
 
    server {
        ## NOTE: This should match the Interworking Interface port in the CloudConfigProperties
        listen       8102 ## HTTP
 
        listen 443 ssl;  ## HTTPS
 
        server_name  example_platform;
 
        ssl_certificate     /etc/nginx/ssl/cert.pem;    ##location of the certificate
        ssl_certificate_key /etc/nginx/ssl/privkey.pem; ##location of the private key
     
        location /rap/ {
 
          proxy_set_header        Host $host;
          proxy_set_header        X-Real-IP $remote_addr;
          proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
          #proxy_pass_header       Server;
           
          proxy_pass http://localhost:8100; ## NOTE: This should match the RAP port in the CloudConfigProperties
        }
 
        location /paam/check_home_token_revocation  {
 
          proxy_set_header        Host $host;
          proxy_set_header        X-Real-IP $remote_addr;
          proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
          #proxy_pass_header       Server;
 
          proxy_pass https://localhost:8300/check_home_token_revocation; ## NOTE: This should match the Platform Authentication & Authentication Manager port in the CloudConfigProperties
        }

        location /paam/get_ca_cert  {
 
          proxy_set_header        Host $host;
          proxy_set_header        X-Real-IP $remote_addr;
          proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
          #proxy_pass_header       Server;
 
          proxy_pass https://localhost:8300/get_ca_cert; ## NOTE: This should match the Platform Authentication & Authentication Manager port in the CloudConfigProperties
        }

        location /paam/login  {
 
          proxy_set_header        Host $host;
          proxy_set_header        X-Real-IP $remote_addr;
          proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
          #proxy_pass_header       Server;
 
          proxy_pass https://localhost:8300/login; ## NOTE: This should match the Platform Authentication & Authentication Manager port in the CloudConfigProperties
        }

        location /paam/request_foreign_token  {
 
          proxy_set_header        Host $host;
          proxy_set_header        X-Real-IP $remote_addr;
          proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
          #proxy_pass_header       Server;
 
          proxy_pass https://localhost:8300/request_foreign_token; ## NOTE: This should match the Platform Authentication & Authentication Manager port in the CloudConfigProperties
        }

 
        location /rh/ {
 
          proxy_set_header        Host $host;
          proxy_set_header        X-Real-IP $remote_addr;
          proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
          #proxy_pass_header       Server;
 
          proxy_pass http://localhost:8001/; ## NOTE: This should match the Registration Handler port in the CloudConfigProperties
        }
 
        # Forwarding to cloudCoreInterface from the platform components
        location /cloudCoreInterface/v1/ {
 
          proxy_set_header        Host $host;
          proxy_set_header        X-Real-IP $remote_addr;
          proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
          #proxy_pass_header       Server;
 
          proxy_pass http://146.124.2.73:8101/cloudCoreInterface/v1/; ## NOTE: The IP and the port should be changed to that of the CloudCoreInterface
        }
 
        # Forwarding to coreInterface from the platform components
        location /coreInterface/v1/ {
 
          proxy_set_header        Host $host;
          proxy_set_header        X-Real-IP $remote_addr;
          proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
          #proxy_pass_header       Server;
 
          proxy_pass http://146.124.2.73:8100/coreInterface/v1/; ## NOTE: The IP and the port should be changed to that of the CoreInterface
        }
    }
}
```
    * By using the configuration above, your Nginx will listen on port 8102 (http) and 443 (https). To enable https (ssl) you need to provide certificate for your machine, which is also required in later steps (more precisely, in step 2.4, set-up of PAAM), so the same certificate can be re-used. When you obtain the certificate (using the certbot tool, step 2.4-->3.1) copy them to the location: `/etc/nginx/ssl/` (you will need to create the ssl folder). Location can be different, but the nginx process needs access to it.

  Besides that platform owner will need to provide a Java implementation of the platform-specific access to the resources and their readings (observations). So, some IDE for write code and Gradle for building and running of the components is required (use version 3, version 2.x can not build Registration Handler properly) . 

#### 2. Download symbIoTe platform components.

Platform components are available in the github, bundled in the [SymbioteCloud](https://github.com/symbiote-h2020/SymbioteCloud) repository. Master branches contain the latest stable symbIoTe release version, develop branch is a general development branch containing the newest features that are added during development and particular feature branches are where new features are developed. For symbIoTe cloud installation, the following components are currently being used and required to properly start platform in L1 compliance:

* CloudConfigService - service that distributes configuration among platform components
* EurekaService - allows discovery of platform components
* ZipkinService - collects logs from various services
* RegistrationHandler (abbr. RH) - service responsible for properly registering platform's resources and distributing this information among platform components
* ResourceAccessProxy (abbr. RAP) - service responsible for providing access to the real readings of the platform's resources
* AuthenticationAuthorizationManager (abbr. PAAM) - service responsible for providing a common authentication and authorization mechanism for symbIoTe
* Monitoring  - service responsible for monitoring the status of the resources exposed by the platform and notifying symbIoTe core
 * CloudConfigProperties - contains a list of properties to configure platform components. It can be found in [CloudConfigProperties](https://github.com/symbiote-h2020/CloudConfigProperties). It must be either deployed in `$HOME/git/symbiote/CloudConfigProperties` or the property `spring.cloud.config.server.git.uri` must be properly set in `src/main/resources/bootstrap.properties` of CloudConfigService component.

For the example integration process described below we assume the following addresses of various Core and Cloud components:

* Admin GUI                                        http://core.symbiote.eu:8250
* Cloud Core Interface                             http://core.symbiote.eu:8101/cloudCoreInterface/v1/
* Core Interface                                   http://core.symbiote.eu:8100/coreInterface/v1/
* Registration Handler                             http://myplatform.eu:8102/rh
* CloudAuthenticationAuthorizationManager          http://myplatform.eu:8102/paam
* Resource Access Proxy                            http://myplatform.eu:8102/rap

## 2. Integration with symbIoTe
#### 1. Provide platform-specific access to the resource and data

Resource Access Proxy is the component in charge of accessing to the resources. This requires the implementation of a software layer (the RAP platform plugin) in order to allow symbIoTe to be able to communicate with the internal mechanisms of the platform. The plugin will communicate with the generic part of the RAP through the rabbitMQ protocol, in order to decouple the symbIoTe Java implementation from the platform specific language.

This figure shows the architecture of the RAP component (orange parts on the bottom are part of the platform specific plugin, to be implemented from platform owners):
# ADD Figure

Here's a quick list of actions and features that RAP platform specific plugin has to implement:

* Registers to generic RAP specifying support for filters, notifications
* Get read / write requests from RAP generic (w/ or w/o filters)
* Applies filters to ‘get history’ requests (optional)
* Get subscribe requests from generic RAP (if it supports notifications)
* Forwards notifications coming from platform to generic RAP

At the beginning, the platform plugin application has to register to the generic RAP, sending a message to exchange `symbIoTe.rapPluginExchange` with key `symbIoTe.rapPluginExchange.add-plugin`, with some information included: 
* the platform ID (a custom string)
* a boolean flag specifying if it supports notifications
* a boolean flag specifying if it supports filters. 
This is the message format expected during plugin registration:
```
{
  type: REGISTER_PLUGIN,
  platformId: string,
  hasNotifications: boolean ,
  hasFilters: boolean
}
```
e.g.:
```
{
  "type": "REGISTER_PLUGIN",
  "platformId": "platform",  
  "hasFilters": true, 
  "hasNotifications": true
}
```
Depending on if the platform can natively support filters/notifications, different configuration steps are required:

1. Filters:
  * If platform supports filters, RAP plugin just forwards filters to platform supporting filters
  * (Optionally) a platform owner can decide to implement filters in RAP platform specific plugin
  * If platform doesn’t support filters the historical readings are retrieved without any filter
2. Notifications:
  *  Enable/disable flag in CloudConfigProperties -> rap.northbound.interface.WebSocket=true/false

#### 2. Register user and configure platform

  The next step is to create a user in the symbIoTe Core Admin webpage. After creating the user and registering, the user needs to specify the description of their platform.

   - **Name** - name of the platform
   - **Description** - description of the platform
   - **Url** - url of the platform's Interworking Interface which will provide entry point to sybmIoTe Cloud components. For the example we assume our platform's Interworking Interface is running on address http://myplatform.eu:8101/
   - **Information Model** - used to differentiate between types of information models (to be used in the future when we provide support for platform specific information models)

  After registration of the platform, the portal displays the unique **_platformId_** that we will use for configuration in the next step.
  
 3. Configuration of the symbIoTe Cloud components

  Before starting symbIoTe Cloud components we need to provide proper configuration in the *CloudConfigProperties* component. Please edit **application.properties** file contained in this component. Platform owner needs to provide URL address of the *CloudCoreInterface* and *platformId* of the platform we registered. It also provides address where RAP service is running:
   - symbIoTe.core.url=http://core.symbiote.eu:8100/cloudCoreInterface/v1/
   - platform.id=58a5a85e9bdddb4dfedb2495
   - rap.url=http://myplatform.eu:8100/

  RAP configuration is done in ResourceAccessProxy component itself - file `src/main/resources/bootstrap.properties` needs to be editted to provide MySQL database configuration:
  ```
  # DataSource settings: set here your own configurations for the database
  # connection.
  spring.datasource.url = jdbc:mysql://localhost:3306/symbioterap
  spring.datasource.username = user
  spring.datasource.password = pass
  ```
  Create the MySQL database you specified in application.properties file (it will not be created on first deployment automatically).
  
 4. Starting of the symbIoTe Cloud components

  Starting symbIoTe Cloud components can be done in following steps:

  1.  Start RabbitMQ server
  2.  Start MongoDB server
  3.  Start MySQL server
  4.  Start symbIoTe Cloud components
    - make sure to first start *CloudConfigService*, and after it is running start *EurekaService*
    - after both services are running you can start rest of the components: *ZipkinService*, *InterworkingInterface*, *ResourceHandler*, *ResourceAccessProxy*

  To start Cloud components you can use `gradle bootRun` task, or build and use `java -jar <build_target>.jar`
  
 5. Register resource

  After your platform has been registered and symbIoTe Cloud components for your platform are configured and running, you can proceed to expose some of our platform's resources to symbIoTe Core. This is done by sending HTTP POST requests containing resource description on *ResourceHandler*'s registration endpoint. Examplary description is shown below:
  ```
  {
  "name": "Sensor1",
  "owner": "PlatformAOwner",
  "description": "This is a test sensor",
  "resourceURL" : "http://myplatform.eu:8101/",
  "internalId": "1234",
  "location":
   {
   "name": "Poznan",
   "description": "Poznan - malta",
   "longitude": 16.940144,
   "latitude": 52.421790,
   "altitude": 100.0
   },
  "observedProperties":
   [
   "Temperature"
   ]
  }
  ```
  #####NOTE:
   - To register this sensor we POST it on our example setup's *RegistrationHandler* endpoint at http://myplatform.eu:8001/resource. *RegistrationHandler* uses *InterworkingInterface* to communicate with symbIoTe Core to register our platform's resource. If the registration process is successful, symbIoTe Core returns a resource description containing a field named **symbioteId**, which is a unique id generated in the symbIoTe Core layer. Information about the registered resource is distributed in Cloud components using RabbitMQ messaging.

##3. Test integrated resource

After our resource has been shared with symbIoTe Core, we can test if we can find and access it properly.

 1. Search for resource

  To search for resource we need to create a query to the symbIoTe Core. In our example we use http://core.symbiote.eu:8100/coreInterface/v1/query endpoint and provide parameters for query. All possible query parameters can be seen below:
  ```
  Query parameters {
           platform_id:           String
           platform_name:         String
           owner:                 String
           name:                  String
           id:                    String
           description:           String
           location_name:         String
           location_lat:          Double
           location_long:         Double
           max_distance:          Integer
           observed_property:     List<String>
  }
  ```
  #####NOTES:
   - To query using geospatial properties, all 3 properties need to be set: location_lat (latitude), location_long (longitude) and max_distance (distance from specified point in meters).
   - Text parameters allow substring searches using '*' character which can be placed at the beginning and/or end of the word to search for. For example querying for name: Sensor* finds all resources with name starting with Sensor, and search for name: *12* will find all resources containing string "12" in its name. Using substring search can be done for the following fields:
     - name
     - platform_name
     - owner
     - description
     - location_name
     - observed_property

  For our example lets search for resources with name *Sensor1*. We can do this by sending an HTTP GET request on symbIoTe Core Interface: http://core.symbiote.eu:8100/coreInterface/v1/query?name=Sensor1. Response contains a list of resources fulfilling the criteria:

  ```
  [
    {

      "platformId": "589c783a9bdddb2d2a7gea92",

      "platformName": "PlatformA",

      "owner": "PlatformAOwner",

      "name": "Sensor1",

      "id": "589dc62a9bdddb2d2a7ggab8",

      "description": "This is a test sensor",

      "locationName": "Poznan",

      "locationLatitude": 52.42179,

      "locationLongitude": 16.940144,

      "locationAltitude": 100,

      "observedProperties": [

        "Temperature"

      ]
      
    }
  ]
  ```
 
 2. Obtaining resource access URL

  To access the resource we need to ask symbIoTe Core for the access link. To do this,  we need to send an HTTP GET request on http://core.symbiote.eu:8100/coreInterface/v1/resourceUrls?id=589dc62a9bdddb2d2a7ggab8

  If we provided the correct id of the resource, we will get a response containing the URL to access the resource:
  ```
  {
    "589dc62a9bdddb2d2a7ggab8": "http://myplatform.eu:8101/rap/Sensor('589dc62a9bdddb2d2a7ggab8')"
  }
  ```
  
 3. Accessing the resource and triggering fetching of our example data

  For an application to access the URL link retrieved from the previous step, it has to send an HTTP GET request to the *Interworking Interface* of the platform, which forwards the access request to the RAP component. RAP searches for the a resource with the *internal id* specified in the URL. The method  created in section 2.1 is then called to retrieve the value of the resource.

  `HTTP GET` on http://myplatform.eu:8101/rap/Sensor('589dc62a9bdddb2d2a7ggab8') results in:

  ```
  {
    "headers": {
      "X-Application-Context": [
        "ResourceAccessProxy:8100"
      ],
      "Content-Type": [
        "application/json;charset=UTF-8"
      ],
      "Transfer-Encoding": [
        "chunked"
      ],
      "Date": [
        "Wed, 15 Feb 2017 14:12:49 GMT"
      ]
    },
    "body": {
      "resultTime": 1487167969540,
      "resourceId": "symbIoTeID1",
      "samplingTime": 1487167968540,
      "location": {
        "longitude": 16.940144,
        "latitude": 52.42179,
        "altitude": 100,
        "name": "Poznan",
        "description": "Poznan test"
      },
      "obsValue": {
        "value": 7,
        "obsProperty": {
          "label": "Temperature",
          "comment": "Air temperature"
        },
        "uom": {
          "symbol": "C",
          "label": "degree Celsius",
          "comment": null
        }
      }
    },
    "statusCode": "OK",
    "statusCodeValue": 200
  }
  ```
  
##4. Alternative approach to provide L1 compliance

There also exists altearnative approach to provide L1 platform compliance. It is more lightweight in terms of amount of cloud components that must be downloaded and configured, but requires more manual coding to provide proper registration and handling of the resources. To follow this approach you only need to download the Resource Access Proxy component. For the example, we will create a simple java application that will register the resource in symbIoTe Core and inform RAP about the new resource using RabbitMQ.

Here are the more detailed steps:

 1. Write platform-specific implementation of RAP plugin (similar to point 2.1 from original description), where you provide ```readResource(String resourceId)``` implementation to access specific resource for observation value.
 2. Register the platform using Admin GUI (point 2.2). Platform's URL should point in this case to where the RAP instance will be running directly.
 3. Start MySQL and RAP instance.
 4. We need to write some code that will register our resource in symbIoTe Core, by sending HTTP POST requests to CloudCoreInterface endpoint.

   - We need to create registration request. Simplest way is to create a POJO object https://github.com/symbiote-h2020/CloudCoreInterface/blob/develop/src/main/java/eu/h2020/symbiote/model/Resource.java and populate it with values for our resource. Remember that in this case the *resourceURL* that you specify for your resource should point directly to your RAP instance (the same URL you specified in 2.)
   - Use some POJO->JSON tools (Jackson, GSON etc.) to change it into JSON and post it to CloudCoreInterface endpoint. Address of the endpoint is http://core.symbiote.eu:8100/cloudCoreInterface/v1/platforms/<platformId>/resources, so in case of your platform it is: http://core.symbiote.eu:8100/cloudCoreInterface/v1/platforms/589dc62a9bdddb2d2a7ggab8/resources

  Example of the final JSON representation of our object should look like this:
  
  ```
  {
   "name": "Sensor1",
   "owner": "PlatformAOwner",
   "description": "This is a test sensor,
   "featureOfInterest": "foi1",
   "platformId": "589dc62a9bdddb2d2a7ggab8",
   "location":
    {
     "name": "Poznan",
     "description": "Poznan - malta",
     "longitude":     16.940144,
     "latitude":     52.421790,
     "altitude": 100
     },
   "observedProperties":
    [
     "Temperature"
    ],
    "resourceURL": "http://myplatform.eu:8100/"
  }
  ```
 5. Parse the response (which is also a *Resource* object) and retrieve the *id* from it. This is the symbIoTe generated id of our resource.
 6. Next step is to inform *RAP* about the resource. To do so you need to prepare and send message on exchange *symbIoTe.rap* with a routing key *symbIoTe.rap.registrationHandler.register_resources*.The message that is expected is again simple JSON which contains two fields: *internalId* and *id*. *InternalId* is your platform's internal id of the resource and *id* is symbIoTe-generated id of the resource from previous step.
 7. If every step was successful your resource should be accessible the same way as resources registered using full stack of symbIoTe cloud. You can use tests described in point 3.
