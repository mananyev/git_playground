# install Java
mkdir spark
cd spark/
wget https://download.java.net/java/GA/jdk11/9/GPL/openjdk-11.0.2_linux-x64_bin.tar.gz
tar xzvf openjdk-11.0.2_linux-x64_bin.tar.gz
# clean
rm openjdk-11.0.2_linux-x64_bin.tar.gz

# export variables
export JAVA_HOME="${HOME}/spark/jdk-11.0.2"
export PATH="${JAVA_HOME}/bin:${PATH}"

# test
which java
java --version

# Install Spark
wget https://archive.apache.org/dist/spark/spark-3.3.2/spark-3.3.2-bin-hadoop3.tgz
tar xzvf spark-3.3.2-bin-hadoop3.tgz
# clean
rm spark-3.3.2-bin-hadoop3.tgz

# test
spark-shell
# in the shell:
val data = 1 to 10000
val distData = sc.parallelize(data)
distData.filter(_ < 10).collect()
