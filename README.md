# SymbioteCloud

As a result of the following steps, you will setup and run symbIoTe Cloud components for your platform. You will also
register your platform and resources in symbIoTe Core offered by symbIoTe project, which collects metadata for all 
symbIoTe-enabled platforms. This will allow other symbIoTe users to use the Core to search and access resources that 
have been shared by you.

In order to run symbIoTe Cloud components you need to have public IP address with DNS entry. For testing purposes and 
Hackathons we provide instructions that use ngrok tool/service but this is not for production.

## 1 Preparation steps

symbIoTe Cloud are explained in the following table.

  

***Infrastructure components***

| Component                     | Supported Version | Exposed ports                                     | Purpose                                                                                                                                                                                                            |
|-------------------------------|-------------------|---------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| RabbitMQ                      | 3.6+              | 15672 - Web based management 5672 - AMQP protocol | For communication between  all cloud components                                                                                                                                                                    |
| MongoDB                       | 3.6+              | 27017 - Mongo DB access port                      | All components use this database when they are running on one  machine but it can be split to more then one database.                                                                                              |
| nginx - Inteworking Interface | 1.12.+            | 443 - HTTPS 8102 - HTTP                           | This is gateway to cloud  microservices. Microservices can be accessed only through this Interworking Interface.   In the case of having certificate it uses HTTPS and in case of using ngrok tool it will use HTTP |
| SpringCloudConfig             |                   | 8888 - HTTP                                       | This component is used for serving configuration to other components. It uses CloudConfigServer  from SpringCloud.                                                                                                 |
| Eureka                        |                   | 8761 - HTTP                                       | This component is used for discovery  of other components. All other components are registered in Eureka at startup.                                                                                               |
| Zipkin                        |                   | 8762 - HTTP                                       | This component is used for distributed tracing. It is used for debugging communication between components.                                                                                                         |
| gradle                        | 4.6+              |                                                   | If there is a need to build the components                                                                                                                                                                         |

***Microservices***

| Component                                        | Supported Version | Exposed ports | Purpose                                                                                                                                                                                             |
|--------------------------------------------------|-------------------|---------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| AuthenticationAuthorizationManager (AAM or PAAM) | 3.+               | 8080 - HTTP   | This component is responsible for security. This port is used for  communication to Core services.                                                                                                  |
| RegistrationHandler (RH)                         | 1.2+              | 8001 - HTTP   | This component is responsible for registration of resources. It exposes HTTP, port where you can send request to register/update/unregister resources. This must be used only in the local network. |
| ResourceAccessProxy (RAP)                        | 1.2+              | 8103 - HTTP   | This component is responsible for accessing resources. It need to be connected to your platform through RAP plugin.                                                                                 |

For the example integration process described below, we assume the following addresses
of various Core and Cloud components_ (NOTE: those are supposed to be changed to real
addresses of Core and Cloud services during integration)_:

  

| Parameter                                      | URL                                                   |
|------------------------------------------------|-------------------------------------------------------|
| Admin GUI                                      | https://symbiote-dev.man.poznan.pl/administration     |
| AuthenticationAuthorizationManager (AAM, PAAM) | https://myplatform.eu:443/paam                        |
| Cloud Core Interface                           | https://symbiote-dev.man.poznan.pl/cloudCoreInterface |
| Core Interface                                 | https://symbiote-dev.man.poznan.pl/coreInterface      |
| Registration Handler (RH)                      | https://myplatform.eu:443/rh                          |
| Resource Access Proxy (RAP)                    | https://myplatform.eu:443/rap                         |

In this table the **platform.eu** is your platform DNS entry. In next sections,
we use concrete examples with **symbiotedoc.tel.fer.hr** DNS entry.

### 1.1 Register use and configure platform in symbIoTe Core

To create a platform owner user in the symbIoTe Core Admin webpage [https://symbiote-ext.man.poznan.pl/administration]("https://symbiote-ext.man.poznan.pl/administration"). During registration, you have to provide:

*   username
*   password
*   email
*   user role (i.e. Platform Owner in this case)

![Platform Owner Registration](https://github.com/symbiote-h2020/SymbioteCloud/raw/master/resources/figures/platform_owner_registration.png "Platform Owner Registration")

Afterwards, you can log in as the new user and register your platform. To this end, you have to click on the
 _**Platform Details**_ panel and then on _**Register New Platform**_ button on the upper right corner.

Then, you have to provide the following details:

*   Preferable platform id (or leave empty for autogeneration)
*   Platform Name
*   Platform Description
*   Interworking Interface url - this is the URL to your host where you will install symbIoTe Cloud. It needs public IP
    address and DNS entry for that IP address. The alternative is to use ngrok tool which is good for experimentation but 
    not for production.
*   Interworking Interface information model - you can us BIM (Best practice Information Model) or specify PIM 
    (Platform Information Model) which is explained in next subsection
*   Type (i.e. Platform or Enabler) - in this case use Platform

![Platform Registration](https://github.com/symbiote-h2020/SymbioteCloud/raw/master/resources/figures/platform_registration.png "Platform Registration")
  

By this procedure your platform is registered in the symbIoTe Core. You will see the panel of the newly
registered Platform and check its details by clicking on its header. 

![Platform Details](https://github.com/symbiote-h2020/SymbioteCloud/raw/master/resources/figures/platform_details.png "Platform Details")


You can also update Platform registration by clicking on Update button.

#### 1.1.1 Registering platform information model (PIM)

If you want to use another information model, not currently available in the symbIoTe Core, then you
can upload your own information model. To do so, go to the _**Information Model**_ panel and click on 
the _**Register New Information Model**_ button.

Then, you have to provide the following:

*   information model id
*   information model uri. Note: The core assumes that all services of your cloud are mapped below
    this uri. You cannot change your URI once  you submitted this information, so choose wisely.
    (This is due to an unimplemented functionality and might change in the future).  
    Also note, that due to some shortcoming in handling URLs the URL MAY NOT end in a slash!
*   file describing the Platform Information Model in an appropriate format (i.e. .ttl, .nt, .rdf, .xml, .n3, .jsonld)

![Register Information Model](https://github.com/symbiote-h2020/SymbioteCloud/raw/master/resources/figures/register_info_model.png "Register Information Model")

Finally, you will see the panel of the newly registered Information Model and check its details by
clicking on its header. Again, you can of course delete the Information Model by clicking on the
 _**Delete**_ button and _**Verify**_ your action.

![Information Model Details](https://github.com/symbiote-h2020/SymbioteCloud/raw/master/resources/figures/info_model_details.png "Information Model Details")
  

#### 1.1.2 Creating a Platform-Specific Information Model (PIM)

A Platform-specific Information Model (PIM) is the formal definition of the information model a platform
uses to describe its resources. It can be imagined to be close to an UML class diagram describing all the
entities as well as their properties and relations that a platform wants to expose through its Interworking
Interface. The main prupose of it is to give other platforms a machine-readable formal definition of the 
model your platform is using so that they know how what kind of (platform-specific) data you offer, how to
access it and how to interpret the data they receive from your platform when requesting data. As described
in deliverable D2.4. "Revised Semantic for IoT and Cloud Resources" 
([https://zenodo.org/record/827229]("https://zenodo.org/record/827229")), symbIoTe uses an approach to
semantic interoperability called _Core Information Model with Extensions_. In symbIoTe, this means that
all platforms must describe their resources based on the Core Information Model (CIM) but can use a
custom/platform-specific extension of the CIM called PIM. So to create a PIM, one should start by having
a look at the CIM.

![Core Information Model](https://github.com/symbiote-h2020/SymbioteCloud/raw/master/resources/figures/core_information_model_v2.2.0.png "Core Information Model v2.2.0")
Relations that don't have an explicit mulitplicity are define to have multiplicity exactly 1.

The CIM is designed to be as abstract as possible but at the same time as detailed as needed (so that 
symbIoTe can understand certain data from each platform). The most important class is Resource and it's
subclasses Service, Actuator and Sensor. These describe the different types of resource symbIoTe knows
by default. For a detailed description of the CIM please refer to the above mentioned deliverable D2.4.

As stated before, the CIM is designed to as abstract as possible which means, it is not detailed enough
to be used as a PIM on its own. For example it defines the class _UnitOfMeasurement_ and that each instance
needs to have the properties name and symbol of type string but does not provide any instances that could
be used when registering resources in the Core, e.g. degree Celsius. Therefore, to actually register a
platform with symbIoTe you need a PIM. symbIoTe comes already equiped with an actually useable PIM which
is called Best Practice Information Model (BIM). It is the PIM used with the symbIoTe use cases and
covers four domains (not in general but only as needed in the use cases): smart yachting, smart home,
smart stadium and smart mobility. Although the BIM will probably not be suited for your platform, it can
always be of help as a complex example of a PIM. Furthermore, the BIM is split up in multiple smaller
ontologies of which you might want to re-use use, especially the ones defining a lot of units of measurements
([http://www.symbiote-h2020.eu/ontology/bim/unit]("http://www.symbiote-h2020.eu/ontology/bim/unit")) and
properties ([http://www.symbiote-h2020.eu/ontology/bim/property]("http://www.symbiote-h2020.eu/ontology/bim/property")).

Now let's get started creating your own PIM!

**Requirements**

First of all, some short theoretical things. PIMs are, as all other information models in symbIoTe,
expressed as OWL2 ontologies. If you never heard of Resource Description Format (RDF) and Web Ontology
Language (OWL/OWL2) you should get yourself familiar with it. We will try to explain the most important
things in just two sentences.  
And ontology can be seen as a number of triples in the form of '<subject, predicate, object> .' where
RDF, OWL and OWL2 are vocabularies defining well-known terms such as X
<[http://www.w3.org/1999/02/22-rdf-syntax-ns#type]("http://www.w3.org/1999/02/22-rdf-syntax-ns#type")\> Y
or short X rdf:type Y (using namespace, so-called prefixes; rdf:type is also often refered to be 'a' as in
"is a"), owl:Class and many more. Based on the existing vocabularies an ontology defines are more complex
model which can define its own classes, data and object properties (also called predicates or relations)
and individuals.

To be usable as PIM, an OWL2 ontology has to fulfill some additional requirements.

*   A PIM file must contain exactly one owl:Ontology definition, e.g. <[http://www.example.com/ontology/examplePIM]("http://www.example.com/ontology/examplePIM")\> rdf:type owl:Ontology .
*   the ontology must import CIM directly either by version IRI (highly advised to use), e.g. <[http://www.example.com/ontology/examplePIM]("http://www.example.com/ontology/examplePIM")\> owl:imports <[http://www.symbiote-h2020.eu/ontology/core/2.2.0]("http://www.symbiote-h2020.eu/ontology/core/2.2.0")\> . or by static IRI (not advised as this model might change in the future), e.g. <[http://www.example.com/ontology/examplePIM]("http://www.example.com/ontology/examplePIM")\> owl:imports <[http://www.symbiote-h2020.eu/ontology/core]("http://www.symbiote-h2020.eu/ontology/core") .
*   the ontology must not contain any definitions inside the CIM namespace, e.g. <[http://www.symbiote-h2020.eu/ontology/core/mySensor]("http://www.symbiote-h2020.eu/ontology/core/mySensor")\> a <[http://www.symbiote-h2020.eu/ontology/core/Sensor]("http://www.symbiote-h2020.eu/ontology/core/Sensor")\> . would not be allowed
*   all used classes need to be explicitely defined, either in the PIM itself or in an imported ontology
*   the most important point is, that cardinality restrictions of OWL2 are used with a slightly different semantic in this context as we are using it in a context with closed-world assumption. This is needed to specific cardinality of properties and relations of objects. The OWL2 cardinality restriction expressions owl:qualifiedCardinality, owl:minQualifiedCardinality and owl:maxQualifiedCardinality are used in the following combinations to represent the well-known cardinality types of information models
    *   \[n\] with n > 0 = owl:qualifiedCardinality n
    *   \[n..*\] with n >= 0 = owl:minQualifiedCardinality n
    *   \[n..m\] = owl:minQualifiedCardinality n & owl:maxQualifiedCardinality m

**Examples**

In the following we will explain how to create a very simple PIM.  
All examples are written in the Turtle Syntax (which is a sorthened form of the above introduced list of
triples) but any other RDF serilization format can be used, e.g. RDF/XML, N-Triples, JSON-LD, etc.  
The easiest ways to create/edit OWL2 files are either with a simple text editor or to use an editor like
Protégé ([https://protege.stanford.edu/]("https://protege.stanford.edu/")).

**Minimal PIM**

```
@prefix : <http://www.example.com/ontology/examplePIM#> .
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
@prefix owl: <http://www.w3.org/2002/07/owl#> .
@prefix core: <http://www.symbiote-h2020.eu/ontology/core#> .
 
<http://www.example.com/ontology/examplePIM> rdf:type owl:Ontology ;                                           
    owl:imports <http://www.symbiote-h2020.eu/ontology/core/2.2.0> .
```

Of course, this example is not very helpful in real world as it defines an empty PIM (which is basically
the CIM as it imports the CIM but does not add anything platform-specific). Furthermore, it is advised to
add some meta data of the ontology itself, e.g. 

**Minimal PIM with meta data**

```
@prefix : <http://www.example.com/ontology/examplePIM#> .
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
@prefix owl: <http://www.w3.org/2002/07/owl#> .
@prefix core: <http://www.symbiote-h2020.eu/ontology/core#> .
 
<http://www.example.com/ontology/examplePIM> rdf:type owl:Ontology ;                                           
    owl:imports <http://www.symbiote-h2020.eu/ontology/core/2.2.0> .
    rdfs:label "My example PIM for paltform XY"@en ;                                           
    owl:versionInfo "v1.0.0 2018/02/20 12:00:00"^^xsd:string ;                                           
    rdfs:comment "Some more detailed description of the model and/or the platform"@en ;
```
 

In the following we will show some examples of commonly needed PIM definitions.


**Subclass of Sensor**
```
:TemperatureSensor rdf:type owl:Class ;              
    rdfs:subClassOf core:Sensor .
```
 

**Additional Data Property**

Now we create a new property called variance of type double that we want every instance of TemperatureSensor
to have.

```
:variance rdf:type owl:DatatypeProperty ;
    rdfs:range xsd:double .
     
:TemperatureSensor rdfs:subClassOf [
    rdf:type owl:Restriction ;
    owl:onProperty :variance ;
    owl:onDataRange xsd:double ;
    owl:qualifiedCardinality "1"^^xsd:nonNegativeInteger
] .
```
 

**Additional Object Property**

Additionally, we can create a class TemperatureRange describing the temperature range a TemperatureSensor
can operate in. We want an isntance of TemperatureSensor to have either 0 or 1 instance of TemperatureRange.


```
:minTemperature rdf:type owl:DatatypeProperty ;
    rdfs:range xsd:double .
     
:maxTemperature rdf:type owl:DatatypeProperty ;
    rdfs:range xsd:double .
     
:hasTemperatureRange rdf:type owl:ObjectProperty ;                   
    rdfs:domain :TemperatureSensor ;
    rdfs:range :TemperatureRange .
 
:TemperatureRange rdf:type owl:Class ;              
    rdfs:subClassOf [
        rdf:type owl:Restriction ;
        owl:onProperty :minTemperature ;
        owl:onDataRange xsd:double ;
        owl:qualifiedCardinality "1"^^xsd:nonNegativeInteger
    ] ;
    rdfs:subClassOf [
        rdf:type owl:Restriction ;
        owl:onProperty :maxTemperature ;
        owl:onDataRange xsd:double ;
        owl:qualifiedCardinality "1"^^xsd:nonNegativeInteger
    ] .
 
:TemperatureSensor rdfs:subClassOf [
    rdf:type owl:Restriction ;
    owl:onProperty :hasTemperatureRange ;
    owl:onClass :TemperatureRange ;
    owl:maxQualifiedCardinality "1"^^xsd:nonNegativeInteger
] .
```
 

**Re-using units and properties from BIM**

If we want all units of measurements and properties defined in the BIM to be usable in our PIM we add import
statements for them to our ontology definition, e.g.

```
<http://www.example.com/ontology/examplePIM> rdf:type owl:Ontology ;                                           
    owl:imports <http://www.symbiote-h2020.eu/ontology/bim/unit/2.2.0> ;
    owl:imports <http://www.symbiote-h2020.eu/ontology/bim/property/2.2.0> .
```

#### 1.1.3 Getting all configuration files in one ZIP (optional)

When you have opened panel of platform that is registered you can download platform configuration files
by clicking on the _**Get Configuration**_ button and enter some details. By doing so, you can download
a **.zip** file containing platform configuration properties which can simplify the components' 
configuration process.  

![Get Platform Configuration](https://github.com/symbiote-h2020/SymbioteCloud/raw/master/resources/figures/get_platform_configuration.png "Get Platform Configuration")

Example of filled form follows:

![Filled Platform Configuration Form](https://github.com/symbiote-h2020/SymbioteCloud/raw/master/resources/figures/filled_configuration_form.png "Filled Platform Configuration Form")

### 1.2 Installation of required tools for symbIoTe platform components

Platform components require the following software to be installed:

*   [Java Development Kit]("http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html") \- You need Oracle Java 8 version 8u131+ or OpenJDK version 8u101+ ([Letsencrypt certificate compatibility]("https://letsencrypt.org/docs/certificate-compatibility/")) because all services are implemented in Java.
*   [RabbitMQ]("https://www.rabbitmq.com/") \- (latest stable, verified working 3.6.+) message queue server for internal messaging between cloud components.
*   [MongoDB]("https://www.mongodb.com/") \- (latest stable, verifierd working 3.6.+) database used by cloud components.
*   [Gradle]("https://gradle.org") \- (latest stable, verified working 4.6)

### 1.3. Downloading sources
Platform components are available in the github, bundled in the following directory:
[https://github.com/symbiote-h2020/SymbioteCloud]("https://github.com/symbiote-h2020/SymbioteCloud").
For concrete lets say that we will install everything in directory /opt/symbiote on Linux machine.

You can download it using the following command:

**Download Superproject**
```
$ git clone --recursive https://github.com/symbiote-h2020/SymbioteCloud.git
```
 
Master branches contain the latest stable symbIoTe release version, develop branch is a general development branch containing newest features that are added during development and particular feature branches are where new features are developed. For symbIoTe cloud installation, the following components are currently being used and required to properly start platform in L1 compliance:

*   CloudConfigService - service that distributes configuration among platform components
*   EurekaService - allows discovery of platform components
*   ZipkinService - collects logs from various services
*   RegistrationHandler (abbr. _RH_) \- service responsible for properly registering platform's resources and distributing this information among platform components
*   ResourceAccessProxy (abbr. _RAP_) \- service responsible for providing access to the real readings of the platform's resources
*   AuthenticationAuthorizationManager (abbr. PAAM) - service responsible for providing a common authentication and authorization mechanism for symbIoTe
*   Monitoring  - service responsible for monitoring the status of the resources exposed by the platform and notifying symbIoTe core

There is also another project that needs to be downloaded and set up properly, containing configuration of the symbIoTe Cloud components, which can be found in [https://github.com/symbiote-h2020/CloudConfigProperties]("https://github.com/symbiote-h2020/CloudConfigProperties"). You need to clone it locally:

**Download Superproject**

```
$ git clone https://github.com/symbiote-h2020/CloudConfigProperties.git
```
 

## 2 Configuring and starting components

### 2.1 Configuration of NGINX

There are two possible way to run cloud components:

1.  On dedicated server accessible from Internet by using DNS entry. In this case you need to obtain
certificate (not self signed) and install it in NGINX. This is **production environment**.
2.  In private network exposed to the world by using ngrok tool/service. This is for testing and 
**hackaton environment** where you can be accessed over public Internet.

#### 2.1.1 Production environment

You can obtain valid certificate by using different companies. Here we explain how to get free certificate by
using **Let's encrypt** service.

##### 2.1.1.1 Obtaining the SSL certificate 

To secure communication between the clients and your platform instance you need an SSL certificate(s) for
InterworkingInterface (i.e. nginx). 

Issue using e.g. [https://letsencrypt.org/]("https://letsencrypt.org/")  
A certificate can be obtained using the **certbot** shell tool ([https://certbot.eff.org/]("https://certbot.eff.org/")) only for resolvable domain name.  
  
Instructions for the Ubuntu (Debian) machine are the following: 

1.  Install certbot:
```
$ sudo apt-get install software-properties-common  
$ sudo add-apt-repository ppa:certbot/certbot  
$ sudo apt-get update 
$ sudo apt-get install certbot python-certbot-apache
```
      
    

    
2.  Obtain the certificate by executing:   
```$ sudo certbot --apache certonly```
    
    Apache port (80 by default) should be accessible from outside on your firewall.  
    Select option **Standalone** (option 2) and enter your domain name.
    
3.  Upon successful execution navigate to the location: 
    
    ```/etc/letsencrypt/live/<domain_name>/``` 
    
    where you can find your certificate and private key (5 files in total, cert.pem  chain.pem  fullchain.pem  privkey.pem  README).
    

##### 2.1.1.2 Configuring NGINX with HTTPS

[Nginx]("https://www.nginx.com/resources/admin-guide/installing-nginx-open-source/") \- represents 
Interworking Interface/Interworking Service component of the architecture, and is used for redirecting
requests from and to cloud components.

* Nginx needs to be configured so that it redirects correctly to appropriate endpoints.  (more instructions [here]("http://nginx.org/en/docs/beginners_guide.html"))  
  This can be done by the placing a *nginx.conf* following this
  [template](https://github.com/symbiote-h2020/SymbioteCloud/blob/master/resources/conf/nginx.conf) in
   `/etc/nginx`, `/usr/local/nginx/conf`,  or `/usr/local/etc/nginx.`  
  (If there are issues, it may be better to simply copy the server {...} part in the default config file
  in `/etc/nginx/nginx.conf` (in Ubuntu/Debian).
      
*   By using the configuration above, your Nginx will listen on port 443 (https). To enable https (ssl) you
need to provide certificate for your machine. When you obtain the certificate (using the certbot tool) copy
them to the location: **_/etc/nginx/ssl/_** (you will need to create the _ssl_ folder). Location can be
different, but the nginx process needs access to it. If you need to run Nginx on another port, you will need
to change the **nginx.conf**.
*   In this **nginx.conf** you have to change **{symbiote-core-hostname}** to exact name of core. In this
case, it is **symbiote-ext.man.poznan.pl**.

Start nginx and open browser on [https://symbiotedoc.tel.fer.hr]("https://symbiotedoc.tel.fer.hr"). 
Nginx should return response. This means that nginx is started and that certificates are OK.

**Note**
You should only expose to the Internet the nginx 443 port. All the other ports must not be exposed to the
internet for security reasons.

#### 2.1.2 Hackathon environment

##### 2.1.2.1 ngrok

[ngrok]("https://ngrok.com") allows you to expose a web server running on your local machine to the 
Internet.

You need to install ngrok tool from this site: [https://ngrok.com/download]("https://ngrok.com/download").

Then you need to start it with following command:

```
$ ./ngrok http --bind-tls "true" 8102


ngrok by @inconshreveable

Session Status                online                                                                                                                                                                                                    
Session Expires               7 hours, 59 minutes                                                                                                                                                                                       
Version                       2.2.8                                                                                                                                                                                                     
Region                        United States (us)                                                                                                                                                                                        
Web Interface                 http://127.0.0.1:4040                                                                                                                                                                                     
Forwarding                    https://b2cb3e08.ngrok.io -> localhost:8102                                                                                                                                                               
                                                                                                                                                                                                                                       
Connections                   ttl     opn     rt1     rt5     p50     p90                                                                                                                                                               
                              0       0       0.00    0.00    0.00    0.00
```

In this example we see that local port 8102 is exposed over
[https://b2cb3e08.ngrok.io]("https://b2cb3e08.ngrok.io"). The session lasts for 8 hours.
After that you need to stop (ctrl-c) and start again ngrok and register new URL in core.

##### 2.1.2.2 Updating platform registration

Go to symbIoTe Core Admin webpage
[https://symbiote-ext.man.poznan.pl/administration]("https://symbiote-ext.man.poznan.pl/administration"),
login, click on platform details. On platform click on update button. Fill in **Interworking Services** to
have value what you got from ngrok. Here is an
![Update Platform](https://github.com/symbiote-h2020/SymbioteCloud/raw/master/resources/figures/update_platform_hackathon.png "Update Platform")


#### 2.1.2.3 Configuring NGINX with HTTPS

[Nginx]("https://www.nginx.com/resources/admin-guide/installing-nginx-open-source/") \- represents
Interworking Interface/Interworking Service component of the architecture, and is used for redirecting
requests from and to cloud components.

*   Nginx needs to be configured so that it redirects correctly to appropriate endpoints.  
    (more instructions [here]("http://nginx.org/en/docs/beginners_guide.html"))  
    This can be done by placing the following [template](https://github.com/symbiote-h2020/SymbioteCloud/blob/master/resources/conf/hackathon/nginx.conf) in
     `/usr/local/nginx/conf`, `/etc/nginx`, or `/usr/local/etc/nginx.`  
       
*   In this **nginx.conf** you have to change **{symbiote-core-hostname}** to exact name of core. In this
    case it is **symbiote-ext.man.poznan.pl**.

Start nginx and open browser on [https://b2cb3e08.ngrok.io]("https://b2cb3e08.ngrok.io"). nginx should return response. This means that nginx is started and that tunnel is working.

***Changed ngrok link***

After 8 hours you need to restart ngrok because of limit on ngrok side. In that case you need to change following two things:

1. Update ngrok in administration in core (see [instructions](https://github.com/symbiote-h2020/SymbioteCloud/blob/master/README.md#2122-updating-platform-registration))

2. Change property _symbIoTe.interworking.interface.url_ in _application.properties_ in _CloudConfigProperties_ (see [instructions](https://github.com/symbiote-h2020/SymbioteCloud/blob/master/README.md#24-configuration-of-cloud-components))

symbIoTe.interworking.interface.url=[https://b2cb3e08.ngrok.io]("https://b2cb3e08.ngrok.io")

3. Sync registration (see [here](https://github.com/symbiote-h2020/SymbioteCloud/blob/master/README.md#285-out-of-sync-problem-with-the-core)) and 
register all resources with new URL (see [here](https://github.com/symbiote-h2020/SymbioteCloud/blob/master/README.md#28-register-resources)).


### 2.2 Starting third-party tools that are prerequisite for symbIoTe

Installation, set-up and execution instructions can be found at the official web pages of third-party software.

Starting the third-party tools can be done in following steps:

*   Start RabbitMQ server
*   Start MongoDB server

### 2.3 Starting (generic) symbIoTe Cloud components

After you downloaded symbIoTe components, you need to build and run them by using the following commands:

**Build and run Components**
```
gradle assemble --refresh-dependencies
java -jar build/libs/{Component}
```
 

That need to be done in each directory. They is general remark the concrete steps are following.

#### 2.3.1 _CloudConfigService_

_CloudConfigService_ needs CloudConfigProperties repository because in _CloudConfigProperties_ are 
configuration files. By default the _CloundConfigService_ expects the directory where you checked out
the _CloudConfigProperties_ to be _$HOME/git/symbiote/CloudConfigProperties_. There are situations when
this default might not be convenient for you (e.g. running it in a different operating system or you want
to use a different directory structure.

##### 2.3.1.1 Creating JAR
```
$ cd /opt/symbiote/SymbioteCloud/CloudConfigService
$ gradle assemble --refresh-dependencies
```
 

##### 2.3.1.2 Customizing path to CloudConfigProperties

1.  Copy _src/main/resources/bootstrap.properties _of _the CloudConfigService_ component in current
    directory 
```
$ cp src/main/resources/bootstrap.properties ./
```

2.  In the file edit the property spring.cloud.config.server.git.uri and provide your path there. If you 
refer to a file the URL must look like_ [file:///path/to/file]("file:///path/to/file")_. If you work under
windows, remember the special form of file URLs there: file:///c:/my/path/to/my/files. Also, do not forget
to have all backslashes replaced with forward slashes. There are even more ways how to configure your server.
They are described [here]("http://docs.spring.io/spring-boot/docs/current/reference/html/boot-features-external-config.html.").
For our example file should look like following:
```
spring.cloud.config.server.git.uri=file:///opt/symbiote/CloudConfigProperties
server.port=8888
```

##### 2.3.1.3 Running service

After you configured the CloudConfigService (e.g. path to the CloudConfigProperties folder) you can start
the component.
```
$ java -jar build/libs/CloudConfigService-1.2.0-run.jar
```
 
For checking that CloudConfigServer is running open
[http://localhost:8888/EurekaService/default]("http://localhost:8888/EurekaService/default").
If you get JSON file it means that CloudConfigService is working.

#### 2.3.2 EurekaService

Build and start the component. 

```
$ cd /opt/symbiote/SymbioteCloud/EurekaService
$ gradle assemble --refresh-dependencies
$ java -jar build/libs/EurekaService-1.2.0-run.jar
```
 
To check if Eureka is running open URL [http://localhost:8761]("http://localhost:8761"). You should get page of Eureka service.

### 2.3.3 Configure and run ZipkinService

Build and start the component.
```
$ cd /opt/symbiote/SymbioteCloud/ZipkinService
$ gradle assemble --refresh-dependencies
$ java -jar build/libs/ZipkinService-1.2.0-run.jar
```
 
For checking that Zipkin is running go to URL na [http://localhost:8762]("http://localhost:8762"). You should
get Zipkin service page.

### 2.4 Configuration of cloud components

Before starting symbIoTe Cloud components we need to provide proper configuration in the
_CloudConfigProperties_ component and to be more precise the  _application.properties _file
contained in this component. If you have 
[downloaded](https://github.com/symbiote-h2020/SymbioteCloud/blob/master/README.md#113-getting-all-configuration-files-in-one-zip-optional) from Administration the **.zip** containing the
configuration files, then you can just replace it with file contained in the _CloudConfigProperties_ folder.
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

symbIoTe.core.interface.url=<TODO set properly (format: https://{CoreInterfaceHost}/coreInterface)>
symbIoTe.core.cloud.interface.url=<TODO set properly (format: https://{CloudCoreInterfaceHost}/cloudCoreInterface)>
 
symbIoTe.interworking.interface.url=<TODO set properly (format: http://{HostName}:{nginx_port}/cloudCoreInterface)>
symbIoTe.localaam.url=<TODO set properly (format: https://{HostName}:{nginx_port}/paam)> 
```
 

For our example here are the values in application.properties:

```
#################################################################
## Platform config
#################################################################

platform.id=xplatform

#################################################################
## AMQP config
#################################################################

rabbit.host=localhost
rabbit.username=guest
rabbit.password=guest

#################################################################
## SymbIoTe Security Config
#################################################################

symbIoTe.core.interface.url=https://symbiote-ext.man.poznan.pl/coreInterface
symbIoTe.core.cloud.interface.url=https://symbiote-ext.man.poznan.pl/cloudCoreInterface
 
# production
symbIoTe.interworking.interface.url=https://symbiotedoc.tel.fer.hr/cloudCoreInterface 
# hackaton
# symbIoTe.interworking.interface.url=https://b2cb3e08.ngrok.io
symbIoTe.localaam.url=http://localhost:8080 
```

_Hint: Some people like to run the same jar on different machines (think development vs. production here).
 This often means different settings for the different machines._


### 2.5 Setting up the Platform Authentication and Authorization Manager (PAAM)

In order to configure PAAM we need new certificates in new keystore. Certificates needs to be created by
using SymbIoTeSecurity.

#### 2.5.1 Creating PAAM certificate keystore

1.  Open [https://jitpack.io/#symbiote-h2020/SymbIoTeSecurity]("https://jitpack.io/#symbiote-h2020/SymbIoTeSecurity")
2.  At the time of writhing this document latest release is e.g. 25.1.0
3.  Download JAR from link that is release dependent e.g. [https://jitpack.io/com/github/symbiote-h2020/SymbIoTeSecurity/25.1.0/SymbIoTeSecurity-25.1.0-helper.jar]("https://jitpack.io/com/github/symbiote-h2020/SymbIoTeSecurity/25.1.0/SymbIoTeSecurity-25.1.0.jar") 
4.  If you have [downloaded](https://github.com/symbiote-h2020/SymbioteCloud/blob/master/README.md#113-getting-all-configuration-files-in-one-zip-optional)
    from the Administration the **.zip** containing the configuration files, then you can use the **cert.properties** file contained
    in the _AuthenticationAuthorizationManager_ folder.  Otherwise, you will have to create it yourselves with
    the following content:
```
# From CloudConfigProperties application.properties file: symbIoTe.core.interface.url
coreAAMAddress=<url to core aam - caam>
    
# The user registered through administration in the symbIoTe Core
serviceOwnerUsername=<core account>
serviceOwnerPassword=<core account>
    
# The platform ID registered to the given platform Owner
serviceId=<platform id>
    
# Generated keystore file name
keyStoreFileName=<file URL to paam-keystore.p12>
    
# used to access the keystore. MUST NOT be longer than 7 chars
# from spring bootstrap file: aam.security.KEY\_STORE\_PASSWORD
# Further more as the Java security package is working totally against the API - ignores the privateKeyPassword.
# IT MUST BE THE SAME as spring bootstrap file: aam.security.PV\_KEY\_PASSWORD
keyStorePassword=<e.g. pass>
    
# platform AAM key/certificate alias... case INSENSITIVE (all lowercase)
# from spring bootstrap file: aam.security.CERTIFICATE_ALIAS
aamCertificateAlias=<e.g. paam>
    
# root CA certificate alias... case INSENSITIVE (all lowercase)
# from spring bootstrap file:  aam.security.ROOT\_CA\_CERTIFICATE_ALIAS
rootCACertificateAlias=<e.g. caam>
```

For our concrete example here is that file:

```
# From CloudConfigProperties application.properties file: symbIoTe.core.interface.url
coreAAMAddress=https://symbiote-ext.man.poznan.pl/coreInterface
    
# The user registered through administration in the symbIoTe Core
serviceOwnerUsername=mytest
serviceOwnerPassword=mytest
    
# The platform ID registered to the given platform Owner
serviceId=xplatform
    
# Generated keystore file name
keyStoreFileName=paam-keystore.p12
    
# used to access the keystore. MUST NOT be longer than 7 chars
# from spring bootstrap file: aam.security.KEY\_STORE\_PASSWORD
# Further more as the Java security package is working totally against the API - ignores the privateKeyPassword. 
# IT MUST BE THE SAME as spring bootstrap file: aam.security.PV\_KEY\_PASSWORD
keyStorePassword=pass
    
# platform AAM key/certificate alias... case INSENSITIVE (all lowercase)
# from spring bootstrap file: aam.security.CERTIFICATE_ALIAS
aamCertificateAlias=paam
    
# root CA certificate alias... case INSENSITIVE (all lowercase)
# from spring bootstrap file:  aam.security.ROOT\_CA\_CERTIFICATE_ALIAS
rootCACertificateAlias=caam
```

5. Start generation of certificate. **NOTE:** Version of Java that is tested works with this is 1.8.0\_15x.
We have encountered problems with 1.8.0\_14x and 1.8.0_16x. This can be executed on another machine and
afterwords generated file copied on production machine:
```
java -jar SymbIoTeSecurity-25.1.0-helper.jar cert.properties
```
If everything is OK it will generate **paam-keystore.p12** file.
    

#### 2.5.2 Configuring the PAAM component

Build the AAM module using command:
```
$ cd /opt/symbiote/SymbioteCloud/AuthenticationAuthorizationManager
$ gradle assemble --refresh-dependencies
```
 
Once one has done previous actions, you need to create **bootstrap.properties**. If you have 
[downloaded](https://github.com/symbiote-h2020/SymbioteCloud/blob/master/README.md#113-getting-all-configuration-files-in-one-zip-optional)
the **.zip** with the configuration files, you can use the_ bootstrap.properties_ file inside the _AAM_ folder.
Otherwise, you have to edit manually for each deployment using the template below or comments from the file
itself.

```
# REQUIRED SETTINGS:
spring.profiles.active=platform

spring.application.name=AuthenticationAuthorizationManager
logging.file=logs/AuthenticationAuthorizationManager.log

#in case of standalone AAM, cloud config should not be enabled
spring.cloud.config.enabled=true
spring.cloud.config.failFast=true
spring.cloud.config.retry.maxAttempts=1000

# username and password of the AAM module (of your choice) -- master password used to manage your AAM (e.g. register new users), not your PO credentials!
aam.deployment.owner.username=TODO
aam.deployment.owner.password=TODO

# name of the PAAM JavaKeyStore file you you generated with helper
aam.security.KEY\_STORE\_FILE_NAME=file://TODO.p12

# name of the root ca certificate entry in the generated Symbiote Keystore
aam.security.ROOT\_CA\_CERTIFICATE_ALIAS=TODO

# name of the certificate entry in the generated Symbiote Keystore
aam.security.CERTIFICATE_ALIAS=TODO

# symbiote keystore password
aam.security.KEY\_STORE\_PASSWORD=TODO

# symbiote certificate private key password
aam.security.PV\_KEY\_PASSWORD=pass

#JWT validity time in milliseconds - how long the tokens issued to your users (apps) 
#are valid... think maybe of an hour, day, week?
aam.deployment.token.validityMillis=86400000

# allowing offline validation of foreign tokens by signature trust-chain only. Useful when foreign tokens are expected 
# to be used along with no internet access
aam.deployment.validation.allow-offline=false
```

A concrete example of configuration is:
```
# REQUIRED SETTINGS:
spring.profiles.active=platform

spring.application.name=AuthenticationAuthorizationManager
logging.file=logs/AuthenticationAuthorizationManager.log


#in case of standalone AAM, cloud config should not be enabled
spring.cloud.config.enabled=true
spring.cloud.config.failFast=true
spring.cloud.config.retry.maxAttempts=1000

# AAM settings
aam.deployment.owner.username=masterPaamUsername
aam.deployment.owner.password=masterPaamPassword

# name of the PAAM JavaKeyStore file you need to put in your src/main/resources directory
aam.security.KEY\_STORE\_FILE_NAME=file://#{systemProperties\['user.dir'\]}/paam-keystore.p12

# name of the root ca certificate entry in the generated Symbiote Keystore
aam.security.ROOT\_CA\_CERTIFICATE_ALIAS=caam

# name of the certificate entry in the generated Symbiote Keystore
aam.security.CERTIFICATE_ALIAS=paam

# symbiote keystore password
aam.security.KEY\_STORE\_PASSWORD=pass

# symbiote certificate private key password
aam.security.PV\_KEY\_PASSWORD=pass

#JWT validity time in milliseconds - how long the tokens issued to your users (apps) 
#are valid... think maybe of an hour, day, week?
aam.deployment.token.validityMillis=86400000

# allowing offline validation of foreign tokens by signature trust-chain only. Useful when foreign tokens are expected 
# to be used along with no internet access
aam.deployment.validation.allow-offline=false
```

The most recent version of AAM is 3.+. So to run example use:
```
$ java -jar AuthenticationAuthorizationManager-3.1.0-run.jar
```
 

#### 2.5.3 Verifying that Platform AAM is working

Verify all is ok by going to: [http://localhost:8080/get\_available\_aams]("http://localhost:8080/get_available_aams"). If everything is OK there you should see the connection green and the content are the symbiote security endpoints fetched from the core.

#### 2.5.4 Verifying that InterworkingInterface is working

Verify all is ok by going to: https://<yourNginxHostname>/paam/get\_available\_aams

Concrete:

*   production: [https://symbiotedoc.tel.fer.hr/paam/get\_available\_aams]("https://symbiotedoc.tel.fer.hr/paam/get_available_aams") 
*   hackaton: [https://c879081a.ngrok.io/paam/get\_available\_aams]("https://c879081a.ngrok.io/paam/get_available_aams") 

There you should see the the same results as in section [2.5.3]("#symbIoTeplatformL1integration(Release1.2.0)-2.5.3").

### 2.6 Starting Registration Handler and resource management

#### 2.6.1. Creating configuration for accessing PAAM

If you have [downloaded](https://github.com/symbiote-h2020/SymbioteCloud/blob/master/README.md#113-getting-all-configuration-files-in-one-zip-optional) 
from Administration the **.zip** containing the configuration files, then you can
use the ****bootstrap**.properties** file contained in the _RegistrationHandler_ folder. 
You just need to move it to the Registration Handler directory. Otherwise, you will have to create it 
yourselves with the following content:

```
# The credentials of the Platform Owner account in the PAAM
symbIoTe.component.username=TODO
symbIoTe.component.password=TODO

# Keystore configuration
symbIoTe.component.keystore.path=keystore.jks
symbIoTe.component.keystore.password=pass
```

This is concrete file for our example:

```
# The credentials of the Platform Owner account in the PAAM
symbIoTe.component.username=masterPaamUsername
symbIoTe.component.password=masterPaamPassword

# Keystore configuration
symbIoTe.component.keystore.path=keystore.jks
symbIoTe.component.keystore.password=pass
```
 

 

#### 2.6.2. Building and starting RH

Build and start Registration Handler as any other Symbiote component.

```
$ cd /opt/symbiote/SymbioteCloud/RegistrationHandler
$ gradle assemble --refresh-dependencies
$ java -jar build/libs/RegistrationHandler-1.2.0-run.jar
```
 

If you start all components in one script then it is important order of starting components and that some of
then are fish starting before others because some of them are dependent on function of others on startup.
For example, *RegistrationnHandler* must be started after *AuthenticationAuthorizationManager* is started.
The same applies to *ResourceAccessProxy*. There are two ways to configure them to start after others:

1.  Environment variables - set following environment variable:
    *   **SPRING\_BOOT\_WAIT\_FOR\_SERVICES=localhost:8080**
2.  Command line options:
    *   java **-DSPRING\_BOOT\_WAIT\_FOR\_SERVICES="localhost:8080"** -jar build/libs/RegistrationHandler-1.2.0-run.jar

When the service is started it will try to connect to specified host and port and retry it after 1 second.
It will repeat it for 1000 times for each specified service. After it can connect to that port it will continue
with starting of service. The format for value is **"host1:port1;host2:port2;..."**


For testing if service is working as expected open [http://localhost:8001/resources]("http://localhost:8001/resources").
You should get empty JSON array because no resource is registered. You can access it over NGINX:

1.  Production - [http://sybiotedoc.tel.fer.hr/rh/resources]("http://sybiotedoc.tel.fer.hr/rh/resources")
2.  Hackaton - [https://b2cb3e08.ngrok.io/rh/resources]("https://b2cb3e08.ngrok.io/rh/resources") 

### 2.7 Set-up of Resource Access Proxy

Resource Access Proxy (RAP) is the component in charge of accessing to the resources. This requires the 
implementation of a software layer (the RAP platform plugin) in order to allow symbIoTe to be able to 
communicate with the internal mechanisms of the platform. The plugin will communicate with the generic part
of the RAP through the rabbitMQ protocol, in order to decouple the symbIoTe Java implementation from the 
platform specific language. This figure shows the architecture of the RAP component (orange parts on the
bottom are part of the platform specific plugin, to be implemented from platform owners):

![RAP Architecture](https://github.com/symbiote-h2020/SymbioteCloud/blob/master/resources/figures/RAP-arch_v02.png?raw=true "RAP Architecture")

Here a quick list of actions and features that RAP platform specific plugin has to implement:

*   Registers to generic RAP specifying support for filters, notifications
*   Get read / write requests from RAP generic (w/ or w/o filters)
*   Applies filters to =E2=80=98get history=E2=80=99 requests (optional)
*   Actuate actuators
*   Invoke services provided by platform
*   Get subscribe requests from generic RAP (if it supports notifications)
*   Forwards notifications coming from platform to generic RAP

Source, from RAP repository, has already implemented dummy example of RAP plugin with one dummy sensor,
actuator and service. 

There are 3 way to create RAP plugin:

1.  Use dummy plugin already provided in source and extend it with your functionality. This way every time something need to be changed in RAP plugin you have to recompile whole RAP component and redeploy in production environment.
2.  Use RAP plugin starter project. I this way you need to create another SpringBoot component in Java for implementing RAP plugin. You also need to start this new component on the machine that has access to RabbitMQ server.
3.  Implement RabbitMQ communication in any language you want.

All 3 approaches are explained later in this document.

In order to just start RAP and test whole process of installing components and checking that everything is
working we will use approach 1 with default implementation. For this case you need to change the configuration
as explained [here](https://github.com/symbiote-h2020/SymbioteCloud/blob/master/README.md#41-customizing-internal-rap-plugin)

#### 2.7.1 Creating configuration for accessing PAAM

If you have [downloaded](https://github.com/symbiote-h2020/SymbioteCloud/blob/master/README.md#113-getting-all-configuration-files-in-one-zip-optional) 
from Administration the **.zip** containing the configuration files, then you can use
the ****bootstrap**.properties** file contained in the _RegistrationHandler_ folder.  You just need to move
it to the RAP directory. Otherwise, you will have to create it yourselves with the following content:
```
# The credentials of the Platform Owner account in the PAAM
symbIoTe.component.username=TODO
symbIoTe.component.password=TODO

# Keystore configuration
symbIoTe.component.keystore.path=keystore.jks
symbIoTe.component.keystore.password=pass
```

This is concrete file for our example:

```
# The credentials of the Platform Owner account in the PAAM
symbIoTe.component.username=masterPaamUsername
symbIoTe.component.password=masterPaamPassword

# Keystore configuration
symbIoTe.component.keystore.path=keystore.jks
symbIoTe.component.keystore.password=pass
```

#### 2.7.1 Building and starting RAP

Build and start Registration Handler as any other Symbiote component.
```
$ cd /opt/symbiote/SymbioteCloud/ResourceAccessProxy
$ gradle assemble --refresh-dependencies
$ java -jar build/libs/ResourceAccessProxy-1.2.3-run.jar
```
 
If you want to put starting RAP from script and need to wait for PAAM apply same approach as for RH.

### 2.8 Register resources

After symbIoTe Cloud components are configured and configured and are running, we can proceed to expose some of our 
platform's resources to symbIoTe Core. In order to do that resources need to be registered. List of properties that are 
supported in registration JSON for Release 1.2.0 can be found here: 
* [List of properties URIS](https://github.com/symbiote-h2020/SymbioteCloud/tree/master/resources/docs/property_uris)
* [List of property names](https://github.com/symbiote-h2020/SymbioteCloud/tree/master/resources/docs/property_names)
 (to be used in JSON description)

#### 2.8.1 Registering resources by using JSON

This is done by sending _HTTP POST_ request containing resource description on _RegistrationHandler's _registration endpoint (i.e. [http://localhost:8001/resources]("http://localhost:8001/resources")). Exemplary description of registering sensor is shown below:

```
[{
  "internalId": "isen1",
  "pluginId": "platform_01",
  "cloudMonitoringHost": "cloudMonitoringHostIP",
  "accessPolicy": {
    "policyType": "PUBLIC",
    "requiredClaims": {}
  },
  "filteringPolicy": {
    "policyType": "PUBLIC",
    "requiredClaims": {}
  },
  "resource": {
    "@c": ".StationarySensor",
    "name": "DefaultSensor1",
    "description": [
      "Default sensor for testing RAP"
    ],
    "featureOfInterest": {
      "name": "temperature feature of interest",
      "description": [
        "measures temperature"
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
    ],
    "locatedAt": {
      "@c": ".WGS84Location",
      "longitude": 52.513681,
      "latitude": 13.363782,
      "altitude": 15,
      "name": "Berlin",
      "description": [
        "Grosser Tiergarten"
      ]
    },
    "interworkingServiceURL": "https://symbiotedoc.tel.fer.hr/"
  }
}]
```

The main fields of a CloudResource description is the following:

*   `internalId`: the internal (platform-specific) id of the resource that is going to be registered in the core
*   `pluginId`: the id of the RAP plugin which serves this resource. If there is just one plugin, it can be null.
*   `accessPolicy`: the [access policy specifier]("https://github.com/symbiote-h2020/SymbIoTeSecurity/blob/master/src/main/java/eu/h2020/symbiote/security/accesspolicies/common/singletoken/SingleTokenAccessPolicySpecifier.java") which is propagated to the RAP. For the moment, there are specific access policies provided by the symbIoTe framework. Further description of access policies are in documentation of [symbioteSecurity]("https://github.com/symbiote-h2020/SymbIoTeSecurity"). For L1 we support only public access policy as put in example.
*   `filteringPolicy`: same as above, just this is related to filtering policies and is used during Core search for the resources; resource is returned in the search queries only for users with specific filtering policies. For L1 we support only public access policy as put in example.
*   `resource`: the resource description supported in the [symbIoTe Core]("https://github.com/symbiote-h2020/SymbIoTeLibraries/tree/master/src/main/java/eu/h2020/symbiote/model/cim")

***Important Note for registering Resources***

The _interworkingServiceURL_ of each resource should be the same with the _interworkingServiceURL_ specified
during platform registration. Registration handler uses Interworking interface (i.e. nginx) to communicate
with symbIoTe Core to register our platform's resource. If the registration process is successful Core returns
the resource descirption containing _id_ field (we call it symbIoTe id) with unique, generated id of the
resource in the symbIoTe Core layer. Information about the registered resource is distributed in Cloud
components using RabbitMQ messaging.

Following, you can see some examples of registering default resources implemented in internal RAP plugin:

##### 2.8.1.1 Registering default (dummy) sensors

For default implemented sensor resources in RAP send this request by using *curl*:
```
$ curl -X POST \
  http://localhost:8001/resources \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -d '[{
  "internalId": "isen1",
  "pluginId": "platform_01",
  "cloudMonitoringHost": "cloudMonitoringHostIP",
  "accessPolicy": {
    "policyType": "PUBLIC",
    "requiredClaims": {}
  },
  "filteringPolicy": {
    "policyType": "PUBLIC",
    "requiredClaims": {}
  },
  "resource": {
    "@c": ".StationarySensor",
    "name": "DefaultSensor1",
    "description": [
      "Default sensor for testing RAP"
    ],
    "featureOfInterest": {
      "name": "temperature feature of interest",
      "description": [
        "measures temperature"
      ],
      "hasProperty": [
        "temperature"
      ]
    },
    "observesProperty": [
      "temperature"
    ],
    "locatedAt": {
      "@c": ".WGS84Location",
      "longitude": 52.513681,
      "latitude": 13.363782,
      "altitude": 15,
      "name": "Berlin",
      "description": [
        "Grosser Tiergarten"
      ]
    },
    "interworkingServiceURL": "https://symbiotedoc.tel.fer.hr/"
  }
}]'
```

Expected response is _200 OK_ with following body:
```
[
    {
        "internalId": "isen1",
        "pluginId": "platform_01",
        "accessPolicy": {
            "policyType": "PUBLIC",
            "requiredClaims": {}
        },
        "filteringPolicy": {
            "policyType": "PUBLIC",
            "requiredClaims": {}
        },
        "resource": {
            "@c": ".StationarySensor",
            "observesProperty": [
                "temperature"
            ],
            "id": "5ab2d2d84a234e2a27f35a80",
            "name": "DefaultSensor1",
            "description": [
                "Default sensor for testing RAP"
            ],
            "interworkingServiceURL": "https://symbiotedoc.tel.fer.hr",
            "locatedAt": {
                "@c": ".WGS84Location",
                "longitude": 52.513681,
                "latitude": 13.363782,
                "altitude": 15,
                "name": "Berlin",
                "description": [
                    "Grosser Tiergarten"
                ]
            },
            "services": null,
            "featureOfInterest": {
                "name": "temperature feature of interest",
                "description": [
                    "measures temperature"
                ],
                "hasProperty": [
                    "temperature"
                ]
            }
        },
        "federationInfo": null
    }
]
```

From this response we can see that this resource has got following symbiote id: *5ab2d2d84a234e2a27f35a80*.

##### 2.8.1.2 Registering default (dummy) actuators

Request for registration of actuator looks like this:
```
$ curl -X POST \
  http://localhost:8001/resources \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -d '[
    {
        "internalId": "iaid1",
        "pluginId": "platform_01",
        "cloudMonitoringHost": "cloudMonitoringHostIP",
        "accessPolicy": {
            "policyType": "PUBLIC",
            "requiredClaims": {}
        },
        "filteringPolicy": {
            "policyType": "PUBLIC",
            "requiredClaims": {}
        },
        "resource": {
            "@c": ".Actuator",
            "name": "Light 1",
            "description": [
                "This is light 1"
            ],
            "services": null,
            "capabilities": [
                {
                    "name": "OnOffCapabililty",
                    "parameters": [
                        {
                            "name": "on",
                            "mandatory": true,
                            "datatype": {
                                "@c": ".PrimitiveDatatype",
                                "baseDatatype": "boolean"
                            }
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
            "interworkingServiceURL": "https://symbiotedoc.tel.fer.hr"
        }
    }
]'
```

##### 2.8.1.3 Registering default (dummy) service

Request for registration of service looks like this:
```
curl -X POST \
  http://localhost:8001/resources \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -d '[
    {
        "internalId": "isrid1",
        "pluginId": "platform_01",
        "cloudMonitoringHost": "cloudMonitoringHostIP",
        "accessPolicy": {
            "policyType": "PUBLIC",
            "requiredClaims": {}
        },
        "filteringPolicy": {
            "policyType": "PUBLIC",
            "requiredClaims": {}
        },
        "resource": {
            "@c": ".Service",
            "name": "Light service 1",
            "description": [
                "This is light service 1"
            ],
            "interworkingServiceURL": "https://symbiotedoc.tel.fer.hr",
            "parameters": [
                {
                    "name": "inputParam1",
                    "mandatory": true,
                    "restrictions": [
                        {
                            "@c": ".LengthRestriction",
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
    }
]'
```

#### 2.8.2. Registering resources by using JSON representation of RDF

It is also possible to register resources using rdf. This is done by sending _HTTP POST_ request
containing rdf resource description on _RegistrationHandler's _registration endpoint
(i.e. [http://localhost:8001/rdf-resources]("http://localhost:8001/rdf-resources")). The body of the message
should be the following:

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

*   idMappings: a map which has as keys the RDF id of the resource and as values the CloudResource
    description (as in the resource registration using plain json)
*   rdfInfo: contains the consolidated rdf description of all the resources and specifies the rdfFormat.
    Accepted formats can be found [here]("https://github.com/symbiote-h2020/SymbIoTeLibraries/blob/develop/src/main/java/eu/h2020/symbiote/core/internal/RDFFormat.java")

#### 2.8.3 Update resources

After registering resources, it is also possible to update them. To do so, you can send an _HTTP POST_ request
to the same endpoint (i.e. [http://localhost:8001/rdf-resources]("http://localhost:8001/")) containing the
same JSON payload as in the previous request. If the resource has not been registered previously, it will be
automatically registered. However, it is not possible to update a resource using rdf. 

Hint: If you do not do any bookkeeping of what you already registered and what not you can query the
registration handler about the resources it knows. Submit a GET request to the URL ***regHandlerBase + "/resources"***
(e.g. [http://localhost:8001/resources]("http://localhost:8001/resources"))

#### 2.8.4 Delete resources

After registering resources, it is also possible to delete them. This is done by sending _HTTP DELETE_ request
containing the_ internal ids_ on _ResourceHandler's delete_ endpoint
(e.g. [http://localhost:8001/resources?resourceInternalId=isen1,isen2]("http://localhost:8001/resources?resourceInternalId=isen1,isen2")).

#### 2.8.5 Out-of-Sync-Problem with the core

The registration handler maintains a local database of resources known to it. It also forwards any
register/update/delete request to the core. Experience has shown that this strategy is fragile and tends
to cause the core's database getting out of sync with the local one. In order to sync resources in local
database and in core invoke _HTTP PUT_ to the following endpoint
[http://localhost:8001/sync]("http://localhost:8001/sync"). 


### 2.9 Other configuration topics

#### 2.9.1 Platform AAM management

To manage your local users you can use the AMQP API listening on:
```
rabbit.queue.manage.user.request=symbIoTe-AuthenticationAuthorizationManager-manage\_user\_request
rabbit.routingKey.manage.user.request=symbIoTe.AuthenticationAuthorizationManager.manage\_user\_request
```
 

With the following contents:

| **Request payload**                                                                                                                                                                                                                                                                                                                                                                                    | **Response**                                                                                                                                                     |
|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| <div> OperationType#CREATE  [UserManagementRequest](https://github.com/symbiote-h2020/SymbIoTeSecurity/blob/develop/src/main/java/eu/h2020/symbiote/security/communication/payloads/UserManagementRequest.java) <ul><li> admin credentials // for operation authorization</li><li>user credentials (username, password) </li><li>user details (recovery mail, federated ID)</li></ul></div>                                                             | [ManagementStatus](https://github.com/symbiote-h2020/SymbIoTeSecurity/blob/develop/src/main/java/eu/h2020/symbiote/security/commons/enums/ManagementStatus.java) |
| <div> OperationType#UPDATE  [UserManagementRequest](https://github.com/symbiote-h2020/SymbIoTeSecurity/blob/develop/src/main/java/eu/h2020/symbiote/security/communication/payloads/UserManagementRequest.java) <ul><li>admin credentials // for operation authorization </li><li> user credentials // for operation authorization </li><li>user credentials (password to store new password) </li><li>user details (recovery mail, federated ID)</li></ul></div> | [ManagementStatus](https://github.com/symbiote-h2020/SymbIoTeSecurity/blob/develop/src/main/java/eu/h2020/symbiote/security/commons/enums/ManagementStatus.java) |
| <div> OperationType#DELETE  [UserManagementRequest](https://github.com/symbiote-h2020/SymbIoTeSecurity/blob/develop/src/main/java/eu/h2020/symbiote/security/communication/payloads/UserManagementRequest.java) <ul><li>admin credentials // for operation authorization</li><li> user credentials (username to find user in repository)</li></ul></div>                                                                                       | [ManagementStatus](https://github.com/symbiote-h2020/SymbIoTeSecurity/blob/develop/src/main/java/eu/h2020/symbiote/security/commons/enums/ManagementStatus.java) |
| <div> OperationType#FORCED_UPDATE  [UserManagementRequest](https://github.com/symbiote-h2020/SymbIoTeSecurity/blob/develop/src/main/java/eu/h2020/symbiote/security/communication/payloads/UserManagementRequest.java) mandatory fields<ul><li>admin credentials // for operation authorization</li><li>user credentials (username to resolve user, password to store new password)</li></ul></div> | [ManagementStatus](https://github.com/symbiote-h2020/SymbIoTeSecurity/blob/develop/src/main/java/eu/h2020/symbiote/security/commons/enums/ManagementStatus.java) | 
  
## 3 Test integrated resource

After our resource have been shared with Core we can test if we can find and access it properly.

### 3.1 Security

In order to be served by Core (search, ...) or Cloud (read sensor data, actuate, invoke service) you need to
put security headers in requests.

#### 3.1.1 Getting security headers for GUEST users

We briefly show how the clients can acquire GUEST credentials required to search and access PUBLIC resources in
SymbIoTe. First comes the generic part for developers that don't want to use our Java implementation and
afterwards the tutorial using our reference Java codes for
[symbioteSecurity library]("https://github.com/symbiote-h2020/SymbIoTeSecurity").

##### 3.1.1.1  Acquire a GUEST Token

To acquire a GUEST Token, send empty HTTP POST request on:
```
https://<coreInterfaceAdress>/get_guest_token
```

or

```
https://<platformInterworkingInterface>/paam/get_guest_token
```
 
, depending on which platform you want to acquire the GUEST token from. Please be aware that either of them
has the same authorization power. In return you will get empty response which header _x-auth-token_ contains
your GUEST token.

##### 3.1.1.2. Create Security Request

Result from previous step is used to create headers in HTTP requests for searching or accessing resources.

To make use of your GUEST token you need to wrap it into our SecurityRequest. For standardized communication,
we deploy it into the following HTTP headers:

*   current timestamp in miliseconds goes into header
    *   x-auth-timestamp
*   don't change just include
    *   x-auth-size=1
*   special JSON structure
    *   under header x-auth-1
    *   containing populated field:
        *   "token":"HERE\_COMES\_THE\_TOKEN\_STRING",
    *   and empty fields which you don't need to care about, just put the there:
        *   "authenticationChallenge":"",
        *   "clientCertificate":"",
        *   "clientCertificateSigningAAMCertificate":"",
        *   "foreignTokenIssuingAAMCertificate":""

Example:

```
x-auth-timestamp: 1519652051000
x-auth-size: 1
x-auth-1:
{
    "token":"eyJhbGciOiJFUzI1NiJ9.eyJ0dHlwIjoiR1VFU1QiLCJzdWIiOiJndWVzdCIsImlwayI6Ik1GaFd1lIS29aSXpqMENBUVlJS29aSXpqMERBUWNEUWdBRVBhZURDNElnT3VITlBmWCtURG5adXZuTHdUbHMwMERQb294aVZCTE8za3I0N0N3TXFYSm4yN3lpdFdZUkRRKzBmWG52MzFIbGJLbkxSWktqSmF5U3p3PT0iLCJpc3MiOiJTeW1iSW9UZV9Db3JlX0FBTSIsImV4cCI6MTUxMDU2Nzg2NywiaWF0IjoxNTEwNTY3MjY3LCJqdGkiOiI2MzI4NDUxMzAiLCJzcGsiOiJNRmt3RXdZSEtvWkl6ajBDQVFZSUtvWkl6ajBEQVFjRFFnQUVsdlNwYVhDa2RFZ3lYM2xJeWQ1VCs2VFgyQ0hXMDluekNjL05aY2krcGEvdmtQSG5DeFZESkpLTkZwL1hQc0g2T1hvSTkxQXJFcUJ1SlJtd3k2dWZSdz09In0.zn7xjwUq89YSNptLTFCZSpb8n65n4o24HPOw2WPTJSglfaO8paW1O5vC3n9072ktm327kj44Kgs5qqMhRy22cA",
    "authenticationChallenge":"",
    "clientCertificate":"",
    "clientCertificateSigningAAMCertificate":"",
    "foreignTokenIssuingAAMCertificate":"" 
}
```

With such prepared headers you can access SymbIoTe resources offered publicly, e.g. execute search queries
or send request to Resource Access Proxy.

##### 3.1.2.1 Access to public resources for Java developers

The following snippet generates the security headers

```
// creating REST client communicating with SymbIoTe Authorization Services 
// AAMServerAddress can be acquired from SymbIoTe web page
IAAMClient restClient = ClientFactory.getAAMClient(AAMServerAddress);

// acquiring Guest Token
String guestToken = restClient.getGuestToken();

// creating securityRequest using guest Token
SecurityRequest securityRequest = new SecurityRequest(guestToken);

// converting the prepared request into communication ready HTTP headers.
Map<String, String> securityHeaders = new HashMap<>();
securityHeaders = securityRequest.getSecurityRequestHeaderParams();
```

With these headers containing your GUEST token you can use SymbIoTe APIs to access public resources. It can be
also acquired in the following way, using end user Java client described here:
```
// Initializing application security handler 
ISecurityHandler clientSH = ClientSecurityHandlerFactory.getSecurityHandler( 
			coreAAMServerAddress, 
			KEY_STORE_PATH, 
			KEY_STORE_PASSWORD, 
			clientId ); 
// examples how to retrieve AAM instances 
AAM coreAAM = clientSH.getCoreAAMInstance(); 
AAM platform1 = clientSH.getAvailableAAMs().get(platformId); 


// Acquiring GUEST token from platform1 
Token guestToken = clientSH.loginAsGuest(platform1); 


// creating securityRequest using guest Token 
SecurityRequest securityRequest = new SecurityRequest(guestToken); 


// converting the prepared request into communication ready HTTP headers. 
Map<String, String> securityHeaders = new HashMap<>(); 
securityHeaders = securityRequest.getSecurityRequestHeaderParams();
``` 

Then, after receiving the response from a SymbIoTe component, you should check if it came from component you
are interested. To do that you can use the following snippet

```
// trying to validate the service response 
MutualAuthenticationHelper.isServiceResponseVerified(serviceResponse,
    restClient.getComponentCertificate(componentIdentifier, platformIdentifier));
```

, where the componentIdentifier can be read from the table available [here](https://github.com/symbiote-h2020/SymbIoTeSecurity/tree/develop#component_table).

### 3.2 Search for resource

#### 3.2.1 Searching by configurable query

To search for resource we need to create a query to the symbIoTe Core. In our example we use
[https://symbiote-ext.man.poznan.pl/coreInterface/query]("https://symbiote-ext.man.poznan.pl/coreInterface/query") 
endpoint and provide parameters for querying. Requests need properly generated security headers. 
More on topic of secure access to symbIoTe component can be read on SymbIoTeSecurity project page
[https://github.com/symbiote-h2020/SymbIoTeSecurity]("https://github.com/symbiote-h2020/SymbIoTeSecurity"). 

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
         resource_type: 		String
         should_rank:           Boolean
}
```
 

_**NOTE1**_      
To query using geospatial properties, all 3 properties need to be set: _location_lat_ 
(latitude), _location_long_ (longitude) and _max_distance_ (distance from specified point in meters).

_**NOTE2**_       
Text parameters allow substring searches using '*' character which can be placed at the 
beginning and/or end of the word to search for. For example querying for name "_Sensor*"_ finds all resources
with name starting with _Sensor,_ and search for name "\*12\*" will find all resources containing string "12"
in its name. Using substring search can be done for the following fields:

*   name
*   platform_name
*   owner
*   description
*   location_name
*   observed_property

_**NOTE3**_      
The _should_rank_ parameter can be set to enable ranking of the resources from the response. This
allows currently available and popular resources to be returned with higher ranking than others. Also, if
geolocation point is used in the query resources closer to the point of interest are returned with higher
ranking.

For our example, let's search for resources with name _Stationary 1_. We do it by sending a  _HTTP GET_
request on symbIoTe Core Interface ([https://symbiote-ext.man.poznan.pl/coreInterface/query?name=Stationary1]("http://symbiote-ext.man.poznan.pl/coreInterface/query?name=Stationary1")). Response contains a list of resources fulfilling the criteria:

```
{
  "resources": [
    {
      "platformId": "test1Plat",
      "platformName": "Test 1 Plat",
      "owner": null,
      "name": "Stationary1",   
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
      "ranking": 0.2
     }
  ]
}

```

#### 3.2.2 SPARQL query endpoint

Starting with Release 0.2.1, an additional endpoint was created to allow sending SPARQL queries to symbIoTe
Core. To send SPARQL requests we need to send request by using _HTTP POST_ to the url:   
`https://symbiote-ext.man.poznan.pl/coreInterface/sparqlQuery`

The endpoint accepts the following payload:
```
{ 
    "sparqlQuery" : "<sparql>",
    "outputFormat" : "<format>"
    
}
```
 

Possible output formats include: SRX, **XML**, **JSON**, SRJ, SRT, THRIFT, SSE, **CSV**, TSV, SRB, **TEXT****,** COUNT,
TUPLES, NONE, RDF, RDF_N3, RDF_XML, N3, **TTL**, **TURTLE,** GRAPH, NT, N_TRIPLES, TRIG.

SPARQL allows for powerful access to all the meta information stored within symbIoTe Core. Below, you can
find few example queries

**Query all resources of the core**

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
**Query for Services and display information about input they are requiring: name and datatype**

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


### 3.3 Obtaining resource access URL

To access the resource we need to ask symbIoTe Core for the access link. To do so we need to send _HTTP GET_
request on:    
`https://symbiote-ext.man.poznan.pl/coreInterface/resourceUrls`    
, with ids of the resources as parameters. For our example we want urls of 2 resources,
so request looks like: 

`https://symbiote-ext.man.poznan.pl/coreInterface/resourceUrls?id=589dc62a9bdddb2d2a7ggab8,589dc62a9bdddb2d2a7ggab9`.      
To access the endpoint we need to specify security headers, as described in 
[SymbIoTeSecurity](https://github.com/symbiote-h2020/SymbIoTeSecurity).


#### 3.3.1 Get the resource urls

If we provide correct ids of the resources along with a valid security credentials in the header, we will
get a response containing URLs to access the resources:
```
{ 
    "589dc62a9bdddb2d2a7ggab8": "https://symbiotedoc.tel.fer.hr/rap/Sensors('589dc62a9bdddb2d2a7ggab8')",
    "589dc62a9bdddb2d2a7ggab9": "https://symbiotedoc.tel.fer.hr/rap/Sensors('589dc62a9bdddb2d2a7ggab9')"
}
```

### 3.4 Accessing the resource and actuating and invoking service for default (dummy) resources

In order to access the resources, you need to create a valid Security Request. For that,
you can either intergrate the Security Handler offered by the symbIoTe framework 
(implemented in Java) or develop a custom implementation for creating the Security Request. More information can be found in
[SymbIoTeSecurity](https://github.com/symbiote-h2020/SymbIoTeSecurity) repository.

RAP is configured to support accessing data by using OData.

The applications can:

1.  Read current value from resource
2.  Read history values from resource
3.  Actuate resource
4.  Invoking service

RAP also supports push mechanism when new data for some resource is available.

#### 3.4.1 Reading current value

In order to read data of some resource you will need to get resource access URL from previous step. 
To create URL for reading current value add to the end _/Observations?$top=1_

Example:

*   received URL: https://symbiotedoc.tel.fer.hr/rap/Sensors('589dc62a9bdddb2d2a7ggab8')
*   created URL: https://symbiotedoc.tel.fer.hr/rap/Sensors('589dc62a9bdddb2d2a7ggab8')_/Observations?$top=1_

Then you can send GET request to generated URL. 

***NOTE:***   
You have to include security headers (see [here](https://github.com/symbiote-h2020/SymbioteCloud/blob/master/README.md#311-getting-security-headers-for-guest-users).

### 3.4.2 Reading historical data

Reading historical data is done the same way as reading current value. The only difference is the value
of ***$top*** should be changed to value more then 1. ***$top*** is a filter that filters historical results
by returning top n readings. Historical readings can be filtered by using another option ***_$filter***.
It support operators as well. Supported operators are: 

1.  Equals
2.  Not Equals
3.  Less Than
4.  Greater Than
5.  And
6.  Or

The following is an example of a OData query that gets the last 30 Observations that has been made in Rome:

```
http://symbiotedoc.tel.fer.hr/rap/Sensor('589dc62a9bdddb2d2a7ggab8')/Observations?$top=30&filter=madeFrom/name eq 'Rome'
```
 
The complete request reading default (dummy) sensor in RAP will be:

```
curl -X GET \
  'http://symbiotedoc.tel.fer.hr/rap/Sensor(\'589dc62a9bdddb2d2a7ggab8\')/Observations?$top=30&filter=madeFrom/name eq \'Rome\'' \
  -H 'x-auth-timestamp: 1519652051000' \
  -H 'x-auth-size: 1' \
  -H 'x-auth-1: {"token":"eyJhbGciOiJFUzI1NiJ9.eyJ0dHlwIjoiR1VFU1QiLCJzdWIiOiJndWVzdCIsImlwayI6Ik1Ga3dFd1lIS29aSXpqMENBUVlJS29aSXpqMERBUWNEUWdBRVBhZURDNElnT3VITlBmWCtURG5adXZuTHdUbHMwMERQb294aVZCTE8za3I0N0N3TXFYSm4yN3lpdFdZUkRRKzBmWG52MzFIbGJLbkxSWktqSmF5U3p3PT0iLCJpc3MiOiJTeW1iSW9UZV9Db3JlX0FBTSIsImV4cCI6MTUxMDU2Nzg2NywiaWF0IjoxNTEwNTY3MjY3LCJqdGkiOiI2MzI4NDUxMzAiLCJzcGsiOiJNRmt3RXdZSEtvWkl6ajBDQVFZSUtvWkl6ajBEQVFjRFFnQUVsdlNwYVhDa2RFZ3lYM2xJeWQ1VCs2VFgyQ0hXMDluekNjL05aY2krcGEvdmtQSG5DeFZESkpLTkZwL1hQc0g2T1hvSTkxQXJFcUJ1SlJtd3k2dWZSdz09In0.zn7xjwUq89YSNptLTFCZSpb8n65n4o24HPOw2WPTJSglfaO8paW1O5vC3n9072ktm327kj44Kgs5qqMhRy22cA", "authenticationChallenge":"", "clientCertificate":"", "clientCertificateSigningAAMCertificate":"", "foreignTokenIssuingAAMCertificate":"" }'
```

#### 3.4.3 Actuating resource

Some resources are registered as actuators. In that case actuation can be triggered by _HTTP PUT_ to resource
access URL. In the body of such request should be JSON body with capability and parameters. The following is
generic example:

```
{
    "capabilityName":
    [ 
        {
             "paramName1": value1,
        },
        {
             "paramName2": value2,
        },
        …
    ]
}
``` 

Values of capabilities, parameters and values need to be used according to model of resource. The model of
resource is defined during registration.

Concrete example of request actuating default (dummy) actuator in RAP is:

```
curl -X PUT \
  'https://symbiotedoc.tel.fer.hr/rap/Actuators('\''5ab5deec4a234e7173807226'\'')' \
  -H 'x-auth-timestamp: 1519652051000' \
  -H 'x-auth-size: 1' \
  -H 'x-auth-1: {"token":"eyJhbGciOiJFUzI1NiJ9.eyJ0dHlwIjoiR1VFU1QiLCJzdWIiOiJndWVzdCIsImlwayI6Ik1Ga3dFd1lIS29aSXpqMENBUVlJS29aSXpqMERBUWNEUWdBRVBhZURDNElnT3VITlBmWCtURG5adXZuTHdUbHMwMERQb294aVZCTE8za3I0N0N3TXFYSm4yN3lpdFdZUkRRKzBmWG52MzFIbGJLbkxSWktqSmF5U3p3PT0iLCJpc3MiOiJTeW1iSW9UZV9Db3JlX0FBTSIsImV4cCI6MTUxMDU2Nzg2NywiaWF0IjoxNTEwNTY3MjY3LCJqdGkiOiI2MzI4NDUxMzAiLCJzcGsiOiJNRmt3RXdZSEtvWkl6ajBDQVFZSUtvWkl6ajBEQVFjRFFnQUVsdlNwYVhDa2RFZ3lYM2xJeWQ1VCs2VFgyQ0hXMDluekNjL05aY2krcGEvdmtQSG5DeFZESkpLTkZwL1hQc0g2T1hvSTkxQXJFcUJ1SlJtd3k2dWZSdz09In0.zn7xjwUq89YSNptLTFCZSpb8n65n4o24HPOw2WPTJSglfaO8paW1O5vC3n9072ktm327kj44Kgs5qqMhRy22cA", "authenticationChallenge":"", "clientCertificate":"", "clientCertificateSigningAAMCertificate":"","foreignTokenIssuingAAMCertificate":"" }' \
  -d '{
  "OnOffCapabililty" : [
    {
      "on" : true
    }
  ]
}'
```

If actuation is successful response code will be 204 and response body is empty. Otherwise, response code
will return error and body will explain problem.

### 3.4.4 Invoking service

Some resources are registered as services. In that case invoking service can be triggered by _HTTP PUT_ to
resource access URL. In the body of such request should be JSON body with array of parameters. The following
is generic example:

```
[
    {
        "paramName1" : value1
    },
    {
        "paramName2" : value2
    },
    …
]
```

Parameters and values need to be used according to model of resource. The model of resource is defined
during registration. Concrete example of request invoking default (dummy) service in RAP is:
```
curl -X POST \
  'https://symbiotedoc.tel.fer.hr/rap/Services('\''5ab5db974a234e717380721f'\'')' \
  -H 'x-auth-timestamp: 1519652051000' \
  -H 'x-auth-size: 1' \
  -H 'x-auth-1: {"token":"eyJhbGciOiJFUzI1NiJ9.eyJ0dHlwIjoiR1VFU1QiLCJzdWIiOiJndWVzdCIsImlwayI6Ik1Ga3dFd1lIS29aSXpqMENBUVlJS29aSXpqMERBUWNEUWdBRVBhZURDNElnT3VITlBmWCtURG5adXZuTHdUbHMwMERQb294aVZCTE8za3I0N0N3TXFYSm4yN3lpdFdZUkRRKzBmWG52MzFIbGJLbkxSWktqSmF5U3p3PT0iLCJpc3MiOiJTeW1iSW9UZV9Db3JlX0FBTSIsImV4cCI6MTUxMDU2Nzg2NywiaWF0IjoxNTEwNTY3MjY3LCJqdGkiOiI2MzI4NDUxMzAiLCJzcGsiOiJNRmt3RXdZSEtvWkl6ajBDQVFZSUtvWkl6ajBEQVFjRFFnQUVsdlNwYVhDa2RFZ3lYM2xJeWQ1VCs2VFgyQ0hXMDluekNjL05aY2krcGEvdmtQSG5DeFZESkpLTkZwL1hQc0g2T1hvSTkxQXJFcUJ1SlJtd3k2dWZSdz09In0.zn7xjwUq89YSNptLTFCZSpb8n65n4o24HPOw2WPTJSglfaO8paW1O5vC3n9072ktm327kj44Kgs5qqMhRy22cA", "authenticationChallenge":"", "clientCertificate":"", "clientCertificateSigningAAMCertificate":"","foreignTokenIssuingAAMCertificate":"" }' \
  -d '[
    {
        "inputParam1" : "on"
    }
]'
```

If invoking service is successful response code will be 200 and response body is JSON that service is
returning. Otherwise response code will return error and body will explain problem.

### 3.4.5 Push feature 

Applications can receive notifications from resources, through SymbIoTe RAP WebSocket. Client shall open
a WebSocket connection towards a Server at ***ws://II:PORT/notification***, where II and PORT are the
Interworking Interface parameters.

To subscribe (or unsubscribe) to resources you have to send a message to the WebSocket specifying:

```
{
  "secRequest": {
    { "key1" : "value1"},
    { "key2" : "value2"},
    ..
  }
  "payload": {
    "action": "SUBSCRIBE" / "UNSUBSCRIBE"
    "ids": ["id1", "id2", "id3", ...]
  }
}
```

Afterwards notifications will be automatically received by the application from the WebSocket.

Concrete example of request body subscribing default (dummy) resource in RAP is:

```
{
  "secRequest": {
    { "x-auth-timestamp": "1519652051000" }
    { "x-auth-size": "1" }
    { "x-auth-1": {"token":"eyJhbGciOiJFUzI1NiJ9.eyJ0dHlwIjoiR1VFU1QiLCJzdWIiOiJndWVzdCIsImlwayI6Ik1Ga3dFd1lIS29aSXpqMENBUVlJS29aSXpqMERBUWNEUWdBRVBhZURDNElnT3VITlBmWCtURG5adXZuTHdUbHMwMERQb294aVZCTE8za3I0N0N3TXFYSm4yN3lpdFdZUkRRKzBmWG52MzFIbGJLbkxSWktqSmF5U3p3PT0iLCJpc3MiOiJTeW1iSW9UZV9Db3JlX0FBTSIsImV4cCI6MTUxMDU2Nzg2NywiaWF0IjoxNTEwNTY3MjY3LCJqdGkiOiI2MzI4NDUxMzAiLCJzcGsiOiJNRmt3RXdZSEtvWkl6ajBDQVFZSUtvWkl6ajBEQVFjRFFnQUVsdlNwYVhDa2RFZ3lYM2xJeWQ1VCs2VFgyQ0hXMDluekNjL05aY2krcGEvdmtQSG5DeFZESkpLTkZwL1hQc0g2T1hvSTkxQXJFcUJ1SlJtd3k2dWZSdz09In0.zn7xjwUq89YSNptLTFCZSpb8n65n4o24HPOw2WPTJSglfaO8paW1O5vC3n9072ktm327kj44Kgs5qqMhRy22cA", "authenticationChallenge":"", "clientCertificate":"", "clientCertificateSigningAAMCertificate":"","foreignTokenIssuingAAMCertificate":"" }
  } }
  "payload": {
    "action": "SUBSCRIBE"
    "ids": ["5ab5db974a234e717380721f"]
  }
}
```

An example of a returned message from notifications, modeled as an instance of 
_eu.h2020.symbiote.model.cim.Observation_ class, is the following:

```
[
  {
    "resourceId": "5ab5db974a234e717380721f",
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

## 4. Creating RAP plugin

### 4.1. Customizing internal RAP plugin

RAP internal plugin is registered under pluginId with value **platform_01** and that can not be changed.
All resources need to have in registration pluginId and if you use internal one please use this value.
There is possibility to use value null but if you have more then one RAP plugins connected to RAP this
will not work.

#### 4.1.1 Configuring starting/not starting internal RAP plugin

RAP plugin that is build inside RAP service has configuration to start it or not:

*   for starting internal RAP plugin put following in bootstrap.properties in current working directory
of RAP or put it in CloudConfigProperties in file **ResourceAccessProxy.properties**:

```
rap.enableSpecificPlugin=true
```

*   to disable starting internal RAP plugin put following in the same files:

```
rap.enableSpecificPlugin=false
```
 

#### 4.1.2 Implementation of internal RAP plugin

All implementation is in class _eu.h2020.symbiote.plugin.PlatformSpecificPlugin_. There are 3 important methods:

*   readResource - for reading last observation from resource
*   readResourceHistory - for reading last 100 observations from resource
*   writeResource - for actuating resource and invoking service

##### 4.1.2.1 Reading last observation

Here is example of code:

```
/**
 * This is called when received request for reading resource.
 *
 * You need to checked if you can read sensor data with that internal id and in case
 * of problem you can throw RapPluginException
 *
 * @param resourceId internal id of sensor as registered
 *
 * @return string that contains JSON of one Observation
 *
 * @throws RapPluginException can be thrown when something went wrong. It has return code
 * that can be returned to consumer.
 */
 
@Override
public String readResource(String resourceId) {
    String json;
    try {
        //
        // INSERT HERE: query to the platform with internal resource id
        //
        // example
 
        if("isen1".equals(resourceId)) {
            Observation obs = observationExampleValue();
            ObjectMapper mapper = new ObjectMapper();
            json = mapper.writeValueAsString(obs);
            return json;
        } else {
            throw new RapPluginException(HttpStatus.NOT_FOUND.value(), "Sensor not found.");
        }
    } catch (JsonProcessingException ex) {
        throw new RapPluginException(HttpStatus.INTERNAL_SERVER_ERROR.value(), "Can not convert to JSON.", ex);
    }
}
```
 

Method *readResource* in argument receives internal resource id. This is the *id* under which this 
resource is registered.

In *line 24* is check that this internal id exists. It if does not exist in *line 30* **RapPluginException**
will be thrown.

RapPlugin exception has two parameters: 
*    response code that will be returned to RAP client 
*    message that will be in the response.

If internal resource id is valid the code in lines 25-28 is executed:

*   line 25 - creates one observation (in real world example creating observation should be reading som sensor data and creating observation from it),
*   line 26 - creates ObjectMapper that is used for serialisation of object to JSON,
*   line 27 - serialises Observation object to JSON,
*   line 28 - returns JSON string as response.

Here is example of code that creates one observation:
```

```
 

#### 4.1.2.2 Reading last 100 observations

This functionality is implemented in readResourceHistory method.

Here is an example of code:
```
/**
 * This is called when received request for reading resource history.
 *
 * You need to checked if you can read sensor data with that internal id and in case
 * of problem you can throw RapPluginException.
 *
 * Default is to return maximum of 100 observations.
 *
 * @param resourceId internal id of sensor as registered
 *
 * @return string that contains JSON with array of Observations (maximum 100)
 *
 * @throws RapPluginException can be thrown when something went wrong. It has return code
 * that can be returned to consumer.
 */
@Override
public String readResourceHistory(String resourceId) {
    String json;
    try {
        List<Observation> value = new ArrayList<>();
        //
        // INSERT HERE: query to the platform with internal resource id and
        // return list of observations in JSON
        //
        // Here is example
 
        if("isen1".equals(resourceId)) {
            Observation obs1 = observationExampleValue();
            Observation obs2 = observationExampleValue();
            Observation obs3 = observationExampleValue();
            value.add(obs1);
            value.add(obs2);
            value.add(obs3);
 
            ObjectMapper mapper = new ObjectMapper();
            json = mapper.writeValueAsString(value);
            return json;
        } else {
            throw new RapPluginException(HttpStatus.NOT_FOUND.value(), "Sensor not found.");
        }
    } catch (RapPluginException e) {
        throw e;
    } catch (Exception ex) {
        throw new RapPluginException(HttpStatus.INTERNAL_SERVER_ERROR.value(), ex);
    }
}
```
 
Method _readResourceHistory_ in argument receives internal resource id and returns JSON array with 
maximum of 100 observations serialised to string.

In *line 20* empty list of observations is created.

*Line 27* checks if internal id is valid. If it is not valid exception is thrown in *line 39*.

The reason why we catch _RapPluginException_ in *line 41* is because we do not want to wrap it in
another _RapPluginException_. Any other type of exceptions is caught in *line 43* and wrapped in
_RapException_ with response code 500 (Internal Server Error) that is thrown (*line 44*).

If everything is OK code from *lines 28-37* is executed:

*   lines 28-30 - creates 3 observations,
*   lines 31-33 - adds observations to list,
*   lines 35-37 - serialises list to JSON array and returns it (similar to the code in _readResource_).

#### 4.1.2.3 Actuating resource and invoking service

For both actuating and invoking service there is this one method writeResource. This method has two arguments:

1.  Internal resource id (same as in reading resource)
2.  Body data for either actuating resource or invoking service

Here is example of implementation that method:
```
/**
 * This method is called when actuating resource or invoking service is requested.
 *
 * In the case of actuation
 * body will be JSON Object with capabilities and parameters.
 * Actuation does not return value (it will be ignored).
 * Example of body:
 * <pre>
 * {
 *   "SomeCapabililty" : [
 *     {
 *       "param1" : true
 *     },
 *     {
 *       "param2" : "some text"
 *     },
 *     ...
 *   ]
 * }
 * </pre>
 *
 * In the case of invoking service body will be JSON Array with parameters.
 * Example of body:
 * <pre>
 * [
 *   {
 *     "inputParam1" : false
 *   },
 *   {
 *     "inputParam2":"some text"
 *   },
 *   ...
 * ]
 * </pre>
 *
 * @param body JSON input depending on what is called (actuation or invoking service)
 *
 * @return returns JSON string that will be returned as response
 *
 * @throws RapPluginException can be thrown when something went wrong. It has return code
 * that can be returned to consumer.
 */
@Override
public String writeResource(String resourceId, String body) {
    // INSERT HERE: call to the platform with internal resource id
    String newBody = body.trim();
    if(newBody.charAt(0) == '{') {
        // actuation
        System.out.println("Actuation on resource " + resourceId + " called.");
        if("iaid1".equals(resourceId)) {
            try {
                // This is example of extracting data from body
                ObjectMapper mapper = new ObjectMapper(); 
                HashMap<String,ArrayList<HashMap<String, Object>>> jsonObject =
                        mapper.readValue(body, new TypeReference<HashMap<String,ArrayList<HashMap<String, Object>>>>() { });
                for(Entry<String, ArrayList<HashMap<String,Object>>> capabilityEntry: jsonObject.entrySet()) {
                    System.out.println("Found capability " + capabilityEntry.getKey());
                    System.out.println(" There are " + capabilityEntry.getValue().size() + " parameters.");
                    for(HashMap<String, Object> parameterMap: capabilityEntry.getValue()) {
                        for(Entry<String, Object> parameter: parameterMap.entrySet()) {
                            System.out.println(" paramName: " + parameter.getKey());
                            System.out.println(" paramValueType: " + parameter.getValue().getClass().getName() + " value: " + parameter.getValue() + "\n");
                        }
                    }
                }
                System.out.println("jsonObject:  " + jsonObject);
                // actuation always returns null if everything is ok
                return null;
            } catch (IOException e) {
                throw new RapPluginException(HttpStatus.INTERNAL_SERVER_ERROR.value(), e.getMessage());
            }
        } else {
            throw new RapPluginException(HttpStatus.NOT_FOUND.value(), "Sensor not found.");
        }
    } else {
        // invoking service
        System.out.println("Invoking service " + resourceId + ".");
        if("isrid1".equals(resourceId)) {
            try {
                // extracting service parameters
                ObjectMapper mapper = new ObjectMapper(); 
                ArrayList<HashMap<String, Object>> jsonObject =
                        mapper.readValue(body, new TypeReference<ArrayList<HashMap<String, Object>>>() { });
                for(HashMap<String,Object> parameters: jsonObject) {
                    System.out.println("Found " + parameters.size() + " parameter(s).");
                    for(Entry<String, Object> parameter: parameters.entrySet()) {
                        System.out.println(" paramName: " + parameter.getKey());
                        System.out.println(" paramValueType: " + parameter.getValue().getClass().getName() + " value: " + parameter.getValue() + "\n");
                    }
                }
                System.out.println("jsonObject:  " + jsonObject);
                // Service can return either null if nothing to return or some JSON
                // example
                return "\"some json\"";
            } catch (IOException e) {
                throw new RapPluginException(HttpStatus.INTERNAL_SERVER_ERROR.value(), e.getMessage());
            }
        } else {
            throw new RapPluginException(HttpStatus.NOT_FOUND.value(), "Service not found!");
        }
    }
}
```
 

We can differentiate actuating resource and invoking service by looking into body argument:

*   If in body is JSON object then it is actuating resource
*   If in body is JSON array then it is invoking service.

*Lines 46, 47* are checking that. So actuating resource is in *lines 48-74* and invoking service is in
*lines 76-100*.

###### 4.1.2.3.1 Actuating resource

In the case of actuating resource (*lines 48-74*) we will get in body JSON object in the following format:

**JSON for actuating resource**

```
{
  "SomeCapabililty" : [
    {
      "param1" : true
    },
    {
      "param2" : "some text"
    },
    ...
  ]
}
```

The object has property _"SomeCapability"_ that has to conform to semantic model of registered resource.
The value is array of parameters. Here the first parameter name is _param1_ and its value is boolean _true_.
The second parameter name is _param2_ and its value is string _"some text"_.
This is parsed with _ObjectMapper_ (created in line 53). Actual parsing is in *lines 54, 55*.

The result of parsing is structure _HashMap<String,ArrayList<HashMap<String,_ Object>>>. Outer _HashMap_ has
for keys name of capability and value is _ArrayList_ of parameters. Parameters are also _HashMap_ where the
key is name of parameter and value is the value. In this example, all structure is just printed. In real
implementation after extracting parameters you should implement actuating (e.g. turning light on).

The actuating resource must return _null_ as result (*line 68*).

###### 4.1.2.3.2 Invoking service

In the case of invoking service (*lines 76-100*) we will get in body JSON array in the following format:

```
[
  {
    "inputParam1" : false
  },
  {
    "inputParam2":"some text"
  },
  ...
]
```

The array consists of parameters which are the same as in actuating resource. This is parsed in *lines 81-83*.
The result of parsing is _ArrayList<HashMap<String, Object>>_. Parameters are _HashMaps_ where the key is 
the name of the parameter and the value is the value. So, in this example first element of _ArrayList_ is
_HashMap_ that has one entry. This entry has key "inputParameter1" and the value is _Boolean_ with value
_false_.

The concrete code just writes parsed parameters (*lines 84-91*) and returns an example of JSON back to RAP
client (*line 94*). The result will be returned in the form of JSON string.

### 4.2. Using RAP plugin starter

The idea of RAP Plugin Starter is to use it as dependency in implementation that connects platform with
SymbIoTe RAP service. Generic parts like RabbitMQ communication with RAP component is implemented in RAP
Plugin Starter library. That way a developer does not have to implement complex communication.

All instructions regarding how to create RAP Plugin with RAP Plugin starter are
[here]("https://github.com/symbiote-h2020/ResourceAccessProxyPluginStarter"). The example of whole project is in [this repository]("https://github.com/symbiote-h2020/RapPluginExample").

### 4.3. Creating RAP plugin in other languages

At the beginning, the platform plugin application has to register to the generic RAP, sending a message to
exchange _symbIoTe.rapPluginExchange_ with key _symbIoTe.rapPluginExchange.add-plugin_, with some information
included:
*   the platform ID (a custom string, used )
*   a boolean flag specifying it supports notifications,
*   a boolean flag specifying it supports filters. 

This is the message format expected during plugin registration:

```
{
  type: REGISTER_PLUGIN,
  platformId: string,
  hasNotifications: boolean,
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

Platform ID is used to specify which is the plugin that is going to handle the resource access request;
this is needed in case of multiple plugins. Consequently, the same string has to be added also during
resource registration (as an addidional parameter) and as routing key for rabbit messages during resource
access (_platformId.get_, _platformId.set_, etc.).

If the platform can natively support filters/notifications, different configuration steps are required:

1.  Filters:
    1.  If platform supports filters, RAP plugin just forwards filters to platform supporting filters
    2.  (Optionally) a platform owner can decide to implement filters in RAP platform specific plugin
    3.  If platform doesn=E2=80=99t support filters the historical readings are retrieved without any filter
2.  Notifications:
    1.  Enable/disable flag in CloudConfigProperties -> _rap.northbound.interface.WebSocket=true/false

#### 4.3.1 Accessing resources

In order to receive messages for accessing resources, platform plugin shall create an exchange with name
_plugin-exchange_ and then bind to it the following:
*   _platformId.get_
*   _platformId.set_
*   _platformId.history_
*   _platformId.subscribe_
*   _platformId.unsubscribe_

Access features supported are (NB: the following examples refer to OData queries
(e.g. _/rap/Sensors('abcdefgh')/Observations_), where paths were split in JSON arrays):

*   Read current value from resource, e.g.:
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
*   Read history values from resource  
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
    "param" : "temperature",
    "cmp" : "EQ",
    "val" : "20"
  },
  "type" : "HISTORY"
}
```

The read history values can be received with or without filters, depending on whether the plugin is
supporting filters or not.
    
*   Actuating resource or invoking service 
    
    When such request is requested, the body of the message will also include parameters needed for the actuation/invoking service, in a format that depends on the resource accessed:
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

#### 4.3.2 Notification

The notifications mechanism follows a different flow than the direct resource access and needs a specific
rabbitMQ queues to be used.

1.  The platform plugin will receive subscription/unsubscription requests from the _plugin-exchange_,
 using _subscribe/unsubscribe_ topic keys. The message will contain a list of resource IDs.
2.  Notifications should be sent from RAP plugin to generic RAP to RabbitMQ exchange 
_symbIoTe.rapPluginExchange-notification_ with a routing key 
_symbIoTe.rapPluginExchange.plugin-notification_.

All returned messages from read accesses (GET, HISTORY and notifications) are modeled as an instance of 
_eu.h2020.symbiote.model.cim.Observation_ class, e.g.:

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

# 5 Resource Description Examples
Below you can find some examples for describing various kind of resources

## 5.1 JSON Description Examples
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

## 5.2 RDF Description Examples
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

 
