#!/bin/bash

echo '<?xml version="1.0" encoding="UTF-8"?>' > ./main.xml
echo '<ocf resource:version="1.0" type="resource" author="The ORCF release team">' >> ./main.xml
echo '  <resources>' >> ./main.xml
echo '    <resource reource:name="songlist" resource:id="0" resource:section="0" resource:format="xmlsonglist" resource:version="1.0" />' >> ./main.xml

echo '<songlist>' > ./list.xml

songid=1
songbins=""

for i in `find ${2} -type f -name "*.ogg"`; do
	title="`echo ${i} | sed -r 's/^.*\/([a-zA-Z0-9 _+-]*)\..*$/\1/g' | sed 's/_/ /g'`"
	album="`ffmpeg -i ${i} 2>&1 | grep ALBUM | sed -r 's/^.*: (.*) *$/\1/g'`"
	artist="`ffmpeg -i ${i} 2>&1 | grep ARTIST | sed -r 's/^.*: (.*) *$/\1/g'`"
	genre="`ffmpeg -i ${i} 2>&1 | grep GENRE | sed -r 's/^.*: (.*) *$/\1/g'`"
	echo "Found: ${title} by ${artist} on ${album} [ ${genre} ]"
	echo "    <resource reource:name=\"song${songid}\" resource:id=\"${songid}\" resource:section=\"${songid}\" resource:format=\"oggvorbis\" resource:version=\"1.0\" />" >> ./main.xml
	echo "  <song resource:name=\"music/${1}/song${songid}\" artist=\"${artist}\" album=\"${album}\" title=\"${title}\" genre=\"${genre}\" />" >> ./list.xml
	echo " -b \"${i}\" \\\\" >> ./genocf.sh
	songid=$((${songid}+1))
	songbins="${songbins} -b \"${i}\""
done

echo "-o \"../${1}\"" >> ./genocf.sh
echo "../../../tools/ocfgen -x ./main.xml -b ./list.xml ${songbins} -o \"../${1}\"" > ./genocf.sh

echo '</songlist>' >> ./list.xml
echo '  </resources>' >> ./main.xml
echo '</ocf>' >> ./main.xml

echo "Generating OCF"
chmod +x ./genocf.sh
./genocf.sh
echo "Done!"
