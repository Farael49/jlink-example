# jlink
We'll be creating a simple spring boot application (spring web, spring data jpa, H2 DB), & see how to get it running with a minimal JRE using Jlink :
We'll be using github actions to create a container image of our Jar & its custom JRE.

# What is jlink ? 
As stated in Oracle's docs, jlink is a command line "tool to assemble and optimize a set of modules and their dependencies into a custom runtime image." 
Using it allows us to get a minimal runtime to run our application, embedding only the necessary modules and not the whole JRE. 

# Why using jlink ?
It's main advantage would be reducing the size of our Docker images. 
We don't need to ship the whole JRE on our images, and we can provide the runtime to any image.  
As we get rid of unnecessary modules, we may also see an improvement on startup time, although it may not be easily noticeable on a typical enterprise application.

# How to use jlink ?
From jlink's documentation
> The following command creates a runtime image in the directory greetingsapp. This command links the module com.greetings, whose module definition is contained in the directory mlib. The directory $JAVA_HOME/jmods contains java.base.jmod and the other standard and JDK modules.
> jlink --module-path $JAVA_HOME/jmods:mlib --add-modules com.greetings --output greetingsapp

# Pushing jlink to the limit 
We can improve our result depending on our goals with optional parameters :
Reducing our runtime size :
- compress: 
Level 0: No compression
Level 1: Constant string sharing
Level 2: ZIP
- include-locales : get rid of unnecessary locales
- strip-debug : remove debugging information

Reducing our startup time :
- class-for-name : "Class optimization, converts Class.forName calls to constant loads."
- generate-jli-classes : move the overhead of lambdas code generation from runtime to linktime 
If you want to go further on reducing your startup time, you may be interested in CDS, Application CDS & AOT (jaotc).  

# Sources :
https://docs.oracle.com/javase/9/tools/jlink.htm

https://blog.gilliard.lol/2017/11/07/Java-modules-and-jlink.html

https://cl4es.github.io/2018/11/29/OpenJDK-Startup-From-8-Through-11.html

https://medium.com/codefx-weekly/is-jlink-the-future-1d8cb45f6306
