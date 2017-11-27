# SymbioteCloud

As a result of the following steps, you will setup and run symbIoTe Cloud components for your platform. You will also register your platform and resources in symbIoTe Core offered by symbIoTe project, which collects metadata for all symbIoTe-enabled platforms. This will allow other symbIoTe users to use the Core to search and access resources that have been shared by you.

## 1 Preparation steps

### 1.1 Installation of required tools for symbIoTe platform components

Platform components require the following tools to be installed:

- [Java Development Kit](http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html) - You need Oracle Java 8 version 8u131+ or OpenJDK version 8u101+ ( [Letsencrypt certificate compatibility](https://letsencrypt.org/docs/certificate-compatibility/))
- [RabbitMQ](https://www.rabbitmq.com/) - message queue server for internal messaging between platform components
- [MongoDB](https://www.mongodb.com/) - database used by Platform components
- [Icinga 2](https://www.icinga.com/products/icinga-2/) - for monitoring
- [Nginx](https://www.nginx.com/resources/admin-guide/installing-nginx-open-source/) - represents Interworking Interface/Interworking Service component of the architecture, and is used for redirecting requests from and to platform components
  - Nginx needs to be configured so that it redirects correctly to the various components.  (more instructions [here](http://nginx.org/en/docs/beginners_guide.html)). This can be done by the placing the following [nginx.conf](https://github.com/symbiote-h2020/SymbioteCloud/blob/master/resources/conf/nginx.conf) in `/usr/local/nginx/conf`, `/etc/nginx`, or `/usr/local/etc/nginx`. (If there are issues, it may be better to simply copy the `server {...}` part in the default config file in `/etc/nginx/nginx.conf` (in Ubuntu/Debian)

  - By using the configuration above, your Nginx will listen on port 8102 (https). To enable https (ssl) you need to provide certificate for your machine, which is also required in later steps (more precisely, in step 2.4.1, set-up of PAAM), so the same certificate can be re-used. When you obtain the certificate (using the certbot tool) copy them to the location: `/etc/nginx/ssl/` (you will need to create the _ssl_ folder). Location can be different, but the nginx process needs access to it.

Besides that platform owner will need to provide a Java implementation of the platform-specific access to the resources and their readings (observations). So, some IDE for writing code and [Gradle](https://gradle.org/) (version at least 3.0) for building and running of the components is required .

### 1.2 Download symbIoTe platform components.

Platform components are available in the github, bundled in [SymbioteCloud](https://github.com/symbiote-h2020/SymbioteCloud) . You can download it using the following command:

`git clone --recursive https://github.com/symbiote-h2020/SymbioteCloud.git`

Master branches contain the latest stable symbIoTe release version, develop branch is a general development branch containing newest features that are added during development and particular feature branches are where new features are developed. For symbIoTe cloud installation, the following components are currently being used and required to properly start platform in L1 compliance:

- *CloudConfigService* - service that distributes configuration among platform components
- *EurekaService* - allows discovery of platform components
- *ZipkinService* - collects logs from various services
- *RegistrationHandler* (abbr. _RH_) - service responsible for properly registering platform&#39;s resources and distributing this information among platform components
- *ResourceAccessProxy* (abbr. _RAP_) - service responsible for providing access to the real readings of the platform&#39;s resources
- *AuthenticationAuthorizationManager* (abbr. PAAM) - service responsible for providing a common authentication and authorization mechanism for symbIoTe
- *Monitoring*  - service responsible for monitoring the status of the resources exposed by the platform and notifying symbIoTe core

There is also another project that needs to be downloaded and set up properly, containing configuration of the symbIoTe Cloud components, which can be found in [CloudConfigProperties](https://github.com/symbiote-h2020/CloudConfigProperties)

Per default the _CloundConfigService_ expects the directory where you checked out the _CloudConfigProperties_ to be _$HOME/git/symbiote/CloudConfigProperties_. There are situations when this default might not be convenient for you (e.g. running it in a different operating system or you want to use a different directory structure. In this case, go to the directory _src/main/resources/bootstrap.properties_ of _the CloudConfigService_ component and make a copy to  the directory where the CloudConfigService.jar is located (default is _build/libs_). Edit the property spring.cloud.config.server.git.uri and provide your path there. If you refer to a file the URL must look like _file:///path/to/file_. If you work under windows, remember the special form of file URLs there: file:///c:/my/path/to/my/files. Also, do not forget to have all backslashes replaced with forward slashes. There are even more ways how to configure your server. They are describe [here](http://docs.spring.io/spring-boot/docs/current/reference/html/boot-features-external-config.html).

For the example integration process described below, we assume the following addresses of various Core and Cloud components _(NOTE: those are supposed to be changed to real addresses of Core and Cloud services during integration)_:

- _Admin GUI_ http://core.symbiote.eu:8250
- _Cloud Core Interface_ https://core.symbiote.eu:8101/cloudCoreInterface/v1
- _Core Interface_ http://core.symbiote.eu:8100/coreInterface/v1/
- _Registration Handler_ http://myplatform.eu:8001
- _AuthenticationAuthorizationManager_ https://myplatform.eu:8102/paam
- _Resource Access Proxy_ http://myplatform.eu:8100/

**You should only expose to the internet the nginx 8102 port. All the other ports must not be exposed to the internet for security reasons.**

### 1.3 SymbIoTe Java libraries

There are also symbIoTe java libraries available in GitHub. Beside other things they contain code that eases the generation of symbIoTe-compliant API messages and provide security utilities (e.g. Security Handler for 3rd party applications):

- [SymbIoTeLibraries](https://github.com/symbiote-h2020/SymbIoTeLibraries)
- [SymbIoTeSecurity](https://github.com/symbiote-h2020/SymbIoTeSecurity)

## 2 Integration with symbIoTe

### 2.1 Provide platform-specific access to the resource and data

Resource Access Proxy is the component in charge of accessing to the resources. This requires the implementation of a software layer (the RAP platform plugin) in order to allow symbIoTe to be able to communicate with the internal mechanisms of the platform. The plugin will communicate with the generic part of the RAP through the rabbitMQ protocol, in order to decouple the symbIoTe Java implementation from the platform specific language.

This figure shows the architecture of the RAP component (orange parts on the bottom are part of the platform specific plugin, to be implemented from platform owners):

![RAP Architecture](https://github.com/symbiote-h2020/SymbioteCloud/blob/master/resources/figures/RAP-arch_v02.png?raw=true "RAP Architecture")

Here a quick list of actions and features that RAP platform specific plugin has to implement:

- Registers to generic RAP specifying support for filters, notifications
- Get read / write requests from RAP generic (w/ or w/o filters)
- Applies filters to &#39;get history&#39; requests (optional)
- Get subscribe requests from generic RAP (if it supports notifications)
- Forwards notifications coming from platform to generic RAP

At the beginning, the platform plugin application has to register to the generic RAP, sending a message to exchange _symbIoTe.rapPluginExchange_ with key _symbIoTe.rapPluginExchange.add-plugin_, with some information included: the platform ID (a custom string, used ), a boolean flag specifying it supports notifications, a boolean flag specifying it supports filters. This is the message format expected during plugin registration:

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

Platform ID is used to specify which is the plugin that is going to handle the resource access request: this is needed in case of multiple plugins. Consequently, the same string has to be added also during resource registration (as an addidional parameter) and as routing key for rabbit messages during resource access (_platformId.get_, _platformId.set_, etc.).

Depending on if the platform can natively support filters/notifications, different configuration steps are required:

1. Filters:
  1. If platform supports filters, RAP plugin just forwards filters to platform supporting filters
  2. (Optionally) a platform owner can decide to implement filters in RAP platform specific plugin
  3. If platform doesn&#39;t support filters the historical readings are retrieved without any filter
2. Notifications:
  1. Enable/disable flag in _CloudConfigProperties_ -> _rap.northbound.interface.WebSocket=true/false_

In order to receive messages for accessing resources, platform plugin shall create an exchange with name _plugin-exchange_ and then bind to it the following: _get, set, history, subscribe, unsubscribe_.
Access features supported are (NB: the following examples refer to OData queries (e.g. _/rap/Light(&#39;abcdefgh&#39;)/Observations_), where paths were splitted in JSON arrays):

- Read current value from resource, e.g.:

```
{
  "resourceInfo" : [ {
    "symbioteId" : "abcdefgh",
    "internalId" : "123456",
    "type" : "Light"
  }, {
    "type" : "Observation"
  } ],
  "type" : "GET"
}
```

- Read history values from resource
e.g.:

```
{
  "resourceInfo" : [ {
    "symbioteId" : "abcdefgh",
    "internalId" : "123456",
    "type" : "EnvSensor"
  }, {
    "type" : "Observation"
  } ],
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

- Write value into resource
When a write access is requested, the body of the message will also include parameters needed for the actuation, in a format that depends on the resource accessed:

```
{
  "resourceInfo" : [ {
    "symbioteId" : "{symbioteId}",
    "internalId" : "{internalId}",
    "type" : "{Model}"
  } ],
  "body" : {
        "{capability}": [
      { "{restriction}": "{value}" }
    ]
  },
  "type" : "SET"
}
```

e.g.:

```
{
  "resourceInfo" : {
    "symbioteId" : "abcdefgh",
    "internalId" : "123456",
    "type" : "RGBLight"
  },
  "body" : {
        "RGBCapability": [
         { "R": "0" },
         { "G": "255" },
         { "B": "0" }
    ]
  },
  "type" : "SET"
}
```

The notifications mechanism follows a different flow than the direct resource access and needs a specific rabbitMQ queues to be used.

1) The platform plugin will receive subscription/unsubscription requests from the _plugin-exchange_, using _subscribe_/_unsubscribe_ topic keys. The message will contain a list of resource IDs.

2) Notifications should be sent from platform plugin to generic RAP to exchange _symbIoTe.rapPluginExchange-notification_ with a routing key _symbIoTe.rapPluginExchange.plugin-notification._

All returned messages from read accesses (GET, HISTORY and notifications) are modeled as an instance of _eu.h2020.symbiote.model.cim.Observation class_, e.g.:

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
![RAP Plugin communication](https://github.com/symbiote-h2020/SymbioteCloud/raw/master/resources/figures/RAP_Plugin_communication.png "RAP Plugin communication")

### 2.2 Register user and configure platform

The next step is to create a platform owner user in the symbIoTe Core Admin webpage (running by default on SymbIoTe core on port 8250, so for our example: [https://core.symbiote.eu:8250](http://core.symbiote.eu:8250)). During registration, you have to provide:

- username
- password
- email
- user role (i.e. Platform Owner in this case)

![Platform Owner Registration](https://github.com/symbiote-h2020/SymbioteCloud/raw/master/resources/figures/platform_owner_registration.png "Platform Owner Registration")

Afterwards, you can log in as the new user and register your platform. To this end, you have to click on the **_Platform Details_** panel and then on **_Register New Platform_** button on the upper right corner.

Then, you have to provide the following details:

- Preferable platform id (or leave empty for autogeneration)
- Platform Name
- Platform Description
- Interworking Interface url
- Interworking Interface information model
- Type (i.e. Platform or Enabler)

![Platform Registration](https://github.com/symbiote-h2020/SymbioteCloud/raw/master/resources/figures/platform_registration.png "Platform Registration")

Then, you will see the panel of the newly registered Platform and check its details by clicking on its header.

![Platform Details](https://github.com/symbiote-h2020/SymbioteCloud/raw/master/resources/figures/platform_details.png "Platform Details")

You can also download platform configuration files by clicking on the ***Get Configuration*** button and enter some details.
By doing so, you can download a ***.zip*** folder containing platform configuration properties, which can simplify the 
components' configuration process.

![Get Platform Configuration](https://github.com/symbiote-h2020/SymbioteCloud/raw/master/resources/figures/get_platform_configuration.png "Get Platform Configuration")

If you want to use another information model, not currently available in the symbIoTe Core, then you can upload your own information model. To do so, go to the **_Information Model_** panel and click on the **_Register New Information Model_** button.

Then, you have to provide the following:

- information model id
- information model uri. Note: The core assumes that all services of your cloud are mapped below this uri. You cannot change your URI once  you submitted this information, so choose wisely. (This is due to an unimplemented functionality and might change in the future).
Also note, that due to some shortcoming in handling URLs the URL MAY NOT end in a slash!
- file describing the Platform Information Model in an appropriate format (i.e. .ttl, .nt, .rdf, .xml, .n3, .jsonld)

![Register Information Model](https://github.com/symbiote-h2020/SymbioteCloud/raw/master/resources/figures/register_info_model.png "Register Information Model")


Finally, you will see the panel of the newly registered Information Model and check its details by clicking on its header. Again, you can of course delete the Information Modle by clicking on the **_Delete_** button and **_Verify_** your action.

![Information Model Details](https://github.com/symbiote-h2020/SymbioteCloud/raw/master/resources/figures/info_model_details.png "Information Model Details")

#### 2.2.1 Creating a Platform-Specific Information Model (PIM)

A PIM is an OWL2 ontology with some special characteristics:

- must contain **exactly one owl:Ontology** definition
- must **import CIM directly** (preferable via version IRI)
- must not define anything inside the CIM namespace
- cardinality restrictions on classes are used in a **closed-world assumption** fashion
  - e. if you define a property cardinality restriction on a class, upon resource registration each instance of that class is checked to fulfil this restrictions
  - nly qualified cardinality restrictions are considered (_wl:qualifiedCardinality_, _wl:minQualifiedCardinality_, _wl:maxQualifiedCardinality_)
  - special meaning of cardinalities to also represent unbounded multiplicities
    - [n] = _owl:qualifiedCardinality_ n
    - [n..\*] = _wl:minQualifiedCardinality_ n
      - special case [\*] = _wl:minQualifiedCardinality_ 0
    - [n..m] = _owl:minQualifiedCardinality_ n &amp; _wl:maxQualifiedCardinality_ m

### 2.3 Configuration of the symbIoTe Cloud components

Before starting symbIoTe Cloud components we need to provide proper configuration in the CloudConfigProperties component 
and to be more precise the  application.properties file contained in this component. If you have downloaded the ***.zip***
containing the configuration files, then you can just replace it with file contained in the CloudConfigProperties folder.
Otherwise, you will have to edit it yourselves providing the following information:
```
#################################################################
## Platform config
#################################################################
 
platform.id=<TODO set properly>
 
#################################################################
## AMQP config
#################################################################
 
rabbit.host=<TODO set properly>
rabbit.username=<TODO set properly (e.g. guest for localhost)>
rabbit.password=<TODO set properly (e.g. guest for localhost)>
 
#################################################################
## SymbIoTe Security Config
#################################################################
 
symbIoTe.core.interface.url=<TODO set properly (format: https://{CoreInterfaceHost}:8100/coreInterface/v1)>
symbIoTe.core.cloud.interface.url=<TODO set properly (format: https://{CloudCoreInterfaceHost}:8101/cloudCoreInterface/v1)>
  
symbIoTe.interworking.interface.url=<TODO set properly (format: http://{HostName}:{nginx_port}/cloudCoreInterface/v1 e.g. http://mysymbiote:8102/cloudCoreInterface/v1)>
symbIoTe.localaam.url=<TODO set properly (format: https://{HostName}:{nginx_port}/paam needed to initialize your components use your local AAM e.g. https://mysymbiote.com:8102/paam>
```

Also, there are some component-specific configurations that need to be applied in each cloud component's 
***bootstrap.properties*** file. They are also marked with ***TODO***.  You can also find them in the **.zip** under the respective 
component's folder.

_Hint: Some people like to run the same jar on different machines (think development vs. production here). This often means different settings for the different machines._

_In this case having a bootstrap.properties file WITHIN the jar is not convenient as the same jar can&#39;t be used on both platforms. To come around this make a copy of the bootstrap.properties and place it in the same directory as the jar file. do not place several jars and their bootstrap.properties-files into the same directory_ 


### 2.4 Setting up the Platform Authentication and Authorization Manager

#### 2.4.1 PAAM certificate

Once a platform instance is registered through Administration module, the Platform owner should generate himself a symbiote intermediate certification authority keystore for the PAAM.

For that please use the  [PlatformAAMCertificateKeystoreFactory](https://github.com/symbiote-h2020/SymbIoTeSecurity/blob/develop/src/main/java/eu/h2020/symbiote/security/helpers/PlatformAAMCertificateKeyStoreFactory.java) 
(available in SymbioTeSecurity module). You need to checkout the code, modify the parameters in the main method and 
after running it, it will generate the keystore that you can copy to your platform AAM deployment. If you have downloaded
the **.zip** with the configuration files, you can find the *PlatformAAMCertificateKeystoreFactory* configured in the 
*SymbIoTeSecurity* folder.
```
// from spring bootstrap file: symbIoTe.core.interface.url
String coreAAMAddress = "";
// of the user registered through administration in the symbIoTe Core
String platformOwnerUsername = "";
String platformOwnerPassword = "";
// of the platform registered to the given platform Owner
String platformId = "";

// how the generated keystore should be named
String keyStoreFileName = "";
// used to access the keystore. MUST NOT be longer than 7 chars
// from spring bootstrap file: aam.security.KEY_STORE_PASSWORD
// R3 dirty fix MUST BE THE SAME as spring bootstrap file: aam.security.PV_KEY_PASSWORD
String keyStorePassword = "";
// platform AAM key/certificate alias... case INSENSITIVE (all lowercase)
// from spring bootstrap file: aam.security.CERTIFICATE_ALIAS
String aamCertificateAlias = "";
// root CA certificate alias... case INSENSITIVE (all lowercase)
// from spring bootstrap file:  aam.security.ROOT_CA_CERTIFICATE_ALIAS
String rootCACertificateAlias = "";
```
For those data, script will provide you with a keystore file containing the certificate required to set-up your platform AAM module.

#### 2.4.2 SSL certificate

To secure communication between the clients and your platform instance you need an SSL certificate(s) for your PAAM and for you InterworkingInterface (i.e. nginx). Should they be deployed on the same host, the certificate can be reused in both components.

##### 2.4.2.1 How to issue the certificate

* Issue using e.g.  [https://letsencrypt.org/](https://letsencrypt.org/)   
* A certificate can be obtained using the  **certbot**  shell tool ([https://certbot.eff.org/](https://certbot.eff.org/)) only for resolvable domain name.
Instructions for the Ubuntu (Debian) machine are the following:
  * Install certbot:
    ```
    sudo apt-get install software-properties-common
    sudo add-apt-repository ppa:certbot/certbot
    sudo apt-get update
    sudo apt-get install certbot python-certbot-apache 
    ```
  * Obtain the certificate by executing
    
    ```
    certbot --apache certonly
    ```

    Apache port (80 by default) should be accessible from outside on your firewall.
Select option  **Standalone**  (option 2) and enter your domain name.

  * Upon successful execution navigate to the location:
    ```
    /etc/letsencrypt/live/<domain_name>/
    ```

    where you can find your certificate and private key (5 files in total, cert.pem, chain.pem, fullchain.pem, privkey.pem, README).

##### 2.4.2.2 How to create a Java Keystore with the issued SSL certificate, required for Platform AAM deployment

Create a Java Keystore containing the certificate. Use the KeyStore Explorer application to create JavaKeystore ([http://keystore-explorer.org/downloads.html](http://keystore-explorer.org/downloads.html)):

1. (optionally) Inspect obtained files using Examine --> Examine File
2. Create a new Keystore --> PKCS #12
3. Tools --> Import Key Pair --> PKCS #8
4. Deselect Encrypted Private Key
Browse and set your private key ( **privkey**.pem)
Browse and set your certificate ( **fullchain**.pem)
5. Import --> enter alias for the certificate for this keystore
6. Enter password
7. File --> Save --> enter previously set password  --> <filename>.p12    
  Filename will be used as configuration parameter of the Platform AAM component.   
  `server.ssl.key-store=classpath:<filename>.p12`

If you do not want to use KeyStore Explorer find some helpful resources below:  
* https://community.letsencrypt.org/t/how-to-get-certificates-into-java-keystore/25961/19  
* http://stackoverflow.com/questions/34110426/does-java-support-lets-encrypt-certificates

#### 2.4.3 Configuring the Platform AAM resources

Once one has done previous actions, you need to fix the file `src/main/resources/bootstrap.properties`. If you have 
downloaded the .zip with the configuration files, you can use the bootstrap.properties file inside the AAM folder. 
Otherwise, you have to edit manually for each deployment using the template below or comments from the file itself.

```
spring.cloud.config.enabled=true
spring.application.name=AuthenticationAuthorizationManager
logging.file=logs/AuthenticationAuthorizationManager.log

# username and password of the AAM module (of your choice) -- master password used to manage your AAM (e.g. register new users), not your PO credentials!
aam.deployment.owner.username=TODO
aam.deployment.owner.password=TODO

# name of the PAAM JavaKeyStore file you need to put in your src/main/resources directory
aam.security.KEY_STORE_FILE_NAME=TODO.p12

# name of the root ca certificate entry in the generated Symbiote Keystore
aam.security.ROOT_CA_CERTIFICATE_ALIAS=TODO

# name of the certificate entry in the generated Symbiote Keystore
aam.security.CERTIFICATE_ALIAS=TODO

# symbiote keystore password
aam.security.KEY_STORE_PASSWORD=TODO

# symbiote certificate private key password
aam.security.PV_KEY_PASSWORD=TODO

#JWT validity time in milliseconds - how long the tokens issued to your users (apps) are valid... think maybe of an hour, day, week?
aam.deployment.token.validityMillis=TODO

# allowing offline validation of foreign tokens by signature trust-chain only. Useful when foreign tokens are expected to be used along with no internet access
aam.deployment.validation.allow-offline=false

# HTTPS only
# name of the keystore containing the letsencrypt (or other) certificate and key pair for your AAM host&#39;s SSL, you need to put it also in your src/main/resources directory
server.ssl.key-store=classpath:TODO.p12

# SSL keystore password
server.ssl.key-store-password=TODO

# SSL certificate private key password
server.ssl.key-password=TODO

# http to https redirect
security.require-ssl=true
```

You also need to copy to the `src/main/resources/` directory:

1. the generated in step 2.4.1 keystore Platform AAM symbiote certificate and keys
2. the generated in step 2.4.2 keystore generated for your SSL cerfitiface

Build the AAM module using command:
```
gradle assemble --refresh-dependencies
```
and run the Platform AAM jar as any other Symbiote component

#### 2.4.4 Veryfing that Platform AAM is working

Verify all is ok by going to:
```
https://<yourPaamHostname>:<selected port>/get_available_aams
```
There you should see the connection green and the content are the symbiote security endpoints fetched from the core

Also you can check that the certificate listed there matches the one you get here:
```
https://<yourPaamHostname>:<selected port>/get_component_certificate/platform/<your_platform_id>/component/aam
```

#### 2.4.5 Veryfing that InterworkingInterface is working

Verify all is ok by going to:
```
https://<yourNginxHostname>:8102/paam/get_component_certificate/platform/<your_platform_id>/component/aam
```
There you should see the connection green and the content is your Platform AAM instance's certificate in PEM format.

#### 2.4.6 Platform AAM managment

To manage your local users you can use the AMQP API listening on:

```
rabbit.queue.manage.user.request=symbIoTe-AuthenticationAuthorizationManager-manage_user_request
rabbit.routingKey.manage.user.request=symbIoTe.AuthenticationAuthorizationManager.manage_user_request
```
With the following contents:   

| **Request payload**                                                                                                                                                                                                                                                                                                                                                                                    | **Response**                                                                                                                                                     |
|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| <div> OperationType#CREATE  [UserManagementRequest](https://github.com/symbiote-h2020/SymbIoTeSecurity/blob/develop/src/main/java/eu/h2020/symbiote/security/communication/payloads/UserManagementRequest.java) <ul><li> admin credentials // for operation authorization</li><li>user credentials (username, password) </li><li>user details (recovery mail, federated ID)</li></ul></div>                                                             | [ManagementStatus](https://github.com/symbiote-h2020/SymbIoTeSecurity/blob/develop/src/main/java/eu/h2020/symbiote/security/commons/enums/ManagementStatus.java) |
| <div>OperationType#UPDATE  [UserManagementRequest](https://github.com/symbiote-h2020/SymbIoTeSecurity/blob/develop/src/main/java/eu/h2020/symbiote/security/communication/payloads/UserManagementRequest.java) <ul><li>admin credentials // for operation authorization </li><li> user credentials // for operation authorization </li><li>user credentials (password to store new password) </li><li>user details (recovery mail, federated ID)</li></ul></div> | [ManagementStatus](https://github.com/symbiote-h2020/SymbIoTeSecurity/blob/develop/src/main/java/eu/h2020/symbiote/security/commons/enums/ManagementStatus.java) |
| <div> OperationType#DELETE  [UserManagementRequest](https://github.com/symbiote-h2020/SymbIoTeSecurity/blob/develop/src/main/java/eu/h2020/symbiote/security/communication/payloads/UserManagementRequest.java) <ul><li>admin credentials // for operation authorization</li><li> user credentials (username to find user in repository)</li></ul></div>                                                                                       | [ManagementStatus](https://github.com/symbiote-h2020/SymbIoTeSecurity/blob/develop/src/main/java/eu/h2020/symbiote/security/commons/enums/ManagementStatus.java) |
| <div> OperationType#FORCED_UPDATE  [UserManagementRequest](https://github.com/symbiote-h2020/SymbIoTeSecurity/blob/develop/src/main/java/eu/h2020/symbiote/security/communication/payloads/UserManagementRequest.java) mandatory fields<ul><li>admin credentials // for operation authorization</li><li>user credentials (username to resolve user, password to store new password)</li></ul></div> | [ManagementStatus](https://github.com/symbiote-h2020/SymbIoTeSecurity/blob/develop/src/main/java/eu/h2020/symbiote/security/commons/enums/ManagementStatus.java) | 

### 2.5 Starting symbIoTe Cloud components

Starting symbIoTe Cloud components can be done in following steps:

1. Start RabbitMQ server
2. Start MongoDB server
3. Start nginx
4. Start Icinga 2
5. Start symbIoTe Cloud components
   1. make sure to first start _CloudConfigService_, and after it is running start _EurekaService_
   2. after both services are running you can start the _AuthenticationAuthorizationManager_
   3. finally, after _AuthenticationAuthorizationManager_ is running you can start rest of the components: _ZipkinService, RegistrationHandler, ResourceAccessProxy, , Monitoring_

To build and run the components you can issue:

```
gradle assemble --refresh-depedencies
java -jar build/libs/{Component}
```

### 2.6 Register resources

After our platform has been registered and symbIoTe Cloud components for our platform are configured and are running, we can proceed to expose some of our platform&#39;s resources to symbIoTe Core. List of properties that are supported in the description in Release 1.1.0 can be found here: [List of properties supported in R2 (BIM + imported models)](file:///colab/pages/viewpage.action%3FpageId=10092548). This is done by sending _HTTP POST_ request containing resource description on _RegistrationHandler&#39;s_ registration endpoint (i.e. [http://myplatform.eu:8102/rh/resources](http://myplatform.eu:8101/)). Exemplary description is shown below:

```
[
  {
    "internalId": "internal_id",
    "pluginId": "plugin_id
    "cloudMonitoringHost": "cloud_monitoring_host_ip",
    "params": {
       "type": "Type of device, used in monitoring"
     },
    "singleTokenAccessPolicy": {
      "policyType": "PUBLIC",
      "requiredClaims": {
      }
    },
    "singleTokenFilteringPolicy": {
      "policyType": "PUBLIC",
      "requiredClaims": {
      }
    },
    "resource": {
      "@c": ".StationarySensor",
      "name": "FER33UXP0547",
      "description": [
        "Virtual sensor based on the MGRS cell"
      ],
      "interworkingServiceURL": "https://symbiote.tel.fer.hr",
      "locatedAt": {
        "@c": ".WGS84Location",
        "longitude": 16.414937973022,
        "latitude": 48.267498016357,
        "altitude": 215,
        "name": "Vienna",
        "description": [
          "Vienna, Austria"
        ]
      },
      "featureOfInterest": {
        "name": "FER33UXP0547",
        "description": [
          "MGRS cell"
        ],
        "hasProperty": [
          "temperature",
          "humidity",
          "atmosphericPressure",
          "carbonMonoxideConcentration",
          "nitrogenDioxideConcentration"
        ]
      },
      "observesProperty": [
        "temperature",
        "humidity",
        "atmosphericPressure",
        "carbonMonoxideConcentration",
        "nitrogenDioxideConcentration"
      ]
    }
  }
]
```

The main fields of a CloudResource description is the following:

- *internalId*: the internal (platform-specific) id of the resource that is going to be registered in the core
- *pluginId*: the id of the rap plugin which serves this resource. If there is just one plugin, it can be ommitted
- *cloudMonitoringHost*: the ip address of the Icinga Monitoring Host
- *params*: the cloud monitoring parameters
- *singleTokenAccessPolicy*: the [access policy specifier](https://github.com/symbiote-h2020/SymbIoTeSecurity/blob/master/src/main/java/eu/h2020/symbiote/security/accesspolicies/common/singletoken/SingleTokenAccessPolicySpecifier.java) which is propagated to the RAP. For the moment, there are specific access policies provided by the symbIoTe framework
- *singleTokenFilteringPolicy*: same as above, just this is related to filtering policies and is used during Core search for the resources; resource is returned in the search queries only for users with specific filtering policies
- *resource*: the resource description supported in the [symbIoTe Core](https://github.com/symbiote-h2020/SymbIoTeLibraries/tree/master/src/main/java/eu/h2020/symbiote/core/model/resources)

##### NOTE:
The _interworkingServiceURL_ of each resource should be the same with the _interworkingServiceURL_ specified during platform registration. RH uses II (i.e. nginx) to communicate with symbIoTe Core to register our platform&#39;s resource. If the registration process is successful Core returns the resource descirption containing _id_ field (i.e. symbIoTeId) with unique, generated id of the resource in the symbIoTe Core layer. Information about the registered resource is distributed in Cloud components using RabbitMQ messaging.

It is also possible to register resources using rdf. This is done by sending _HTTP POST_ request containing rdf resource description on _RegistrationHandler&#39;s_ registration endpoint (i.e. [http://myplatform.eu:8102/rh/rdf-resources](http://myplatform.eu:8101/)). The body of the message should be the following:

```
{
  "idMappings": {
    "http://www.testcompany.eu/customPlatform/service1234": {
      "internalId": "internal1",
      "pluginId": "plugin_internal1",
      "cloudMonitoringHost": "monitoring_internal1",
      "singleTokenAccessPolicy": {
        "policyType": "PUBLIC",
        "requiredClaims": {}
      },
      "singleTokenFilteringPolicy": {
        "policyType": "PUBLIC",
        "requiredClaims": {}
      },
      "resource": null,
      "params": {
        "type": "Actuator"
      }
    },
    "http://www.testcompany.eu/customPlatform/sensor1": {
      "internalId": "internal2",
      "pluginId": "plugin_internal2",
      "cloudMonitoringHost": "monitoring_internal2",
      "singleTokenAccessPolicy": {
        "policyType": "PUBLIC",
        "requiredClaims": {}
      },
      "singleTokenFilteringPolicy": {
        "policyType": "PUBLIC",
        "requiredClaims": {}
      },
      "resource": null,
      "params": {
        "type": "Actuator"
      }
    },
    "http://www.testcompany.eu/customPlatform/actuator1": {
      "internalId": "internal3",
      "pluginId": "plugin_internal3",
      "cloudMonitoringHost": "monitoring_internal3",
      "singleTokenAccessPolicy": {
        "policyType": "PUBLIC",
        "requiredClaims": {}
      },
      "singleTokenFilteringPolicy": {
        "policyType": "PUBLIC",
        "requiredClaims": {}
      },
      "resource": null,
      "params": {
        "type": "Actuator"
      }
    }
  },
  "rdfInfo": {
    "rdf": "insert rdf containing your resources",
    "rdfFormat": "NTriples"
  }
}
```

The request contains the following:

- *idMappings*: a map which has as keys the RDF id of the resource and as values the CloudResource description (as in the resource registration using plain json)
- *rdfInfo*: contains the consolidated rdf description of all the resources and specifies the rdfFormat. Accepted formats can be found [here](https://github.com/symbiote-h2020/SymbIoTeLibraries/blob/master/src/main/java/eu/h2020/symbiote/core/model/RDFFormat.java)

### 2.7 Update resources

After registering resources, it is also possible to update them. To do so, you can send an _HTTP POST_ request to the same endpoint (i.e. [http://myplatform.eu:8102/rh/rdf-resources](http://myplatform.eu:8101/)) containing the same JSON payload as in the previous request. If the resource has not been registered previously, it will be automatically registered. However, it is not possible to update a resource using rdf.

***Hint***: If you do not do any bookkeeping of what you already registered and what not you can query the registration handler about the resources it knows. Submit a GET request to the URL regHandlerBase+"/resources (e.g. [http://myplatform.eu:8102/rh/resources](http://myplatform.eu:8101/))

### 2.8 Delete resources

After registering resources, it is also possible to delete them. This is done by sending _HTTP DELETE_ request containing the _internal ids_ on _ResourceHandler's delete_ endpoint (e.g. https://myplatform.eu:8102/rh/resources?resourceInternalId=1600,1700).

### 2.9 Out-of-Sync-Problem with the core

The registration handler maintains a local database of resources known to it. It also forwards any register/update/delete request to the core. Experience has shown that this strategy is fragile and tends to cause the core&#39;s database getting out of sync with the local one.

This problem will be addressed in a later release. Up to then avoid the following actions:

- Do not run two instances of the RH (like one instance on a development machine vs. one instance on a production machine). If you really need to do that make sure both machines use the same data set (i.e. the same mongodb or a replicating pair).
- Do not purge the local database while there are still resources registered in the core.

## 3 Test integrated resource

After our resource have been shared with Core we can test if we can find and access it properly.

### 3.1 Search for resource

#### 3.1.1 Searching by configurable query

To search for resource we need to create a query to the symbIoTe Core. In our example we use [https://core.symbiote.eu:8100/coreInterface/v1/query](http://core.symbiote.eu:8100/coreInterface/v1/) endpoint and provide parameters for querying. Requests need properly generated security headers. More on topic of secure access to symbIoTe component can be read on [SymbIoTeSecurity](https://github.com/symbiote-h2020/SymbIoTeSecurity) project page.

All possible query parameters can be seen below:

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
         resource_type:         String
         should_rank:           Boolean
}
```

**_NOTE 1:_**   To query using geospatial properties, all 3 properties need to be set: _location\_lat_ (latitude), _location\_long_ (longitude) and _max\_distance_ (distance from specified point in meters).

**_NOTE 2:_**   Text parameters allow substring searches using &#39;\*&#39; character which can be placed at the beginning and/or end of the word to search for. For example querying for name "_Sensor\*"_ finds all resources with name starting with _Sensor,_ and search for name "\*12\*" will find all resources containing string "12" in its name. Using substring search can be done for the following fields:

- name
- platform_name
- owner
- description
- location_name
- observed_property

**_NOTE 3:_**  *should_rank* parameter can be set to enable ranking of the resources from the response. This allows currently available and popular resources to be returned with higher ranking than others. Also if geolocation point is used in the query resources closer to the point of interest are returned with higher ranking.

For our example lets search for resources with name _Stationary 1_. We do it by sending a  _HTTP GET_ request on symbIoTe Core Interface ( [https://core.symbiote.eu:8100/coreInterface/v1/query?name=Stationary 1](http://core.symbiote.eu:8100/coreInterface/v1/query)). Response contains a list of resources fulfilling the criteria:

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
        "http://www.symbiote-h2020.eu/ontology/core#StationarySensor"
      ],
         "ranking": 0.5
         }
  ]
}
```

#### 3.1.2 SPARQL query endpoint

Starting with Release 0.2.1, an additional endpoint was created to allow sending SPARQL queries to symbIoTe Core. To send SPARQL requests we need to send request by using _HTTP POST_ to the url: [https://core.symbiote.eu:8100/coreInterface/v1/sparqlQuery](http://core.symbiote.eu:8100/coreInterface/v1/)

The endpoint accepts the following payload:

```
{
  "sparqlQuery" : "<sparql>",
  "outputFormat" : "<format>"
}
```
Possible output formats include: SRX, **XML** , **JSON** , SRJ, SRT, THRIFT, SSE, **CSV** , TSV, SRB, **TEXT** , **COUNT, TUPLES, NONE, RDF, RDF\_N3, RDF\_XML, N3,** TTL **,** TURTLE ****,** GRAPH, NT, N\_TRIPLES, TRIG

SPARQL allows for powerful access to all the meta information stored within symbIoTe Core. Below you can find few example queries

- Query all resources of the core

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

- Query for Services and display information about input they are requiring: name and datatype

```
{
  "sparqlQuery" : "PREFIX cim: <http://www.symbiote-h2020.eu/ontology/core#> PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#> SELECT ?res ?resourceName ?inputName ?inputDatatype WHERE { ?res a cim:Service. ?res rdfs:label ?resourceName . ?res cim:hasInputParameter ?input . ?input cim:name ?inputName . ?input cim:datatype ?inputDatatype }",
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

### 3.2 Obtaining resource access URL

To access the resource we need to ask symbIoTe Core for the access link. To do so we need to send _HTTP GET_ request on *https://core.symbiote.eu/coreInterface/v1/resourceUrls*, with ids of the resources as parameters. For our example, we want urls of 2 resources, so request looks like: *https://core.symbiote.eu/coreInterface/v1/resourceUrls?id=589dc62a9bdddb2d2a7ggab8,589dc62a9bdddb2d2a7ggab9*. To access the endpoint we need to specify security headers, as described in [SymbIoTeSecurity](https://github.com/symbiote-h2020/SymbIoTeSecurity)

##### 3.2.1 Get the resource urls

If we provide correct ids of the resources along with a valid security credentials in the header, we will get a response containing URLs to access the resources:
```
{
  "589dc62a9bdddb2d2a7ggab8": "https://myplatform.eu:8102/rap/Sensor(&#39;589dc62a9bdddb2d2a7ggab8&#39;)",
  "589dc62a9bdddb2d2a7ggab9": "https://myplatform.eu:8102/rap/Sensor(&#39;589dc62a9bdddb2d2a7ggab9&#39;)"
}
```

### 3.3 Accessing the resource and triggering fetching of our example data

In order to access the resources, you need to create a valid Security Request. For that, you can either integrate the Security Handler offered by the symbIoTe framework (implemented in Java) or develop a custom implementation for creating the Security Request. More information can be found in [SymbIoTeSecurity](https://github.com/symbiote-h2020/SymbIoTeSecurity) repository.

As stated previously, RAP can be configured to support different interfaces for accessing the data:

- OData
- REST

The applications can:

1. Read current value from resource
2. Read history values from resource
3. Write value into resource

### 3.3.1 OData access

1. _GET https://myplatform.eu:8102/rap/{Model}s('symbioteId')/Observations?$top=1_
2. _GET https://myplatform.eu:8102/rap/{Model}s('symbioteId')/Observations_
   Historical readings can be filtered, using the option _$filter._
   Operators supported:
   1. Equals
   2. Not Equals
   3. Less Than
   4. Greater Than
   5. And
   6. Or
3. _PUT_ _https://myplatform.eu:8102/rap/{Model}s('serviceId')_   
    ***Request body:***   

    ```
    {
      "capability":
      [ 
        {
          "restriction1": “value1",
        },
        {
          "restriction2": “value2",
        },
        …
      ]
    }
    ```

The keyword _{Model}_ depends on the Information Model used to register devices: can be _Sensor_, _Actuator_, _Light_, _Curtain_, etc..
The same reasoning applies for _capability, restriction_ and _value._

### 3.3.2 REST access

1. _GET https://myplatform.eu:8102/rap/Sensor/{symbioteId}_
2. _GET https://myplatform.eu:8102/rap/Sensor/{symbioteId}/history_
3. _POST https://myplatform.eu:8102/rap/Service('symbioteId')_   
    ***Request body:***   
    
    ```
    {
      "capability":
      [ 
        {
          "restriction1": “value1",
        },
        {
          "restriction2": “value2",
        },
        …
      ]
    }
    ```
### 3.3.3 Push feature

Applications can receive notifications from resources, through SymbIoTe RAP WebSocket.
``
Client shall open a WebSocket connection towards a Server at

```
ws://IP:PORT/notification
```

, where IP and PORT are the Interworking Interface parameters.

To subscribe (or unsubscribe) to resources you have to send a message to the WebSocket specifying:
```
{
  "action": "SUBSCRIBE" / "UNSUBSCRIBE"
  "ids": ["id1", "id2", "id3", ...]
}
```
Afterwards notifications will be automatically received by the application from the WebSocket.


# 4 Resource Description Examples
Below you can find some examples for describing various kind of resources

## 4.1 JSON Description Examples
* ***Stationary Sensor*** :
```
{
  "@c": ".StationarySensor",
  "name": "Stationary 1",
  "description": [
    "This is stationary 1"
  ],
  "interworkingServiceURL": "https://www.example.com/Test1Platform",
  "locatedAt": {
    "@c": ".WGS84Location",
    "longitude": 5.349014,
    "latitude": 25.864716,
    "altitude": 35,
    "name": "SomeLocation",
    "description": [
    	"Secret location"
	]
  },
  "featureOfInterest": {
    "name": "Room1",
    "description": [
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
}
```
* ***Actuator*** :
```
{
  "@c": ".Actuator",
  "name": "Actuator 1",
  "description": [
    "This is actuator 1"
  ],
  "services": null,
  "capabilites": [
    {
      "parameters": [
        {
          "name": "inputParam1",
          "mandatory": true,
          "restrictions": [
            {
              "@c": ".RangeRestriction",
              "min": 2,
              "max": 10
            }
          ],
          "datatype": {
            "@c": ".PrimitiveDatatype",
            "isArray": false,
            "baseDatatype": "http:\/\/www.w3.org\/2001\/XMLSchema#string"
          }
        }
      ],
      "effects": [
        {
          "actsOn": {
            "name": "Room1",
            "description": [
              "This is room 1"
            ],
            "hasProperty": [
              "temperature"
            ]
          },
          "affects": [
            "temperature",
            "humidity"
          ]
        }
      ]
    }
  ],
  "locatedAt": {
    "@c": ".WGS84Location",
    "longitude": 2.349014,
    "latitude": 48.864716,
    "altitude": 15,
    "name": "Paris",
    "description": [
      "This is paris"
    ]
  },
  "interworkingServiceURL": "https://www.example.com/Test1Platform"
}
```
* ***Service*** :
```
{
  "@c": ".Service",
  "name": "Service 1",
  "description": [
    "This is service 1"
  ],
  "interworkingServiceURL": "https://www.example.com/Test1Platform",
  "name": "service1Name",
  "resultType": {
    "@c": ".RdfsDatatype",
    "array": false,
    "isArray": false,
    "datatypeName": "http:\/\/www.w3.org\/2001\/XMLSchema#string"
  },
  "parameters": [
    {
      "name": "inputParam1",
      "mandatory": true,
      "restrictions": [
        {
          "@c": ".RangeRestriction",
          "min": 2,
          "max": 10
        }
      ],
      "datatype": {
        "@c": ".PrimitiveDatatype",
        "isArray": false,
        "baseDatatype": "http:\/\/www.w3.org\/2001\/XMLSchema#string"
      }
    }
  ]
}
```
* ***Mobile Sensor*** :
```
{
  "@c": ".MobileSensor",
  "name": "Mobile 1",
  "description": [
    "This is mobile 1"
  ],
  "interworkingServiceURL": "https://www.example.com/Test1Platform",
  "locatedAt": {
    "@c": ".WGS84Location",
    "longitude": 2.349014,
    "latitude": 48.864716,
    "altitude": 15,
    "name": "Paris",
    "description": [
      "This is paris"
    ]
  },
  "services": null,
  "observesProperty": [
    "temperature"
  ]
}
```

## 4.2 RDF Description Examples
```
@prefix : <http://nextworks.com/ontology/resource#> .
@prefix nxw-location: <http://nextworks.com/ontology/location#> .
@prefix nxw-foi: <http://nextworks.com/ontology/foi#> .
@prefix geo:   <http://www.w3.org/2003/01/geo/wgs84_pos#> .
@prefix core:  <http://www.symbiote-h2020.eu/ontology/core#> .
@prefix qu:    <http://purl.oclc.org/NET/ssnx/qu/quantity#> .
@prefix owl:   <http://www.w3.org/2002/07/owl#> .
@prefix rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix meta:  <http://www.symbiote-h2020.eu/ontology/meta#> .
@prefix xsd:   <http://www.w3.org/2001/XMLSchema#> .
@prefix rdfs:  <http://www.w3.org/2000/01/rdf-schema#> .
@prefix bim: <http://www.symbiote-h2020.eu/ontology/bim#> .
@prefix bim-sr: <http://www.symbiote-h2020.eu/ontology/bim/smartresidence#> .
@base <http://nextworks.com/ontology/resource#> .
:nxw-Light1
        a                   bim-sr:Light ;
        a                   owl:NamedIndividual ;
        a                   core:FeatureOfInterest ;
        core:description        "Light sensor 1" ;
        core:name          "NXW Light 1" ;
        core:locatedAt      nxw-location:Location1 ;
        core:hasCapability  [ a                  bim-sr:OnOffCapabililty ;
                              core:hasEffect     [ a                          bim-sr:OnOffEffect ;
                                                   core:actsOn :nxw-Light1
                                                 ] ;
                              core:hasEffect     [ a                    core:Effect ;
                                                   core:actsOn nxw-foi:nxw-Room1 ;
                                                   core:affects qu:humidity , qu:temperature
                                                 ]
                            ] ;
        core:hasCapability  [ a                  bim-sr:DimmerCapability ;
                              core:hasEffect     [ a                          bim-sr:DimmerEffect ;
                                                   core:actsOn nxw-foi:nxw-Room1
                                                 ] ;
                            ] ;
        core:hasCapability  [ a                  bim-sr:RGBCapability ;
                              core:hasEffect     [ a                          bim-sr:RGBEffect ;
                                                   core:actsOn :nxw-Light1
                                                 ] ;
                              core:hasEffect     [ a                    core:Effect ;
                                                   core:actsOn nxw-foi:nxw-Room1 ;
                                                   core:affects qu:illuminance
                                                 ]
                            ] ;
        core:observesProperty  qu:illuminance.

nxw-location:Location1
        a             core:WGS84Location ;
        core:description  "Location of first deployment nxw" ;
        core:name    "Pisa" ;
        geo:alt       "15.0" ;
        geo:lat       "43.720663784" ;
        geo:long      "10.389831774" .
nxw-foi:nxw-Room1
        a                   core:FeatureOfInterest ;
        core:description        "Light sensor 1" ;
        core:name          "NXW Light 1" ;
        core:hasProperty    qu:humidity , qu:temperature, qu:illuminance .
```
