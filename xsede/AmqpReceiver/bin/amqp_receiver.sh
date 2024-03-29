#!/bin/sh -x


file_list=`find lib -type f`
classpath="build/classes"

for jar_file in $file_list; do
  classpath="$classpath:$jar_file"
done

java -Xms256M -Xmx1024M -ea -cp "$classpath" org.xsede.ReceiverExample $@
