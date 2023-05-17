# Java

This doc outlines how Java is packaged within Wolfi, and how to determine which package is right for your needs.

Each version of Java provided by Wolfi consists of the following packages:

- `openjdk-#-jre`: the Java Runtime Environment (JRE)
- `openjdk-#`: the Java Development Kit (JDK) and the JRE

The installation location for these packages is `/usr/lib/jvm/java-#-openjdk`. It is important to note that this path is **not** added to the default `$PATH` when installed. Instead, we strongly recommend that you configure `JAVA_HOME=/usr/lib/jvm/java-#-openjdk` post installation, and if you require the Java tooling on your default `$PATH`, to add it post installation. An example of this being done is below:

```bash
export JAVA_HOME=/usr/lib/jvm/java-#-openjdk
export PATH=$JAVA_HOME/bin:$PATH
```

Alternatively, a compatibility package: `openjdk-#-default-jvm` is provided that will provide both the JDK, JRE, and ensure they are added to the default `$PATH`.
