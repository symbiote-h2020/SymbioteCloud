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
1. the platform ID (a custom string)
2. a boolean flag specifying if it supports notifications
3. a boolean flag specifying if it supports filters. 
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

In order to receive messages for accessing resources, platform plugin shall create an exchange with name plugin-exchange and then bind to it the following: get, set, history, subscribe, unsubscribe. Access features supported are:
* Read current value from resource, e.g.:
```
{
  "resourceInfo" : {
    "symbioteId" : "abcdefgh",
    "internalId" : "123456",
    "observedProperties" : [ "temperature" ]
  },
  "type" : "GET"
}
```
* Read history values from resource, e.g.:
```
{
  "resourceInfo" : {
    "symbioteId" : "abcdefgh",
    "internalId" : "123456",
    "observedProperties" : [ "temperature" ]
  },
  "filter" : {
    "type" : "expr",
    "param" : "[obsValue, temperature]",
    "cmp" : "EQ",
    "val" : "20"
  },
  "type" : "HISTORY"
}
```
The read history values can be received with or without filters, depending on whether the plugin is supporting filters or not.

* Write value into resource. When a write access is requested, the body of the message will also include parameters needed for the actuation, in a format that depends on the resource accessed:
```
{
  "inputParameters":
    [  
        {
             "name": “prop1Name",
             "value": “prop1Value“
        },
        {
              "name": “prop2Name",
              "value": “prop2Value“
        },
        …
    ]
}
```
e.g.:
```
{
  "resourceInfo" : {
    "symbioteId" : "bcdefghi",
    "internalId" : "234567",
    "observedProperties" : [ "light" ]
  },
  "inputParameters" : [ {
    "array" : false,
    "name" : "light",
    "value" : "100"
  } ],
  "type" : "SET"
}
```
The notifications mechanism follows a different flow than the direct resource access and needs specific a rabbitMQ queues to be used.

1. The platform plugin will receive subscription/unsubscription requests from the *plugin-exchange*, using *subscribe/unsubscribe* topic keys. The message will contain a list of resource IDs.
2. Notifications should be sent from platform plugin to generic RAP to exchange `symbIoTe.rapPluginExchange-notification` with a routing key `symbIoTe.rapPluginExchange.plugin-notification`. 

All returned messages from read accesses (GET, HISTORY and notifications) are modeled as an instance of *eu.h2020.symbiote.core.model.Observation* class, e.g.:
```
[
  {
    "resourceId": "abcdefgh", 
    "location": {
      "longitude": 150.89, 
      "latitude": 23.56, 
      "altitude": 343.74
    }, 
    "resultTime": "2017-05-17T10:35:50", 
    "samplingTime": "2017-05-17T10:35:50", 
    "obsValues": [
      {
        "value": 21, 
        "uom": { 
		  "symbol": "°C",
          "label": "Celsius",
          "comment": "Celsius degrees" }, 
        "obsProperty": {
          "label": "temperature", 
          "comment": "temperature in degrees"
        }
      }
    ]
  }
]
```


#### 2. Register user and configure platform

The next step is to create a platform owner user in the symbIoTe Core Admin webpage. During registration, it is also necessary to specify some platform details that are needed for security purposes. These are:
* Name - name of the platform
* Address - url of the platform's Interworking Interface which will provide entry point to sybmIoTe Cloud components.
* Id - a preferred id for the platform. It is optional, if not provided symbiote will generate one for you
# ADD Figure

After registering the user, you will be given your user's certificate and key. You will need to store these somewhere, since you can not re-display them, only issue new ones. This limitation is only for release 0.2.0.
# ADD Figure

Afterwards, you can log in as the new user and activate your platform, by supplying other secondary platform details:
* Description - description of the platform
* Information Model - used to differentiate between types of information models - to be used in the future when we provide support for platform specific information models.
# ADD Figure

Finally, your platform should be active, and all necessary details (like platform id can be seen or modified)
# ADD Figure

#### 3. Configuration of the symbIoTe Cloud components

Before starting symbIoTe Cloud components we need to provide proper configuration in the CloudConfigProperties component. Please edit `application.properties` file contained in this component and provide the following information:
```
rabbit.host=<TODO set properly>
rabbit.username=<TODO set properly (e.g. guest for localhost)>
rabbit.password=<TODO set properly (e.g. guest for localhost)>
security.user=<TODO set properly (username used during registration)>
security.password=<TODO set properly (password used during registration)>
symbiote.coreaam.url=<TODO set properly (format: http://{nginxIp}:{nginxPort}/coreInterface/v1 e.g. http://localhost:8102/coreInterface/v1)>
platform.id=<TODO set properly>
symbIoTe.interworkinginterface.url=<TODO set properly (format: http://{nginxIp}:{nginxPort}/cloudCoreInterface/v1 e.g. http://localhost:8102/cloudCoreInterface/v1)>
```
#### 4.  Setting up the Platform Authentication and Authorization Manager

#### 5. Starting symbIoTe Cloud components

Starting symbIoTe Cloud components can be done in following steps:

1.  Start RabbitMQ server
2.  Start MongoDB server
3.  Start MySQL server
4.  Start symbIoTe Cloud components
  - make sure to first start *CloudConfigService*, and after it is running start *EurekaService*
  - after both services are running you can start rest of the components: *ZipkinService*, *RegistrationHandler*,      *ResourceAccessProxy*, *CloudAuthenticationAuthorizationManager*, *Monitoring*

To build and run the components you can issue:
```
gradle assemble
java -jar build/libs/{Component}
```

#### 6. Register resource

After our platform has been registered and symbIoTe Cloud components for our platform are configured and are running, we can proceed to expose some of our platform's resources to symbIoTe Core. List of properties that are supported in the description in R2 can be found here: List of properties supported in R2 (BIM + imported models). This is done by sending *HTTP POST* request containing resource description on *RegistrationHandler*'s registration endpoint (i.e. http://myplatform.eu:8102/rh/resources). Exemplary description is shown below:
  ```
  [
  {
    "internalId": "1600",
    "cloudMonitoringHost": "cloudMonitoringHostIP",
    "resource": {
      "@c": ".StationarySensor",
      "labels": [
        "lamp"
      ],
      "comments": [
        "A comment"
      ],
      "interworkingServiceURL": "http://symbiote-h2020.eu/example/interworkingService/",
	  "locatedAt": {
        "@c": ".WGS84Location",
        "longitude": 2.349014,
        "latitude": 48.864716,
        "altitude": 15,
        "name": "Paris",
        "description": "This is paris"
      },
	  "featureOfInterest": {
	    "labels": [
	      "Room1"
	    ],
	    "comments": [
	      "This is room 1"
	    ],
	    "hasProperty": [
	      "temperature"
	    ]
	 },
 	 "observesProperty": [
	   "temperature",
  	   "humidity"
	 ]
     },
     "params": {
       "type": "Type of device, used in monitoring"
     }
  },
  {
    "internalId": "1700",
    "cloudMonitoringHost": "cloudMonitoringHostIP",
    "resource": {
  		"@c": ".Actuator",
  		"id": "actuator1",
		"labels": [
		    "Actuator 1"
		],
	    "comments": [
	    	"This is actuator 1"
	    ],
 	    "interworkingServiceURL": "http://symbiote-h2020.eu/example/interworkingService/",
  		"locatedAt": {
		    "@c": ".WGS84Location",
		    "longitude": 2.349014,
		    "latitude": 48.864716,
		    "altitude": 15,
		    "name": "Paris",
		    "description": "This is paris"
		},
	    "capabilites": [
		    {
	        "@c": ".ActuatingService",
      		"id": "actuatingService1",
		    "labels": [
        		"Actuating Service 1"
		    ],
		    "comments": [
        		"This is actuating service 1"
	        ],
		    "interworkingServiceURL": "http://symbiote-h2020.eu/example/interworkingService/",
	        "name": "actuatingService1Name",
	        "outputParameter": {
				"array": false,
		        "isArray": false,
		        "datatype": "xsd:string"
	        },
	        "inputParameter": [
		        {
        		"array": false,
	            "isArray": false,
	            "datatype": "xsd:string",
	            "name": "inputParam1",
		        "mandatory": true,
	            "restrictions": [
		            {
		              "@c": ".RangeRestriction",
		              "min": 2,
		              "max": 10
		            }
       	 	   ]
	           }
		   ],
	       "actsOn": {
		       "labels": [
		          "Room1"
		       ],
	           "comments": [
		          "This is room 1"
	           ],
		       "hasProperty": [
		          "temperature"
	           ]
	      },
    	  "affects": [
    		    "temperature"
	      ]
    	}
	  ]
	},
     "params": {
       "type": "Type of device, used in monitoring"
     }
 }
]
  ```
##### NOTE:
The *interworkingServiceURL* of each resource should be the same with the *interworkingServiceURL* specified during platform registration. RH uses II (i.e. nginx) to communicate with symbIoTe Core to register our platform's resource. If the registration process is successful Core returns resource containing field id (i.e. symbIoTeId) with unique, generated id of the resource in the symbIoTe Core layer. Information about the registered resource is distributed in Cloud components using RabbitMQ messaging.

#### 2.7 Update resources

After registering resources, it is also possible to update them. This is done by sending *HTTP PUT* request containing resource description on *RegistrationHandler*'s update endpoint (i.e. http://myplatform.eu:8102/rh/resources). Exemplary description is shown below:
```
[
  {
    "internalId": "1600",
    "cloudMonitoringHost": "cloudMonitoringHostIP",
    "resource": {
      "@c": ".StationarySensor",
      "id": "symbIoTeId1",
      "labels": [
        "lamp"
      ],
      "comments": [
        "Another comment"
      ],
      "interworkingServiceURL": "http://symbiote-h2020.eu/example/interworkingService/",
	  "locatedAt": {
        "@c": ".WGS84Location",
        "longitude": 2.349014,
        "latitude": 48.864716,
        "altitude": 15,
        "name": "Paris",
        "description": "This is paris"
      },
	  "featureOfInterest": {
	    "labels": [
	      "Room1"
	    ],
	    "comments": [
	      "This is room 1"
	    ],
	    "hasProperty": [
	      "temperature"
	    ]
	 },
 	 "observesProperty": [
	   "temperature",
  	   "humidity"
	 ]
     },
     "params": {
       "type": "Type of device, used in monitoring"
     }
  },
  {
    "internalId": "1700",
    "cloudMonitoringHost": "cloudMonitoringHostIP",
    "resource": {
  		"@c": ".Actuator",
  		"id": "actuator1",
		"labels": [
		    "Actuator 1 - modified"
		],
	    "comments": [
	    	"This is modified actuator 1"
	    ],
 	    "interworkingServiceURL": "http://symbiote-h2020.eu/example/interworkingService/",
  		"locatedAt": {
		    "@c": ".WGS84Location",
		    "longitude": 2.349014,
		    "latitude": 48.864716,
		    "altitude": 15,
		    "name": "Paris",
		    "description": "This is paris"
		},
	    "capabilites": [
		    {
	        "@c": ".ActuatingService",
      		"id": "actuatingService1",
		    "labels": [
        		"Actuating Service 1"
		    ],
		    "comments": [
        		"This is actuating service 1"
	        ],
		    "interworkingServiceURL": "http://symbiote-h2020.eu/example/interworkingService/",
	        "name": "actuatingService1Name",
	        "outputParameter": {
				"array": false,
		        "isArray": false,
		        "datatype": "xsd:string"
	        },
	        "inputParameter": [
		        {
        		"array": false,
	            "isArray": false,
	            "datatype": "xsd:string",
	            "name": "inputParam1",
		        "mandatory": true,
	            "restrictions": [
		            {
		              "@c": ".RangeRestriction",
		              "min": 2,
		              "max": 10
		            }
       	 	   ]
	           }
		   ],
	       "actsOn": {
		       "labels": [
		          "Room1"
		       ],
	           "comments": [
		          "This is room 1"
	           ],
		       "hasProperty": [
		          "temperature"
	           ]
	      },
    	  "affects": [
    		    "temperature"
	      ]
    	}
	  ]
	},
     "params": {
       "type": "Type of device, used in monitoring"
     }
  }
]
```

##### Note
The *interworkingServiceURL* of each resource should be the same with the *interworkingServiceURL* specified during platform registration. RH uses II (i.e. nginx) to communicate with symbIoTe Core to update our platform's resource. The *id* of each resource should be the same *id* returned during registration.

#### 2.8 Delete resources

After registering resources, it is also possible to delete them. This is done by sending *HTTP DELETE* request containing the internal ids on *ResourceHandler*'s delete endpoint (e.g. http://myplatform.eu:8102/rh/resources?resourceInternalId=1600,1700).









