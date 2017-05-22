# SymbioteCloud

As a result of the following steps, you will setup and run symbIoTe Cloud components for your platform. You will also register your platform and resources in symbIoTe Core offered by symbIoTe project, which collects metadata for all symbIoTe-enabled platforms. This will allow other symbIoTe users to use the Core to search and access resources that have been shared by you.

## 1. Preparation steps
#### 1.1 Installation of required tools for symbIoTe platform components
Platform components require the following tools to be installed:
  * [Java Runtime Environment](https://java.com/download) - You need Oracle Java 8 version 101+ [(Letsencrypt certificate compatibility)](https://letsencrypt.org/docs/certificate-compatibility/)
  * [RabbitMQ](https://www.rabbitmq.com/) - message queue server for internal messaging between platform components
  * [MongoDB](https://www.mongodb.com/) - database used by Platform components
  * [Icinga 2](https://www.icinga.com/products/icinga-2/) - for monitoring the registered resources
  * [Nginx](https://www.nginx.com/resources/admin-guide/installing-nginx-open-source/) - replaced Interworking Interface component of Release 0.1.0
    * Nginx needs to be configured so that it redirects correctly to the various components.  (more instructions [here](http://nginx.org/en/docs/beginners_guide.html)). This can be done by the placing the following [nginx.conf](https://github.com/symbiote-h2020/SymbioteCloud/blob/master/resources/conf/nginx.conf) in `/usr/local/nginx/conf`, `/etc/nginx`, or `/usr/local/etc/nginx`. (If there are issues, it may be better to simply copy the `server {...}` part in the default config file in `/etc/nginx/nginx.conf` (in Ubuntu/Debian)
 
    * By using the configuration above, your Nginx will listen on port 8102 (http) and 443 (https). To enable https (ssl) you need to provide certificate for your machine, which is also required in later steps (more precisely, in step 2.4, set-up of PAAM), so the same certificate can be re-used. When you obtain the certificate (using the certbot tool, step 2.4-->3.1) copy them to the location: `/etc/nginx/ssl/` (you will need to create the ssl folder). Location can be different, but the nginx process needs access to it.

  Besides that platform owner will need to provide a Java implementation of the platform-specific access to the resources and their readings (observations). So, some *IDE* for writing code and *Gradle* for building and running of the components is required (use version 3, version 2.x can not build Registration Handler properly) . 

#### 1.2 Download symbIoTe platform components
Platform components are available in the GitHub, bundled in the [SymbioteCloud](https://github.com/symbiote-h2020/SymbioteCloud) repository. Master branches contain the latest stable symbIoTe release version, develop branch is a general development branch containing the newest features that are added during development and particular feature branches are where new features are developed. For symbIoTe cloud installation, the following components are currently being used and required to properly start platform in L1 compliance:

  * *CloudConfigService* - service that distributes configuration among platform components
  * *EurekaService* - allows discovery of platform components
  * *ZipkinService* - collects logs from various services
  * *RegistrationHandler* (abbr. RH) - service responsible for properly registering platform resources and distributing this information among platform components
  * *ResourceAccessProxy* (abbr. RAP) - service responsible for providing access to the real readings of the platform resources
  * *AuthenticationAuthorizationManager* (abbr. PAAM) - service responsible for providing a common authentication and authorization mechanism for symbIoTe
  * *Monitoring* - service responsible for monitoring the status of the resources exposed by the platform and notifying symbIoTe core
   * *CloudConfigProperties* - contains a list of properties to configure platform components. It can be found in [CloudConfigProperties](https://github.com/symbiote-h2020/CloudConfigProperties). It must be either deployed in `$HOME/git/symbiote/CloudConfigProperties` or the property `spring.cloud.config.server.git.uri` must be properly set in `src/main/resources/bootstrap.properties` of CloudConfigService component.

For the example integration process described below, we assume the following addresses of various Core and Cloud components:

  * *Admin GUI*                                        https://core.symbiote.eu:8250
  * *Cloud Core Interface*                             https://core.symbiote.eu:8101/cloudCoreInterface/v1/
  * *Core Interface*                                   https://core.symbiote.eu:8100/coreInterface/v1/
  * *Registration Handler*                             https://myplatform.eu:8102/rh
  * *CloudAuthenticationAuthorizationManager*          https://myplatform.eu:8102/paam
  * *Resource Access Proxy*                            https://myplatform.eu:8102/rap

## 2. Integration with symbIoTe
#### 2.1 Provide platform-specific access to the resource and data
Resource Access Proxy is the component in charge of providing access to the resources. This requires the implementation of a software layer (the RAP platform plugin) in order to allow symbIoTe to be able to communicate with the internal mechanisms of the platform. The plugin will communicate with the generic part of the RAP through the rabbitMQ protocol, in order to decouple the symbIoTe Java implementation from the platform specific language.

The figure below figure shows the architecture of the RAP component (orange parts at the bottom are part of the platform specific plugin, to be implemented from platform owners):

![RAP Architecture](https://github.com/symbiote-h2020/SymbioteCloud/blob/master/resources/figures/RAP-arch_v02.png?raw=true)

Here's a quick list of actions and features that have to be implemented in RAP platform specific plugin:

  * Sends registration request to generic RAP, specifying support for filters, notifications
  * Get read/write requests from RAP generic (w/ or w/o filters)
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
  * Filters:
    * If platform supports filters, RAP plugin just forwards filters to platform supporting filters
    * (Optionally) a platform owner can decide to implement filters in RAP platform specific plugin
    * If platform doesn’t support filters the historical readings are retrieved without any filter
  * Notifications:
    *  Enable/disable flag in CloudConfigProperties -> `rap.northbound.interface.WebSocket=true/false`

In order to receive messages for accessing resources, platform plugin shall create an exchange with name `plugin-exchange` and then bind to it the following: get, set, history, subscribe, unsubscribe. Access features supported are:
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
The notifications mechanism follows a different flow than the direct resource access and needs specific a rabbitMQ queues to be used:
  1. The platform plugin will receive subscription/unsubscription requests from the `plugin-exchange`, using `subscribe/unsubscribe` topic keys. The message will contain a list of resource IDs.
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


#### 2.2 Register user and configure platform
The next step is to create a platform owner user in the symbIoTe Core Admin webpage. During registration, it is also necessary to specify some platform details that are needed for security purposes. These are:
  * Name - name of the platform
  * Address - url of the platform's Interworking Interface which will provide the entry point to sybmIoTe Cloud components.
  * Id - a preferred id for the platform. It is optional, if not provided symbiote will generate one for you

![Administration Registration](https://github.com/symbiote-h2020/SymbioteCloud/blob/master/resources/figures/Administration_registration.png?raw=true)

After registering the user, you will be given your user's certificate and key. You will need to store these somewhere, since you can not re-display them, only issue new ones. This limitation is only for release 0.2.0.

![Administration Certificate](https://github.com/symbiote-h2020/SymbioteCloud/blob/master/resources/figures/Administration_certificate.png?raw=true)

Afterwards, you can log in as the new user and activate your platform, by supplying other secondary platform details:
  * Description - description of the platform
  * Information Model - used to differentiate between types of information models - to be used in the future when we provide support for platform specific information models.

![Administration Activate](https://github.com/symbiote-h2020/SymbioteCloud/blob/master/resources/figures/Administration_activate.png?raw=true)

Finally, your platform should be active, and all necessary details (like platform id can be seen or modified)

![Administration Ready](https://github.com/symbiote-h2020/SymbioteCloud/blob/master/resources/figures/Administration_ready.png?raw=true)

#### 2.3 Configuration of the symbIoTe Cloud components
Before starting symbIoTe Cloud components, we need to provide proper configuration in the CloudConfigProperties component. Please edit `application.properties` file contained in this component and provide the following information:
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
#### 2.4  Setting up the Platform Authentication and Authorization Manager
##### 2.4.1 PAAM certificate
Once a platform instance is registered through Administration module, the Platform owner should contact us providing the following data:

| Country Code  |     State     | Locality  | Organization | Organization Unit | Platform Identifier (CN in certificate)  | hostname |
| ------------- |:-------------:|:---------:|:------------:|:-----------------:|:----------------------------------------:|:----------
| *PL* | Wielkopolska | Poznan | PSNC | IoT Department| psnc-platform-1 | iot-1.symbiote.man.poznan.pl |

For those data we will provide you with a keystore file containing the certificate required to set-up your platform *AAM* module.

##### 2.4.2 SSL certificate
To secure communication between the clients and your platform instance you need an SSL certificate(s) for your *PAAM* and for your *InterworkingInterface* (i.e. nginx). Should they be deployed on the same host, the certificate can be reused in both components.

##### 2.4.2.1 How to issue the certificate
* Issue using e.g. https://letsencrypt.org/
* A certificate can be obtained using the certbot shell tool (https://certbot.eff.org/) only for resolvable domain name. Instructions for the Ubuntu (Debian) machine are the following: 
  * Install certbot:
  ```
  sudo apt-get install software-properties-common
  sudo add-apt-repository ppa:certbot/certbot
  sudo apt-get update
  sudo apt-get install certbot python-certbot-apache
  ```
  * Obtain the certificate by executing:
  ```
  certbot --apache certonly
  ```
    Apache port (80 by default) should be accessible from outside on your firewall. Select option Standalone (option 2) and enter your domain name.

  * Upon successful execution navigate to the location `/etc/letsencrypt/live/<domain_name>/`, where you can find your certificate and private key (5 files in total, cert.pem  chain.pem  fullchain.pem  privkey.pem  README).

##### 2.4.2.2 How to create a Java Keystore with the issued SSL certificate, required for Platform AAM deployment
Create a Java Keystore containing the certificate. Use the [KeyStore Explorer](http://keystore-explorer.org/downloads.html) application to create JavaKeystore :

1. (optionally) Inspect obtained files using *Examine* --> Examine File
2. *Create a new Keystore --> PKCS #12*
3. *Tools --> Import Key Pair --> PKCS #8*
4. Deselect *Encrypted Private Key*  
   Browse and set your private key (**privkey.pem**)  
   Browse and set your certificate (**fullchain.pem**)  
5. *Import --> enter alias for the certificate for this keystore*
6. Enter password
7. *File --> Save --> enter previously set password  --> \<filename\>.p12*
   Note: Filename will be used as configuration parameter of the Platform AAM component.
    `server.ssl.key-store=classpath:<filename>.p12`

If you do not want to use KeyStore Explorer find some helpful resources below:  
* https://community.letsencrypt.org/t/how-to-get-certificates-into-java-keystore/25961/19  
* http://stackoverflow.com/questions/34110426/does-java-support-lets-encrypt-certificates

##### 2.4.3 Configuring the Platform AAM resources
Once you have done the previous actions, you need to fix the file `src/main/resources/bootstrap.properties` manually for each deployment using the template below or comments from the file itself.
```
spring.cloud.config.enabled=true
spring.application.name=AuthenticationAuthorizationManager
logging.file=logs/AuthenticationAuthorizationManager.log
# security agreed constants
aam.security.KEY_PAIR_GEN_ALGORITHM=ECDSA
aam.security.CURVE_NAME=secp256r1
aam.security.SIGNATURE_ALGORITHM=SHA256withECDSA
  
# username and password of the AAM module (of your choice)
aam.deployment.owner.username=TODO
aam.deployment.owner.password=TODO
# name of the PAAM JavaKeyStore file you need to put in your src/main/resources directory
aam.security.KEY_STORE_FILE_NAME=TODO.p12
# name of the certificate entry in the Keystore you were given
aam.security.KEY_STORE_ALIAS=TODO
# symbiote keystore password
aam.security.KEY_STORE_PASSWORD=TODO
# symbiote certificate private key password
aam.security.PV_KEY_PASSWORD=TODO
#JWT validity time in milliseconds - how long the tokens issued to your users (apps) are valid... think maybe of an hour, day, week?
aam.deployment.token.validityMillis=TODO
# HTTPS only
# name of the keystore containing the letsencrypt (or other) certificate and key pair for your AAM host's SSL, you need to put it also in your src/main/resources directory
server.ssl.key-store=classpath:TODO.p12
# SSL keystore password
server.ssl.key-store-password=TODO
# SSL certificate private key password
server.ssl.key-password=TODO
# http to https redirect
security.require-ssl=true
```
You also need to copy to the `src/main/resources/` directory:
1. JavaKeyStore file containing the Platform AAM cert+key that you receive from us (e.g. via e-mail)
2. the keystore generated for your SSL cerfitiface

Build the AAM module using command:
```
gradle assemble
```
and then run the Platform AAM jar as any other Symbiote component.

##### 2.4.4 Veryfing that Platform AAM is working
Verify everything is ok by going to:
```
https://<yourPaamHostname>:<selected port>/get_ca_cert  
```
The content there is your Platform AAM instance's certificate in PEM format.

##### 2.4.5 Veryfing that InterworkingInterface is working
Verify everything is ok by going to:
```
https://<yourNginxHostname>/paam/get_ca_cert  
```
The content there is again your Platform AAM instance's certificate in PEM format.

##### 2.4.6 Platform AAM managment
To access a 'simple' management panel of your AAM go to:  
```
https://<yourPaamHostname>:<selected port>/aam_owner_login  
```
To register a local application/user go to:  
```
https://<yourPaamHostname>:<selected port>/app_registration  
```

#### 2.5  Setting up your Monitoring
The installation of the monitoring component is detailed [here](https://github.com/symbiote-h2020/SymbioteCloud/raw/master/resources/docs/SymbIoTe_Monitoring_guide.pdf).

#### 2.6 Starting symbIoTe Cloud components
Starting symbIoTe Cloud components can be done in following steps:

  * Start RabbitMQ server
  * Start MongoDB server
  * Start MySQL server
  * Start symbIoTe Cloud components
    * make sure to first start *CloudConfigService*, and after it is running start *EurekaService*
    * after both services are running you can start rest of the components: *ZipkinService*, *RegistrationHandler*,      *ResourceAccessProxy*, *CloudAuthenticationAuthorizationManager*, *Monitoring*
    
To build and run the components you can issue:
```
gradle assemble
java -jar build/libs/{Component}
```

#### 2.7 Register resource
After our platform has been registered and symbIoTe Cloud components for our platform are configured and are running, we can proceed to expose some of our platform's resources to symbIoTe Core. This is done by sending *HTTP POST* request containing resource description on *RegistrationHandler*'s registration endpoint (i.e. https://myplatform.eu:8102/rh/resources). Exemplary description is shown below:
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
      "interworkingServiceURL": "https://symbiote-h2020.eu/example/interworkingService/",
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
 	    "interworkingServiceURL": "https://symbiote-h2020.eu/example/interworkingService/",
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
		    "interworkingServiceURL": "https://symbiote-h2020.eu/example/interworkingService/",
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
The *interworkingServiceURL* of each resource should be the same with the *interworkingServiceURL* specified during platform registration. RH uses II (i.e. nginx) to communicate with symbIoTe Core to register our platform's resource. If the registration process is successful Core returns resource containing field id (i.e. symbIoTeId) with a uniquely generated id of the resource in the symbIoTe Core layer. Information about the registered resource is distributed in Cloud components using RabbitMQ messaging.

#### 2.8 Update resources
After registering resources, it is also possible to update them. This is done by sending *HTTP PUT* request containing resource description on *RegistrationHandler*'s update endpoint (i.e. https://myplatform.eu:8102/rh/resources). Exemplary description is shown below:
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
      "interworkingServiceURL": "https://symbiote-h2020.eu/example/interworkingService/",
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
 	    "interworkingServiceURL": "https://symbiote-h2020.eu/example/interworkingService/",
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
		    "interworkingServiceURL": "https://symbiote-h2020.eu/example/interworkingService/",
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
The *interworkingServiceURL* of each resource should be the same as the *interworkingServiceURL* specified during platform registration. RH uses II (i.e. nginx) to communicate with symbIoTe Core to update our platform's resource description. The *id* of each resource should be the same *id* returned during registration.

#### 2.9 Delete resources
After registering resources, it is also possible to delete them. This is done by sending *HTTP DELETE* request containing the internal ids on *ResourceHandler*'s delete endpoint (e.g. https://myplatform.eu:8102/rh/resources?resourceInternalId=1600,1700).


## 3 Test integrated resource
After our resources have been shared with Core we can test if we can find and access them properly.

#### 3.1 Search for resource
To search for resource we need to create a query to the symbIoTe Core. In our example, we use https://core.symbiote.eu:8100/coreInterface/v1/query endpoint and provide parameters for querying. All possible query parameters can be seen below:
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
         resource_type: 	String 
}
```
##### NOTE 1:
To query using geospatial properties, all 3 properties need to be set: *location_lat* (latitude), *location_long* (longitude) and *max_distance*(distance from specified point in meters).

##### NOTE 2:
Text parameters allow substring searches using '\*' character which can be placed at the beginning and/or end of the word to search for. For example, querying for name "Sensor\*" finds all resources with name starting with Sensor, and querying for name "\*12\*" will find all resources containing string "12" in its name. Using substring search can be done for the following fields:

* name
* platform_name
* owner
* description
* location_name
* observed_property

For our example lets search for resources with name *Stationary 1*. We do it by sending *HTTP GET* request on symbIoTe Core Interface (e.g. https://core.symbiote.eu:8100/coreInterface/v1/query?name=Stationary 1). The response contains a list of resources fulfilling the criteria:
```
{
  "resources": [
    {
      "platformId": "test1Plat",
      "platformName": "Test 1 Plat",
      "owner": null,
      "name": "Stationary 1",
      "id": "591ae23eb80b283c012fdf26",
      "description": "This is stationary 1",
      "locationName": "SomeLocation",
      "locationLatitude": 25.864716,
      "locationLongitude": 5.349014,
      "locationAltitude": 35,
      "observedProperties": [
        "temperature",
        "humidity"
      ],
      "resourceType": [
        "https://www.symbiote-h2020.eu/ontology/core#StationarySensor"
      ]
    }
  ]
}
```
##### 3.1.2 SPARQL query endpoint
In release 0.2.0, an additional endpoint was created to allow sending *SPARQL* queries to symbIoTe Core. To send *SPARQL* queries, we need to send a request by using *HTTP POST* to the url: https://core.symbiote.eu:8100/coreInterface/v1/sparqlQuery. The endpoint accepts the following payload:
```
{ 
    "sparqlQuery" : "<sparql>",
    "outputFormat" : "<format>"
    
}
```
Possible output formats include: SRX, XML, JSON, SRJ, SRT, THRIFT, SSE, CSV, TSV, SRB, TEXT, COUNT, TUPLES, NONE, RDF, RDF_N3, RDF_XML, N3, TTL, TURTLE, GRAPH, NT, N_TRIPLES, TRIG. SPARQL allows for powerful access to all the meta information stored within symbIoTe Core. Below you can find few example queries:

* Query all resources of the core
```
 { 
    "sparqlQuery" : "PREFIX cim: <http://www.symbiote-h2020.eu/ontology/core#> PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#> SELECT ?res ?resourceName WHERE { ?res a cim:Resource. ?res rdfs:label ?resourceName . }",
    "outputFormat" : "TEXT"
}
```
returns the following output:
```
------------------------------------------------------------------------------------------------------
| res                                                                        | resourceName          |
======================================================================================================
| <http://www.symbiote-h2020.eu/ontology/resources/591ae23eb80b283c012fdf26> | "Stationary 1"        |
| <http://www.symbiote-h2020.eu/ontology/resources/591ae5edb80b283c012fdf29> | "Actuating Service 1" |
------------------------------------------------------------------------------------------------------
```
* Query for Actuating Services and display information about input they are requiring: name and datatype
```
{ 
    "sparqlQuery" : "PREFIX cim: <http://www.symbiote-h2020.eu/ontology/core#> PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#> SELECT ?res ?resourceName ?inputName ?inputDatatype WHERE { ?res a cim:ActuatingService. ?res rdfs:label ?resourceName . ?res cim:hasInputParameter ?input . ?input cim:name ?inputName . ?input cim:datatype ?inputDatatype }",
    "outputFormat" : "TEXT"
}
```
returns the following output:
```
--------------------------------------------------------------------------------------------------------------------------------------
| res                                                                        | resourceName          | inputName     | inputDatatype |
======================================================================================================================================
| <http://www.symbiote-h2020.eu/ontology/resources/591af131b80b2847be1d62eb> | "Actuating Service 1" | "inputParam1" | "xsd:string"  |
--------------------------------------------------------------------------------------------------------------------------------------
```

#### 3.2 Obtaining resource access URL
To access the resource we need to ask symbIoTe Core for the access url. To do so, we need to send a *HTTP GET* request on https://core.symbiote.eu:8100/coreInterface/v1/resourceUrls?id=589dc62a9bdddb2d2a7ggab8. To access the endpoint, we need to specify *X-Auth-Token* header with a valid platform token of the user that is trying to access the resources. 

##### 3.3.1 Request a platform token directly
In this case, you can request a platform token from the PAAM of the platform which owns the resources you are interested in. For that, you have to issue a *HTTP POST* request to https://myplatform.eu:8102/paam/login containing the following:
```
{
  "username" : "The username name used when registering to the PLATFORM",
  "password" : "The password name used when registering to the PLATFORM"
}
```
The token will be contained in the *X-Auth-Token* header field of the response.

##### NOTE:
If you do not know the PAAM url, then you can issue a *HTTP GET* request to https://core.symbiote.eu:8100/coreInterface/v1/get_available_aams and distinguishing the desired PAAM by the *platform id*. 

##### 3.3.2 Request a platform token by providing a core token
In this case, first you have to get a core token. For that, you have to issue a "HTTP POST" request to https://core.symbiote.eu:8100/coreInterface/v1/login containing the following:
```
{
  "username" : "The username name used when registering to the symbIoTe CORE",
  "password" : "The password name used when registering to the symbIoTe CORE"
}
```
Then, you have to get the url of the PAAM as described above and issue a *HTTP POST* request to https://myplatform.eu:8102/paam/login containing the core token in the *X-Auth-Token* header field. The platform token will be included in the *X-Auth-Token* header field of the response.

##### 3.3.3 Get the resource urls
If we provide correct ids of the resources along with a valid platform token, we will get a response containing URLs to access the resources:
```
{  
	"589dc62a9bdddb2d2a7ggab8": "https://myplatform.eu:8102/rap/Sensor('589dc62a9bdddb2d2a7ggab8')",
	"589dc62a9bdddb2d2a7ggab9": "https://myplatform.eu:8102/rap/Sensor('589dc62a9bdddb2d2a7ggab9')"
 }
 ```
 
#### 3.3 Accessing the resource and triggering fetching of our example data
##### NOTE:
First, you have to get a valid platform token and included it in the *X-Auth-Token* header field as described above. The same token used to get the resource url can also be used for accessing the resource if it is still valid.  

As stated previously, RAP can be configured to support different interfaces for accessing the data:
* OData
* REST

The applications can:
* Read current value from resource
* Read history values from resource
* Write value into resource

3.3.1 OData access
* GET  https://myplatform.eu:8102/rap/Sensor('symbioteId')/Observations? $top=1
* GET https://myplatform.eu:8102/rap/Sensor('symbioteId')/Observations
  Historical readings can be filtered, using the option $filter.
  Operators supported: 
  * Equals
  * Not Equals
  * Less Than
  * Greater Than
  * And
  * Or
* PUT https://myplatform.eu:8102/rap/Actuator(‘actuatorId')/ActuatingService(‘serviceId')
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

##### 3.3.2 REST access
* GET https://myplatform.eu:8102/rap/Sensor/{symbioteId}
* GET https://myplatform.eu:8102/rap/Sensor/{symbioteId}/history
* POST https://myplatform.eu:8102/rap/Service(‘symbioteId')
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

##### 3.3.3 Push feature 
Applications can receive notifications from resources, through SymbIoTe RAP WebSocket. The client shall open a WebSocket connection towards a Server at ws://IP:PORT/rap/notification, where IP and PORT are the Interworking Interface parameters.

To subscribe (or unsubscribe) to resources you have to send a message to the WebSocket specifying:
```
{
"action": SUBSCRIBE / UNSUBSCRIBE
"ids": [id1, id2, id3, ...]
}
```
Afterwards, notifications will be automatically received by the application from the WebSocket.
