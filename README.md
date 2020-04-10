# jlink
We'll be creating a simple spring boot application (spring web, spring data jpa, H2 DB), & see how to get it running with a minimal JRE using jlink

We'll also use github actions to create a container image of our Jar & its custom JRE.

# What is jlink ? 
As stated in Oracle's docs, jlink is a command line "tool to assemble and optimize a set of modules and their dependencies into a custom runtime image." 
Using it allows us to get a minimal runtime to run our application, embedding only the necessary modules and not the whole JRE. 

# Why use jlink ?
Its main advantage would be reducing the size of our Docker images. 
We don't need to ship the whole JRE on our images, and we can provide the runtime to any image.  
As we get rid of unnecessary modules, we may also see an improvement on startup time, although it may not be easily noticeable on a typical enterprise application.

# How to use jlink ?
From the documentation

> The following command creates a runtime image in the directory greetingsapp. This command links the module com.greetings, whose module definition is contained in the directory mlib. The directory $JAVA_HOME/jmods contains java.base.jmod and the other standard and JDK modules.

` jlink --module-path $JAVA_HOME/jmods:mlib --add-modules com.greetings --output greetingsapp `
We'll see how  to apply this to a spring boot application

## 1 - Generate our Project
The project was generated from https://start.spring.io with H2, Spring Data JPA, Spring Web, Java 14 & Spring Boot 2.3.0.M4 (living on the edge 😀) 

## 2 - Get our Modules list
For our Spring project, the tricky thing is getting the modules to add. 

On a simple modular project, we can use the `jdeps` tool on our generated JAR to get its dependencies. 

For Spring we encounter some issues preventing us from getting the proper dependencies list 

Running 
`jdeps -s target/app.jar`
returns only

> - app.jar -> java.base
> - app.jar -> java.logging
> - app.jar -> not found

Removing the -s (summary) tells us the "not found" comes from the spring dependencies. 

Extracting the lib folder from our jar and running jdeps with it (as we need to know the modules our libs rely on) :

`jdeps -cp "target/lib/*" -s --multi-release=14 --recursive target/app.jar`

returns much more modules, but we still encounter some pesky "not found" 

You can get the app running by combining the modules from jdeps and googling around for the NoClassDefFound to find the missing ones.  
I ended up with the following modules
`java.base,java.logging,java.xml,java.sql,java.naming,java.desktop,java.management,java.instrument,java.security.jgss`

Getting the modules _could_ be automated for a proper modular project (only depending on modular projects and so on), but here we have to manually maintain this list to create our runtime. Keep in mind that adding a new dependency could depend on a new module, and the NoClassDefFound will only be encountered at runtime, so ... **_test your docker images_**. 

## 3 - Generate our runtime
``` 
$ jlink --module-path $JAVA_HOME/jmods \ 
        --add-modules java.base,java.logging,java.xml,java.sql,java.naming,java.desktop,java.management,java.instrument,java.security.jgss     --output custom-jre
```

## 4 - Wrap it up under a Github Action
We'll build our JRE with the github actions, and ship it with our app in a docker image. 
Our custom JRE is specific to an OS, our list of modules and additional options. We're using actions/cache in order to reuse a previously made JRE if these don't change. To properly cache it, the jlink options were put on a file (see jlink --save-opts) from which we get the hash. If the file change, the hash change, meaning we have to rebuild our runtime. 
```
  build-jre:
    runs-on: ubuntu-latest
    steps:
      - name: Cache runtime
        id: cache-runtime
        uses: actions/cache@v1
        with:
          path: custom-jre
          key: ${{ runner.os }}-${{ hashFiles('**/jlink-opts.txt') }}
      - name: Set up JDK 1.14
        if: steps.cache-runtime.outputs.cache-hit != 'true'
        uses: actions/setup-java@v1
        with:
          java-version: 1.14
      - name: Create custom runtime
        if: steps.cache-runtime.outputs.cache-hit != 'true'
        run: jlink @jlink-opts.txt
      - uses: actions/upload-artifact@v1
        if: steps.cache-runtime.outputs.cache-hit != 'true'
        with:
          name: runtime
          path: custom-jre
```

# Pushing jlink to the limit 
We can improve our result depending on our goals with optional parameters, mainly :

Reducing runtime size :
- compress: 
Level 0: No compression
Level 1: Constant string sharing
Level 2: ZIP
- include-locales : get rid of unnecessary locales
- strip-debug : remove debugging information
- no-header-files
- no-man-pages 

Reducing startup time :
- class-for-name : "Class optimization, converts Class.forName calls to constant loads."
- generate-jli-classes : move the overhead of lambdas code generation from runtime to linktime 

If you want to go further on reducing your startup time, you may be interested in CDS, Application CDS, Graal & AOT (jaotc).  

# Result
# Conclusion


# Sources :
https://docs.oracle.com/javase/9/tools/jlink.htm

https://blog.gilliard.lol/2017/11/07/Java-modules-and-jlink.html

https://cl4es.github.io/2018/11/29/OpenJDK-Startup-From-8-Through-11.html

https://medium.com/codefx-weekly/is-jlink-the-future-1d8cb45f6306
