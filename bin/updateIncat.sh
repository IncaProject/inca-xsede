#!/bin/bash


file_list=`find lib/ -type f`
classpath="build/update-incat.jar"

for jar_file in $file_list; do
  classpath="$classpath:$jar_file"
done

if [ "$1" = "auto" ]; then
  java -Xms256M -Xmx1024M -ea -cp "$classpath" edu.sdsc.inca.UpdateIncat config-auto.xml cache incat-auto.xml
else
  java -Xms256M -Xmx1024M -ea -cp "$classpath" edu.sdsc.inca.UpdateIncat $@
fi
