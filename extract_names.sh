#!/bin/sh
TMP_NAMES=`mktemp`
TMP_TAGS=`mktemp`
OUTPUT="$1"

ctags -x --c-kinds=f -f *.c | grep "^Java_\|^JNI_" | cut -d' ' -f 1 > "$TMP_NAMES"
ctags --c-kinds=f --fields=+ST -f "$TMP_TAGS" *.c > /dev/null

rm -f "$OUTPUT"

cat <<EOF >> "$OUTPUT"
#include <jni.h>

#define UNUSED	__attribute__ ((__unused__))

EOF

while read FN_NAME; do
	FN_SIGNATURE=`cat "$TMP_TAGS" | grep "^$FN_NAME	" | cut -f 5 | sed 's/signature://'`
	FN_RETURNTYPE=`cat "$TMP_TAGS" | grep "^$FN_NAME	" | cut -f 6 | sed 's/returntype://' | sed 's/[ ]*JNIEXPORT[ ]*//' | sed 's/[ ]*JNICALL[ ]*//'`
	echo "extern $FN_RETURNTYPE $FN_NAME $FN_SIGNATURE;" >> "$OUTPUT"
done < "$TMP_NAMES"

cat <<EOF >> "$OUTPUT"

typedef struct method_entry {
	char *name;
	void *func;
	int type;
} methodEntry;

methodEntry cherijni_MethodList[] = {
EOF

while read FN_NAME; do
	FN_RETURNTYPE=`cat "$TMP_TAGS" | grep "^$FN_NAME	" | cut -f 6 | sed 's/returntype://' | sed 's/[ ]*JNIEXPORT[ ]*//' | sed 's/[ ]*JNICALL[ ]*//'`
	case "$FN_RETURNTYPE" in
	void) 	
		FN_TYPE=1 
		;;
	jint|jlong|jbyte|jboolean|jchar|jshort|jfloat|jdouble|jsize)
		FN_TYPE=2
		;;
	jobject|jclass|jstring|jthrowable|jweak|jarray|j*Array) 
		FN_TYPE=3 
		;;
	*) 
		echo "Unknown return type \"$FN_RETURNTYPE\""
		exit 1
		;;
	esac
	echo "	{ \"$FN_NAME\", &$FN_NAME, $FN_TYPE }," >> "$OUTPUT"
done < "$TMP_NAMES"

cat <<EOF >> "$OUTPUT"
	{NULL, NULL, 0}
};
EOF

rm -f "$TMP_NAMES" "$TMP_TAGS"
