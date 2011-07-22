#!/bin/bash

echo '<?xml version="1.0" encoding="UTF-8"?>' > ./main.xml
echo '<ocf resource:version="1.0" type="resource" author="The ORCF release team">' >> ./main.xml
echo '  <resources>' >> ./main.xml
echo '<?xml version="1.0" encoding="UTF-8"?>' > ./mainlist.xml
echo '<ocf resource:version="1.0" type="resource" author="The ORCF release team">' >> ./mainlist.xml
echo '  <resources>' >> ./mainlist.xml
echo '    <resource resource:name="songlist" resource:id="0" resource:section="0" resource:format="xmlsonglist" resource:version="1.0" />' >> ./mainlist.xml

echo '<songlist>' > ./list.xml

songid=0
songbins=""

for i in `find ${2} -type f -name "*.ogg"`; do
	title="`echo ${i} | sed -r 's/^.*\/([a-zA-Z0-9 _+-]*)\..*$/\1/g' | sed 's/_/ /g'`"
	album="`ffmpeg -i ${i} 2>&1 | grep ALBUM | sed -r 's/^.*: (.*) *$/\1/g'`"
	artist="`ffmpeg -i ${i} 2>&1 | grep ARTIST | sed -r 's/^.*: (.*) *$/\1/g'`"
	genre="`ffmpeg -i ${i} 2>&1 | grep GENRE | sed -r 's/^.*: (.*) *$/\1/g'`"
	if [ -z "${title}" ]; then title="Unnamed Song"; fi
	if [ -z "${album}" ]; then album="Unknown Album"; fi
	if [ -z "${artist}" ]; then artist="Unknown Artist"; fi
	if [ -z "${genre}" ]; then genre="None"; fi
	echo "Found: ${title} by ${artist} on ${album} [ ${genre} ]"
	echo "    <resource resource:name=\"song${songid}\" resource:id=\"${songid}\" resource:section=\"${songid}\" resource:format=\"oggvorbis\" resource:version=\"1.0\" />" >> ./main.xml
	echo "  <song resource:name=\"music/${1}.ocf/song${songid}\" artist=\"${artist}\" album=\"${album}\" title=\"${title}\" genre=\"${genre}\" />" >> ./list.xml
	echo " -b \"${i}\" \\\\" >> ./genocf.sh
	songid=$((${songid}+1))
	songbins="${songbins} -b \"${i}\""
done

echo "../../../tools/ocfgen -x ./mainlist.xml -b list.xml -o \"../${1}-list.ocf\"" > ./genocf.sh
echo "../../../tools/ocfgen -x ./main.xml ${songbins} -o \"../${1}.ocf\"" >> ./genocf.sh

echo '</songlist>' >> ./list.xml
echo '  </resources>' >> ./main.xml
echo '</ocf>' >> ./main.xml
echo '  </resources>' >> ./mainlist.xml
echo '</ocf>' >> ./mainlist.xml

echo "Generating OCF"
chmod +x ./genocf.sh
./genocf.sh
echo "Done!"
